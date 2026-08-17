# Submitting: the three things left, step by step

Verified 2026-08-10. Everything technical is done — this is account work.

**Do these in parallel, not in sequence.** Play's tester clock is the long pole,
so start recruiting today even before you pay the $25.

---

# A · Microsoft Store — free, ~1 week

### A1. Register (30 minutes, then a wait)

1. Go to **storedeveloper.microsoft.com**. This is the **only** supported entry
   point for the free individual flow — starting anywhere else can drop you into
   the old company/paid path.
2. Choose **Individual developer (free)**.
3. Sign in with a **personal** Microsoft account (not a work/school account).
   Use one you will still control in five years; the account owns the listing.
4. **Identity verification:** government-issued ID + a selfie. Do this on your
   phone, in good light, with the original document — not a photocopy or a photo
   of a screen.
5. Fill in profile details and check the auto-filled fields.
6. **Wait up to 30 minutes** for verification to propagate. If app submission
   isn't available yet, that's expected — wait and retry rather than redoing it.

### A2. Reserve the name (5 minutes)

7. In **Partner Center** → your app → **Product management → Manage app names**.
8. Type `Analytics by Shanikwa` → **Check availability** → green tick →
   **Reserve product name**.

> The reserved name generates your package identity, and **that identity is
> permanent once published.** If the exact name is taken, pick the variant you
> can live with forever.

### A3. Get the three identity values (5 minutes)

9. **Product management → Product identity.** Copy these three:

| Partner Center field | Goes into `pubspec.yaml → msix_config` |
|---|---|
| Package/Identity/Name | `identity_name` |
| Package/Identity/Publisher (`CN=…`) | `publisher` |
| Publisher display name | `publisher_display_name` |

10. Paste them in, replacing the `REPLACE…` placeholders. **Character for
    character, including case.** A mismatch is the most common MSIX rejection.

### A4. Build and submit (20 minutes)

```bash
flutter build windows --dart-define=APP_NICHE=full
dart run msix:create --store
```

11. Upload `build/windows/x64/runner/Release/analyticsbyshanikwa_app.msix`.
12. Paste the listing from `store/LISTING.md` (Microsoft Store section).
13. Add the **desktop** screenshots from `store/screenshots/desktop-*.png`.
14. Category **Education → Reference**. Privacy policy URL. Submit.

Review is usually days.

**For every future update:** bump `msix_version` (it must increase, and the last
digit must stay `0`), rebuild, re-upload. No certificate ever — Microsoft signs
Store packages.

### A5. ~~Upload 1.0.2.0 once 1.0.1.0 clears certification~~ — **DONE 2026-08-12**

> Certification passed 2026-08-12 and 1.0.2.0 was uploaded the same day. Live at
> <https://apps.microsoft.com/detail/9P0FQN3JFWRD>. Kept below because the
> mechanics are the same for every future update.


1.0.1.0 was packaged before the Five Talents reward code existed, so it still
shows the old "look for the reward note at checkout" line with no code. **The
package that fixes it is already built and verified** — nothing needs building:

```
build/windows/x64/runner/Release/analyticsbyshanikwa_app.msix   (1.0.2.0)
```

**Why wait rather than replace it now:** Partner Center allows one submission in
flight. Uploading now means cancelling 1.0.1.0 and restarting certification for
no gain — reaching 250 Talents takes all ten badges, so nobody hits the stale
copy in the meantime.

**Trigger:** the certification result email to **nikki.19972010@hotmail.com**.

**Steps (about two minutes):**

1. Partner Center → the app → **Product → Submissions → New submission**.
   Do *not* edit the in-flight one.
2. **Packages** → remove 1.0.1.0, upload the `.msix` above. It should read
   **1.0.2.0**. If it still says 1.0.1.0 you grabbed a stale file — rebuild with
   `dart run msix:create --store`.
3. Everything else — pricing, properties, age rating, listing — **carries over
   from the last submission**. Don't retype it. Two things to eyeball, because
   they are the ones that bit us the first time:
   - **Device family: Desktop only.** Confirm it is still ticked.
   - **`runFullTrust` justification** still filled in. That box silently
     truncates at exactly 500 characters; the 468-char version that was accepted
     is in `store/LISTING.md`. If it looks cut off mid-sentence, re-paste it.
