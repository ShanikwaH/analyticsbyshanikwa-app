/**
 * Proving the caller actually bought the thing.
 *
 * iOS      StoreKit 2 gives the app a transaction id. We ask Apple's App Store
 *          Server API about it, authenticating with a JWT signed by an App
 *          Store Connect key (ES256, .p8).
 * Android  The app has a purchaseToken. We ask Google's Android Publisher API,
 *          authenticating with a service account (RS256 JWT -> access token).
 *
 * Everything fails closed: any missing config, network error, unexpected shape
 * or mismatch returns not-entitled. There is no path where an error grants a
 * download.
 *
 * `deps` exists so the tests can inject fetch and a fixed clock — these paths
 * are impossible to exercise for real without live store credentials.
 */

const enc = new TextEncoder();

const b64url = (bytes) => {
  let s = '';
  for (const b of new Uint8Array(bytes)) s += String.fromCharCode(b);
  return btoa(s).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
};

const b64urlJson = (obj) => b64url(enc.encode(JSON.stringify(obj)));

/** Decode a JWS payload WITHOUT verifying. Only safe for data Apple just
 *  handed us over TLS on an authenticated call — never for client input. */
function decodeJwsPayload(jws) {
  const parts = String(jws || '').split('.');
  if (parts.length !== 3) return null;
  try {
    const pad = parts[1].length % 4 ? '='.repeat(4 - (parts[1].length % 4)) : '';
    const bin = atob(parts[1].replace(/-/g, '+').replace(/_/g, '/') + pad);
    const bytes = Uint8Array.from(bin, (c) => c.charCodeAt(0));
    return JSON.parse(new TextDecoder().decode(bytes));
  } catch {
    return null;
  }
}

/** PEM (PKCS#8) -> DER bytes. Handles the \n-escaped form env vars usually hold. */
function pemToDer(pem) {
  const body = String(pem || '')
    .replace(/\\n/g, '\n')
    .replace(/-----[A-Z ]+-----/g, '')
    .replace(/\s+/g, '');
  if (!body) throw new Error('empty key');
  const bin = atob(body);
  return Uint8Array.from(bin, (c) => c.charCodeAt(0)).buffer;
}

async function signJwtES256(privatePem, header, payload) {
  const key = await crypto.subtle.importKey(
    'pkcs8', pemToDer(privatePem),
    { name: 'ECDSA', namedCurve: 'P-256' }, false, ['sign']);
  const data = `${b64urlJson(header)}.${b64urlJson(payload)}`;
  // WebCrypto returns raw r||s, which is exactly the JOSE ES256 encoding.
  const sig = await crypto.subtle.sign(
    { name: 'ECDSA', hash: 'SHA-256' }, key, enc.encode(data));
  return `${data}.${b64url(sig)}`;
}

async function signJwtRS256(privatePem, header, payload) {
  const key = await crypto.subtle.importKey(
    'pkcs8', pemToDer(privatePem),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['sign']);
  const data = `${b64urlJson(header)}.${b64urlJson(payload)}`;
  const sig = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, enc.encode(data));
  return `${data}.${b64url(sig)}`;
}

const deny = (reason) => ({ ok: false, status: 403, reason });
const misconfigured = (reason) => ({ ok: false, status: 500, reason });

// ---------------------------------------------------------------- Apple

