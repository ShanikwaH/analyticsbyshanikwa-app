# Selling this app — the whole path, in order

> **Current plan (2026-08-11): Web + Windows only. No Mac, no iOS, no Android.**
> Total cost **$0**. Follow **`store/SELL-WEB-AND-WINDOWS.md`** — that is the
> live plan, and the web app already covers iPhone and Android users as an
> installable PWA at 0% commission.
>
> The mobile phases below are kept for reference in case that changes. The
> Android keystore and signed `.aab` are done and will keep.

One page. `SHIP.md`, `SELLING.md` and `worker/GO-LIVE.md` are detail you only need
when you reach that step.

---

## First: there is no "keystore" for iOS or desktop

A keystore is an Android-only thing. Each platform proves who you are differently, and
only one of them is something you can generate yourself:

| Platform | What signs it | Where it comes from | Cost |
|---|---|---|---|
| **Android** | Keystore (`.jks`) you generate | `keytool`, on your machine | free |
| **iOS** | Certificate + provisioning profile | **Apple issues it** — needs the paid account | $99/yr |
| **macOS** | Developer ID certificate | **Apple issues it** — same account | (same $99) |
| **Windows Store** | Microsoft signs your package for you | Partner Center, at submission | **free** |
| **Windows direct `.exe`** | Authenticode certificate | **Bought from a CA** (DigiCert, Sectigo…) | ~$200–400/yr |

So: you generate exactly one signing asset yourself (the Android keystore). Everything else
is issued or purchased once you have the account. Nothing is blocked on "making a key".

---

## Where you actually are — verified 2026-08-10

| | State |
|---|---|
| **Web** | **Live and selling** at app.analyticsbyshanikwa.com, 0% platform fee |
| **Windows** | **Submitted for certification 2026-08-11**, package 1.0.1.0, rated Everyone 3+. **1.0.2.0 built and waiting** — see below |
| **Android** | **Ready to upload.** Signed `.aab` (50.6 MB), real keystore, valid to 2053 |
| **iOS** | Project scaffolded, bundle id `com.analyticsbyshanikwa.analyticsbyshanikwaApp`. Needs a Mac/CI + $99 |
| **macOS / Linux** | Not scaffolded. Add later with `flutter create --platforms=macos .` |
| **In-app purchase** | Built and tested, deliberately **off** |
| **Fulfilment worker** | Built, 40 tests pass, **not deployed** |
| **Tests** | 33 Flutter + 40 worker, all green |

---

## Phase 0 — earn from what is already live · $0 · this week

Nothing to install, nothing to approve. **Do this before spending a cent** — it tells you
whether the app converts at all, which is the only honest basis for paying Apple $99.

- [ ] Put `app.analyticsbyshanikwa.com` in your site nav, TikTok bio, Pinterest, the Sunday
      letter, Medium, and your Shopify store.
- [ ] **Tell people to install it.** Chrome and Edge offer "Install" on that URL and it then
      runs like a native app, offline. Most visitors never notice unless you say so.
- [ ] Watch it in Shopify Analytics — every product link carries `utm_source=app`, and
      `utm_content` tells you which card was tapped.
- [x] **Product links verified 2026-08-10** — all 20 live Payhip/Shopify links
      from `content.json` return 200. Re-check with the snippet in
      `tools/` whenever you change the catalog.

---

## Phase 1 — Windows · **$0** · ~1 week

Do this before Android. It is now **free**, there is no tester requirement, and it is the
fastest way to have a real store listing.

- [x] **Partner Center account — registered 2026-08-11**, Individual (free), ID +
      selfie verified. Name `Analytics by Shanikwa` reserved.
- [x] **MSIX packaging configured and proven.** `msix_config` is in `pubspec.yaml` and
      `dart run msix:create --store` produces a **23 MB** `.msix` in
      `build/windows/x64/runner/Release/`. Confirmed: **Store mode needs no certificate** —
      Microsoft signs it.
- [x] **Identity fields filled** from Product identity and verified inside the
      built package's `AppxManifest.xml`, not just in the config.
