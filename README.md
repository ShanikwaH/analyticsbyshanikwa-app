# Analytics by Shanikwa — Cross-Platform App

One Flutter codebase → **Web, Android, iOS, Windows**, in four brand builds.
(`macos/` and `linux/` are not scaffolded — add with `flutter create --platforms=macos .`)

**Live now: [app.analyticsbyshanikwa.com](https://app.analyticsbyshanikwa.com)** — installable, works
offline, sells today via link-out checkout at 0% platform fee.

| Build | `APP_NICHE` | App name | Brand track |
|---|---|---|---|
| All-in-one | `full` (default) | Analytics by Shanikwa | Web (Navy/Blue/Green) |
| Accounting/CPA | `accounting` | Balanced Books | Web |
| Data Analytics | `data` | Analytics by Shanikwa | Web |
| Bible Stories | `bible` | Faithful Tales | Social (Purple/Lavender/Gold) |

Each build shows only its niche's sections and leads with its niche's products.

## Status — verified 2026-08-10

| | State |
|---|---|
| **Web** | **Live and selling.** Deployed to GitHub Pages, custom domain, PWA-installable |
| **Android** | **Toolchain ready and the app builds** (`app-release.aab`, 50.6 MB). Needs an upload keystore + the $25 account |
| **iOS** | Not started. $99/yr |
| **In-app purchase** | Built and tested, deliberately **off** (`iap_enabled: false`) |
| **Fulfilment worker** | Built and tested, **not deployed**. Refuses everything by default |
| **Catalog** | 115 products live in the app, from the live Shopify/Payhip stores |
| **Tests** | **33 Flutter + 40 worker, all passing** |
| **App icon / privacy policy** | Done, all platforms |

New here? Read **`START-HERE.md`** — the whole path to selling, in dependency order.

## What's inside

- **Today** — this week's letter, daily **Stewardship Audit** (Proverbs 27:23, four questions,
  streaks), steward rank progress, newsletter join.
- **Stories** — 30 Bible stories across three series, series filter, read tracking, deep links,
  cross-sell to Scripture Memory System / Bible Timeline.
- **Play — the flagship tab.** Four sections (Today & this week / Arcade / Drills & decks /
  Records & rewards), all paying into the **Talents economy** (named for the parable). 20+ games —
  Word Search, Memory Flip, Number Slide, Letter Hunt, Tic-Tac-Toe, Follow the Pattern, Coin Catch,
  Daily Challenge, Weekly Quest, quiz decks, Ledger Lines, Data Signals, Scripture Memory,
  Lightning Round, Story Match, Order the Story, Number Crunch, The Gauntlet, Who Am I?,
  Template Trivia, plus the Talents Ledger, Steward's Badges and Rewards Vault.
  See **"Games worth knowing about"** below for the non-obvious ones.
- **Shop** — Featured (the 4 hero products) + **All 115**, with search, category chips and a
  Bundles filter. Dual Payhip/Shopify checkout in an in-app browser.
- **Free** — the four real lead magnets.
- **Remote content updates** — the app fetches `analyticsbyshanikwa.com/app/content.json` on launch;
  a higher `version` replaces bundled content instantly, **no store re-release**.

All progress (Talents, streaks, audit journal) is stored **on-device only** — no accounts, no server,
no privacy liability. That is a genuine App Store data-safety answer: *no data collected*.

### Games worth knowing about

- **Word Search** — 9×9 grid, six real niche terms. **Click-and-drag selection** like a real puzzle
  book: press a letter and drag along the word (snaps to straight lines, live highlight), with
  tap-first/tap-last as an accessibility fallback. The drag uses a custom eager-accept gesture
  recognizer (`_BoardPanRecognizer`) so the surrounding scroll view cannot steal the gesture — that
  bug made vertical words undraggable. Placement is **guaranteed** via board-level retries plus a
  deterministic row fallback (`lib/games/word_search_gen.dart`, proven over 500 seeded boards).
- **Coin Catch / Follow the Pattern** — persisted **four-tier speed selector**
  (🐌 Gentle / 🐢 Relaxed / ⚖️ Standard / ⚡ Quick). Same +15 at every speed, with Coin Catch payout
  thresholds effort-normalized per tier (10/12/15/18) so slower modes aren't quietly punished.
- **🎯 Find my speed** — two-stage calibration (2×10s). Round 1 probes at the standard 700ms hop;
  round 2 re-measures at that tier's own hop and moves ±1 tier by catch-rate. If round 2 *moves* the
  tier, one more confirmation runs (cap: 3/session), so a two-tier miss still lands in one session.
  Both stages are pure functions (`recommendCoinSpeed`, `refineCoinSpeed`), fully tested, with no
  payout or best-score pollution.
