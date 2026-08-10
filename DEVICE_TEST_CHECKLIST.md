# Device Test Checklist — First Real Build

The container that built this project can't run the Flutter engine, so two
things were verified statically instead of on-device. This checklist turns
your first build into the missing verification. Total time: ~5 minutes.

## Step 0 — Headless verification (no device needed)

```bash
flutter pub get
flutter test
```

`flutter test` passing proves more than the tests themselves: it **fully
compiles** `models.dart`, `app_state.dart`, and everything they import —
closing the "static checks only" gap. The suite also verifies the Talents
economy math (daily locks, crunch cap, gauntlet payout, weekly quest, the
10-badges-equals-250 identity) and the real-catalog contract (all four
Payhip URLs, all four bundled files present in `assets/freebies/`).

## Step 1 — The open-with-fallback path (the one untestable in CI)

Run on a real phone: `flutter run`

| # | Device state | Tap | Expected |
|---|--------------|-----|----------|
| 1 | Any phone | Free tab → **Personal Life OS** | Opens in Sheets/Excel if installed |
| 2 | Phone **without** any spreadsheet app | Free tab → **Personal Life OS** | Snackbar: "No app on this device opens that file…" then the free-resources page opens in-app |
| 3 | Any phone | Free tab → **Accounting Analytics Starter Kit** (HTML) | Opens in browser/viewer |
| 4 | Airplane mode + no spreadsheet app | Free tab → **Personal Life OS** | Snackbar, then browser error page (acceptable: fallback needs network by definition) |
| 5 | Any phone | Rewards Vault → any bundled card | Same behavior as Free tab |

To simulate case 2 on Android without uninstalling apps: Settings → Apps →
Sheets/Excel/Drive → Disable. Re-enable after.

**No manifest changes are required.** `open_filex` ships its own Android
FileProvider; `path_provider` temp dirs need no permissions on either OS.

## Step 2 — Per-niche smoke test (2 minutes)

```bash
flutter run --dart-define=APP_NICHE=accounting
flutter run --dart-define=APP_NICHE=data
flutter run --dart-define=APP_NICHE=bible
```

For each: Play tab renders, its exclusive game is present (Ledger Lines /
Data Signals / story games), no Portfolio tab anywhere.

## Known-good dependency pins

`open_filex: ^4.5.0` and `path_provider: ^2.1.4` are stable, widely-deployed
releases. If `flutter pub get` ever resolves a breaking major bump, pin the
exact versions above.

## If the fallback fires more than expected

That's not a bug — it's the funnel. Every fallback lands the user on the
email-gated free-resources page (Omnisend list). Check Omnisend for the
subscribers it produced before "fixing" anything.

## Feel pass — real-time game tuning (requires a real device)
| Game | What to check | If it feels wrong |
|---|---|---|
| Coin Catch | Tap 🎯 Find my speed (2×10s) FIRST — round 1 probes at 700ms, round 2 confirms at YOUR tier's hop | Round 2 moves ±1 tier: ≥80% catch-rate at your hop → faster, ≤35% → slower, else locked |
| Coin Catch | Hand the phone to the youngest tester and run 🎯 again | The threshold scales with speed (Gentle needs 10, Quick needs 18) so every tier is winnable |
| Follow the Pattern | Standard flash (450ms) readable on your phone? | 🐌 Gentle = 850ms flash for pre-readers; chip persists |
| Both | Chip choice survives app restart | Speeds are persisted via shared_preferences |

Payout note: +15 is identical at every speed — the once-per-day cap is the anti-farm control, so speed is purely about feel (a pre-reader on Faithful Tales can run 🐢 everywhere).

## Word Search drag feel (requires a real device)
| Check | Expectation |
|---|---|
| Drag a finger across a word | Highlight follows and snaps to the straight line, like a marker stroke |
| Drag diagonally with a wobbly finger | Snap picks the dominant direction — no jitter between lines |
| Page doesn't scroll while dragging on the grid | `touch-action:none` (web) / pan gesture (Flutter) owns the grid |
| Tap one letter, then the last letter | Fallback mode still claims the word (accessibility path) |
