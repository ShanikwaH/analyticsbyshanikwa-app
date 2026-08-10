# Making this app sellable — the whole path, in order

One page. Everything else (`SHIP.md`, `SELLING.md`, `worker/GO-LIVE.md`) is
detail you only need when you reach that step.

---

## Where you actually are, verified today

| | State |
|---|---|
| **The app** | Live at **app.analyticsbyshanikwa.com** — 115 products, 20+ games, works offline, installable |
| **Selling on the web** | **Working now.** Buy buttons open Payhip/Shopify, 0% platform fee |
| **Android** | Not started. $25 |
| **iOS** | Not started. $99/yr |
| **In-app purchase** | Built and tested, switched **off**. Needs developer accounts |
| **Fulfilment** | 11 bundles uploaded to private R2, verified byte-for-byte |
| **Privacy policy** | Live at `/privacy-policy.html`, mentions the app |
| **App icon** | Done, all platforms |

**You can already sell to anyone in the world today**, through the web app and
your site. Everything below is about reach, not capability.

---

## Phase 0 — earn from what is already live · $0 · this week

Nothing to install, nothing to approve.

- [ ] **Put the link everywhere.** `app.analyticsbyshanikwa.com` in your site
      nav, TikTok bio, Pinterest, the Sunday letter, your Shopify store.
- [ ] **Tell people to install it.** On the live URL, Chrome and Edge offer
      "Install" and it then runs like a native app, offline. Most visitors do
      not know that unless you say so.
- [ ] **Watch what it earns.** Every product link already carries
      `utm_source=app`, so app-driven sales show up as their own source in
      Shopify Analytics, and `utm_content` tells you which card was tapped.
- [ ] **Check a few product links** actually land on the right listing.

Do this before spending anything. It tells you whether the app converts at all,
which is the only honest basis for paying Apple $99.

---

## Phase 1 — Android · $25 once · 3–5 weeks

The $25 is one payment, forever, all your apps.

- [x] **Install Android Studio + SDK — done.** Studio Quail 3 at
      `C:\Users\nikki\AndroidStudio`, SDK (platform 36, build-tools 36.1.0,
      platform-tools 37.0.1) at `%LOCALAPPDATA%\Android\Sdk`, all licenses
      accepted, `flutter doctor` clean. *(`SHIP.md` §3)*
- [x] **The app really builds:** `flutter build appbundle` produced
      `app-release.aab` (50.6 MB) in ~12 min. No NDK was needed.
- [x] **Java version — already handled.** JDK 17.0.20 is installed at
      `C:\Users\nikki\jdk-17` and Flutter is pointed at it
      (`flutter config --jdk-dir "C:\Users\nikki\jdk-17"`). JDK 22 is still on
      the system PATH for everything else; only Flutter/Gradle use 17.
      Verified: Gradle 9.1.0 launches on `17.0.20 (Microsoft 17.0.20+8-LTS)`.
- [ ] **Create the upload keystore — the next blocker.** The `.aab` built today
      is signed `CN=Android Debug` (see the `TODO` in
      `android/app/build.gradle.kts` line 30). **Play rejects debug-signed
      bundles.** You must create this yourself — it needs a password you choose
      and nobody else should ever hold. Back it up somewhere permanent.
      **Lose it and you can never update your own app again** — you would have
      to publish a new listing and lose your reviews.
- [ ] **Pay the $25**, complete ID verification (allow several days).
- [ ] **Recruit 12 testers now.** A new personal developer account must run a
      closed test with **12 testers for 14 continuous days** before production.
      This is the single biggest delay and it cannot be rushed.
- [ ] `flutter build appbundle --release` → upload the `.aab`.
- [ ] Store listing: screenshots, the privacy policy URL, **data safety: no
      data collected** (true — everything is on-device, and it is a real
      selling point), content rating, category **Education** (not Games).

---

## Phase 2 — iOS · $99/year · 2–4 weeks

- [ ] **Enrol in the Apple Developer Program.** Individual needs ID; business
      needs a D-U-N-S number.
- [ ] **Sign the Paid Applications Agreement** in App Store Connect →
      Business. **Nothing sells until this is signed** — required even for a
      free app with external links. This blocks more first-time sellers than
      anything else.
- [ ] **Apply to the Small Business Program** — 15% instead of 30%. It is
      **not automatic**; you must apply.
- [ ] **You cannot build iOS on Windows.** Use **Codemagic's free tier**
      (500 build-minutes/month) — it builds on their Macs. You still need the
      $99 account for signing. *(`SHIP.md` §4)*
- [ ] **List worldwide.** The app region-gates itself: the Shop shows link-out
      buttons in the US and Japan, and hides them elsewhere, so it is
      compliant everywhere. No need to restrict the storefront.
- [ ] **Paste the review notes** from `SELLING.md` §6d. They pre-empt the two
      likely rejections: external links (3.1.1) and "minimum functionality"
      (4.2).

---

## Phase 3 — sell *inside* the app in the UK, Canada, Australia · after Phase 2

Only worth doing if Phase 1–2 show real demand outside the US.

- [ ] Deploy the download worker — safe, it refuses everything by default.
- [ ] `wrangler secret put SIGNING_SECRET`
- [ ] Sandbox-prove grant → download, then switch back to `disabled`.
- [ ] Get the Apple `.p8` key and the Google service account.
- [ ] `ENTITLEMENT_MODE = "stores"`, then `iap_enabled: true` in `content.json`.
- [ ] **Run the three sandbox checks**, then refund a sandbox purchase and
      confirm the download stops working.

Full commands, in order, with a verification after each: **`worker/GO-LIVE.md`**.

---

## What blocks what

```
Phase 0  (web)          ── nothing blocks it. Do it now.
   │
Phase 1  (Android $25)  ── ID check · 12 testers × 14 days
   │
Phase 2  (iOS $99)      ── enrolment · Paid Apps Agreement · Mac/Codemagic
   │
Phase 3  (IAP)          ── needs BOTH accounts, for the store credentials
```

Phases 1 and 2 are independent — do Android first because it is cheaper and
teaches you the process, or iOS first if that is where your audience is.

---

## Money

| | Cost | You keep on a $18.99 sale |
|---|---|---|
| Web / link-out | $0 | **~$17.60** |
| iOS IAP, Small Business 15% | $99/yr | $16.14 |
| iOS IAP, standard 30% | $99/yr | $13.29 |

**First year on all three: $124.** Then $99/year.

Link-out is worth ~$4.31 more per sale than IAP, which is why the app links out
wherever the rules allow and only falls back to IAP where they do not.

---

## Two things to check yourself, not take from me

1. **App Store Guideline 3.1.1 changed twice in 18 months**, and the Google
   settlement was still in front of a judge in 2026. Re-read the current rule
   on the day you submit. *(`SELLING.md` §2 has the sources.)*
2. **No real store purchase has ever been tested** — no developer account
   exists yet. The IAP code and the worker are thoroughly tested against mocks
   and real crypto, but the first live receipt is the first live receipt.
   Sandbox testing is required, not optional.

---

## The short version

**This week:** put the link everywhere and see if anyone uses it. That costs
nothing and answers the only question that matters.

**If they do:** $25 for Android, then $99 for iOS.

**If people outside the US start asking:** Phase 3.
