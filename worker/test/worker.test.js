import { test } from 'node:test';
import assert from 'node:assert/strict';
import worker from '../src/index.js';
import { sign } from '../src/sign.js';

const SECRET = 'worker-signing-secret-32-chars-min!!';
const PRODUCT = 'com.analyticsbyshanikwa.bundle.cpa_exam_prep_bundle';
const KEY = 'bundles/CPA-Exam-Prep-Bundle.zip';

// Minimal R2 stand-in: get(key) -> { body, httpMetadata } or null.
const r2 = (files) => ({
  async get(key) {
    return key in files
      ? { body: files[key], httpMetadata: { contentType: 'application/zip' } }
      : null;
  },
});

const baseEnv = (over = {}) => ({
  SIGNING_SECRET: SECRET,
  ENTITLEMENT_MODE: 'disabled',
  PRODUCT_FILES: JSON.stringify({ [PRODUCT]: KEY }),
  FILES: r2({ [KEY]: 'ZIPBYTES' }),
  ...over,
});

const post = (body) =>
  new Request('https://dl.example.com/grant', {
    method: 'POST',
    body: JSON.stringify(body),
  });

test('/health reports what is configured without leaking secrets', async () => {
  const res = await worker.fetch(new Request('https://dl.example.com/health'), baseEnv());
  const body = await res.json();
  assert.equal(res.status, 200);
  assert.equal(body.signing, 'ready');
  assert.equal(body.entitlement, 'disabled');
  assert.equal(body.products, 1);
  assert.equal(JSON.stringify(body).includes(SECRET), false, 'must not echo the secret');
});

test('with entitlement disabled, nothing is granted — fails closed', async () => {
  const res = await worker.fetch(post({ productId: PRODUCT, receipt: 'anything' }), baseEnv());
  assert.equal(res.status, 501);
});

test('unknown product is refused before any entitlement work', async () => {
  const env = baseEnv({ ENTITLEMENT_MODE: 'shared-secret', TEST_GRANT_SECRET: 'x'.repeat(20) });
  const res = await worker.fetch(post({ productId: 'com.nope', receipt: 'x'.repeat(20) }), env);
  assert.equal(res.status, 404);
});

test('wrong test secret is refused', async () => {
  const env = baseEnv({ ENTITLEMENT_MODE: 'shared-secret', TEST_GRANT_SECRET: 'x'.repeat(20) });
  const res = await worker.fetch(post({ productId: PRODUCT, receipt: 'wrong' }), env);
  assert.equal(res.status, 403);
});

test('grant then download: the happy path serves the file', async () => {
  const env = baseEnv({ ENTITLEMENT_MODE: 'shared-secret', TEST_GRANT_SECRET: 'x'.repeat(20) });
  const granted = await worker.fetch(post({ productId: PRODUCT, receipt: 'x'.repeat(20) }), env);
  assert.equal(granted.status, 200);
  const { url, expiresIn } = await granted.json();
  assert.equal(expiresIn, 300);

  const dl = await worker.fetch(new Request(url), env);
  assert.equal(dl.status, 200);
  assert.equal(await dl.text(), 'ZIPBYTES');
  assert.match(dl.headers.get('content-disposition'), /CPA-Exam-Prep-Bundle\.zip/);
  assert.equal(dl.headers.get('cache-control'), 'private, no-store');
  assert.match(dl.headers.get('x-robots-tag'), /noindex/);
});

test('a download link stops working once it expires', async () => {
  const env = baseEnv();
  // Mint a token that expired an hour ago.
  const stale = await sign(SECRET, { productId: PRODUCT, key: KEY }, 60, Date.now() - 3_600_000);
  const res = await worker.fetch(
    new Request(`https://dl.example.com/download?t=${encodeURIComponent(stale)}`), env);
  assert.equal(res.status, 403);
  assert.equal((await res.json()).error, 'expired');
});

test('a token signed with someone else\'s secret is refused', async () => {
  const env = baseEnv();
  const forged = await sign('a-totally-different-secret-value!!', { productId: PRODUCT, key: KEY }, 300);
  const res = await worker.fetch(
    new Request(`https://dl.example.com/download?t=${encodeURIComponent(forged)}`), env);
  assert.equal(res.status, 403);
  assert.equal((await res.json()).error, 'bad signature');
});

test('the client cannot choose which file it gets', async () => {
  const env = baseEnv();
  // Validly signed, but pointing at a file this product does not map to.
  const sneaky = await sign(SECRET,
    { productId: PRODUCT, key: 'bundles/The-Complete-Vault.zip' }, 300);
  const res = await worker.fetch(
    new Request(`https://dl.example.com/download?t=${encodeURIComponent(sneaky)}`), env);
  assert.equal(res.status, 403, 'a $39.99 token must not fetch the $197 bundle');
  assert.equal((await res.json()).error, 'stale token');
});

test('path traversal in the product map is rejected', async () => {
  const env = baseEnv({
    PRODUCT_FILES: JSON.stringify({ [PRODUCT]: '../../etc/passwd' }),
    ENTITLEMENT_MODE: 'shared-secret',
    TEST_GRANT_SECRET: 'x'.repeat(20),
  });
  const res = await worker.fetch(post({ productId: PRODUCT, receipt: 'x'.repeat(20) }), env);
  assert.equal(res.status, 404);
});

test('a missing object is a 404, not a 500', async () => {
  const env = baseEnv({ FILES: r2({}) });
  const tok = await sign(SECRET, { productId: PRODUCT, key: KEY }, 300);
  const res = await worker.fetch(
    new Request(`https://dl.example.com/download?t=${encodeURIComponent(tok)}`), env);
  assert.equal(res.status, 404);
});

test('malformed requests do not crash the worker', async () => {
  const env = baseEnv({ ENTITLEMENT_MODE: 'shared-secret', TEST_GRANT_SECRET: 'x'.repeat(20) });
  const bad = new Request('https://dl.example.com/grant', { method: 'POST', body: 'not json' });
  assert.equal((await worker.fetch(bad, env)).status, 400);
  assert.equal((await worker.fetch(post({}), env)).status, 400);
  assert.equal((await worker.fetch(new Request('https://dl.example.com/nope'), env)).status, 404);
  assert.equal(
    (await worker.fetch(new Request('https://dl.example.com/download'), env)).status, 403);
});

test('without a signing secret the worker refuses to operate', async () => {
  const env = baseEnv({ SIGNING_SECRET: undefined });
  assert.equal((await worker.fetch(post({ productId: PRODUCT, receipt: 'x' }), env)).status, 500);
  assert.equal(
    (await worker.fetch(new Request('https://dl.example.com/download?t=x.y'), env)).status, 500);
});
