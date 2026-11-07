# Feature ideas — 2026-11-06

Suggested enhancements, in priority order. None of them is built yet
(checked against the code on 2026-11-06). Every idea keeps the hard rules in
AGENTS.md:

- **Offline-first / privacy:** everything runs on the phone; nothing about a
  report leaves it except through the explicit Sync.
- **No manual data entry:** nothing here asks the user to type health data.
- **No health score / no judging:** we summarise what the lab printed; any
  medical wording comes from a reviewed source (like docs/REFERENCE_RANGES.md).
- Strings in `app_en.arb`, colours from `context.colors`, dates via
  `formatDate()`, shapes from `AppRadius`/`AppShape`, motion ≤ 250 ms and
  respecting Reduce Motion.

Effort: **S** ≈ a day · **M** ≈ 2–4 days · **L** ≈ a week or more
(including tests and a phone check). 👤 = needs the product owner.

| # | Idea | Value | Effort | Needs |
|---|---|---|---|---|
| 1 | Open in Vitalog (share sheet) | Very high | M | — |
| 2 | Doctor summary PDF | Very high | M | 👤 layout sign-off |
| 3 | Same test across units | High | S–M | 👤 clinical check of factors |
| 4 | Retest reminder suggestion | Medium | S | 👤 clinical intervals |
| 5 | "What is this test?" | Medium | M | 👤 written + reviewed text |
| 6 | Factual trend notes ✅ built 2026-11-06 | Medium | S | — |
| 7 | Home screen widget | Low–medium | M | 👤 lock-screen privacy call |
| 8 | Apple Health / Google Fit import | Medium | L | docs/HEALTH_APPS_SYNC_PLAN.md |

---

## 1. Open in Vitalog (receive a shared file)

**Problem.** Most Indian labs (Thyrocare, SRL, Dr Lal PathLabs, Apollo,
Metropolis) send the report as a PDF on WhatsApp or by email. Today the user
must save it to Files, open Vitalog, tap Add report → Choose a file, and find
it again: about six steps, and older users get lost in the Files app.

**What it does.** Vitalog appears in the system share sheet for PDFs and
images. From WhatsApp: long-press the PDF → Share → Vitalog. The app opens on
a small "Who is this report for?" sheet (the member list, with the person
whose printed name matches pre-selected), then the report goes through the
normal upload flow (stored encrypted → read on the phone → timeline).

**Flow.**
1. Share → Vitalog.
2. App opens (or comes to the front) on the "Who is this for?" sheet.
   - One member only → skip the sheet.
   - First launch / onboarding not finished → hold the file until onboarding
     ends, then show the sheet.
   - Originals lock not yet decided → the existing `_askOriginalsLock`
     explanation comes first, exactly as with Add report.
3. `UploadReport(path, name)` for the chosen member; the existing
   duplicate check (`fileHash`) and "Wrong person?" check still apply.
4. Several files shared at once → one report each.

**Where it goes.**
- Android: `ACTION_SEND` / `ACTION_SEND_MULTIPLE` intent filters for
  `application/pdf` and `image/*` in `AndroidManifest.xml`; `MainActivity.kt`
  copies the content URI into the app's cache and passes the path over the
  existing `vitalog/report_ocr` channel (or a small new one).
- iOS: a Share Extension target (or "Open in…" via `CFBundleDocumentTypes` +
  `LSSupportsOpeningDocumentsInPlace = NO` as the lighter first step), handing
  the file to the app through an App Group container.
- Dart: a listener next to `InviteLinkListener` in `main.dart` that turns an
  incoming file into the "Who is this for?" sheet, then `UploadReport`.