4. **Certification notes:** the reviewer needs to know what changed, or they
   re-test from scratch:

   > Copy-only update. The reward message on the Shop and Play screens now names
   > the discount code (FIVETALENTS) that the previous build referred to without
   > naming. No new features, permissions, or capabilities. Same device family
   > (Desktop) and same age rating.

5. **Submit.** Same review wait as before.

**Verifying it took, after it goes live:** install from the Store, earn the
badges or check the About screen version — it should read **1.0.2**.

### A6. ~~FAILED 2026-08-13 — policy 10.8.2, missing in-app-purchase declaration~~ — **RESUBMITTED 2026-08-13**

> Nikki ticked the declaration and resubmitted the same day. **Awaiting the
> certification result.** Kept in full below because the declaration must be
> re-ticked on every future submission — see the note at the end.


**This is not a code problem. Do not rebuild. Do not change the package.**

Certification for 1.0.2.0 came back **"Attention needed"** on 08/13/2026:

> **10.8.2 Third-Party In-Product Purchases** — In-Product Purchase Found In:
> Shop – Payhip. Currently, your product is missing a required declaration.
> • Product Description Page Declaration: Shop - Payhip

**Why they are right:** the Shop screen links out to Payhip and Shopify, where
the customer spends money. Even though the transaction happens outside the app
and outside Microsoft's commerce system, Microsoft requires shoppers to be told
*before* they click **Get**. The declaration renders as a small text notice
under the Get button on the listing. It costs nothing and does not change the
app's behaviour, its rating, or its price.

**The fix — about three minutes, all in Partner Center:**

1. Partner Center → the app → **Product → Submissions → New submission**.
2. Go to **Properties**.
3. Under **Product declarations**, tick:
   **"This app allows users to make purchases, but does not use the Microsoft
   Store commerce system"**
4. **Packages: change nothing.** The 1.0.2.0 package carries over from the
   failed submission. Re-uploading it is unnecessary and only risks grabbing a
   stale file.
5. Confirm the two fields that have bitten us before are still intact:
   **Device family = Desktop only**, and the **`runFullTrust` justification**
   (it silently truncates at 500 chars; the accepted 468-char text is in
   `store/LISTING.md`).
6. **Certification notes** — tell the reviewer exactly what changed, or they
   re-test from scratch:

   > Resubmission addressing policy 10.8.2. No code, package, or feature change
   > — the same 1.0.2.0 package as the previous submission. The only change is
   > in Properties: the product declaration "This app allows users to make
   > purchases, but does not use the Microsoft Store commerce system" is now
   > ticked, covering the Shop screen's links out to Payhip and Shopify.

7. **Submit.**

**Keep this ticked on every future submission.** The declaration lives on the
submission, not on the product, so a future submission that leaves it unticked
will fail 10.8.2 again. The only way it should ever come off is if the app stops
linking out to paid products entirely.

Reference:
<https://docs.microsoft.com/en-us/windows/uwp/publish/product-declarations>

### A7. 1.0.3.0 — storefront domain change (built 2026-08-17)

**What changed and why:** the Shopify store moved to its own domain, so every
outbound product link is now `shop.analyticsbyshanikwa.com` instead of
`jrip3r-qz.myshopify.com`. Links and content only — no new features, no new
capabilities, no behaviour change.

> **This release is not what fixed the links.** The app pulls its catalogue at
> runtime from `analyticsbyshanikwa.com/app/content.json` (see
> `lib/content_repository.dart`), and that file was bumped to **v14** on
> 2026-08-17, which every install picks up on next launch. The bundled copy is
> only the offline floor. So 1.0.3.0 is a freshness release — if certification
> drags, nobody is stuck on stale links meanwhile. Old myshopify URLs also
> 301-redirect to the new domain.

**Building it — this machine cannot.** `flutter build windows` requires Visual
Studio 2022 with the Desktop C++ workload, whose installer needs admin. There is
no Flutter SDK and no Visual Studio here, and neither can be installed. The build
therefore runs in CI on a GitHub-hosted Windows runner, which ships that
toolchain:

- Workflow: `.github/workflows/build-msix.yml` (runs on push to `source` touching
  `pubspec.yaml`, `lib/**`, `assets/**`, `windows/**`, `icon_src/**`, or the
  workflow itself; also `workflow_dispatch`).
- It mirrors the documented local steps exactly:
  `flutter build windows --release --dart-define=APP_NICHE=full`, then
  `dart run msix:create --store`.
- Download the `analyticsbyshanikwa_app-msix` artifact from the run
  (`gh run download <run-id> -n analyticsbyshanikwa_app-msix -D dist`).
  Artifacts expire after 30 days; just re-run the workflow if one lapses.

**First build:** run 32018109992, success in 6m 2s. SHA256
`cc1d4083de56beba1111d0759a2838617232a411bbef85db0601b418bae6c69b`, 22.6 MB.
Verified by reading the package's own `AppxManifest.xml`: Identity
`AnalyticsbyShanikwa.AnalyticsbyShanikwa`, Publisher
`CN=82609663-1176-497C-A1B0-947A85A73EEF`, Version `1.0.3.0`. The bundled
`content.json` inside the package carries 0 old URLs and 120 new ones.

**Versions bumped in `pubspec.yaml`:** `version: 1.0.2+3 → 1.0.3+4` and
`msix_version: 1.0.2.0 → 1.0.3.0`. The Store requires msix_version to increase
and the last digit to stay 0.

**The submission — three things that have each failed us before:**

1. **Tick the declaration** (Properties → Product declarations):
   *"This app allows users to make purchases, but does not use the Microsoft
   Store commerce system."* This is what A6 failed on. It lives on the
   submission, not the product, so it is blank again every time.
2. **Device family = Desktop only.**
3. **`runFullTrust` justification** — the box truncates silently at 500
   characters. Paste the 468-character version from `store/LISTING.md`.

**Notes for certification:**

> New package 1.0.3.0, replacing 1.0.2.0.
>
> What changed: the online store moved to a custom domain, so the catalogue's
> outbound links now point to shop.analyticsbyshanikwa.com instead of the
> previous myshopify.com address. Links and content only — no new features, no
> new capabilities, no permission changes, and no change to how the app behaves.
>
> Purchases: unchanged from the accepted 1.0.2.0 submission. The Shop screen
> links out to Payhip and Shopify in the user's default browser. The app does
> not process payments and does not use the Microsoft Store commerce system. The
> corresponding product declaration is ticked.
>
> Device family: Desktop only. runFullTrust is required because this is a native
> Win32 (Flutter) app packaged as MSIX; the capability is added automatically by
> the packaging tool. No elevation, no drivers or services, no system changes.
>
> Testing: no account or sign-in is required. Shop links open in the default
> browser.

**Note vs. declaration — they are different fields.** Notes tell the reviewer
what changed so they don't re-test from scratch; they do **not** satisfy policy
10.8.2. Only the declaration tickbox does. Good notes with the declaration
unticked will fail again.

---

# B · Google Play — $25 once

### B1. Register and verify (30 min, then hours to 2 business days)

1. **play.google.com/console** → sign in.
   **Choose this Google account carefully** — moving a Play listing between
   accounts later is painful. Use one you will keep.
2. Account type: **Personal**. No D-U-N-S number needed — that's organisations
   only.
3. Pay the **$25**. One-time, forever, all your apps, **non-refundable**.
4. **Identity verification:** government ID, and possibly a selfie. Typically a
   few hours, up to two business days.
5. Complete the developer profile.

> **Privacy point worth pausing on:** Play publishes a developer contact email on
> your listing, and depending on account type may publish more. If you run this
> from home, check exactly what becomes public before entering a home address.
> A PO box or business address is worth setting up first if so.

### B2. Create the app (20 minutes)

6. **Create app** → name `Analytics by Shanikwa`, English (US), **App** (not
   Game), **Free**.

> "Free" is permanent — a free app can never be switched to paid. That's correct
> here: the app is free and links out to your storefront.

