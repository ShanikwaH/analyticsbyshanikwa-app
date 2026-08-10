# Analytics by Shanikwa — Cross-Platform App

One Flutter codebase → native **Windows, macOS, iOS, and Android** apps, in four brand builds:

| Build | `APP_NICHE` | App name | Brand track |
|---|---|---|---|
| All-in-one | `full` (default) | Analytics by Shanikwa | Web (Navy/Blue/Green) |
| Accounting/CPA | `accounting` | Balanced Books | Web |
| Data Analytics | `data` | Analytics by Shanikwa | Web |
| Bible Stories | `bible` | Faithful Tales | Social (Purple/Lavender/Gold) |

(The Data Portfolio tab was removed by design — the portfolio lives on the website; the app is the play-and-buy surface.)

**Bundled free files (real, from Shanikwa's own catalog, in `assets/freebies/`):** Accounting Analytics Starter Kit (HTML), Accounting Analytics Skill Checker (HTML app), From Numbers to Decisions (HTML ebook), Personal Life OS (xlsx, 8 tabs incl. Debt Tracker + Payoff Timeline + Method Comparison). Listed in `content.json → bundled_files` and surfaced in the Free tab and Rewards Vault.

**Catalog policy: real products only.** The four products, prices, Payhip URLs, and cover images in `content.json` are pulled from the live shop (verified Aug 2026). The four free resources are the live, email-gated downloads on the site (delivered via the Omnisend-powered list — no Kit anywhere). To change the catalog, edit `content.json` and bump the remote version.

Each build shows only its niche's sections and leads with its niche's products, per the Sibling-Brand Track System.

## What's inside

- **Today** — this week's letter, daily **Stewardship Audit** (Proverbs 27:23, four questions, streaks), steward rank progress, newsletter join.
- **Stories** — all 30 Bible stories across the three series, series filter, read tracking, deep links to full articles, cross-sell to Scripture Memory System / Bible Timeline.
- **Play — the flagship tab.** Organized into four sections (Today & this week / Arcade — real games / Drills & decks / Records & rewards). The **Talents economy** (named for the parable):
  - **Word Search** — 9×9 grid hiding six real niche terms (Bible names from the story catalog, accounting terms, data terms); **click/drag selection** like a real puzzle book — press a letter and drag along the word (snaps to straight lines, live highlight), with tap-first/tap-last kept as an accessibility fallback (+15 daily)
  - **Memory Flip** — classic concentration, 8 themed pairs (+15 daily)
  - **Number Slide** — the classic 3×3 sliding puzzle, always-solvable shuffle (+15 daily)
  - **Letter Hunt** — hangman-style term guessing, six lives (+15 daily)
  - **Tic-Tac-Toe** — vs a classic heuristic AI (win > block > center > corner); beat it for +15 daily
  - **Follow the Pattern** — Simon-style memory: watch, repeat, sequence grows; round 5 pays +15 daily, best tracked
  - **Coin Catch** — 30-second tap-reflex round; 15+ catches pays +15 daily, best tracked
  - Both real-time games have a persisted **four-tier speed selector** (🐌 Gentle / 🐢 Relaxed / ⚖️ Standard / ⚡ Quick) — same +15 at every speed, with Coin Catch payout thresholds effort-normalized per tier (10/12/15/18 catches) so slower modes aren't quietly punished
  - Coin Catch includes a two-stage **🎯 Find my speed** calibration (2×10s): round 1 probes at the standard 700ms hop for a provisional tier; round 2 re-measures at that tier's own hop and moves ±1 tier by catch-rate (≥80% up, ≤35% down, clamped). Fixes the understated-slow-player case — 3 catches at 700ms says nothing about 1300ms. If a confirmation round MOVES the tier, one more confirmation runs at the new tier (cap: 3 rounds/session), so even a two-tier miss lands in a single 🎯 session. Both stages are pure functions (`recommendCoinSpeed`, `refineCoinSpeed`), fully tested; no payout or best-score pollution in either stage
  - Word Search placement is **guaranteed**: board-level retries plus a deterministic row fallback (`lib/games/word_search_gen.dart`, proven over 500 seeded boards in `flutter test`)
  - **Daily Challenge** — one question a day, double reward (+20)
  - **Weekly Quest** — 5 different activities in a calendar week → +75
  - **Quiz decks** — Bible / Accounting & CPA / Data Analytics (+10 per first-time correct)
  - **Ledger Lines** (accounting builds) — debit/credit true-false drill with why-explanations (+5 each)
  - **Data Signals** (data builds) — statistics & SQL true-false drill (+5 each)
  - **Scripture Memory** — word-rebuild game (+15 per verse mastered clean)
  - **Lightning Round** — 60 seconds, all decks mixed, +2 per correct on the first run each day, all-time best score tracked
  - **Story Match** — pair stories to their scripture references (+15 daily)
  - **Order the Story** — arrange five real events in biblical order, from the curated `story_order` chronology (+15 daily)
  - **Talents Ledger** — every earn posted with date, label, and running balance ("numbers tie, even here")
  - **Steward's Badges** — 10 achievements, +25 each. **All ten badges pay exactly 250 Talents — a complete path to the reward.** Market it: "Earn every badge, earn the reward."
  - **Number Crunch** — procedurally generated mental math (accounting equation & net income for accounting builds; means & ranges for data builds) — never runs out; first 5 correct per day pay +5 each
  - **The Gauntlet** — 10 correct in a row, one miss ends the run; +30 first win each day, best streak tracked forever
  - **Who Am I?** — 10 characters from the actual story catalog, 3 progressive clues each (+5 per solve)
  - **Template Trivia** — every question is a real feature of a real product; every answer reveals the live listing (+5 each). The most honest ad format ever shipped.
  - **Rewards Vault** — the full real catalog (live Payhip listings with real cover art + the four site freebies + the four bundled files) and the 250-Talent reward reveal

  The niche builds now play differently: accounting gets Ledger Lines, data gets Data Signals, bible gets the story games — same engine, distinct daily loops.
- **Shop** — all four products with dual Payhip/Shopify checkout opening in an in-app browser (no Apple 30% cut, since checkout happens on the web).
- **Free** — the four lead magnets, funneling to the email-gated site downloads.
- **Remote content updates** — the app checks `analyticsbyshanikwa.com/app/content.json` on launch; a higher `version` number replaces bundled content instantly, no store re-release.

All progress (Talents, streaks, audit journal) is stored **on-device only** — no accounts, no server, no privacy liability.

## One-time setup

1. Install Flutter (stable, **3.29 or newer**): https://docs.flutter.dev/get-started/install
2. From inside this folder, generate the platform scaffolding (this adds `android/`, `ios/`, `windows/`, `macos/` without touching the existing `lib/` and `assets/`):

```bash
flutter create --org com.analyticsbyshanikwa --project-name analyticsbyshanikwa_app --platforms=android,ios,windows,macos .
flutter pub get
```

3. Run it:

```bash
flutter run                                   # all-in-one build on whatever device is connected
flutter run --dart-define=APP_NICHE=bible     # Faithful Tales build
```

## Building releases

```bash
# Android (Play Store)
flutter build appbundle --dart-define=APP_NICHE=full

# iOS (App Store — requires a Mac + Xcode + Apple Developer account $99/yr)
flutter build ipa --dart-define=APP_NICHE=full

# Windows (Microsoft Store or direct .exe distribution)
flutter build windows --dart-define=APP_NICHE=full

# macOS
flutter build macos --dart-define=APP_NICHE=full
```

Repeat any command with `APP_NICHE=accounting`, `data`, or `bible` for the niche builds. In-app branding, colors, sections, and product ordering switch automatically. **Note:** if you ship multiple niche builds to the same store, each needs its own application ID (Android: `applicationId` in `android/app/build.gradle`; iOS: bundle identifier in Xcode) and its own store listing — set those once per niche after `flutter create`.

App icons: generate per-niche icon sets with the `flutter_launcher_icons` package (add it to `dev_dependencies`, point it at a 1024×1024 PNG per niche — orb logo on brand gradient).

## Remote content updates (no re-release needed)

1. Edit `remote/content.json` (same schema as the bundled file).
2. **Bump the `"version"` number** — the app ignores files with an equal or lower version.
3. Upload it to your site so it's reachable at:
   `https://analyticsbyshanikwa.com/app/content.json`
4. Every installed app picks it up on next launch (silent, offline-safe — failures fall back to cache, then bundled).

Use this to rotate `this_week`, add stories, change prices, add quiz questions, or add products.

## Before you ship — launch checklist

- [ ] **Reward at 250 Talents**: the app promises "a shop reward" at the Five Talents rank. Create a real discount code in Payhip **and** Shopify (e.g. `FIVETALENTS`) and add the code text to the reward card copy in `lib/screens/play_screen.dart` and `lib/screens/shop_screen.dart` — right now the copy is deliberately vague so nothing false ships.
- [ ] Store listings: Apple rejects apps that are "just a website wrapper" — this app is safe because the games, audit journal, streaks, and offline story reader are native functionality, but lead your App Store description with those, not the shop.
- [ ] Privacy policy URL (App Store + Play Store both require one): your existing `analyticsbyshanikwa.com/privacy-policy.html` works — confirm it mentions that the app stores progress locally and collects nothing.
- [ ] Test the four niche builds once each (`flutter run --dart-define=...`).
- [ ] Verses in the memory game are KJV (public domain) — if you ever swap in NIV/ESV text, licensing applies.

## Project map

```
lib/
  app_config.dart          # niche switch, two-track brand tokens, section lists
  models.dart              # defensive JSON models
  content_repository.dart  # bundled → cached → remote content loading
  app_state.dart           # Talents economy, streaks, persistence
  main.dart                # theme + app scope
  widgets/common.dart      # link opener (in-app browser), chips, cards
  screens/                 # today, stories, story detail, play (daily
                           # challenge, quizzes, lightning, match, badges),
                           # verse game, shop, resources, audit
assets/content/content.json  # bundled content database (v1)
remote/content.json          # copy to host at /app/content.json
```

— Built from real work. Not theory.
