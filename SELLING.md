# Selling this app — Web, Android, iOS

Written 2026-08-10. Prices and store rules move; the rule in §2 moved twice in
the last 18 months, so re-check it before you submit.

---

## 1. First: what are you actually selling?

Three different things, three different rule sets. Be clear which you mean,
because the platforms treat them completely differently.

| # | The thing | Where the money lands | Platform cut |
|---|---|---|---|
| **A** | **The app itself** — a one-time price to download | Apple / Google | 15–30% |
| **B** | **Something inside the app** — unlock, subscription, Talents | Apple / Google (IAP) | 15–30% |
| **C** | **Your existing digital products** — the Payhip / Shopify catalog | Payhip / Shopify / Stripe | 0% platform cut |

**Your app is built for C.** The Shop tab has no in-app purchase code at all —
every button calls `openLink()` and opens Payhip or Shopify in an in-app
browser. That is a deliberate design and it is the highest-margin one. It was
also, until recently, the thing Apple rejected apps for.

---

## 2. The rule that used to block this — and what changed

Historically, **App Store Guideline 3.1.1** ("anti-steering") banned exactly
what your app does: linking out to buy digital goods. Apps were rejected for it
routinely. Google Play had an equivalent rule.

Both changed, in the US, because of the Epic lawsuits:

- **Apple** — after the Epic v. Apple injunction, apps **on the US storefront
  may include external purchase links and buttons, with no entitlement and no
  Apple commission.** You may also show web pricing next to IAP pricing and tell
  users the web is cheaper.
- **Google** — a court-ordered injunction, in effect **through 1 November 2027**,
  lets US developers link out and use alternative billing. Policies launched
  9 December 2025. A revised settlement was still moving through court in 2026,
  so the fee structure may shift.

**The catch, and it is a big one: this is the US only.** The same external-link
button in an app distributed to the UK, Canada, Australia, Japan and most other
countries is still a 3.1.1 violation. §6 covers what to do about that.

**Before you submit, verify this yourself.** It changed in 2024, again in
May 2025, and the Google settlement was still in front of a judge in 2026. Read
the current Guideline 3.1.1 text and Play's US policy page on the day you
submit. Do not take this document's word for it.

---

## 3. Pick a model

| Model | You get | You give up | Good for you? |
|---|---|---|---|
| **1. Free app → web checkout** *(what you built)* | 100% of product revenue | US-only distribution, or region gating | **Yes — start here** |
| **2. Paid app** (one price to download) | Simple, zero rule risk, works worldwide | 15–30%, and a paywall before anyone sees value | Maybe later |
| **3. Free + IAP** (unlock or subscription) | Works worldwide, no 3.1.1 issue | 15–30%, plus real dev work to wire in | Only if you go worldwide |
| **4. Web only** (PWA + Payhip) | 0% platform fees, live today, $0 | No store listing, no discovery | **Already done** |

**Recommended sequence:** Web now (done, free) → Android ($25) → iOS ($99/yr),
US storefront first. Add IAP only if non-US demand justifies it.

**Apple Small Business Program:** if you earn under $1M/year you pay **15%,
not 30%** — you must apply, it is not automatic. Google has the same 15% rate on
the first $1M/year, applied automatically.

---

## 4. Web — sell today, 0% platform fees

You are already live at `app.analyticsbyshanikwa.com`, and the Shop tab already
links to Payhip and Shopify. There is nothing to approve and no one takes a cut.

To make it earn:

1. **Confirm every product link resolves.** `content.json → products[].payhip_url`
   and `shopify_url`. Test each on the live app.
2. **Add the app link everywhere** — site nav, TikTok bio, Pinterest, the Sunday
   letter, your Shopify store. A free interactive app is a strong lead magnet.
3. **Prompt the install.** On the live https URL, Chrome and Edge offer "Install"
   and it runs like a native app. Say so in the app: *"Install this — it works
   offline."*
4. **Track it.** Add a `?ref=app` parameter to the Payhip/Shopify URLs in
   `content.json` so you can see how much revenue the app actually drives. One
   content edit, no rebuild — bump `version` and upload to
   `analyticsbyshanikwa.com/app/content.json`.

**Why Payhip over raw Stripe:** Payhip acts as merchant of record and handles
EU/UK VAT for you. With bare Stripe, cross-border digital VAT is your problem.

---

## 5. Android — $25 once

### 5a. Money setup (do this first, it gates everything)
1. **Play Console** → pay the **$25 one-time** registration.
2. **Identity verification** — government ID. Allow several days.
3. **Payments profile** — only needed if you sell *through* Play (models 2/3).
   For model 1 (external checkout) you still complete the developer profile, but
   the money flows through Payhip, not Google.
4. **Tax info** — W-9 for a US person.

### 5b. Build and upload
Follow `SHIP.md` §3 for the SDK, keystore and `flutter build appbundle`.

### 5c. Declarations that matter for selling
- **App category:** Education (not Games — Games has stricter rating rules).
- **Data safety form:** your app stores everything on-device, no accounts, no
  analytics SDK. Declare *no data collected*. This is a genuine selling point.
