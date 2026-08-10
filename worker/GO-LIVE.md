# Taking real money — the exact steps

Run these in `worker/`. Each step is independently checkable; do not skip the
verifications, because the failure mode of getting this wrong is charging
someone and delivering nothing.

Nothing here can hurt you before step 5: `ENTITLEMENT_MODE` is `disabled` in
`wrangler.jsonc`, so a deployed worker returns 501 to every `/grant`.

---

## 1. Deploy the worker (safe — it refuses everything)

```bash
cd worker
npx wrangler deploy
```

Gives you `https://abs-downloads.<your-subdomain>.workers.dev`.

**Check:**
```bash
curl https://abs-downloads.<sub>.workers.dev/health
# {"ok":true,"signing":"ready","entitlement":"disabled","products":11}
```

`entitlement: disabled` is correct at this point.

---

## 2. Set the signing secret

Generate 48 random chars — do not invent one by hand:

```bash
node -e "console.log(require('crypto').randomBytes(36).toString('base64url'))"
```

Then:

```bash
npx wrangler secret put SIGNING_SECRET
# paste the value when prompted
```

**Never** put this in `wrangler.jsonc`, and never ship it in the app. It only
ever lives in Cloudflare. Rotating it instantly invalidates every outstanding
download link, which is the emergency lever if one ever leaks.

**Check:** `npx wrangler secret list` shows `SIGNING_SECRET`.

---

## 3. Prove it works, before real receipts exist

Temporarily switch to the sandbox mode:

```bash
npx wrangler secret put TEST_GRANT_SECRET     # any 20+ random chars
# in wrangler.jsonc: "ENTITLEMENT_MODE": "shared-secret"
npx wrangler deploy
```

```bash
curl -X POST https://abs-downloads.<sub>.workers.dev/grant \
  -H 'content-type: application/json' \
  -d '{"productId":"com.analyticsbyshanikwa.bundle.cpa_exam_prep_bundle",
       "platform":"ios","receipt":"<TEST_GRANT_SECRET>"}'
# -> {"url":"https://.../download?t=...","expiresIn":300}
```

Fetch that URL: you should get `O09.zip`, the CPA Exam Prep Bundle. Wait six
minutes and fetch it again: `{"error":"expired"}`.

**Then switch `ENTITLEMENT_MODE` back to `disabled` and redeploy** until step 5.
Leaving `shared-secret` live means anyone holding that string gets every file.

---

## 4. Credentials — needs the paid developer accounts

### Apple

1. App Store Connect → **Users and Access → Integrations → App Store Connect API**
2. Create a key with the **App Manager** role. Download the `.p8` **once** —
   Apple will not show it again.
3. Note the **Issuer ID** (top of the page) and the **Key ID**.

```bash
npx wrangler secret put APPLE_ISSUER_ID     # the UUID
npx wrangler secret put APPLE_KEY_ID        # e.g. ABC123DEFG
npx wrangler secret put APPLE_PRIVATE_KEY   # paste the whole .p8, BEGIN/END lines included
npx wrangler secret put APPLE_BUNDLE_ID     # com.analyticsbyshanikwa.analyticsbyshanikwaApp
```

The app sends the StoreKit 2 **transaction id** as `receipt`. The worker asks
Apple about it, tries production then sandbox, and requires `bundleId` to be
yours, `productId` to match, and `revocationDate` to be absent — so a refunded
purchase stops working.

### Google

1. Play Console → **Setup → API access** → link a Google Cloud project.
2. Create a **service account**, grant it **View financial data** and
   **Manage orders and subscriptions**.
3. Download its JSON key; you need `client_email` and `private_key`.

```bash
npx wrangler secret put GOOGLE_SA_EMAIL     # client_email from the JSON
npx wrangler secret put GOOGLE_SA_KEY       # private_key, newlines and all
npx wrangler secret put ANDROID_PACKAGE     # com.analyticsbyshanikwa.analyticsbyshanikwaApp
```

The app sends the **purchaseToken** as `receipt`. The worker exchanges a signed
JWT for an access token, then requires `purchaseState == 0`; cancelled (1) and
pending (2) are refused.

---

## 5. Go live

```jsonc
// wrangler.jsonc
"ENTITLEMENT_MODE": "stores"
```

```bash
npx wrangler deploy
curl https://abs-downloads.<sub>.workers.dev/health
# {"ok":true,"signing":"ready","entitlement":"stores","products":11}
```

Then in `content.json`, set each bundle's `fulfillment_url` to the worker's
`/grant` endpoint, bump `version`, upload. Content change, no app release.

Finally flip `commerce.iap_enabled` to `true` — and only then can the app
charge anyone.

---

## 6. Verify with a real sandbox purchase

Do this before a single real customer.

- **iOS:** App Store Connect → Users and Access → **Sandbox Testers**. Sign in
  on a device with that account, buy a bundle, confirm the file downloads.
- **Android:** Play Console → **License testing**, add your account, buy from
  an internal-testing build.

Then confirm the three things that actually matter:

1. Buy → the file downloads.
2. Force-quit, reopen → still shows **Owned**.
3. Delete the app, reinstall, tap **Restore purchases** → the item comes back.

Refund the sandbox purchase and confirm the worker starts refusing it. That
proves `revocationDate` / `purchaseState` handling works, which is the part
that stops refund fraud.

---

## What is already proven, and what is not

**Proven** — `npm test`, 40 cases:

- signing, expiry to the second, forgery, cross-product substitution
- grant → download against the **real R2 bucket** via `wrangler dev --remote`,
  byte-identical files
- entitlement logic: refunds refused, wrong product refused, wrong app refused,
  sandbox fallback, network failure denies rather than grants, malformed ids
  never reach the network — all with **real ES256 and RSA keys**, only the
  store HTTP responses mocked
- `stores` mode with no credentials returns 500, never a grant

**Not proven** — and only step 6 can prove it:

- a real Apple or Google receipt has never been validated, because no developer
  account exists yet. The request shapes follow the documented APIs, but the
  first live call is the first live call.
