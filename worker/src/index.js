import { sign, verify } from './sign.js';
import { verifyStores } from './entitlement.js';

/**
 * Download worker for paid fulfilment.
 *
 *   POST /grant     { productId, platform, receipt }  -> { url, expiresIn }
 *   GET  /download?t=<token>                          -> the file
 *
 * Files live in a private R2 bucket. They are never publicly addressable, so
 * unlike a folder on GitHub Pages there is no link to leak — a download URL
 * stops working after TTL_SECONDS.
 *
 * ENTITLEMENT_MODE controls who may be granted a link:
 *   disabled       (default) /grant returns 501. Fails closed.
 *   shared-secret  sandbox testing only; needs TEST_GRANT_SECRET.
 *   stores         real Apple / Google receipt validation (entitlement.js).
 */

const TTL_SECONDS = 300; // 5 minutes: long enough to download, short enough to be useless if shared

const json = (obj, status = 200) =>
  new Response(JSON.stringify(obj), {
    status,
    headers: { 'content-type': 'application/json', 'cache-control': 'no-store' },
  });

/**
 * Decide whether this caller is entitled to this product.
 * Real implementations live in entitlement.js; this only picks the mode.
 */
async function verifyEntitlement(env, { productId, platform, receipt }) {
  const mode = env.ENTITLEMENT_MODE || 'disabled';

  if (mode === 'disabled') {
    return { ok: false, status: 501, reason: 'entitlement verification not configured' };
  }

  // Escape hatch for sandbox testing ONLY. Requires a secret the app never
  // ships, and refuses to run unless explicitly switched on.
  if (mode === 'shared-secret') {
    const expected = env.TEST_GRANT_SECRET;
    if (!expected || expected.length < 16) {
      return { ok: false, status: 500, reason: 'TEST_GRANT_SECRET missing or too short' };
    }
    return receipt === expected
      ? { ok: true }
      : { ok: false, status: 403, reason: 'bad test secret' };
  }

  if (mode === 'stores') {
    return verifyStores(env, { productId, platform, receipt });
  }

  return { ok: false, status: 500, reason: `unknown ENTITLEMENT_MODE: ${mode}` };
}

/** productId -> object key in R2. Kept server-side so the client cannot pick files. */
function fileFor(env, productId) {
  let map = {};
  try {
    map = JSON.parse(env.PRODUCT_FILES || '{}');
  } catch {
    return null;
  }
  const key = map[productId];
  // Defend against traversal even though these come from our own config.
  if (typeof key !== 'string' || key.includes('..') || key.startsWith('/')) return null;
  return key;
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (url.pathname === '/health') {
      return json({
        ok: true,
        signing: 'ready',
        entitlement: env.ENTITLEMENT_MODE || 'disabled',
        products: Object.keys((() => {
          try { return JSON.parse(env.PRODUCT_FILES || '{}'); } catch { return {}; }
        })()).length,
      });
    }

    if (url.pathname === '/grant' && request.method === 'POST') {
      if (!env.SIGNING_SECRET) return json({ error: 'not configured' }, 500);

      let body;
      try {
        body = await request.json();
      } catch {
        return json({ error: 'bad json' }, 400);
      }
      const { productId, platform, receipt } = body || {};
      if (!productId || !receipt) return json({ error: 'productId and receipt required' }, 400);

      const key = fileFor(env, productId);
      if (!key) return json({ error: 'unknown product' }, 404);

      const ent = await verifyEntitlement(env, { productId, platform, receipt });
      if (!ent.ok) return json({ error: ent.reason }, ent.status);

      const token = await sign(env.SIGNING_SECRET, { productId, key }, TTL_SECONDS);
      return json({
        url: `${url.origin}/download?t=${encodeURIComponent(token)}`,
        expiresIn: TTL_SECONDS,
      });
    }

    if (url.pathname === '/download' && request.method === 'GET') {
      if (!env.SIGNING_SECRET) return json({ error: 'not configured' }, 500);

      const res = await verify(env.SIGNING_SECRET, url.searchParams.get('t') || '');
      if (!res.ok) return json({ error: res.reason }, 403);

      // Re-derive the key from the product id rather than trusting the token's
      // `key` blindly: if the mapping changes, the token cannot pin an old file.
      const key = fileFor(env, res.claims.productId);
      if (!key || key !== res.claims.key) return json({ error: 'stale token' }, 403);

      const obj = await env.FILES.get(key);
      if (!obj) return json({ error: 'file missing' }, 404);

      return new Response(obj.body, {
        headers: {
          'content-type': obj.httpMetadata?.contentType || 'application/octet-stream',
          'content-disposition': `attachment; filename="${key.split('/').pop()}"`,
          'cache-control': 'private, no-store',
          'x-robots-tag': 'noindex, nofollow',
        },
      });
    }

    return json({ error: 'not found' }, 404);
  },
};
