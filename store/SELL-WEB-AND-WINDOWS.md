# Selling on Web and Windows only — no Mac, no iOS, no Android

Verified 2026-08-11. **Total cost: $0, now and ongoing.**

This is the whole plan. No developer accounts to pay for, no certificates to
buy, no app review to pass on Apple's or Google's terms, no 12-tester rule.

---

## What you are actually giving up: less than it sounds

**You still reach iPhone and Android users.** The web app is installable, and I
verified that on the live site today:

| Check | Result |
|---|---|
| `manifest.json` | 200 · `display: standalone` · name "Analytics by Shanikwa" |
| Icons | 4, including maskable 192 and 512 |
| Service worker | `flutter_service_worker.js` 200 — works offline |
| iOS home-screen icon | `apple-touch-icon` → `icons/Icon-192.png` (200) |
| Rendering on iPhone 13 | 390 px viewport, no horizontal overflow, correct layout |

Installed from Safari or Chrome it runs full-screen with your icon, offline,
indistinguishable from a native app for what this app does. **And every sale
through it keeps ~$17.60 of $18.99, because no store is involved.**

What you genuinely lose: App Store and Play Store *search* discovery, and push
notifications on iOS. For a faith-and-analytics niche whose audience comes from
TikTok, Pinterest, Medium and the Sunday Letter, store search was never going
to be the channel.

---

# Phase 1 · Web — $0, live today

Nothing to build. The work is telling people it exists.

### 1a. Put the link everywhere
- Site nav on analyticsbyshanikwa.com
- TikTok bio · Pinterest profile · Medium profile
- The Sunday Letter (a permanent footer line, not one announcement)
- Your Shopify store description

### 1b. Tell people to install it — this is the step everyone skips
Most visitors do not know a website can become an app. Say it explicitly, with
the steps, because they differ per platform:

> **iPhone / iPad:** open in **Safari** → Share button → **Add to Home Screen**
> **Android:** open in **Chrome** → menu → **Install app**
> **Windows / Mac desktop:** Chrome or Edge → **install icon in the address bar**

Safari is required on iPhone — the Add to Home Screen option does not appear in
Chrome on iOS. Worth stating, or people will try and fail.

### 1c. Measure it
Every product link already carries `utm_source=app`, and `utm_content` records
which card was tapped. In Shopify Analytics, app-driven sales appear as their
own source. Check it after two weeks — that number decides whether any further
investment is worth it.

### 1d. Re-verify after catalog changes
All 20 live product links returned 200 on 2026-08-10. Re-check whenever you
change the catalog.

---

# Phase 2 · Windows (Microsoft Store) — $0

Everything technical is done: the app builds, the icon and metadata are right,
and `dart run msix:create --store` produces a 23 MB package. **Microsoft signs
Store submissions**, so there is no certificate to buy.

### 2a. Register — free
1. Go to **storedeveloper.microsoft.com**. This is the **only** entry point for
   the free individual flow; starting elsewhere can land you in the old paid
   company path.
2. Choose **Individual developer (free)**.
3. Sign in with a **personal** Microsoft account you will still control in five
   years — it owns the listing.
4. Verify identity: government ID + selfie, on your phone, good light, original
   document.
5. Wait up to **30 minutes** for verification to propagate. If submission is not
   available yet, that is normal — wait, do not restart.

### 2b. Reserve the name
6. Partner Center → **Product management → Manage app names**
7. `Analytics by Shanikwa` → Check availability → **Reserve product name**

> The reserved name generates your package identity, and **that identity is
> permanent once published.** If the exact name is taken, choose a variant you
> can live with forever.

### 2c. Fill in the three identity fields
8. **Product management → Product identity**, and copy into
   `pubspec.yaml → msix_config`, replacing the `REPLACE…` placeholders:

| Partner Center | `msix_config` key |
|---|---|
| Package/Identity/Name | `identity_name` |
| Package/Identity/Publisher (`CN=…`) | `publisher` |
| Publisher display name | `publisher_display_name` |

Character for character, including case. Mismatch is the most common rejection.

### 2d. Build and submit
```bash
flutter build windows --dart-define=APP_NICHE=full
dart run msix:create --store
```
9. Upload `build/windows/x64/runner/Release/analyticsbyshanikwa_app.msix`
10. Paste the **Microsoft Store** section of `store/LISTING.md`
11. Screenshots: `store/screenshots/desktop-*.png`
12. Category **Education → Reference**; privacy policy
    `https://analyticsbyshanikwa.com/privacy-policy.html`
13. Submit. Review is usually days.

### 2e. Every update
Bump `msix_version` (must increase; last digit stays `0`), rebuild, re-upload.

> **Do not** distribute a bare `.exe` from your site instead. That is the only
> Windows path needing a purchased Authenticode certificate (~$200–400/yr), and
> without one SmartScreen warns users away. The Store is free and signs for you.

---

## A bug this plan exposed, now fixed

The Shop tab was gated to `link_out_regions` (`["US","JP"]`) on every non-web
build. That gate exists for **Apple's Guideline 3.1.1 and Google Play's payments
policy** — neither of which applies to the Microsoft Store.

The effect: **a Windows user in the UK, Canada or Australia would have seen no
Shop at all**, hiding your storefront to satisfy a rule that does not apply to
them.

`AppConfig.canLinkOut` now applies the region gate only on iOS and Android.
Desktop and web always allow linking out. Covered by a regression test that
fails if the carve-out is removed.

---

## What you keep

| Channel | Setup | Ongoing | Kept on a $18.99 sale |
|---|---|---|---|
| Web (incl. installed on phones) | $0 | $0 | **~$17.60** |
| Microsoft Store | $0 | $0 | **~$17.60** |

Because every channel links out to Payhip or Shopify, no platform takes a cut.
Apple's 3.1.1, Google's billing policy, the 12-tester rule, notarization and
Authenticode all stop being your problems.

---

## If you ever reconsider (verified 2026-08-11, so you don't re-research it)

- **Mac** costs **$99/year** either way. Direct download needs a Developer ID
  certificate *and* notarization, both members-only; an unsigned Mac app will
  not launch unless the user disables Gatekeeper. You also cannot build macOS on
  Windows — Codemagic's free tier gives 500 min/month on M2.
- That same $99 covers **iOS**, so if you ever pay it for Mac, iOS is no longer
  the expensive part.
- **Android** is $25 once, but a new personal account must run a closed test
  with **12 testers for 14 continuous days**, resetting if anyone drops out, and
  since April 2026 Google also rejects for weak tester engagement.

Detailed mobile instructions, if it ever matters: `store/SUBMIT.md`.
