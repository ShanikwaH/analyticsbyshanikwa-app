# Shipping this app — Web, Android, iOS

Written 2026-08-09 against the real project, after getting it to build.

---

## Read this first: the app did not compile

The zip you gave me had **20 compile errors**. It had never been built — there
were no `android/`, `ios/` or `web/` folders either, so no build had ever been
attempted. That is normal for generated code, but it means "turn this into an
app" started one step earlier than expected.

All 20 are fixed and committed. What was wrong:

| Problem | Why it mattered |
|---|---|
| `AppContent` constructor never initialized 6 declared fields (`tfDecks`, `storyOrder`, `whoAmI`, `templateTrivia`, `bundledFiles`, `gameWords`) | Nothing compiled. All six keys exist in `content.json` — the constructor just stopped early. |
| `Product` never read `image` / `format` | `vault_screen` used both. They exist in `content.json`. |
| `TalentsState` used without importing `app_state.dart` | Coin Catch screen failed. |
| 10 × `invalid_constant` | `AppConfig.primary` is a niche-dependent getter, so it can never sit inside a `const`. |
| `pubspec.yaml` declared `assets/freebies/content.json` | That file does not exist; a missing declared asset fails the build. |
| `import 'dart:io'` in `widgets/common.dart` | **`dart:io` does not exist on web.** This alone made `flutter build web` impossible. Now split behind a conditional import (`lib/widgets/file_opener.dart`). |

**Verified after the fixes:** `flutter analyze` → 0 errors. `flutter build web
--release` → succeeds. Loaded in Chrome: Today tab renders this week's letter,
Stewardship Audit, steward rank; Play tab renders Daily Challenge, Weekly Quest
and the arcade list; **no console errors.**

Flutter 3.44.9 is installed at `C:\Users\nikki\flutter-sdk`.

---

## What it actually costs

You asked for free if possible. Here is the truth, per platform.

| Platform | Cost | Free? |
|---|---|---|
| **Web** | $0 forever | Yes, completely |
| **Android — direct APK** | $0 | Yes — but no Play Store listing |
| **Android — Google Play** | **$25 once**, lifetime | No |
| **iOS — App Store** | **$99/year**, forever | **No. There is no free path.** |

**There is no way to publish to the iOS App Store for free.** Not TestFlight
(same $99 program), not a workaround. The only free iOS option is running it on
your own device with a free provisioning profile, which expires after 7 days and
cannot be shared with anyone. If someone tells you otherwise, they are describing
either sideloading or a service that resells someone else's paid account.

**You also cannot build an iOS app on Windows.** Apple requires macOS to compile
and sign. Options in Step 4.

**Recommended order: Web first ($0), then Android ($25), then iOS ($99) only
once the app is earning.** Web costs nothing and proves the product.

---

## Step 1 — Confirm it still builds (2 minutes)

```
cd C:\Users\nikki\analyticsbyshanikwa-app
set PATH=C:\Users\nikki\flutter-sdk\bin;%PATH%
flutter analyze
flutter build web --release
```

Expect `0 errors` and `✓ Built build\web`. Add Flutter to your PATH permanently
so you don't retype it: search Windows for "environment variables" → Path → New
→ `C:\Users\nikki\flutter-sdk\bin`.

Run it locally any time:

```
flutter run -d chrome
```

---

## Step 2 — Ship the Web version (free, do this today)

Flutter web builds to a plain folder of static files, which GitHub Pages hosts
for free.

```
flutter build web --release --base-href /abs-app/
cd build\web
git init -b main
git add -A
git commit -m "web build"
gh repo create abs-app --public --source . --push
gh api -X POST repos/ShanikwaH/abs-app/pages -f "source[branch]=main" -f "source[path]=/"
```

Live at `https://shanikwah.github.io/abs-app/` in about a minute.

**The `--base-href` must match the repo name** or you get a blank white page —
this is the single most common Flutter-web deploy mistake.

### Better: put it on your own domain
`app.analyticsbyshanikwa.com` looks far more professional than a github.io URL,
and it's still free:

1. In the repo: Settings → Pages → Custom domain → `app.analyticsbyshanikwa.com`
2. At Porkbun (where your DNS lives): add a CNAME record,
   `app` → `shanikwah.github.io`
3. Rebuild with `--base-href /` since it's now at the domain root.

Cloudflare Pages is an equally free alternative and slightly faster.

### Make it installable
The web build already supports PWA install — `flutter create` generated the
manifest. On the live https URL, Chrome shows an install button and the app runs
in its own window, offline. That gets you most of "a real app" for $0.

Edit `web/manifest.json` to fix the name and colours before shipping — the
generated defaults say `analyticsbyshanikwa_app`.

---

## Step 3 — Android ($25 once)

### 3a. Install the Android SDK (free)
`flutter build apk` currently fails with *"No Android SDK found"*. Fix:

1. Install **Android Studio** (free): https://developer.android.com/studio
2. First launch → SDK Manager → install **Android SDK Platform 35** and
   **Android SDK Command-line Tools**
3. Accept licences: `flutter doctor --android-licenses` (type `y` to each)
4. Verify: `flutter doctor` — the Android section should be green

**Watch out:** you have **Java 22** installed. Android Gradle wants **JDK 17**.
If the build fails with a Gradle/JVM error, install JDK 17 and point Flutter at
it: `flutter config --jdk-dir "C:\Program Files\Java\jdk-17"`.