- [x] **SUBMITTED FOR CERTIFICATION 2026-08-11**, package `1.0.1.0`,
      IARC rating **Everyone 3+**. Result emails nikki.19972010@hotmail.com.
      Gotchas hit along the way are recorded in `store/LISTING.md`: Desktop-only
      device family, the runFullTrust justification and its silent 500-character
      cap, and why the privacy question must be answered "Yes".
- [x] **1.0.2.0 built, verified, and waiting to upload.** 1.0.1.0 was packaged
      *before* the Five Talents reward code existed, so it still shows the old
      vague "look for the reward note at checkout" line. The web app is already
      correct — it was rebuilt and redeployed with the fix. Windows needs a new
      package, and 1.0.2.0 is it: verified by reading the compiled `data/app.so`
      inside the built `.msix`, where the old string is gone and
      `Five Talents rank reached. Use code ` is present (Dart stores literals
      containing emoji or em dashes as UTF-16, so grep them that way, not ASCII).
      Identity and version confirmed in `AppxManifest.xml`. 37 tests pass.

      **When to upload it:** *after* 1.0.1.0 finishes certification. Partner
      Center allows only one submission in flight — starting a new one now means
      cancelling the current one and restarting the clock for no real gain.
      Nobody can reach 250 Talents before then; it takes all ten badges.
      Then: **Product → Submissions → New submission**, replace the package,
      note "reward code copy fix" in the certification notes, submit.

**If you also want a plain downloadable `.exe`** from your own site: that is the one case
where you'd buy an Authenticode certificate (~$200–400/yr). Without it Windows SmartScreen
warns users off. My honest read: skip it. The web app already covers "use it on a PC".

---

## Phase 2 — Android · $25 once · 3–5 weeks

The $25 is one payment, forever, all your apps.

- [x] **Upload keystore — created 2026-08-10.** 4096-bit RSA, alias `upload`, valid to
      **2053**, at `C:\Users\nikki\keystores\upload-keystore.jks`. Credentials in
      `android/key.properties` (gitignored). Signer verified:
      `CN=Shanikwa Haynes, O=Analytics by Shanikwa, C=US`.
      The password was generated randomly and written straight to disk — it was never
      printed to screen, so **`android/key.properties` is the only copy.**
- [ ] **BACK UP BOTH FILES TODAY. This is the highest-risk item in the whole project.**
      1. `C:\Users\nikki\keystores\upload-keystore.jks`
      2. `C:\Users\nikki\analyticsbyshanikwa-app\android\key.properties` — open it and put
         the `storePassword` value in your password manager.
      Store a copy somewhere that is not this laptop. **Lose either one and you can never
      update your own listing again** — you would publish a new app and lose every review
      and install. (Play App Signing enrolment at upload time gives you a reset path via
      Google support; do enrol, but do not rely on it.)
- [x] **Signer verified:** `flutter build appbundle` → `bash tools/check_signing.sh`
      prints the Owner line above, not `CN=Android Debug`. Re-run it before every upload.
- [ ] **Pay the $25**, complete ID verification (allow several days).
- [ ] **Recruit 12 testers now — this is the long pole.** A personal account created after
      13 Nov 2023 must run a closed test with **12 testers opted in for 14 continuous days**.
      Three traps:
      - All 12 must overlap in the *same* window. One drops out on day 7 → **counter resets**.
      - Since **April 2026** Google also rejects for weak *engagement* — testers must actually
        open and use the app, not just install it. Ask them for a couple of minutes every day or two.
      - Real devices, real Google accounts. Emulators and duplicates don't count.
- [x] **Listing assets are done and waiting** in `store/`:
      copy for all three stores (`store/LISTING.md`), 4 phone screenshots at
      1080×1920, 4 desktop at 1366×768, the required 1024×500 feature graphic and
      512×512 icon. Data-safety and content-rating answers are written out too.
- [ ] Upload the `.aab`, then paste the listing from `store/LISTING.md`.
      **Read the ⚠ note at the bottom of that file first** — Google's billing
      policy for link-out digital goods is not Apple's, and it has not been
      verified for you.

