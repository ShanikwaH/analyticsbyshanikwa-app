# HANDOFF — Windows Store live, 1.0.2.0 in certification

**Written:** 2026-08-12 13:44 ET
**Session before this:** 2026-08-10 store readiness (`HANDOFFS/2026-08-10-store-readiness.md`)

---

## Goal

Shanikwa (Nikki) Haynes sells Christian faith-based digital products under
**Analytics by Shanikwa**. The Flutter app (Bible stories, games, template
catalog, links out to Shopify/Payhip) is her free top-of-funnel product.

**Current plan, set 2026-08-11: Web + Windows only. No Mac, no iOS, no Android.**
Total cost $0. The web build is an installable PWA, which already covers iPhone
and Android users at 0% commission. Android is packaged and signed but
deliberately parked. The authoritative plan is
`C:\Users\nikki\analyticsbyshanikwa-app\store\SELL-WEB-AND-WINDOWS.md`.

---

## Current state

### Shipped and verified

| Channel | State |
|---|---|
| **Web** | Live at `app.analyticsbyshanikwa.com`. Deployed from the app repo's `main` branch. |
| **Windows** | **LIVE on the Microsoft Store** — <https://apps.microsoft.com/detail/9P0FQN3JFWRD> |
| Android | `.aab` signed and ready, **not uploaded**. Keystore valid to 2053. |
| iOS / macOS / Linux | Not pursued. |

- **Certification passed 2026-08-12** for package `1.0.1.0`. That is what the
  listing serves today.
- **`1.0.2.0` FAILED certification 2026-08-13 on policy 10.8.2.** Not a code
  fault — the listing needs a Properties checkbox declaring the Shop screen's
  link-out purchases. Fix and rationale: `store\SUBMIT.md` **A6**. The live
  listing is unaffected. This is the only open item.
- **37 Flutter tests pass** (`flutter test`, run 2026-08-12).
- **Store URL published in 3 places**, each verified after publishing:
  1. Site `app.html` — badge section `#windows` + cross-link from the
     Windows & Mac install card. Confirmed live by fetching the page.
  2. **YouTube** channel link titled "Windows App" (10th link). Published,
     and all 9 pre-existing links confirmed intact afterward.
  3. **Omnisend Welcome email 1** (contentID `6a1e374665ea1d29dee4cea5`).
     PUT returned 200; response diffed to confirm only the intended text changed.

### Deliberately NOT done

- **TikTok / Pinterest / Medium bios** — all at their character limits
  (TikTok 71/80, Pinterest 472/500, Medium ~125/160). The Store URL is 44+
  chars and does not fit without cutting her existing copy. **Nikki decided on
  2026-08-12 to leave all three as-is** — each already links to the site or the
  web app, and the site now carries the Store badge. Do not revisit unasked.
- **Omnisend Welcome emails 2 and 3** — left without the Store link on purpose.
  Three mentions in a subscriber's first week reads as nagging.
- **Sunday Letter scheduling** — explicitly deferred by Nikki:
  *"fix the sunday letter scheduling once I get my first subscriber that is not
  Shanikwa nikki.19972010@gmail.com because that is myself the owner."*
  Baseline verified earlier: exactly 1 contact. **Do not touch until she says so.**

### Repos

Both clean and pushed as of this handoff.

- `C:\Users\nikki\analyticsbyshanikwa-app` — branch **`source`** at `39209fd`.
  Branch `main` is the **deployed public web build** (`29089f5`), not source.
- `C:\Users\nikki\analyticsbyshanikwa.com` — branch `main` at `701d9e5`.
  **Working tree is intentionally dirty** (see Gotchas).

---

## Key files & locations

### App repo — `C:\Users\nikki\analyticsbyshanikwa-app\`