- **Steward's Badges** — 10 achievements, +25 each. **All ten pay exactly 250 Talents — a complete
  path to the reward.** Market it: "Earn every badge, earn the reward."
- **Template Trivia** — every question is a real feature of a real product; every answer reveals the
  live listing. The most honest ad format ever shipped.

The niche builds play differently: accounting gets Ledger Lines, data gets Data Signals, bible gets
the story games — same engine, distinct daily loops.

## Catalog policy: real products only

Every product, price, URL and cover image in `content.json` comes from the **live** Shopify and
Payhip stores. The four free resources are the live, email-gated downloads on the site (delivered via
Omnisend — no Kit anywhere). Never add a product here that isn't really for sale.

The 115-item catalog is generated by `tools/import_catalog.py`, which scores each product into a
category (tags weighted 3×) and greedily assigns **one bundle zip per product**, aborting on
duplicate IAP ids rather than shipping an ambiguous mapping.

## How selling works, and why it's built this way

Link-out earns **~$17.60** on a $18.99 sale; iOS IAP at the 15% Small Business rate earns $16.14. So
the app links out **wherever the rules allow** and only falls back to IAP where they don't:

- `commerce.link_out_regions` is currently `["US", "JP"]` — the US after the Epic injunction, Japan
  since 2025-12-18 under the Mobile Software Competition Act (Apple charges 15% steering there).
- Everywhere else, linking out is still a **Guideline 3.1.1** violation, so the Shop hides link-out
  buttons entirely. `AppConfig.canLinkOut()` **fails closed** when the region is unknown.
- **Web builds ignore all of this** — no store, no rules, no cut.
- Both lists are remote-configurable: edit `content.json`, bump `version`, done. No app release.

A product only ever shows a buy button when it can actually be delivered
(`Purchases.sellable()` — needs `iap_enabled` **and** a non-empty `iap_id` **and** a
`fulfillment_url`). **The app will never take money it cannot fulfil.**

## Fulfilment worker (`worker/`)

Paid downloads are served by a Cloudflare Worker backed by a **private** R2 bucket, so unlike a
folder on a static host there is no public URL to leak.

```
POST /grant     { productId, platform, receipt }  -> { url, expiresIn: 300 }
GET  /download?t=<token>                          -> the file
```

- Tokens are **HMAC-SHA256**, 5-minute TTL, verified in constant time before any JSON parsing.
- The file key is **re-derived server-side** from the product id — a token cannot pin an old file,
  and the client can never choose which file it gets.
- `ENTITLEMENT_MODE` gates who may be granted a link: `disabled` (default — `/grant` returns 501),
  `shared-secret` (sandbox testing only), or `stores` (real receipt validation).
- **Real** Apple (ES256 JWT → App Store Server API, production→sandbox fallback, checks bundleId,
  productId and `revocationDate`) and Google (RS256 JWT → OAuth → Android Publisher, requires
  `purchaseState === 0`) verification in `worker/src/entitlement.js`.
- **Everything fails closed.** Missing config, network error, malformed id or mismatch → denied.
  There is no code path where an error grants a download.

**Not yet proven:** no real Apple or Google receipt has ever been validated, because no developer
account exists yet. The 40 tests use real ES256/RSA keys and a real R2 round-trip, but only the store
HTTP responses are mocked. **Sandbox testing is required, not optional** — see `worker/GO-LIVE.md`.

## One-time setup

1. Install Flutter (stable, **3.29 or newer**): https://docs.flutter.dev/get-started/install
2. `flutter pub get`
3. Run it:

```bash
flutter run -d chrome                          # web
flutter run --dart-define=APP_NICHE=bible      # Faithful Tales build
```

### Android toolchain — already installed on this machine

| Piece | Where | Note |
|---|---|---|
| JDK 17.0.20 LTS | `C:\Users\nikki\jdk-17` | Side-by-side; JDK 22 stays the system default |
| Android SDK | `C:\Users\nikki\AppData\Local\Android\Sdk` | platform 36, build-tools 36.1.0, platform-tools 37.0.1 |
| Android Studio Quail 3 | `C:\Users\nikki\AndroidStudio` | `AI-261.26222.65`, Start Menu shortcut created |

All three are registered with Flutter (`flutter config --list` shows `jdk-dir`, `android-sdk`,
`android-studio-dir`). `flutter doctor` reports **No issues found**.

