# abs-downloads — signed fulfilment worker

Serves paid product files from a **private** R2 bucket via short-lived signed
links, replacing publicly-addressable URLs on the website.

    POST /grant     { productId, platform, receipt }  -> { url, expiresIn: 300 }
    GET  /download?t=<token>                          -> the file
    GET  /health                                      -> config sanity check

## Status

| Half | State |
|---|---|
| **Signing / expiry / serving** | **Done and tested** — 23 cases, `npm test` |
| **Entitlement (who bought it)** | Stubbed, **fails closed** |

`ENTITLEMENT_MODE` defaults to `disabled`, so `/grant` returns 501 and nothing
downloads. A permissive stub would be worse than the public URLs this replaces.

## What the tests actually prove

    npm test        # 23 passing

- a token expires exactly on its deadline, and a stale one is refused
- editing the payload to extend expiry breaks the signature
- a token minted for the $39.99 bundle cannot fetch the $197 one
- a validly-signed token cannot name a file the product does not map to
- there is no `alg` field, so no "alg: none" downgrade
- garbage input returns a reason, never a 500
- the worker refuses to run without a signing secret
- path traversal in the product map is rejected

## Finishing it

1. **Secrets**

       wrangler secret put SIGNING_SECRET      # 32+ random chars

2. **Entitlement.** Implement `verifyEntitlement` in `src/index.js` — the notes
   there name the exact Apple and Google endpoints and the fields to check.
   Needs an App Store Connect key and a Play service account, i.e. the paid
   developer accounts. Then set `ENTITLEMENT_MODE = "stores"`.

3. **Sandbox first.** Set `ENTITLEMENT_MODE = "shared-secret"` plus
   `TEST_GRANT_SECRET`, confirm grant→download end to end, then switch to
   `stores`.

4. **Point the app at it.** Replace each product's `fulfillment_url` in
   `content.json` with the `/grant` call, or keep the URL and have the app POST
   to `/grant` first. Content edit + version bump; no app release.

## Files

    src/sign.js               HMAC-SHA256 signing and verification
    src/index.js              the worker; verifyEntitlement is the seam
    test/sign.test.js         11 crypto/expiry cases
    test/worker.test.js       12 request-level cases with a mock R2
    product-files.json        productId -> R2 key, generated
    ../tools/package_fulfilment.py   packages products and uploads to R2

Files live in R2 bucket `abs-fulfilment` — private, never publicly addressable.