| Path | Purpose |
|---|---|
| `START-HERE.md` | The one-page plan and status table. Read first. |
| `store\SELL-WEB-AND-WINDOWS.md` | The live plan: web + Windows, $0. |
| `store\SUBMIT.md` | Step-by-step submission. **Section A5** = resubmit mechanics for every future update. |
| `store\LISTING.md` | Listing copy + Partner Center gotchas hit during first submission. |
| `pubspec.yaml` | `version: 1.0.2+3`, `msix_config.msix_version: 1.0.2.0`. |
| `lib\app_config.dart` | `canLinkOut()` region gate + desktop carve-out. |
| `lib\models.dart` | `AppContent.rewardCode` / `hasReward` — reward is content-driven, not hardcoded. |
| `lib\screens\shop_screen.dart` | Names the reward code when configured; stays vague when not. |
| `test\commerce_test.dart` | Region-gate + Five Talents reward regressions. |
| `assets\content\content.json` | Bundled content, `commerce.reward_code = FIVETALENTS`. |
| `remote\content.json` | v13, published to the site — lets content change without an app release. |
| `build\windows\x64\runner\Release\analyticsbyshanikwa_app.msix` | The 1.0.2.0 package (24.3 MB). |

### Site repo — `C:\Users\nikki\analyticsbyshanikwa.com\`

| Path | Purpose |
|---|---|
| `app.html` | App landing page: install steps per device, Store badge at `#windows`. |
| `privacy-policy.html` | Section 10 covers the app; `id="app"` anchor is linked from `app.html`. |
| `app\content.json` | The remote content the shipped app fetches. Currently v13. |

### Other

- Keystore: `C:\Users\nikki\keystores\upload-keystore.jks` (Android, parked).
- Store product ID: **9P0FQN3JFWRD**. Publisher CN
  `CN=82609663-1176-497C-A1B0-947A85A73EEF`, identity
  `AnalyticsbyShanikwa.AnalyticsbyShanikwa`.
- Certification emails go to **nikki.19972010@hotmail.com** (NOT the Gmail).

---

## Decisions & constraints

- **Web + Windows only.** Do not scaffold or propose Mac/iOS/Android work.
- **The reward code lives in `content.json`, not Dart** — so the offer can change
  or be withdrawn without an app release. `hasReward` gates the UI: with no code
  configured it says "every download in one place" and names nothing.
  `FIVETALENTS` = 20% off, exists in **both** Shopify and Payhip, no expiry.
- **Region gate is mobile-only.** Applying it on desktop hid the Shop from, e.g.,
  a Windows user in the UK — satisfying an Apple/Google rule that does not apply
  to them and costing the sale. Test uses `'ZZ'` so it has teeth on any machine.
- **Fonts are bundled, not fetched.** `GoogleFonts.config.allowRuntimeFetching =
  false` — runtime fetching leaked user IPs to Google on first launch.
