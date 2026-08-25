@KNOWL.md

## Analytics by Shanikwa — project instructions

One Flutter codebase shipping Web, Android, iOS and Windows in four brand builds.
`README.md` is the full picture; `START-HERE.md` is the path to shipping, in
dependency order. This file is the short version an agent needs before touching
anything.

### Branches — read this first

- **`source` is the development branch.** All work happens here: `lib/`,
  `pubspec.yaml`, `android/`, `ios/`, `web/`, `windows/`, `test/`, `worker/`,
  `tools/`, `remote/`, `store/`.
- **`main` is generated output**, not source. It holds the built web app that
  GitHub Pages serves at `app.analyticsbyshanikwa.com`. Never hand-edit it, and
  never open it expecting project context — the agent config below is
  deliberately untracked there.
- **`main` is public and carries `.nojekyll`**, which disables Jekyll's
  filtering, so every tracked file in it is a candidate to be served as a public
  URL. Never commit paid inventory, credentials or agent config to `main`.
  `build/` and `worker/.staging/` are gitignored for exactly that reason.

Agent config (`KNOWL.md`, `AGENTS.md`, `CLAUDE.md`, `.mcp.json`, `.claude/`) is
tracked **here on `source`** and gitignored on `main`.

### Setup and running

Flutter stable **3.29 or newer**; Dart SDK `>=3.7.0 <4.0.0`.

```bash
flutter pub get
flutter run -d chrome                        # web
flutter run --dart-define=APP_NICHE=bible    # a specific niche build
flutter test                                 # 33 Flutter tests
flutter analyze                              # flutter_lints
cd worker && npm test                        # 40 worker tests
```

Run the tests and the analyzer before pushing. The README records 33 Flutter +
40 worker tests all green as of 2026-08-10 — keep that true rather than
assuming it still is.

### The four niche builds

`APP_NICHE` selects which sections and products the app shows.

| `APP_NICHE` | App name | Brand track |
|---|---|---|
| `full` (default) | Analytics by Shanikwa | Web (Navy/Blue/Green) |
| `accounting` | Balanced Books | Web |
| `data` | Analytics by Shanikwa | Web |
| `bible` | Faithful Tales | Social (Purple/Lavender/Gold) |

A change to shared code affects all four. Test the niche you touched, and check
the others if you changed section gating or brand tokens.

### Rules that are not style preferences

These encode real commercial and legal constraints. Do not relax one to make
something work.

- **Real products only.** Every product, price, URL and cover image in
  `content.json` must correspond to something actually for sale on the live
  Shopify or Payhip store. Never add a placeholder product.
- **Never take money the app cannot fulfil.** `Purchases.sellable()` requires
  `iap_enabled` **and** a non-empty `iap_id` **and** a `fulfillment_url` before a
  buy button appears. Do not bypass it.
- **Fail closed, always.** `AppConfig.canLinkOut()` denies when the region is
  unknown; the fulfilment worker denies on missing config, network error,
  malformed id or mismatch. There must be no code path where an error grants a
  download or shows a buy button.
- **Verses are KJV** (public domain). Swapping in NIV/ESV triggers licensing.
- **In-app purchase is deliberately off** (`iap_enabled: false`) and the worker
  is deliberately undeployed. Neither is an oversight — see `worker/GO-LIVE.md`
  before changing either.

### Remote content updates

The app fetches `analyticsbyshanikwa.com/app/content.json` at launch, so content
ships without an app release: edit `remote/content.json`, **bump `version`**
(live is v12 — the app ignores an equal or lower version), upload.

Two gotchas that have bitten before: the CDN caches for ~10 minutes, and a
remote file *missing* a key overrides the bundled one that has it — that is how
the Shop once rendered "All 0". Verify the live JSON after every upload.

### Where things are

```
lib/app_config.dart          # niche switch, brand tokens, canLinkOut() region gate
lib/models.dart              # defensive JSON models incl. CatalogItem
lib/content_repository.dart  # bundled -> cached -> remote content loading
lib/app_state.dart           # Talents economy, streaks, persistence
lib/main.dart                # PurchasesScope > AppScope > MaterialApp
lib/commerce/purchases.dart  # in_app_purchase service + sellable() gate
lib/games/                   # word search generation, speed calibration
lib/screens/                 # today, stories, play, shop, catalog, resources, audit, +20 games
assets/content/content.json  # bundled content database
remote/content.json          # the copy hosted at /app/content.json
tools/                       # import_catalog.py, package_fulfilment.py, check_signing.sh, ...
worker/                      # signed-download Cloudflare Worker (src, tests, runbook)
test/                        # Flutter tests
```

**Structural gotcha:** in `lib/main.dart` the scopes must sit *above*
`MaterialApp`, or pushed routes cannot reach them.

The 115-item catalog is generated by `tools/import_catalog.py` — regenerate it
there rather than hand-editing catalog entries.

### Further reading

| File | For |
|---|---|
| `START-HERE.md` | The whole path to a sellable app, in dependency order |
| `SHIP.md` | Per-platform build and store submission |
| `SELLING.md` | Pricing, fees, regions, App Store review notes |
| `store/SELL-WEB-AND-WINDOWS.md` | The current live plan (Web + Windows, $0) |
| `worker/GO-LIVE.md` | Exact steps to take real money |
| `DEVICE_TEST_CHECKLIST.md` | Manual test pass before a release |