---

## Phase 3 — iOS · $99/year · 2–4 weeks

- [ ] **Enrol in the Apple Developer Program** ($99/yr). Individual needs ID; a business
      entity needs a D-U-N-S number.
- [ ] **Sign the Paid Applications Agreement** in App Store Connect → Business.
      **Nothing sells until this is signed** — required even for a free app with external
      links. This blocks more first-time sellers than anything else.
- [ ] **Apply to the Small Business Program** — 15% instead of 30%. It is **not automatic**.
- [ ] **Certificates and provisioning profiles come from Apple**, not from you. Xcode or
      Codemagic will create them once the account exists.
- [ ] **You cannot build iOS on Windows.** Use **Codemagic's free tier** (500 build-minutes/
      month) — it builds on their Macs. You still need the $99 account for signing.
- [ ] **List worldwide.** The app region-gates itself: link-out buttons show only where they
      are legal, and hide elsewhere. No need to restrict the storefront.
- [ ] Paste the review notes from `SELLING.md` §6d — they pre-empt the two likely rejections,
      external links (3.1.1) and minimum functionality (4.2).

---

## Phase 4 — in-app purchase outside the US/Japan · after Phase 3

Only worth doing if Phases 2–3 show real demand elsewhere. Full commands, with a
verification after each: **`worker/GO-LIVE.md`**.

- [ ] Deploy the worker (safe — it refuses everything by default).
- [ ] `wrangler secret put SIGNING_SECRET`
- [ ] Sandbox-prove grant → download, then switch back to `disabled`.
- [ ] Get the Apple `.p8` key and the Google service account.
- [ ] `ENTITLEMENT_MODE = "stores"`, then `iap_enabled: true` in `content.json`.
- [ ] Run the three sandbox checks, then **refund a sandbox purchase and confirm the download
      stops working**. That is the part that stops refund fraud.

---

## What blocks what

```
Phase 0  web        ── nothing blocks it. Do it now.
Phase 1  Windows $0 ── identity check only. No testers. Fastest real listing.
Phase 2  Android $25 ── KEYSTORE → ID check → 12 testers × 14 continuous days
Phase 3  iOS $99    ── enrolment → Paid Apps Agreement → Mac/Codemagic
Phase 4  IAP        ── needs BOTH mobile accounts, for the store credentials
```

Phases 1–3 are independent. Order given is cheapest-and-fastest first.

---

## Money

| Channel | Cost | You keep on a $18.99 sale |
|---|---|---|
| Web / link-out | $0 | **~$17.60** |
| Microsoft Store | $0 | ~$17.60 (link-out; no IAP) |
| iOS IAP, Small Business 15% | $99/yr | $16.14 |
| iOS IAP, standard 30% | $99/yr | $13.29 |

**First year, all channels: $124.** Then $99/year.

Link-out is worth ~$4.31 more per sale than IAP, which is why the app links out wherever the
rules allow and only falls back to IAP where they don't.

---

## Three things to verify yourself on the day, not take from me

1. **The US external-link rule is genuinely unsettled.** After the 2025 Epic contempt ruling,
   US apps may link out with **no entitlement required**, and the commission is **0% right
   now** — but that is pending the district court approving a rate. Apple has asserted a
   "Link Entitlement" commission of up to **27%** with a 7-day attribution window. If that
   gets approved, the economics above change. **Re-read Guideline 3.1.1 the day you submit.**
2. **Small Business Program terms** — confirm the current rate and eligibility on Apple's own
   page before relying on 15%.
3. **No real store purchase has ever been tested**, because no developer account exists yet.
   The IAP code and worker are tested against mocks and real crypto; the first live receipt
   is the first live receipt. Sandbox testing is required, not optional.

---

## The short version

**This week:** put the link everywhere. Free, and it answers the only question that matters.

**Then:** Windows, because it is now free and has no tester gate.

**Then:** $25 Android — but create the keystore *today*, since the 14-day tester clock cannot
start until the build is properly signed.

**Then:** $99 iOS, if the numbers justify it.
