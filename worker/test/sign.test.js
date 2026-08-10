import { test } from 'node:test';
import assert from 'node:assert/strict';
import { sign, verify } from '../src/sign.js';

const SECRET = 'test-secret-at-least-16-chars-long';
const OTHER = 'a-completely-different-secret-value';
const CLAIMS = { productId: 'com.analyticsbyshanikwa.bundle.cpa_exam_prep_bundle',
                 file: 'CPA-Exam-Prep-Bundle.zip' };
const T0 = 1_800_000_000_000; // fixed clock

test('round trip: a fresh token verifies and carries its claims', async () => {
  const tok = await sign(SECRET, CLAIMS, 300, T0);
  const r = await verify(SECRET, tok, T0 + 1000);
  assert.equal(r.ok, true);
  assert.equal(r.claims.productId, CLAIMS.productId);
  assert.equal(r.claims.file, CLAIMS.file);
  assert.equal(r.claims.exp, Math.floor(T0 / 1000) + 300);
});

test('expiry is enforced, and exactly at the boundary', async () => {
  const tok = await sign(SECRET, CLAIMS, 300, T0);
  const justBefore = await verify(SECRET, tok, T0 + 299_000);
  assert.equal(justBefore.ok, true, 'still valid 1s before expiry');

  const atExpiry = await verify(SECRET, tok, T0 + 300_000);
  assert.equal(atExpiry.ok, false);
  assert.equal(atExpiry.reason, 'expired');

  const later = await verify(SECRET, tok, T0 + 3_600_000);
  assert.equal(later.reason, 'expired');
});

test('a different secret cannot verify the token', async () => {
  const tok = await sign(SECRET, CLAIMS, 300, T0);
  const r = await verify(OTHER, tok, T0);
  assert.equal(r.ok, false);
  assert.equal(r.reason, 'bad signature');
});

test('tampering with the payload is rejected — including pushing out expiry', async () => {
  const tok = await sign(SECRET, CLAIMS, 60, T0);
  const [, sig] = tok.split('.');

  // Re-encode the claims with a far-future expiry and reuse the old signature.
  const forged = Buffer.from(JSON.stringify(
    { ...CLAIMS, exp: Math.floor(T0 / 1000) + 999_999 }))
    .toString('base64url');
  const r = await verify(SECRET, `${forged}.${sig}`, T0);
  assert.equal(r.ok, false);
  assert.equal(r.reason, 'bad signature');
});

test('swapping in another product id is rejected', async () => {
  const tok = await sign(SECRET, CLAIMS, 60, T0);
  const [, sig] = tok.split('.');
  const forged = Buffer.from(JSON.stringify(
    { productId: 'com.analyticsbyshanikwa.bundle.the_complete_vault',
      file: 'The-Complete-Vault.zip',
      exp: Math.floor(T0 / 1000) + 60 }))
    .toString('base64url');
  const r = await verify(SECRET, `${forged}.${sig}`, T0);
  assert.equal(r.ok, false, 'a $39.99 token must not unlock the $197 bundle');
});

test('a token for one product does not claim to be another', async () => {
  // Two products, two tokens: the claims must stay distinct so the download
  // handler can compare them against the file it is about to serve.
  const a = await verify(SECRET, await sign(SECRET, CLAIMS, 60, T0), T0);
  const b = await verify(SECRET,
    await sign(SECRET, { productId: 'other', file: 'other.zip' }, 60, T0), T0);
  assert.notEqual(a.claims.productId, b.claims.productId);
});

test('garbage input never throws — it returns a reason', async () => {
  for (const bad of ['', 'nodot', 'a.b.c', '.', 'x.', '.y', '!!!.???',
                     null, undefined, 42, {}]) {
    const r = await verify(SECRET, bad, T0);
    assert.equal(r.ok, false, `should reject: ${JSON.stringify(bad)}`);
    assert.ok(typeof r.reason === 'string' && r.reason.length > 0);
  }
});

test('an unsigned token is rejected — there is no "alg: none" to exploit', async () => {
  const payload = Buffer.from(JSON.stringify(
    { ...CLAIMS, exp: Math.floor(T0 / 1000) + 60 })).toString('base64url');
  for (const attempt of [`${payload}.`, `${payload}.AAAA`, payload]) {
    const r = await verify(SECRET, attempt, T0);
    assert.equal(r.ok, false);
  }
});

test('a weak signing secret is refused outright', async () => {
  await assert.rejects(() => sign('short', CLAIMS, 60, T0), /at least 16/);
  const r = await verify('short', 'a.b', T0);
  assert.equal(r.ok, false);
});

test('bad ttl and claims are refused', async () => {
  await assert.rejects(() => sign(SECRET, CLAIMS, 0, T0), /positive/);
  await assert.rejects(() => sign(SECRET, CLAIMS, -5, T0), /positive/);
  await assert.rejects(() => sign(SECRET, null, 60, T0), /claims/);
});

test('tokens are unique per mint even for identical claims', async () => {
  // Different clocks -> different exp -> different signature. Guards against a
  // future refactor that accidentally makes tokens replayable-by-construction.
  const a = await sign(SECRET, CLAIMS, 60, T0);
  const b = await sign(SECRET, CLAIMS, 60, T0 + 1000);
  assert.notEqual(a, b);
});
