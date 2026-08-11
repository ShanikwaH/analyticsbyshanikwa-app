# Store listing copy — ready to paste

Written 2026-08-10 from the app as it actually runs, not from the README.
Character counts are in brackets and are within each store's limit.

Everything leads with what the app *does* — games, stories, the daily audit,
offline use. The shop is mentioned late and briefly, on purpose: both Apple and
Google are quicker to reject something that reads as a storefront wrapper.

---

# GOOGLE PLAY

### App name  [21 / 30]
```
Analytics by Shanikwa
```

### Short description  [74 / 80]
```
Bible stories, 20+ games, and templates that actually work. Free, offline.
```

### Full description  [1,969 / 4,000]
```
Analytics by Shanikwa is a quiet daily habit: one Bible story, one small
challenge, and a set of tools built by someone who does this work for a living.

No account. No sign-up. Nothing to cancel. Open it and it works — on a plane,
on the subway, anywhere.

PLAY — 20+ REAL GAMES
Not quizzes wearing a hat. Actual games:
• Word Search — six hidden names in a 9x9 grid, drag to select
• Memory Flip, Number Slide, Letter Hunt, Tic-Tac-Toe
• Follow the Pattern and Coin Catch, with four speed settings and a
  "Find my speed" calibration so the pace fits you, not the other way round
• The Gauntlet — ten right in a row, one miss ends it
• Lightning Round — 60 seconds, every deck mixed together
• Story Match, Order the Story, Who Am I?, Number Crunch, and more

Every play earns Talents. Talents raise your Steward rank. Ten badges are worth
exactly 250 — a complete path to the reward, so it is reachable, not a tease.

STORIES — 30 BIBLE STORIES
Three series, read-tracking, and a plain telling from the text. King James
Version throughout, so nothing is paraphrased for you.

TODAY — THE STEWARDSHIP AUDIT
Four questions. Five minutes. A streak that is honest about whether you showed
up. Built on Proverbs 27:23 — "Be thou diligent to know the state of thy flocks."

DRILLS THAT MATCH YOUR WORK
Accounting and CPA candidates get Ledger Lines — debit/credit calls with the
reasoning shown. Data folks get Data Signals — statistics and SQL. Everyone gets
Scripture Memory. Same engine, different daily loop.

YOUR PROGRESS STAYS ON YOUR PHONE
Talents, streaks, and your audit journal are stored on your device and nowhere
else. There is no account, no server, and no profile. We collect nothing —
which also means there is nothing to leak.

TEMPLATES
A library of spreadsheets and guides for accounting, analytics, career changes,
and Bible study. Browse them in the app; checkout happens on the web.

Free to download. Free to use. Built from real work, not theory.
```

### Category
**Education**, not Games — the core is stories, drills, and the daily audit, and
the arcade exists to support the habit.

> Judgement call, not a rule. With 20+ arcade games, Google may reclassify to
> *Games → Educational*. Either is defensible; Education reaches the audience you
> actually want. If Google moves it, do not fight it.

### Tags / search terms
`bible study` · `christian games` · `scripture memory` · `accounting` ·
`CPA exam` · `data analytics` · `offline`

---

# MICROSOFT STORE

### Name  [21]
```
Analytics by Shanikwa
```

### Short description  [174 / 500]
```
Bible stories, 20+ real games, and a daily five-minute audit — plus a library of
accounting, analytics and Bible-study templates. No account, works offline,
collects nothing.
```

### Description
Use the Google Play full description above verbatim; it is inside the Microsoft
Store's 10,000-character limit.

### Features (bullets shown on the listing)
```
20+ games: word search, memory, sliding puzzle, pattern, reflex, and more
30 Bible stories across three series, King James text
Daily Stewardship Audit with streaks — four questions, five minutes
Accounting/CPA and data-analytics drill decks
Talents progress system, Steward ranks and 10 badges
Works fully offline — no account, no sign-up, nothing collected
```

### Search terms (max 7)
```
bible, christian, scripture, accounting, CPA, analytics, offline
```

### Category
**Education** → sub-category **Reference**

### Properties → privacy question
**Answer "Yes, my product uses personal information."**

Counter-intuitive, but correct. The question is capability-driven: the package
declares `internetClient`, so Partner Center hard-requires a privacy policy URL,
and answering "No" contradicts that and leaves the page permanently incomplete.
It is also defensible on the merits — any outbound request carries an IP
address, which is personal data under GDPR. The app makes exactly one, to fetch
`content.json`, and section 10 of the privacy policy says so.