- **Never touch `content_automation\`** in the site repo. It is WIP and holds
  ~212 MB of video that must not enter the repo.
- **Post only to** analyticsbyshanikwa.com, medium.com/@shanikwa.lhaynes, TikTok,
  Pinterest, and YouTube. Never X/LinkedIn or any platform not explicitly named.
- **Verify store state live** (Shopify/Payhip/Partner Center) rather than
  recalling it — the catalog moves faster than any notes.
- Strip `?cid=DevShareMCLPCS` from Partner Center share links; it is share
  attribution, not part of the address.

---

## Gotchas

These each cost real time. Read before acting.

1. **Flutter/Dart strings in a Windows release are UTF-16.**
   To confirm a string shipped, grep `data\app.so` inside the packed `.msix`.
   Literals containing emoji or em dashes are stored **UTF-16LE** — an ASCII
   grep returns nothing and a correct build looks broken.
   ```python
   d=open('app.so','rb').read(); d.find('your string'.encode('utf-16-le'))
   ```

2. **A green push to the site repo does not mean a live page.**
   GitHub Pages serves from `main` root, `build_type: legacy`. A force-push made
   two builds fail instantly (`duration: 0`, "Page build failed") with nothing
   wrong in the tree. Always check, and retrigger if needed:
   ```bash
   gh api repos/ShanikwaH/analyticsbyshanikwa.com/pages/builds --jq '.[0].status'
   gh api -X POST repos/ShanikwaH/analyticsbyshanikwa.com/pages/builds
   ```

3. **NEVER `git add -A` in the site repo.** Its working tree is permanently
   dirty with `content_automation\` WIP including three 60–75 MB videos. I did
   this and pushed 212 MB before catching it. **Stage by filename.**

4. **Flutter is not on PATH.** Use `/c/Users/nikki/flutter-sdk/bin`:
   ```bash
   export PATH="/c/Users/nikki/flutter-sdk/bin:$PATH"
   ```

5. **Browser automation: use element refs, not screenshot coordinates.**
   On dynamic pages (YouTube Studio, Medium) the layout shifts between the
   screenshot and the click. This overwrote an existing YouTube link and, on
   Medium, navigated away mid-task. Use `find` → `computer{ref:...}`, and read
   the DOM to verify **before** clicking Publish/Save.

6. **Omnisend `put_email_content_id` is a full-document replace.** GET, edit,
   PUT the whole thing. Omitted sections are deleted. `generalSettings` is
   required, and some text block must contain `[[unsubscribe_link]]`.

7. **Partner Center:** only one submission in flight. A "New submission" is
   correct; *editing* the in-flight one cancels it and restarts the clock.
   The `runFullTrust` justification box **silently truncates at 500 chars** —
   the accepted 468-char version is in `store\LISTING.md`.

8. **Windows machine:** no winget, not admin, `Program Files` unwritable.
   Install via vendor zip + SHA256 verify into `C:\Users\nikki\`.

9. **Chrome extension connection is flaky** — it dropped mid-session twice.
   Re-call `tabs_context_mcp{createIfEmpty:true}` to recover.

---

## Next steps

Ordered. Item 1 is the only thing actually pending; the rest are event-driven.

1. **Resubmit 1.0.2.0 with the 10.8.2 declaration ticked.** It failed
   certification 2026-08-13. **Nikki must do this herself** — it is all
   Partner Center account work behind her login, and no MCP reaches it.
   New submission → **Properties → Product declarations** → tick *"This app
   allows users to make purchases, but does not use the Microsoft Store
   commerce system"* → leave the package alone → submit. Full steps and the
   certification-notes text: `store\SUBMIT.md` **A6**.
   Then wait on the result email to `nikki.19972010@hotmail.com` — **no way to
   poll it** here. If it fails again, ask her to forward the report.
2. **Only when she reports a first real subscriber** (anyone other than
   `nikki.19972010@gmail.com`): revisit Sunday Letter scheduling. Not before.
3. **Optional, unprompted — do not start without asking:** Medium's full About
   page is empty and unlimited, and is the one remaining place a Store link
   would fit naturally.

---

## How to verify current state

```bash
# App repo — clean, on `source`, tests green
export PATH="/c/Users/nikki/flutter-sdk/bin:$PATH"
cd /c/Users/nikki/analyticsbyshanikwa-app
git status --short && git log --oneline -1        # expect clean, 39209fd
flutter test 2>&1 | tail -2                       # expect "All tests passed!" (37)

# The built 1.0.2.0 package: identity + the reward string actually compiled in
python -c "
import zipfile,re
z=zipfile.ZipFile('build/windows/x64/runner/Release/analyticsbyshanikwa_app.msix')
print(re.search(r'<Identity[^>]*>',z.read('AppxManifest.xml').decode('utf-8-sig')).group(0))
d=z.read('data/app.so')
print('new copy :', d.find('Five Talents rank reached. Use code '.encode('utf-16-le'))>=0)
print('old copy :', d.find('your shop reward is live'.encode('utf-16-le'))>=0)
"
# expect Version=\"1.0.2.0\", new copy True, old copy False

# Site repo — only app.html should differ from origin; everything else is WIP
cd /c/Users/nikki/analyticsbyshanikwa.com
git log --oneline -1                              # expect 701d9e5
gh api repos/ShanikwaH/analyticsbyshanikwa.com/pages/builds --jq '.[0].status'  # expect "built"

# The Store badge is actually live
curl -s https://analyticsbyshanikwa.com/app.html | grep -o 'apps.microsoft.com/detail/9P0FQN3JFWRD'
```

Store listing (should load, titled "Analytics by Shanikwa"):
<https://apps.microsoft.com/detail/9P0FQN3JFWRD>