export async function verifyApple(env, { productId, receipt }, deps = {}) {
  const fetchFn = deps.fetch || fetch;
  const now = deps.now || Date.now;

  const { APPLE_ISSUER_ID, APPLE_KEY_ID, APPLE_PRIVATE_KEY, APPLE_BUNDLE_ID } = env;
  if (!APPLE_ISSUER_ID || !APPLE_KEY_ID || !APPLE_PRIVATE_KEY || !APPLE_BUNDLE_ID) {
    return misconfigured('apple credentials missing');
  }
  const transactionId = String(receipt || '').trim();
  if (!/^[0-9]{5,25}$/.test(transactionId)) return deny('bad transaction id');

  let jwt;
  try {
    const iat = Math.floor(now() / 1000);
    jwt = await signJwtES256(
      APPLE_PRIVATE_KEY,
      { alg: 'ES256', kid: APPLE_KEY_ID, typ: 'JWT' },
      { iss: APPLE_ISSUER_ID, iat, exp: iat + 600, // Apple caps this at 60 min
        aud: 'appstoreconnect-v1', bid: APPLE_BUNDLE_ID });
  } catch (e) {
    return misconfigured(`apple key unusable: ${e.message}`);
  }

  // Production first; 4040010 means "try sandbox", which is what a TestFlight
  // or sandbox tester purchase returns.
  const hosts = [
    'https://api.storekit.itunes.apple.com',
    'https://api.storekit-sandbox.itunes.apple.com',
  ];
  for (const host of hosts) {
    let res;
    try {
      res = await fetchFn(`${host}/inApps/v1/transactions/${transactionId}`, {
        headers: { authorization: `Bearer ${jwt}` },
      });
    } catch {
      return { ok: false, status: 503, reason: 'apple unreachable' };
    }
    if (res.status === 404) continue;      // not in this environment, try the next
    if (res.status === 401) return misconfigured('apple rejected our key');
    if (!res.ok) return { ok: false, status: 503, reason: `apple ${res.status}` };

    let body;
    try { body = await res.json(); } catch { return deny('apple bad response'); }
    const tx = decodeJwsPayload(body.signedTransactionInfo);
    if (!tx) return deny('apple bad transaction');

    if (tx.bundleId !== APPLE_BUNDLE_ID) return deny('bundle mismatch');
    if (tx.productId !== productId) return deny('product mismatch');
    if (tx.revocationDate) return deny('refunded');
    return { ok: true };
  }
  return deny('transaction not found');
}

// ---------------------------------------------------------------- Google

export async function verifyGoogle(env, { productId, receipt }, deps = {}) {
  const fetchFn = deps.fetch || fetch;
  const now = deps.now || Date.now;

  const { GOOGLE_SA_EMAIL, GOOGLE_SA_KEY, ANDROID_PACKAGE } = env;
  if (!GOOGLE_SA_EMAIL || !GOOGLE_SA_KEY || !ANDROID_PACKAGE) {
    return misconfigured('google credentials missing');
  }
  const purchaseToken = String(receipt || '').trim();
  if (purchaseToken.length < 20) return deny('bad purchase token');

  let assertion;
  try {
    const iat = Math.floor(now() / 1000);
    assertion = await signJwtRS256(
      GOOGLE_SA_KEY,
      { alg: 'RS256', typ: 'JWT' },
      { iss: GOOGLE_SA_EMAIL,
        scope: 'https://www.googleapis.com/auth/androidpublisher',
        aud: 'https://oauth2.googleapis.com/token', iat, exp: iat + 3600 });
  } catch (e) {
    return misconfigured(`google key unusable: ${e.message}`);
  }

  let accessToken;
  try {
    const tokRes = await fetchFn('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'content-type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion,
      }).toString(),
    });
    if (!tokRes.ok) return misconfigured('google rejected our service account');
    accessToken = (await tokRes.json()).access_token;
    if (!accessToken) return misconfigured('google returned no access token');
  } catch {
    return { ok: false, status: 503, reason: 'google unreachable' };
  }

  const url = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/` +
    `${encodeURIComponent(ANDROID_PACKAGE)}/purchases/products/` +
    `${encodeURIComponent(productId)}/tokens/${encodeURIComponent(purchaseToken)}`;

  let res;
  try {
    res = await fetchFn(url, { headers: { authorization: `Bearer ${accessToken}` } });
  } catch {
    return { ok: false, status: 503, reason: 'google unreachable' };
  }
  if (res.status === 404 || res.status === 400) return deny('purchase not found');
  if (!res.ok) return { ok: false, status: 503, reason: `google ${res.status}` };

  let p;
  try { p = await res.json(); } catch { return deny('google bad response'); }

  // 0 = purchased, 1 = cancelled, 2 = pending. Only 0 is entitled.
  if (p.purchaseState !== 0) return deny('not purchased');
  return { ok: true };
}

// ---------------------------------------------------------------- dispatch

export async function verifyStores(env, { productId, platform, receipt }, deps = {}) {
  if (platform === 'ios') return verifyApple(env, { productId, receipt }, deps);
  if (platform === 'android') return verifyGoogle(env, { productId, receipt }, deps);
  return deny('unknown platform');
}
