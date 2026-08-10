import { test } from 'node:test';
import assert from 'node:assert/strict';
import { generateKeyPairSync } from 'node:crypto';
import { verifyApple, verifyGoogle, verifyStores } from '../src/entitlement.js';

const PRODUCT = 'com.analyticsbyshanikwa.bundle.cpa_exam_prep_bundle';
const BUNDLE_ID = 'com.analyticsbyshanikwa.analyticsbyshanikwaApp';
const NOW = () => 1_800_000_000_000;

// Real keys, so the JWT signing path is genuinely exercised rather than mocked.
const ec = generateKeyPairSync('ec', {
  namedCurve: 'P-256',
  privateKeyEncoding: { type: 'pkcs8', format: 'pem' },
  publicKeyEncoding: { type: 'spki', format: 'pem' },
});
const rsa = generateKeyPairSync('rsa', {
  modulusLength: 2048,
  privateKeyEncoding: { type: 'pkcs8', format: 'pem' },
  publicKeyEncoding: { type: 'spki', format: 'pem' },
});

const APPLE_ENV = {
  APPLE_ISSUER_ID: '11111111-2222-3333-4444-555555555555',
  APPLE_KEY_ID: 'ABC123DEFG',
  APPLE_PRIVATE_KEY: ec.privateKey,
  APPLE_BUNDLE_ID: BUNDLE_ID,
};
const GOOGLE_ENV = {
  GOOGLE_SA_EMAIL: 'downloads@abs.iam.gserviceaccount.com',
  GOOGLE_SA_KEY: rsa.privateKey,
  ANDROID_PACKAGE: BUNDLE_ID,
};

const jws = (payload) =>
  ['e30', Buffer.from(JSON.stringify(payload)).toString('base64url'), 'sig'].join('.');

const appleRes = (tx, status = 200) => ({
  ok: status === 200, status,
  json: async () => ({ signedTransactionInfo: jws(tx) }),
});

// --------------------------------------------------------------- Apple

test('apple: a genuine transaction for this product is entitled', async () => {
  let authHeader, calledUrl;
  const res = await verifyApple(APPLE_ENV, { productId: PRODUCT, receipt: '2000000123456789' }, {
    now: NOW,
    fetch: async (url, init) => {
      calledUrl = url; authHeader = init.headers.authorization;
      return appleRes({ bundleId: BUNDLE_ID, productId: PRODUCT });
    },
  });
  assert.equal(res.ok, true);
  assert.match(calledUrl, /api\.storekit\.itunes\.apple\.com\/inApps\/v1\/transactions\/2000000123456789$/);
  // The JWT must be real: three parts, ES256, our key id.
  const jwt = authHeader.replace('Bearer ', '');
  const [h] = jwt.split('.');
  const header = JSON.parse(Buffer.from(h, 'base64url').toString());
  assert.equal(jwt.split('.').length, 3);
  assert.equal(header.alg, 'ES256');
  assert.equal(header.kid, APPLE_ENV.APPLE_KEY_ID);
});

test('apple: a refunded purchase is refused', async () => {
  const res = await verifyApple(APPLE_ENV, { productId: PRODUCT, receipt: '2000000123456789' }, {
    now: NOW,
    fetch: async () => appleRes({ bundleId: BUNDLE_ID, productId: PRODUCT, revocationDate: 1 }),
  });
  assert.equal(res.ok, false);
  assert.equal(res.reason, 'refunded');
});

test('apple: a receipt for a different product does not unlock this one', async () => {
  const res = await verifyApple(APPLE_ENV, { productId: PRODUCT, receipt: '2000000123456789' }, {
    now: NOW,
    fetch: async () => appleRes({ bundleId: BUNDLE_ID, productId: 'com.someone.else' }),
  });
  assert.equal(res.reason, 'product mismatch');
});

test('apple: a receipt from another app is refused', async () => {
  const res = await verifyApple(APPLE_ENV, { productId: PRODUCT, receipt: '2000000123456789' }, {
    now: NOW,
    fetch: async () => appleRes({ bundleId: 'com.other.app', productId: PRODUCT }),
  });
  assert.equal(res.reason, 'bundle mismatch');
});

test('apple: falls back to sandbox when production 404s', async () => {
  const seen = [];
  const res = await verifyApple(APPLE_ENV, { productId: PRODUCT, receipt: '2000000123456789' }, {
    now: NOW,
    fetch: async (url) => {
      seen.push(url);
      return url.includes('sandbox')
        ? appleRes({ bundleId: BUNDLE_ID, productId: PRODUCT })
        : { ok: false, status: 404, json: async () => ({}) };
    },
  });
  assert.equal(res.ok, true, 'a sandbox tester purchase must still verify');
  assert.equal(seen.length, 2);
  assert.match(seen[1], /storekit-sandbox/);
});