- **Content rating** questionnaire — expect "Everyone".
- **Ads:** declare **no ads**.
- **External payments:** if you keep the outbound Shop links, enrol in the US
  external-offers program in Play Console and declare it.

### 5d. The 12-tester rule
New **personal** developer accounts must run a **closed test with 12 testers for
14 continuous days** before production access. Organisation accounts are exempt.
Recruit those 12 people before you need them — it is the single biggest delay.

---

## 6. iOS — $99/year, US storefront first

### 6a. Money setup
1. **Apple Developer Program** — $99/year. Individual enrolment needs ID; a
   business needs a D-U-N-S number. Allow a few days.
2. **App Store Connect → Business** → sign the **Paid Applications Agreement**.
   **Nothing can be sold until this is signed** — this trips up more first-time
   sellers than anything else. Required even for a free app with external links,
   because Apple treats the account as commerce-enabled.
3. **Banking** and **Tax forms** (W-9) in the same section.
4. **Small Business Program** — apply if under $1M/year, for 15% instead of 30%.

### 6b. Build
You cannot build iOS on Windows. Use **Codemagic's free tier** (500 build-min/
month) as in `SHIP.md` §4. You still need the $99 account for signing.

### 6c. Set availability to the United States only — at first
This is the decision that makes your current design legal.

App Store Connect → your app → **Pricing and Availability** → **Availability** →
deselect all, select **United States**.

Now your external Shop links are within Apple's US rules. Expand to other
countries only when you have handled §6e.

### 6d. Review notes — write these, they prevent rejections
In App Store Connect → **App Review Information → Notes**, say plainly:

> This app is distributed on the US storefront only. It contains links to
> purchase digital templates on the developer's own website, permitted under the
> updated US external purchase link rules. No digital content is unlocked inside
> the app by those purchases. All app features — the games, the Talents economy,
> the audit and the Bible stories — are free and fully functional offline with no
> purchase of any kind.

That last sentence pre-empts **Guideline 4.2 (Minimum Functionality)**, the other
likely rejection.

### 6e. Going worldwide later — two options
1. **Region-gate the Shop tab.** Hide external purchase links outside the US.
   Sketch:
   ```dart
   // Rough shape — verify against current rules before shipping.
   final region = WidgetsBinding.instance.platformDispatcher.locale.countryCode;
   final canLinkOut = region == 'US';
   ```
   Locale is *not* the same as the App Store storefront, so this is approximate;
   Apple may still object. Treat it as a starting point, not a guarantee.
2. **Add real IAP** with the `in_app_purchase` package, sell the templates as
   non-consumable products, accept 15–30%. Compliant everywhere, but it is real
   work: products defined in both consoles, restore-purchases, receipt handling.

---

## 7. What each route actually costs you

On a **$18.99** Scripture Memory System sale:

| Route | Platform fee | Payment fee | You keep |
|---|---|---|---|
| Web / app external link → Payhip | $0 | ~5% + Payhip plan | **~$17.60** |
| iOS IAP, Small Business (15%) | $2.85 | included | **$16.14** |
| iOS IAP, standard (30%) | $5.70 | included | **$13.29** |

The external-link route is worth roughly **$4.31 more per sale** than standard
IAP. On 100 sales that is $431 — which is why the US rule change matters and why
model 1 is the right starting point.

---

## 8. Honest timeline

| | Cost | Live in | Blocked by |
|---|---|---|---|
| Web | **$0** | Now — it is live | Nothing |
| Android | $25 | 3–5 weeks | ID check, 12-tester × 14-day close test |
| iOS | $99/yr | 2–4 weeks | Enrolment, Paid Apps Agreement, review |

**First year to be on all three: $124.** Then $99/year.

---

## 9. Before you spend anything

- [ ] Every product link in `content.json` resolves to a live listing
- [ ] `?ref=app` tracking added so you can measure what the app earns
- [ ] Privacy policy live at a public URL (`SHIP.md` §5)
- [ ] Real app icon — done
- [ ] Screenshots taken at required sizes
- [ ] **Guideline 3.1.1 re-read on the day you submit** — see §2
- [ ] 12 Android testers lined up

Do the web checklist first. It costs nothing, it is already live, and it tells
you whether anyone wants the app before you pay Apple $99 to find out.

## Sources for §2

- [Apple updates App Store Guidelines to allow links to external payments — 9to5Mac](https://9to5mac.com/2025/05/01/apple-app-store-guidelines-external-links/)
- [Apple Updates App Store Rules to Allow External Purchase Links in US — iClarified](https://www.iclarified.com/97192/apple-updates-app-store-rules-to-allow-external-purchase-links-in-us)
- [How to Add External Purchase Links to Your iOS App in 2026 — Stora](https://stora.sh/blog/2026-05-16-apple-app-store-external-purchase-links-implementation-guide)
- [An update regarding Google Play's policies for developers serving users in the US — Play Console Help](https://support.google.com/googleplay/android-developer/answer/15582165?hl=en)
- [Google Play Policy Update 2026: Out-of-App Payments & Epic Settlement — Coda](https://www.coda.co/blog/epic-v-google-policy-update-2026/)
