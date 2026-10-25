# Vitalog — first-run tester runbook

Use this checklist to test the app as a new tester, starting with an empty
installation. Record each case as **Pass**, **Fail**, **Blocked**, or **Not
run**. The report files in `test-data/reports/` contain synthetic data only.

## Safety and test account setup

- Use a dedicated test installation/device. Uninstalling the app clears local
  profiles, reports, encryption keys, and settings on that device. Do not do
  this on a device containing records you need to keep.
- Test local features first without cloud keys. The app should work without
  signing in or connecting to Supabase.
- Sync v1 sends readable test names, values, units, ranges, and dates. For any
  cloud test, use only the synthetic reports in `test-data/reports/`; never
  Sync a real medical report.
- Gmail is not required. Email/password sign-up can use any address whose inbox
  you can access to receive Supabase's confirmation link. A temporary inbox
  may work, but avoid shared/public inboxes and addresses that expire before
  you finish testing. Some disposable-email providers may reject or filter
  confirmation mail; mark that case **Blocked** and use another tester-owned
  non-Gmail inbox. Keep passwords out of screenshots, notes, and chat.
- Google sign-in has extra provider setup and is not a prerequisite for this
  run. Test email/password first.

## Start the app

1. Install a fresh build, or uninstall the previous test build and reinstall
   it to start with empty app storage.
2. For local-only testing, run without Supabase defines:

   ```bash
   flutter devices
   flutter run -d <device-id>
   ```

3. For the development Supabase account/Sync cases only, run with the
   git-ignored local config:

   ```bash
   flutter run -d 00008120-000E48CE0CBBA01E --dart-define-from-file=supabase.local.json
   ```

4. Put the synthetic sample files on the device. For an iOS simulator, drag a
   file onto the Simulator window; on Android, drag it onto the emulator; on a
   phone, transfer it to Files/Downloads.

## A. First launch and onboarding

| ID | Steps | Expected |
|---|---|---|
| A01 | Fresh install, open Vitalog. | Splash completes, then onboarding appears. No sample family names, reports, or results are preloaded. |
| A02 | Swipe through all welcome pages. | The illustration and page indicator follow each page. |
| A03 | At the sign-in offer, choose **Continue without an account**. | App reaches an empty start screen with **Add family member**. No sign-in is required for local use. |
| A04 | Force-close and reopen the app. | Splash goes to the app; onboarding does not appear again. |
| A05 | Open Settings/Accessibility and turn Reduce Motion on, then restart. | App remains usable; onboarding and other motion respect Reduce Motion. |

## B. First profile and family navigation

| ID | Steps | Expected |
|---|---|---|
| B01 | On the empty start screen tap **Add family member**. Enter a made-up tester name, relation **You**, age, and sex; save. | The profile is created, selected, and the app navigation appears. No sample profiles appear. |
| B02 | Force-close and reopen. | The tester profile remains; onboarding stays complete. |
| B03 | Family tab → add a second made-up profile. | It appears in the family list and becomes selected. |
| B04 | Switch profiles from the Home action area and from the Family list. | The selected person is visibly indicated; Home, Categories, and Reports follow that selection. Switching from Family returns to Home. |
| B05 | Add a profile with sex unset. | The profile saves without guessing sex; results that require it remain **Needs review**. |

## C. Home, Categories, and report extraction

Upload one file at a time from `test-data/reports/` and compare with these
expected results:

| ID | File / steps | Expected |
|---|---|---|
| C01 | `01-all-normal.txt` | One Ready report; 5 results, all Within range; lab Greenleaf Diagnostics; report date 21 Oct 2026, collection date 20 Oct. |
| C02 | `02-needs-attention.csv` | Ready report with 6 results; total cholesterol, LDL, triglycerides, and HbA1c High; HDL and Vitamin D Low. Home clearly lists attention items; no celebratory confetti. |
| C03 | `03-no-printed-ranges.txt` | No printed range is invented. TSH 9.9 and fasting glucose 92 use a labeled usual range when available. Hemoglobin for sex-unset profile remains Needs review. |
| C04 | `04-unknown-test.txt` | Report needs review; Zonulin Serum is under Other / needs a category. Assign a category through Edit, then confirm the report status updates. |
| C05 | `05-contact-details.txt` | Lab is shown as Riverside Diagnostics; address, phone, and email are removed from the displayed lab metadata. Creatinine and Urea are Within range. |
| C06 | `06-no-date.txt` | Report is Needs review. Missing report date is not silently replaced with upload date. |
| C07 | `07-unsupported.zip` | Clear unsupported-file message, no crash, and no misleading OCR result. |
| C08 | Upload `01-all-normal.txt` twice for the same profile, then once for another profile. | Same-profile duplicate is detected and links to the existing report; another profile may keep its own copy. |
| C09 | Open a report from the timeline. | The report dashboard shows only that report's results and dates. |
| C10 | Open a result → Edit a synthetic value → Save. | Edit persists and status is recalculated from the displayed reference range. |
| C11 | Open a test with multiple reports. | History is chronological by report date; units remain visible; the chart uses comparable values and dates. |
| C12 | Open Categories. | Tested categories appear before yet-to-test categories. Categories with no result do not show fabricated measurements. |
| C13 | Upload a synthetic PDF/photo; if available, also a DOCX/XLSX or multi-page file. | Supported documents show Reading then a result/Needs review state; dates and results stay tied to the right report. Test scanner camera on a physical device. |

