/**
 * Short-lived signed download tokens.
 *
 * This is the half of the fulfilment story that can be built and proven today:
 * given that someone is entitled to a file, hand them a URL that works for a
 * few minutes and then stops. The other half — deciding WHO is entitled, by
 * validating an App Store or Play receipt — needs store credentials that do
 * not exist until the developer accounts do. See index.js `verifyEntitlement`.
 *
 * Format:  base64url(JSON claims) + "." + base64url(HMAC-SHA256 of that)
 *
 * Deliberate choices:
 *  - No algorithm field in the token. JWT's `alg` header is the source of the
 *    classic "alg: none" and HS/RS confusion attacks; there is nothing to
 *    negotiate here, so nothing to downgrade.
 *  - Signature is checked with crypto.subtle.verify, which is constant-time.
 *    A hand-rolled string compare would leak timing.
 *  - Expiry is inside the signed payload, so it cannot be edited.
 *  - The product id is inside the payload too: a token minted for one product
 *    must not unlock another. The caller is expected to compare.
 *
 * Runs unmodified on Cloudflare Workers and in Node 18+ (both have WebCrypto).
 */

const enc = new TextEncoder();
const dec = new TextDecoder();

function b64url(bytes) {
  let s = '';
  for (const b of bytes) s += String.fromCharCode(b);
  return btoa(s).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function unb64url(str) {
  const pad = str.length % 4 === 0 ? '' : '='.repeat(4 - (str.length % 4));
  const bin = atob(str.replace(/-/g, '+').replace(/_/g, '/') + pad);
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
}

async function hmacKey(secret) {
  if (typeof secret !== 'string' || secret.length < 16) {
    throw new Error('signing secret must be a string of at least 16 chars');
  }
  return crypto.subtle.importKey(
    'raw', enc.encode(secret),
    { name: 'HMAC', hash: 'SHA-256' }, false, ['sign', 'verify']);
}

/**
 * Mint a token.
 * @param {string} secret   shared signing secret (Worker env, never shipped in the app)
 * @param {object} claims   e.g. { productId: 'com.x.bundle.cpa', file: 'cpa.zip' }
 * @param {number} ttlSeconds  how long the link stays good
 * @param {number} [nowMs]  injectable clock, for tests
 */
export async function sign(secret, claims, ttlSeconds, nowMs = Date.now()) {
  if (!claims || typeof claims !== 'object') throw new Error('claims required');
  if (!Number.isFinite(ttlSeconds) || ttlSeconds <= 0) {
    throw new Error('ttlSeconds must be a positive number');
  }
  const body = { ...claims, exp: Math.floor(nowMs / 1000) + Math.floor(ttlSeconds) };
  const payload = b64url(enc.encode(JSON.stringify(body)));
  const key = await hmacKey(secret);
  const sig = new Uint8Array(
    await crypto.subtle.sign('HMAC', key, enc.encode(payload)));
  return `${payload}.${b64url(sig)}`;
}

/**
 * Check a token. Never throws on bad input — returns a reason instead, so a
 * malformed token is a 403 and not a 500.
 * @returns {Promise<{ok: boolean, claims?: object, reason?: string}>}
 */
export async function verify(secret, token, nowMs = Date.now()) {
  if (typeof token !== 'string' || token.length === 0) {
    return { ok: false, reason: 'missing token' };
  }
  const dot = token.indexOf('.');
  // Exactly one separator, and neither half empty.
  if (dot <= 0 || dot === token.length - 1 || token.indexOf('.', dot + 1) !== -1) {
    return { ok: false, reason: 'malformed token' };
  }
  const payload = token.slice(0, dot);
  const sigPart = token.slice(dot + 1);

  let key, sigBytes;
  try {
    key = await hmacKey(secret);
    sigBytes = unb64url(sigPart);
  } catch {
    return { ok: false, reason: 'malformed signature' };
  }

  let good = false;
  try {
    good = await crypto.subtle.verify('HMAC', key, sigBytes, enc.encode(payload));
  } catch {
    return { ok: false, reason: 'malformed signature' };
  }
  // Signature first: never parse attacker-controlled JSON we have not authenticated.
  if (!good) return { ok: false, reason: 'bad signature' };

  let claims;
  try {
    claims = JSON.parse(dec.decode(unb64url(payload)));
  } catch {
    return { ok: false, reason: 'malformed payload' };
  }
  if (!claims || typeof claims !== 'object' || typeof claims.exp !== 'number') {
    return { ok: false, reason: 'malformed payload' };
  }
  if (Math.floor(nowMs / 1000) >= claims.exp) {
    return { ok: false, reason: 'expired' };
  }
  return { ok: true, claims };
}