**Privacy.** The incoming copy is plaintext: delete it right after
`keepOriginal` encrypts it (same rule as `_discardTempCopy` for scans), and
sweep leftovers on start (see PENDING_TASKS #27).

**Tests.** Widget test: an incoming file path → sheet → report on the
timeline. Phone check: WhatsApp PDF, Gmail attachment, photo from Gallery,
two files at once, app closed vs. in the background.

**Open questions.** iOS Share Extension needs its own target and App Group
(works with a free team? check before committing to it; "Open in…" does).

---

## 2. Doctor summary (shareable PDF)

**Problem.** At an appointment, families scroll through photos of old reports
on the phone. Doctors want one page: the latest values, what's out of range,
and how those moved.

**What it does.** On a member's Home (and the report dashboard), a
"Doctor summary" action builds a one-page PDF on the phone and opens the
share sheet (print, WhatsApp to the doctor, save to Files).

**Content (one A4 page, two at most).**
- Header: member's name, age, sex; "Prepared with Vitalog on <date>"; the
  date range of reports included.
- **Needs attention:** every test whose latest result is high/low, with the
  value, unit, the lab's printed range, the lab and date, and the previous
  2–3 values of the same test (same unit, or converted per idea 3).
- **Latest results by group:** the predefined categories, one line per test:
  latest value, unit, range, status word (never colour alone).
- Footer: "Values and ranges as printed by the lab. Usual ranges marked *
  where the lab printed none." No interpretation, no score.

**Options before sharing.** Which member (defaults to the one being viewed);
"Last 12 months / All"; include usual-range results or not.

**Where it goes.**
- Data: `FamilyHealthSnapshot` already has what's needed
  (`latestPerTest`, `resultsByCategory`, test history).
- Rendering: the `pdf` package (pure Dart, no network) is a new dependency;
  alternatively draw with Flutter and print via the platform. Share with the
  existing `share_plus`.
- Strings in `app_en.arb`; the PDF uses the app's language and `formatDate()`.

**Privacy.** The PDF is health data in plaintext. Build it in memory and
hand bytes to the share sheet; if a file is needed, write it to the temp dir
and delete it after sharing. Never sync it. Simple-mode users get a large,
obvious button.

**Tests.** Unit test on the summary data (what goes under "Needs attention",
ordering, previous values). Golden/widget test for the layout. Phone check:
open the PDF in WhatsApp and print preview.

**Open questions (👤).** Layout sign-off; whether to include the member's
photo (default no); whether a clinician should review the footer wording.

---

## 3. Same test across units

**Problem.** Labs report the same test in different units: glucose mg/dL vs
mmol/L, cholesterol mg/dL vs mmol/L, creatinine mg/dL vs µmol/L, vitamin D
ng/mL vs nmol/L. The test page charts only same-unit readings, so changing
labs breaks the trend.

**What it does.** A small fixed table of exact conversion factors for
well-known tests. The test history and trend tiles convert readings into the
unit of the latest report, mark converted points ("converted from mmol/L"),
and still list the original printed values.

**Rules.**
- Only tests and unit pairs in the table; anything else stays separate, as
  today. Never guess a unit (matches the reference-range rule).
- Status (high/low) is never recalculated from a converted value: it stays
  what the lab printed or what the usual range said for the original.
- The stored result is never changed; conversion is display-only.

**Where it goes.** A `const` table next to `lab_test_catalog.dart`
(test → {unit pair → factor}), used by `trendsFor` / the test history chart
in `health_subscreens.dart` and the summary PDF.

**Starter table (to be checked 👤).** Glucose 1 mmol/L = 18.016 mg/dL;
total/HDL/LDL cholesterol 1 mmol/L = 38.67 mg/dL; triglycerides
1 mmol/L = 88.57 mg/dL; creatinine 1 mg/dL = 88.42 µmol/L; urea
1 mmol/L = 6.006 mg/dL (urea, not BUN); vitamin D 1 ng/mL = 2.496 nmol/L;
haemoglobin 1 g/dL = 10 g/L.

**Tests.** Pure unit tests on the table and the chart data (mixed units →
one series; unknown unit → separate; status unchanged).

---

## 4. Retest reminder suggestion

**Problem.** People get an out-of-range HbA1c or TSH and forget to retest.
Reminders exist, but users have to think of creating one.

**What it does.** When a report finishes reading and some tests in a known
list are high/low, the "report ready" notice (or the report dashboard) offers:
"Remind me to retest HbA1c in 3 months?" One tap creates a normal reminder
(`RemindersCubit.add`) for that member, with a pre-filled title the user can
edit.

**Rules.**
- Only for tests with an interval from a reviewed source (👤): e.g. HbA1c,
  TSH, lipid profile, vitamin D, ferritin. No suggestion otherwise.
- Wording is an offer, never advice: "Remind me…", not "You should…".
- At most one suggestion per report (the earliest interval), and never when
  the member already has a reminder in that window.
- The lock-screen rule still holds: the reminder's title is the user's; the
  default title must not name the test or value (e.g. "Retest for Maya").

**Where it goes.** A `const` interval table next to the reference ranges;
the offer in the notice handling in `dash_board_screen.dart` /
`report_dashboard_screen.dart`.

**Tests.** Bloc/widget test: out-of-range HbA1c → offer → reminder created
with a safe title; normal results → no offer.

---

## 5. "What is this test?"

**Problem.** Older users don't know what "SGPT", "TSH" or "eGFR" mean, and
search engines send them to frightening pages.

**What it does.** On the test detail page, a short "About this test" card:
two or three plain sentences (what it measures, why doctors order it), plus
what the group means. No interpretation of the user's value.

**Rules.**
- Text written ahead of time, per catalog test, reviewed by the clinician
  who reviews the ranges (👤). Same discipline as docs/REFERENCE_RANGES.md:
  one source document, compiled as `const`.
- Translated like everything else (en/te/hi); missing translations fall back
  to English.
- No AI, no network.

**Where it goes.** `docs/TEST_EXPLAINERS.md` (source) →
`domain/reference/test_explainers.dart` (const) → a card in
`health_subscreens.dart` (test history page).

**Tests.** A test that every catalog test with an explainer has all
required fields, and the widget shows it.

---

## 6. Factual trend notes ✅ built 2026-11-06

Built as `trendStreak` / `streakNote` in `health_charts.dart` ("Up 3 times
in a row" on trend tiles and under the test history chart; tests in
`test/health_charts_test.dart`).

**Problem.** Trend tiles show the latest value and the change since the
previous one; a steady drift over several reports is easy to miss.

**What it does.** A one-line note on the trend tile and test page when the
same test moved in one direction for 3+ consecutive reports: "Went up in
each of the last 3 reports." Shown only when the readings are comparable
(same unit, or converted per idea 3).

**Rules.** States what happened, never what it means: no "worsening", no
colour judgment beyond the existing status colours. Hidden in Simple mode if
the tile is hidden there (trends already are).

**Where it goes.** A pure helper next to `trendsFor` in
`health_charts.dart` (unit-tested), plus the label in `app_en.arb`.

**Tests.** Unit tests: up/up/up → note; up/down/up → none; mixed units →
none; fewer than 3 → none.

---

## 7. Home screen widget

**Problem.** Reminders are easy to miss if the app isn't opened.

**What it does.** A small home-screen widget (iOS WidgetKit, Android
App Widget): "Next reminder: Maya · Tue" and "2 results need attention".
Tapping opens the app on Home.

**Rules (👤 privacy call).** A home screen is visible to anyone who
picks up the phone: show counts and first names at most, never test names,
values or the user's reminder title. Option to hide names. Data shared with
the widget through an App Group / SharedPreferences must contain only those
counts and names, never report data.

**Effort note.** Needs native code on both platforms (WidgetKit in Swift,
Glance/RemoteViews in Kotlin) and a way to refresh when reminders change.

---

## 8. Apple Health / Google Fit import

Already planned in docs/HEALTH_APPS_SYNC_PLAN.md (read that for scope). In
short: bring in lab-type records (and possibly weight/BP) from the platform
health store, on the phone, into the same timeline and charts.

---

## Considered and not recommended

| Idea | Why not (for now) |
|---|---|
| Medication / condition list | Needs typing: against the no-manual-entry rule. Could come later only if it can be read from prescriptions on the phone. |
| Emergency card (blood group, allergies) | Same: manual entry; also lock-screen exposure. |
| AI chat about results / AI summaries | Would send report content off the phone: needs the product owner's sign-off (AGENTS.md hard rule). An on-device model could be revisited. |
| A health score | Explicitly ruled out: we summarise what the lab printed. |

## Suggested order

1. **#1 + #2 together:** #1 makes adding reports easy, #2 makes the app
   useful at the doctor's.
2. **#3:** it makes #2 and the charts correct across labs.
3. #6, then #4 (small once #3 exists; #4 waits on the reviewed intervals).
4. #5 when the clinician review of texts can be scheduled.
5. #7, #8 later.