test('apple: unknown transaction in both environments is refused', async () => {
  const res = await verifyApple(APPLE_ENV, { productId: PRODUCT, receipt: '2000000123456789' }, {
    now: NOW, fetch: async () => ({ ok: false, status: 404, json: async () => ({}) }),
  });
  assert.equal(res.reason, 'transaction not found');
});

test('apple: network failure denies rather than grants', async () => {
  const res = await verifyApple(APPLE_ENV, { productId: PRODUCT, receipt: '2000000123456789' }, {
    now: NOW, fetch: async () => { throw new Error('ECONNRESET'); },
  });
  assert.equal(res.ok, false);
  assert.equal(res.status, 503);
});

test('apple: missing credentials fail closed, not open', async () => {
  const res = await verifyApple({}, { productId: PRODUCT, receipt: '2000000123456789' }, { now: NOW });
  assert.equal(res.ok, false);
  assert.equal(res.status, 500);
});

test('apple: junk transaction ids never reach the network', async () => {
  let called = false;
  for (const bad of ['', 'abc', '../../x', '1', 'x'.repeat(40)]) {
    const res = await verifyApple(APPLE_ENV, { productId: PRODUCT, receipt: bad },
      { now: NOW, fetch: async () => { called = true; return appleRes({}); } });
    assert.equal(res.ok, false);
  }
  assert.equal(called, false, 'malformed ids must be rejected before any request');
});

// --------------------------------------------------------------- Google

const googleFetch = (purchase, { tokenOk = true } = {}) => async (url) => {
  if (url.includes('oauth2.googleapis.com')) {
    return tokenOk
      ? { ok: true, status: 200, json: async () => ({ access_token: 'ya29.test' }) }
      : { ok: false, status: 400, json: async () => ({}) };
  }
  return { ok: true, status: 200, json: async () => purchase };
};

test('google: a purchased token is entitled', async () => {
  const res = await verifyGoogle(GOOGLE_ENV,
    { productId: PRODUCT, receipt: 'p'.repeat(60) },
    { now: NOW, fetch: googleFetch({ purchaseState: 0 }) });
  assert.equal(res.ok, true);
});

test('google: cancelled and pending purchases are refused', async () => {
  for (const state of [1, 2]) {
    const res = await verifyGoogle(GOOGLE_ENV,
      { productId: PRODUCT, receipt: 'p'.repeat(60) },
      { now: NOW, fetch: googleFetch({ purchaseState: state }) });
    assert.equal(res.ok, false, `purchaseState ${state} must not be entitled`);
    assert.equal(res.reason, 'not purchased');
  }
});

test('google: the API is called with the right package and product', async () => {
  let apiUrl;
  await verifyGoogle(GOOGLE_ENV, { productId: PRODUCT, receipt: 'p'.repeat(60) }, {
    now: NOW,
    fetch: async (url) => {
      if (url.includes('oauth2')) return { ok: true, json: async () => ({ access_token: 't' }) };
      apiUrl = url;
      return { ok: true, status: 200, json: async () => ({ purchaseState: 0 }) };
    },
  });
  assert.match(apiUrl, new RegExp(`applications/${BUNDLE_ID}/purchases/products/${PRODUCT}/tokens/p{60}$`));
});

test('google: a rejected service account is a 500, not a grant', async () => {
  const res = await verifyGoogle(GOOGLE_ENV,
    { productId: PRODUCT, receipt: 'p'.repeat(60) },
    { now: NOW, fetch: googleFetch({}, { tokenOk: false }) });
  assert.equal(res.ok, false);
  assert.equal(res.status, 500);
});

test('google: unknown purchase token is refused', async () => {
  const res = await verifyGoogle(GOOGLE_ENV, { productId: PRODUCT, receipt: 'p'.repeat(60) }, {
    now: NOW,
    fetch: async (url) => url.includes('oauth2')
      ? { ok: true, json: async () => ({ access_token: 't' }) }
      : { ok: false, status: 404, json: async () => ({}) },
  });
  assert.equal(res.reason, 'purchase not found');
});

test('google: short tokens never reach the network', async () => {
  let called = false;
  const res = await verifyGoogle(GOOGLE_ENV, { productId: PRODUCT, receipt: 'short' },
    { now: NOW, fetch: async () => { called = true; return {}; } });
  assert.equal(res.ok, false);
  assert.equal(called, false);
});

test('google: a broken private key is misconfiguration, not entitlement', async () => {
  const res = await verifyGoogle({ ...GOOGLE_ENV, GOOGLE_SA_KEY: 'not a key' },
    { productId: PRODUCT, receipt: 'p'.repeat(60) }, { now: NOW });
  assert.equal(res.ok, false);
  assert.equal(res.status, 500);
});

// --------------------------------------------------------------- dispatch

test('an unknown platform is refused', async () => {
  const res = await verifyStores({}, { productId: PRODUCT, platform: 'web', receipt: 'x' });
  assert.equal(res.ok, false);
  assert.equal(res.reason, 'unknown platform');
});