### 3b. Create a signing key (free, do it once, never lose it)
```
keytool -genkey -v -keystore C:\Users\nikki\abs-upload-key.jks ^
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Then create `android/key.properties`:
```
storePassword=<what you typed>
keyPassword=<what you typed>
keyAlias=upload
storeFile=C:/Users/nikki/abs-upload-key.jks
```

**Back this .jks file up somewhere permanent.** Lose it and you can never update
your own app again — you'd have to publish a new listing and lose your reviews.
It is already in `.gitignore` so it never reaches GitHub.

Wire it into `android/app/build.gradle.kts` — the Flutter docs page
"Build and release an Android app" has the exact block to paste.

### 3c. Build the upload file
```
flutter build appbundle --release
```
Output: `build\app\outputs\bundle\release\app-release.aab`

### 3d. Google Play Console — $25, one time
1. https://play.google.com/console → pay $25 (lifetime, all your apps)
2. Identity verification — **allow several days**, they check ID
3. Create app → upload the `.aab`
4. Fill in: store listing, privacy policy URL (Step 5), data safety form,
   content rating questionnaire, target audience
5. **New personal developer accounts must run a closed test with 12 testers for
   14 continuous days before production access.** Plan for it — recruit 12
   people early. Organisation accounts are exempt.

### Free alternative, no $25
`flutter build apk --release` produces an installable `.apk` you can host on
your own site or sell through Payhip as a download. Buyers must enable "install
unknown apps". Zero fees, zero commission, far more friction. Reasonable as a
launch test, not as your main channel.

---

## Step 4 — iOS ($99/year, and you need a Mac)

### The Mac problem
You are on Windows. Apple requires macOS to compile and sign iOS apps. Three
routes:

| Route | Cost | Notes |
|---|---|---|
| **Codemagic CI** | Free tier: 500 build-min/month | Builds on their Macs, uploads to App Store Connect. **Best option for you.** |
| GitHub Actions `macos-latest` | Free for public repos | Free minutes are limited and macOS runners burn them 10× faster |
| Borrow / rent a Mac | varies | Mac mini, a friend's Mac, or MacinCloud (~$25/mo) |

Codemagic connects to your GitHub repo, detects Flutter, and builds iOS without
you owning a Mac. You still need the $99 Apple account for the certificates.

### 4a. Apple Developer Program — $99/year
https://developer.apple.com/programs — enrolment takes a day or two; individuals
need ID, businesses need a D-U-N-S number.

### 4b. Build and submit
1. In App Store Connect, create the app with bundle id
   `com.analyticsbyshanikwa.analyticsbyshanikwaApp` (already set by
   `flutter create --org`)
2. In Codemagic: connect the repo, add your Apple API key, enable iOS build,
   set "publish to App Store Connect"
3. Screenshots required for **6.7"** and **5.5"** iPhone sizes minimum
4. Submit. First review is typically 24–48 hours.

### Expect a rejection or two. Two likely ones for this app specifically:

**Guideline 4.2 — Minimum Functionality.** Apple rejects apps it considers
repackaged web content or "not enough for an app". Your app is genuinely native
with real games and offline state, so lead with that in the review notes.

**Guideline 3.1.1 — In-App Purchase.** This is the big one. Your README says
*"no Apple 30% cut, since checkout happens on the web."* **Do not assume that
holds.** Historically, linking out to buy digital goods was a straight
rejection. A 2025 US court injunction changed this for the US storefront, and
external-link entitlements now exist elsewhere with conditions. The rules have
moved twice recently and may have moved again since my information was
current — **check Guideline 3.1.1 and the External Purchase Link entitlement
yourself before submitting**, or budget for IAP.

Cleanest alternative that sidesteps the whole fight: **sell the app itself** as
a paid download (one price, Apple/Google take their cut, no external-link
question), and keep the in-app shop as pure content links.

---

## Step 5 — Things both stores require before they'll take you

- **Privacy policy at a public URL.** Non-negotiable. Yours is easy: all state
  is on-device, no accounts, no server. Put it at
  `analyticsbyshanikwa.com/app-privacy`. Note that the app fetches
  `content.json` from your site (a plain content request, no personal data).
- **App icon.** Replace the generated Flutter placeholder. Easiest path is the
  `flutter_launcher_icons` package: one 1024×1024 PNG → every size for both
  stores.
- **Screenshots.** Phone sizes for each store. Take them from the running app.
- **Content rating questionnaire** (Play) and **age rating** (Apple).
- **Support URL and contact email** — use `hello@analyticsbyshanikwa.com`.
- **Export compliance** — Apple asks about encryption. You use plain https, so
  the standard exemption applies.

---

## Step 6 — Which build to ship

The app supports four niche builds via `--dart-define`:

```
flutter build appbundle --release --dart-define=APP_NICHE=full
flutter build appbundle --release --dart-define=APP_NICHE=accounting
flutter build appbundle --release --dart-define=APP_NICHE=bible
```

**Ship `full` first, as one app.** Four listings means four review cycles, four
sets of screenshots, and four things to update forever — before you know whether
anyone wants one. Split later if the data says to.

---

## Honest summary

| | Cost | Time to live | Blocked on |
|---|---|---|---|
| Web | **$0** | Under an hour | Nothing. It builds today. |
| Android | $25 | 1–3 weeks | Android Studio, keystore, 12-tester closed test |
| iOS | $99/yr | 2–4 weeks | Apple enrolment, Mac or Codemagic, review |

**Do Web this week.** It's free, it works right now, and it gives you a real
link for Notion, TikTok, your Shopify store and your email list. Everything
after that is a business decision about whether $124 of store fees earns its
place.

## What I have not verified

- The Android build — no SDK installed, so it stops at "No Android SDK found".
  Everything before that point is confirmed working.
- The iOS build — impossible to check on Windows.
- Runtime behaviour of the freebie-opening code on a real phone. The web path
  is new code I wrote (`file_opener_web.dart`) and is untested in a browser
  against a real download.
- Whether Apple will accept the external-checkout model. See Guideline 3.1.1
  above — that one needs your own check against current policy.
