# Selling on Web, Windows and Mac only — no iOS, no Android

Verified 2026-08-11.

---

## Read this first: dropping iOS does not avoid Apple's $99

You cannot ship a Mac app for free. Both routes require an **Apple Developer
Program membership at $99/year**:

| Mac route | Needs | Commission |
|---|---|---|
| Mac App Store | $99/yr membership | 15–30% on in-app sales, plus review and anti-steering rules |
| Direct download from your site | $99/yr membership (**Developer ID certificate + notarization**) | **0%** — no store, no review |

An unsigned Mac app **will not launch at all** unless the user fully disables
Gatekeeper. There is no "ship it unsigned and let people click through" path any
more. Developer ID certificates are only issued to paying members.

**So the honest framing:** Web and Windows are free. Mac costs $99/year — and
that same $99 would also cover iOS if you ever wanted it. If you are paying it
for Mac, iOS is no longer the expensive part; the 12-tester-style friction is
Google's, not Apple's.

---

## The plan

| Phase | Channel | Cost | Effort | Waiting |
|---|---|---|---|---|
| 1 | Web | **$0** | already done | none |
| 2 | Windows (Microsoft Store) | **$0** | ~1 hour | days |
| 3 | Mac (direct DMG) | **$99/yr** | ~1 day | none — no review |

Do 1 and 2 first. Decide on 3 only after you see whether the free channels
convert.

---

# Phase 1 · Web — $0, already live

`app.analyticsbyshanikwa.com` is live, installable, works offline, and sells
today through link-out checkout at **0% platform fee**. This is your best margin
of any channel — roughly **$17.60 kept on a $18.99 sale.**

Nothing to build. The work is distribution:

1. Put the link in your site nav, TikTok bio, Pinterest, Medium, the Sunday
   Letter, and your Shopify store.
2. Say the words "you can install it" — Chrome and Edge offer it, and most
   visitors never notice on their own.
3. Watch it in Shopify Analytics: every product link already carries
   `utm_source=app`, and `utm_content` says which card was tapped.

That last point is the whole reason to do Phase 1 before spending anything —
it tells you whether the app converts before you pay Apple.

---

# Phase 2 · Windows — $0

Already packaged and proven: `dart run msix:create --store` produces a 23 MB
Store package, and **Microsoft signs it for you** — no certificate to buy.

Full step-by-step: **`store/SUBMIT.md` section A.** In short:

1. Register at **storedeveloper.microsoft.com** — Individual, free, ID + selfie.
   That URL is the only entry point for the free flow.
2. Partner Center → Product management → **Manage app names** → reserve
   `Analytics by Shanikwa`.
3. Product management → **Product identity** → copy the three values into
   `pubspec.yaml → msix_config`, replacing the `REPLACE…` placeholders.
4. `flutter build windows --dart-define=APP_NICHE=full`
   then `dart run msix:create --store`
5. Upload the `.msix`, paste the Microsoft section of `store/LISTING.md`, attach
   `store/screenshots/desktop-*.png`, category Education → Reference.

**Do not** distribute a plain `.exe` from your site instead. That is the one
Windows case needing a bought Authenticode certificate (~$200–400/yr), and
without it SmartScreen warns users off. The Store is free and signs for you.

---

# Phase 3 · Mac — $99/year, and only if Phase 1 shows demand

## Choose direct download, not the Mac App Store

Sell the DMG from your own site. Reasons:

- **0% commission** vs 15–30%.
- **No app review**, so no rejection risk and no waiting.
- **No anti-steering rules.** The Mac App Store applies the same external-link
  restrictions as iOS, which is exactly the constraint your app currently
  works around with region gating. Outside the store, that constraint vanishes
  and the Shop can simply always work.
- You already have the storefront and the audience. A Mac listing buys you
  discovery you do not especially need.

The only thing you give up is Mac App Store search, which is a small channel
for a niche faith-and-analytics app.

## Steps

### 3a · Pay and enrol

1. Enrol in the **Apple Developer Program**, $99/year. Individual enrolment
   needs a government ID. A business entity needs a D-U-N-S number — individual
   is simpler and fine.

### 3b · Get a Mac to build on

**You cannot build macOS on Windows.** Two options:

- **Codemagic free tier** — 500 build-minutes/month on Apple silicon M2, which
  is plenty for occasional releases. No Mac purchase. (One parallel build,
  30-day artifact retention.)
- **A borrowed or rented Mac** — simpler to debug the first time, if you have
  access to one.

Start with Codemagic. Buying a Mac to ship one app is not justified yet.

### 3c · Scaffold the Mac target

`macos/` does not exist in the repo yet. On the Mac (or in CI):

```bash
flutter create --platforms=macos .
```

Then, as happened with Windows, **delete the default `test/widget_test.dart`**
it drops in — it tests a counter app and will fail. Also regenerate icons
(`dart run flutter_launcher_icons`) and fix the app display name, exactly as
`windows/runner/Runner.rc` needed fixing.

macOS needs the **network client** entitlement so the app can fetch
`content.json` and open links. Sandbox entitlements live in
`macos/Runner/*.entitlements`.

### 3d · Sign, notarize, staple

1. In the Apple Developer portal, create a **Developer ID Application**
   certificate and install it on the build Mac.
2. Build: `flutter build macos --release --dart-define=APP_NICHE=full`
3. **Hardened Runtime must be enabled** — notarization refuses without it.
4. Package the `.app` into a `.dmg`.
5. Sign the DMG with the Developer ID certificate.
6. **Notarize** with `notarytool`, using an app-specific password or an App
   Store Connect API key.
7. **Staple** the notarization ticket to the DMG so it validates offline.

Notarization is an automated malware scan, not a review. Minutes, not days, and
there is no rejection-on-taste risk.

### 3e · Distribute

8. Host the DMG at `analyticsbyshanikwa.com/app/` (or a release on GitHub) and
   link it from the app page next to the "install the web app" prompt.
9. Test on a Mac that has never seen the app: download, open, confirm **no**
   Gatekeeper warning. If a warning appears, notarization or stapling failed —
   fix it before announcing.

### 3f · Every update

Repeat 3d and 3e and bump the version. No store, no review, ship whenever.

---

## What this costs, and what you keep

| Channel | Setup | Ongoing | Kept on a $18.99 sale |
|---|---|---|---|
| Web | $0 | $0 | ~$17.60 |
| Microsoft Store | $0 | $0 | ~$17.60 |
| Mac direct DMG | $99 | $99/yr | ~$17.60 |

Because every channel here links out to Payhip/Shopify rather than using
in-app purchase, **you keep the same margin everywhere.** No store takes a cut
of a web checkout. That is the quiet advantage of skipping mobile entirely: the
whole 15–30% question disappears, along with Apple's 3.1.1, Google's billing
policy, and the 12-tester rule.

**Mac needs to clear $99/year to be worth it** — about six sales. Phase 1 will
tell you whether that is realistic before you commit.

---

## What is already done, and what is not

**Done:** web live; Windows builds and packages; icons, listing copy,
screenshots, and store graphics all prepared in `store/`.

**Not done, and not verifiable from this Windows machine:** everything macOS.
`macos/` is not scaffolded, nothing has been signed or notarized, and none of
the Phase 3 steps have been run. Treat that section as a correct plan, not as
tested instructions.