## D. Reports and local data actions

| ID | Steps | Expected |
|---|---|---|
| D01 | Upload a report, change tabs while it says Reading. | Reading completes; the report remains in the timeline and a notice offers View. |
| D02 | Upload two synthetic files quickly. | Both reports finish and neither loses results. |
| D03 | Open Compare with original on a device with passcode/biometrics. | Authentication is requested when required; canceling does not reveal the original or break the app. |
| D04 | Long-press or open the report menu → Delete → Cancel. Then repeat and confirm Delete. | Cancel keeps the report. Confirming removes that report and its results from this device. |
| D05 | Turn on airplane mode; add a profile and upload a synthetic report. | Local profile creation and on-device reading still work. Only cloud actions need network. |

## E. Display and navigation

| ID | Steps | Expected |
|---|---|---|
| E01 | Visit Home, Categories, Reports, and Family using the bottom navigation. | Each tab opens and the selected tab is clear. |
| E02 | Family → enable Simple mode. | Text/buttons become easier to read; trends/category grid are simplified as designed. |
| E03 | Customize Home and hide/show sections; restart. | Choices persist; hidden sections stay hidden. A report-specific dashboard still shows its report. |
| E04 | Change System/Light/Dark theme and accent; restart. | Selection persists, text remains readable, and High/Low meaning is not color-only. |
| E05 | Set phone text size to large, then use Home, Reports, and test detail. | Text and controls remain readable without clipping or overlap. |

## F. Email account and Supabase (synthetic data only)

Run this section only with `supabase.local.json` configured for the dev project.

| ID | Steps | Expected |
|---|---|---|
| F01 | Family → Sign in → Create account with a tester-controlled email and password of at least 8 characters. | App reports that confirmation is needed; the account can use any accessible email provider, not only Gmail. |
| F02 | Open the confirmation message on the same device and follow its link. | App returns through the configured `com.vitalog.app://login-callback` deep link and shows the signed-in account. If a temporary provider blocks or loses the message, mark Blocked. |
| F03 | Sign out; sign in again. Try a wrong password, then the correct one. | Wrong password shows a clear error; correct password signs in. Local profiles/reports remain local. |
| F04 | Add/upload `05-contact-details.txt`, then tap Sync in Reports. | Sync occurs only after the explicit tap; success notice appears and the unsynced count reaches zero. |
| F05 | Supabase Dashboard → Authentication → Users; then Table Editor → `reports` and `lab_results`. | Test account exists; rows belong to that account; only synthetic values are present; report filename is generic (`report.txt`), and no profile name/contact details are present. Values are readable in Sync v1—do not use real data. |
| F06 | Tap Sync again without changes. | No duplicate report/result rows are created. |
| F07 | Attempt Sync while signed out; then retry with network disabled. | Sign-in is requested when signed out; network failure is reported and local data remains usable. |
| F08 | Create a second controlled test account and check whether it can access Account A's rows through the app. | Account B cannot read or change Account A's rows (RLS isolation). Use only synthetic data. |
| F09 | Try Google sign-in only if provider/client IDs have been configured. | Otherwise record Blocked by provider setup; do not count it as an app failure. Android requires its Android OAuth/SHA-1 setup. |

## G. Test record and bug report

For every case, record:

```text
Case ID:
Result: Pass / Fail / Blocked / Not run
Device and OS:
App build/commit:
Steps and observed result:
Screenshot (crop out email addresses and other personal details):
```

Never attach a real medical report, a password, or a secret key. If a report
parses incorrectly, report the synthetic sample filename or describe the
layout; do not send patient documents. For deeper parser cases and platform
specifics, see `docs/TEST_PLAN.md`.

## Current feature boundaries

- Runtime demo profiles/results are disabled; sample report files remain test
  fixtures only.
- Profiles, originals, and results are stored locally on the device by
  default. Sync is push-only and still uses readable Sync v1 rows.
- End-to-end encrypted Sync v2, family invites, cloud restore, server-side
  delete/tombstones, and in-app account deletion are not ready for real-user
  testing.