7. Work through **Dashboard → Set up your app**, using `store/LISTING.md`:
   - Privacy policy: `https://analyticsbyshanikwa.com/privacy-policy.html`
   - App access: **no login required** (true — there are no accounts)
   - Ads: **No**
   - Content rating questionnaire → expect **Everyone**
   - Target audience: 13+ is the simple answer. Selecting under-13 pulls you
     into Families policy and extra review — don't unless you mean it.
   - **Data safety: no data collected.** Reasoning is in `store/LISTING.md`.
   - Government app: No. Financial features: No.
8. Store listing: short + full description, the four `phone-*.png` screenshots,
   `play-feature-graphic-1024x500.png`, `play-icon-512.png`.

### B3. Upload to CLOSED testing (15 minutes)

9. **Testing → Closed testing → Create track.**
10. Upload `build/app/outputs/bundle/release/app-release.aab`.
11. **Accept Play App Signing** when prompted on the first upload. Google then
    holds the distribution key and yours becomes an *upload* key — resettable
    through support if it is ever lost. Do this.
12. Verify the signer Google reports matches:
    `BA:43:6E:2F:7E:EE:F6:DE:9B:B4:E0:78:26:D3:90:40:DF:2A:99:FB:C3:D4:6E:A3:6C:67:1E:D6:55:DA:2F:D2`

> Do **not** upload straight to Production. A new personal account cannot get
> production access without completing closed testing first.

**Before you submit, read the ⚠ section at the end of `store/LISTING.md`** about
Google's billing policy for the link-out shop. It is not the same rulebook as
Apple's and it has not been verified for you.

---

# C · The 12 testers — start today, it gates everything

### The actual rule

- **12 testers minimum**, opted in and staying opted in for **14 continuous days**.
- The clock starts only once the release is approved **and** 12 have opted in.
- **All 12 must overlap.** One drops out on day 7 → **the counter resets to zero.**
- Since **April 2026**, Google also rejects for weak *engagement*. Installing is
  not enough — testers must actually open and use the app.
- Real devices, real Google accounts. Emulators and duplicate accounts don't count.

### C1. Recruit 16, not 12

Two spare testers is the difference between 14 days and 28. Dropout is the
single most common reason people redo this.

Where yours realistically come from:
- Family and friends with Android phones — the reliable core
- Your church community — the natural fit for this app
- TikTok and Pinterest followers — ask directly; "help me launch" converts well
- The Sunday Letter list

> Your Omnisend audience is very small right now, so don't plan around it.
> Personal asks will do the work here.

### C2. Set it up so it's manageable

1. Create a **Google Group** (e.g. `abs-app-testers@googlegroups.com`) and add
   testers to that, rather than pasting 16 addresses into Play. Then adding or
   replacing someone doesn't mean editing the track.
2. In Play: **Closed testing → Testers → add the group**.
3. Copy the **opt-in link** Play generates. That link is the whole job for them.

### C3. What to actually ask them

Send this — short and specific beats enthusiastic and vague:

> I'm launching an app and Google needs 12 testers for 14 days straight.
> Three things:
> 1. Tap this link on your Android phone and press **Become a tester**: [link]
> 2. Install it from the Play link that appears.
> 3. Open it for two minutes every day or two — play a game, read a story.
>    Google checks that testers actually *use* it, not just install it.
>
> Please don't leave the test before [date]. If you drop out, my 14 days start
> over. Thank you — genuinely.

### C4. Track it

- Play Console shows **opt-in count** but not engagement, so check in around day
  3 and day 10 and ask people directly.
- Put the end date in your calendar the day the twelfth person opts in.
- On day 15: **Production → apply for production access.** Google asks how you
  ran the test and what you learned — answer concretely, not with boilerplate.

---

# Realistic timeline

| | Effort | Then waiting |
|---|---|---|
| Microsoft register → live | ~1 hour | days |
| Play register → verified | ~30 min | hours – 2 days |
| Play closed test | ~30 min | **14+ days**, plus recruiting |
| Play production review | — | days |

**Fastest path to a live store listing: Microsoft.** Fastest path to Android:
start recruiting testers *today*, in parallel with everything else.
