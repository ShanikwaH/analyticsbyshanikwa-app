# Handoff — 2026-08-10 · Android/Windows store readiness

Written at the end of a long session. A fresh agent should be able to continue
from this without re-reading the transcript.

**Repo:** `C:\Users\nikki\analyticsbyshanikwa-app` · branch **`source`** ·
remote `ShanikwaH/analyticsbyshanikwa-app` · working tree clean, all pushed.

> ⚠ **`main` is PUBLIC** and holds the deployed web build. Source lives on
> `source`. Never commit paid inventory, keystores, or `key.properties`.

---

## What this session did

Took the app from "web-only, never built for Android" to "signed Android bundle
+ Windows package + all store assets ready". Nothing is left that doesn't
require Nikki's own accounts.

| | Before | After |
|---|---|---|
| Android toolchain | none | JDK 17 + SDK 36 + Studio, `flutter doctor` clean |
| Android bundle | didn't build | **signed** `app-release.aab`, 50.6 MB |
| Windows | folder didn't exist | builds (30 MB exe) + 23 MB Store MSIX |
| Store assets | none | copy, 8 screenshots, feature graphic, icon |

---

## Environment installed (machine-level, outside the repo)

| Thing | Path | Note |
|---|---|---|
| JDK 17.0.20 LTS | `C:\Users\nikki\jdk-17` | Gradle needs 17 |
| Android SDK | `%LOCALAPPDATA%\Android\Sdk` | platform 36, build-tools 36.1.0, platform-tools 37.0.1 |
| Android Studio Quail 3 | `C:\Users\nikki\AndroidStudio` | `AI-261.26222.65` |
| Upload keystore | `C:\Users\nikki\keystores\upload-keystore.jks` | **not in the repo** |

All three registered via `flutter config` (`jdk-dir`, `android-sdk`,
`android-studio-dir`). `flutter doctor` → **No issues found**.

**This machine has no `winget` and the shell is not elevated.** Installers that
demand UAC exit **1223**. Install by downloading the vendor's zip, verifying the
published SHA256, and extracting into `C:\Users\nikki\...`. That is how both the
JDK and Android Studio got here.

---

## Signing — read before touching anything Android

- Keystore: 4096-bit RSA, alias `upload`, valid to **2053**.
  Signer `CN=Shanikwa Haynes, O=Analytics by Shanikwa, C=US`.
  SHA256 `BA:43:6E:2F:7E:EE:F6:DE:9B:B4:E0:78:26:D3:90:40:DF:2A:99:FB:C3:D4:6E:A3:6C:67:1E:D6:55:DA:2F:D2`
- Credentials: `android/key.properties` — **gitignored, and the only plaintext
  copy on this machine**. The password was generated in-shell and never printed,
  so it is not in any transcript.
- Backups: `.jks` in `OneDrive\App Signing Keys\analyticsbyshanikwa-app\`
  (with a READ-ME-FIRST). `key.properties` was **deliberately deleted** from
  OneDrive so the key and its password are not stored together. Nikki says the
  password is in her password manager — **not independently verified.**
- `android/app/build.gradle.kts` loads release signing from `key.properties` and
  **falls back to debug signing with a warning** if absent, so fresh clones still
  build. That fallback is why `tools/check_signing.sh` exists — **run it before
  every upload.**

---

## Where things are

```
store/LISTING.md     paste-ready copy: Play, Microsoft, App Store
                     + data-safety answers + content-rating answers
                     + a ⚠ section on Google's billing policy (UNVERIFIED)
store/SUBMIT.md      step-by-step account instructions for the 3 remaining tasks
store/screenshots/   4 phone 1080x1920, 4 desktop 1366x768
store/graphics/      play-feature-graphic-1024x500.png, play-icon-512.png
tools/check_signing.sh    who signed the .aab; non-zero on debug
tools/screenshots.py      regenerate screenshots from the live app
tools/store_graphics.py   regenerate the Play graphics
START-HERE.md        the ordered path across all four sell channels
```

---

## Verified today (do not re-derive)

- `flutter test` → **33 pass**; `worker` → **40 pass**
- Signed `.aab` builds; `check_signing.sh` exits 0 with the real Owner
- Windows `.exe` launches, titles "Analytics by Shanikwa", closes cleanly
- Store-mode MSIX builds with **no certificate** (Microsoft signs)
- All **20 live product links return 200**
- Live `content.json` is **v12**, 115 catalog items, `iap_enabled: false`,
  `link_out_regions: ["US","JP"]`

External facts checked 2026-08-10 (re-check if acting on them later):
Microsoft Store individual registration is **free**; Play is **$25** with a
12-tester/14-continuous-day closed test that **resets if anyone drops out**, and
since April 2026 also rejects for weak engagement; US external purchase links
need no Apple entitlement and are at **0% commission pending court approval**,
with Apple asserting up to 27%.

---

## Traps this session hit — don't repeat them

1. **Scopes must sit above `MaterialApp`.** (Pre-existing fix; still true.)
2. **`MaterialApp.builder` caps content at 900px and centres it.** The desktop
   NavigationRail is therefore *not* at x=0. This silently produced four
   identical screenshots; `tools/screenshots.py` now fails on duplicates.
3. **`flutter create --platforms=…` drops in a default `widget_test.dart`** that
   tests a counter app and fails. Delete it after scaffolding.
4. **Android Studio bundles JBR Java 25**, which breaks Gradle just like the
   system's JDK 22. Flutter is pinned to 17 — leave it pinned.
5. **`flutter doctor` has no Android Studio validator in 3.44.** Its absence is
   not a detection failure.
6. **Opening a Flutter project root in Studio never triggers a Gradle sync.**
   Normal. Use *Tools → Flutter → Open Android module* if you need one.
7. `node --test test/` fails on Windows — pass explicit file paths.

---

## What is left (all requires Nikki's accounts)

1. **Microsoft Partner Center** (free) → reserve the name → paste the three
   identity fields into `pubspec.yaml → msix_config` (currently `REPLACE…`
   placeholders) → `dart run msix:create --store` → upload. Fastest listing.
2. **Google Play** $25 + ID verification → create app → upload `.aab` to
   **Closed testing** (not Production) → accept Play App Signing.
3. **Recruit 16 testers** (not 12 — dropouts reset the clock). The long pole.

Full instructions: `store/SUBMIT.md`.

### Open / unverified

- **Google Play's billing policy for the link-out shop has NOT been verified.**
  The `link_out_regions` gate was designed against Apple's 3.1.1. Google is a
  different rulebook. See the ⚠ at the end of `store/LISTING.md`.
- Whether the keystore password actually reached the password manager.
- iOS: scaffolded, bundle id `com.analyticsbyshanikwa.analyticsbyshanikwaApp`,
  needs $99 + a Mac or Codemagic. Nothing done.
- `macos/` and `linux/` are not scaffolded.
- The fulfilment worker is built and tested but **not deployed**; IAP is off.
  Phase 4, only if demand appears outside the US/JP. See `worker/GO-LIVE.md`.

---

## Standing constraints (from Nikki, honour these)

- Publish/post **only** to: analyticsbyshanikwa.com, medium.com/@shanikwa.lhaynes,
  TikTok, Pinterest. Never X, LinkedIn, or anything not explicitly named.
- **Real products only** — never list something that isn't genuinely for sale.
- **Verify Shopify/Payhip state live**; never recall it from notes.
- Leave `content_automation/` in the analyticsbyshanikwa.com repo alone.