**Gradle needs JDK 17** — not the system's 22, and not Android Studio's bundled JBR (Java 25).
Both would fail. Flutter is pinned:

```bash
flutter config --jdk-dir "C:\Users\nikki\jdk-17"   # already done
```

Android Studio was installed from Google's **no-installer zip** (`ide-zips/…-windows.zip`), because
the `.exe` installer demands UAC elevation. The zip needs no admin rights. Launch it from the Start
Menu or `C:\Users\nikki\AndroidStudio\bin\studio64.exe`.

`flutter doctor` shows no "Android Studio" line — that is expected: Flutter 3.44 removed that
validator. It is not a detection failure.

## Building releases

```bash
flutter build web --base-href /                       # web (what's deployed today)
flutter build appbundle --dart-define=APP_NICHE=full  # Android — verify: bash tools/check_signing.sh
flutter build windows --dart-define=APP_NICHE=full    # Windows (30 MB .exe, ~76s)
flutter build ipa --dart-define=APP_NICHE=full        # iOS — needs a Mac; use Codemagic's free tier
```

Repeat with `APP_NICHE=accounting`, `data`, or `bible`. **If you ship multiple niche builds to the
same store, each needs its own application ID and store listing.**

## Remote content updates (no re-release needed)

1. Edit `remote/content.json`.
2. **Bump `"version"`** — the app ignores files with an equal or lower version. Live is **v12**.
3. Upload to `https://analyticsbyshanikwa.com/app/content.json`.
4. Installed apps pick it up on next launch (silent, offline-safe: remote → cache → bundled).

Use this to rotate `this_week`, add stories or products, change prices, or flip commerce flags.

**Gotcha:** the CDN caches for ~10 minutes, and a remote file *without* a key overrides the bundled
one that has it — that's how the Shop once showed "All 0". Always verify the live JSON after upload.

## Before you ship — launch checklist

- [ ] **Reward at 250 Talents**: the app promises "a shop reward". Create a real discount code in
      Payhip **and** Shopify (e.g. `FIVETALENTS`) and put the code in the reward card copy in
      `lib/screens/play_screen.dart` and `shop_screen.dart` — the copy is deliberately vague today so
      nothing false ships.
- [ ] Store listings: lead with the games, audit journal, streaks and offline reader — **not** the
      shop. `SELLING.md` §6d has review notes that pre-empt the two likely rejections (3.1.1 external
      links, 4.2 minimum functionality).
- [ ] Data safety: **no data collected** — true, and a selling point. Category **Education**, not Games.
- [ ] Privacy policy URL: `analyticsbyshanikwa.com/privacy-policy.html`, already mentions the app.
- [ ] Test the four niche builds once each.
- [ ] Verses are KJV (public domain). Swapping in NIV/ESV triggers licensing.
- [ ] **Re-read Guideline 3.1.1 on the day you submit** — it changed twice in 18 months.

## Documentation map

| File | What it's for |
|---|---|
| **`START-HERE.md`** | The whole path to a sellable app, in dependency order. Start here. |
| `SHIP.md` | Per-platform build and store-submission detail |
| `SELLING.md` | Commercial side: pricing, fees, regions, App Store review notes |
| `worker/GO-LIVE.md` | Exact steps to take real money, with a verification after each |
| `worker/README.md` | Worker architecture and threat model |
| `DEVICE_TEST_CHECKLIST.md` | Manual test pass before a release |

## Project map

```
lib/
  app_config.dart          # niche switch, brand tokens, canLinkOut() region gate
  models.dart              # defensive JSON models incl. CatalogItem
  content_repository.dart  # bundled -> cached -> remote content loading
  app_state.dart           # Talents economy, streaks, persistence
  main.dart                # PurchasesScope > AppScope > MaterialApp (scopes MUST sit
                           # above MaterialApp or pushed routes can't reach them)
  commerce/purchases.dart  # in_app_purchase service + sellable() safety gate
  games/                   # word search generation, speed calibration
  widgets/                 # common, BrandOrb, file_opener (web/io conditional import)
  screens/                 # today, stories, play, shop, catalog, resources, audit, +20 games
assets/content/content.json  # bundled content database
remote/content.json          # copy hosted at /app/content.json (live: v12)
tools/                       # catalog import, fulfilment packaging + publishing
worker/                      # signed-download Cloudflare Worker (src, tests, runbook)
test/                        # 33 Flutter tests
```

**Branches:** source lives on **`source`**. `main` holds the deployed web build and is **public** —
never commit paid inventory to it. `build/` and `worker/.staging/` are gitignored for that reason.

— Built from real work. Not theory.