This is **not** inconsistent with the Play data-safety answer below ("no data
collected"). Play asks which specific data *types* are collected; the app
collects none. Microsoft asks whether anything identifying could be transmitted.

URL: `https://analyticsbyshanikwa.com/privacy-policy.html`
(Section 10 covers the app — added 2026-08-11.)

### Other Properties answers
- Support address fields: **leave blank** — they publish on the listing.
- System requirements: **all "Not specified"**. Marking Keyboard or Mouse as
  minimum puts a hardware warning in front of touch users and blocks them from
  reviewing.
- Product declarations and Mixed Reality: leave unchecked.

### Device family availability
Tick **Windows 10/11 Desktop only.** The package is x64 desktop; leaving Mobile,
Xbox, Team or Mixed Reality ticked is a hard submission error.

### Restricted capability justification  (paste into the runFullTrust box)
Partner Center requires a written justification before it will approve
`runFullTrust`. Separate required field from Notes for certification, and it is
**length-limited** — the long version was rejected as too long on 2026-08-11.
**The field caps at exactly 500 characters and truncates silently** — a 532-char
version was cut mid-sentence on 2026-08-11. Use this 468-char one:
```
Flutter desktop app: a native Win32 executable packaged as MSIX. runFullTrust is required because it runs full-trust rather than as a UWP app, and is added automatically by the MSIX packaging tool. It is used only for native Direct3D rendering, storing user progress in the app's own data folder, and opening the user's default browser or file handler. The app never elevates, installs no drivers or services, changes no system settings, and collects no personal data.
```

**288 characters:**
```
Flutter desktop app: a native Win32 executable packaged as MSIX, so it runs full-trust rather than as a UWP app. The capability is added automatically by the MSIX packaging tool. No elevation, no drivers or services, no system changes, and nothing written outside its own app-data folder.
```

**189 characters:**
```
Native Win32 (Flutter) app packaged as MSIX; runFullTrust is required for full-trust execution and is added automatically by the packaging tool. No elevation, no drivers, no system changes.
```

### Publishing hold options
**"Publish as soon as it passes certification."** Nothing is tied to a launch
date, and a manual hold is a step that is easy to forget.

### Microsoft certification notes  (paste into Notes for certification)
```
No account or login is required. All functionality is available immediately on
first launch, and the app works fully offline.

Where to find the main features:
- Play tab: 20+ games including Word Search, Memory Flip, Number Slide,
  Tic-Tac-Toe, and daily challenges.
- Stories tab: 30 Bible stories, King James text.
- Today tab: the daily Stewardship Audit and progress tracking.
- Shop tab: a catalogue of spreadsheet templates. Selecting one opens the user's
  browser at Payhip or Shopify; purchases are not made inside the app.

All user progress is stored locally on the device. The app makes one network
request, to analyticsbyshanikwa.com, to fetch its content file.
```

---

# APP STORE (for Phase 3)

### Name  [21 / 30]
```
Analytics by Shanikwa
```

### Subtitle  [27 / 30]
```
Bible stories, games, tools
```

### Promotional text  [118 / 170]
```
One story, one challenge, five honest minutes a day. 20+ games, 30 Bible
stories, and drills that fit the work you do.
```

### Keywords  [95 / 100]
```
bible,scripture,christian,devotional,memory,accounting,cpa,analytics,puzzle,offline,study,faith
```

### Description
Use the Google Play full description.

### App Review notes
See `SELLING.md` §6d. Two rejections to pre-empt: **3.1.1** (external purchase
links — the app region-gates them and hides the Shop where they are not allowed)
and **4.2** (minimum functionality — lead the reviewer to the games, the audit,
and offline reading).

---

# PLAY DATA SAFETY — answers

| Question | Answer |
|---|---|
| Does your app collect or share any required user data types? | **No** |
| Is all user data encrypted in transit? | N/A — no user data is transmitted |
| Do you provide a way to request data deletion? | N/A — uninstalling removes everything |
| Does your app contain ads? | **No** |
| In-app purchases? | **No** *(true today — `iap_enabled: false`. If you ever turn it on, this answer must change before that release.)* |

**Why "no" is honest here:** progress lives in on-device storage only. The app
fetches `content.json` over HTTPS, which is app content, not user data. Tapping a
product opens the browser, and anything that happens there is governed by
Payhip's or Shopify's own policy, not this app's.

Privacy policy URL: `https://analyticsbyshanikwa.com/privacy-policy.html`

---

# CONTENT RATING — expected answers

Violence **no** · Sexuality **no** · Profanity **no** · Controlled substances
**no** · User-generated content **no** · Location sharing **no** ·
Digital purchases **yes** (the app links out to buy templates).

Expected result: **Everyone / PEGI 3**.

Bible stories include historical accounts of conflict. The app narrates them
plainly from the text with no imagery. Answer literally — the questionnaire asks
about depictions, and there are none.

---

# ⚠ VERIFY BEFORE YOU SUBMIT TO PLAY

**Google Play's billing rules are not the same as Apple's, and I have not
verified the current position for you.**

Play policy generally requires Google Play Billing for digital content used
*inside* an app. This app links out to Payhip/Shopify for spreadsheets and
guides that are used *outside* it — which is the exemption most sellers rely on —
and the 2025 Epic v. Google injunction separately loosened external links in the
US. Both of those are live, moving areas.

The app's `commerce.link_out_regions` gate was designed against **Apple's**
Guideline 3.1.1. It is currently `["US", "JP"]`.

Read Play's current Payments policy the day you submit. If Google's answer
differs from Apple's, you change `content.json` and bump the version — no app
release needed.
