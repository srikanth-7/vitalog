# Vitalog — test plan

Two parts: **A. local testing** (simulator / emulator / your own phone, fake
data) and **B. staging with real user data** (what has to be true first, and
how to run it safely).

> ⚠️ **Today's Sync uploads readable test names, values, ranges and dates.**
> The product owner decided (2026-10-23) that Sync must be end-to-end
> encrypted before real data is synced (docs/SHARING.md). Until then, only
> ever sync the **fake reports in `test-data/reports/`**.

---

## A. Local testing

### A0. Set up once

| What | How |
|---|---|
| Supabase keys | `supabase.local.json` in the project root (git-ignored) holds the URL and publishable key. |
| iPhone simulator | `flutter run -d "iPhone 16 Plus" --dart-define-from-file=supabase.local.json` |
| Android emulator / phone | `flutter run -d <device> --dart-define-from-file=supabase.local.json` (list devices with `flutter devices`), or install the built APK: `adb install -r build/app/outputs/flutter-apk/app-debug.apk` |
| Offline build (no cloud) | Same commands without `--dart-define-from-file`. Sign-in/Sync then say cloud sync isn't set up. |
| Fake reports | `test-data/reports/` (below). Get them onto the device: **iOS simulator** drag the file onto the simulator window (it lands in Files); **Android emulator** drag onto the emulator (lands in Downloads); **real phone** AirDrop / email / Google Drive, then save to Files. |
| Reset the app | Delete the app from the device and reinstall (wipes reports, keys, settings). |

**Automated checks** (run before any manual round):

```bash
flutter analyze        # expect: No issues found
flutter test           # expect: All tests passed
```

### A1. Sample files and what each should do

All names in these files are fake ("Test Person One").

| File | Expected result in the app |
|---|---|
| `01-all-normal.txt` | Status **Ready**. 5 tests, all *Within range*. Confetti + "5 tests added". Lab "Greenleaf Diagnostics", reported 21 Oct 2026, collected 20 Oct. |
| `02-needs-attention.csv` | **Ready**, "6 tests added · 6 need attention", **no confetti**. Total cholesterol, LDL, triglycerides, HbA1c *High*; HDL, Vitamin D *Low*. They show in Home → "Needs attention". |
| `03-no-printed-ranges.txt` | No ranges printed. **TSH 9.9** → *High · usual range* (source shown on test detail). **Fasting glucose 92** → *Within range · usual range*. **Hemoglobin 11.0** → depends on the member's sex: with sex set → judged by usual range; sex not set → stays *Needs review* (never guessed). |
| `04-unknown-test.txt` | **Needs review**. "Zonulin Serum" lands in **Other tests** with "needs a category". TSH *Within range*. |
| `05-contact-details.txt` | Lab shows just **"Riverside Diagnostics"** (address, phone, email cut). Creatinine and Urea *Within range*. |
| `06-no-date.txt` | **Needs review** (no report date found). HDL and LDL *Within range*. |
| `07-unsupported.zip` | **Couldn't read** with a "this file type can't be read" line and **no Try again**. |

### A2. Test cases

Mark each ✅ / ❌. "Member" = the selected family profile.

#### First launch & splash
| # | Steps | Expected |
|---|---|---|
| 1 | Fresh install, open the app | Logo animates (lines slide, pulse draws, dot pops, heartbeat) then the welcome pages appear. |
| 2 | Swipe the 3 welcome pages | Pictures and text follow the finger; dots track the page. |
| 3 | On the sign-in offer tap **Continue without an account** | App opens on Home. Never shows the welcome pages again after a restart. |
| 4 | Restart the app | Splash → straight to Home. |
| 5 | Settings → Accessibility → Reduce Motion ON, restart | No splash animation / confetti; everything still works. |

#### Family members
| # | Steps | Expected |
|---|---|---|
| 6 | Family tab → add a member (name, relation, age, sex) | Member appears and becomes selected. |
| 7 | Switch members from the Home header | Home, Categories and Reports change to that member. |
| 8 | Add a member with sex not set, upload `03` to them | Hemoglobin stays *Needs review*. |

#### Uploading & reading
| # | Steps | Expected |
|---|---|---|
| 9 | Reports → Add → **Choose a file** → `01-all-normal.txt` | Card shows **Reading…** with a scan beam; you can switch tabs meanwhile. Snackbar "5 tests added" with **View**; confetti. |
| 10 | Tap **View** | Opens that report's own dashboard (only its 5 results). |
| 11 | Upload `02` | Snackbar "6 tests added · 6 need attention", no confetti. Home → At a glance + Needs attention list. |
| 12 | Upload `03`, `04`, `05`, `06`, `07` | As in table A1. |
| 13 | Take a **photo** of a printed report (or `01` printed on paper) | Same results as the file. iOS = Apple Vision, Android = ML Kit. |
| 14 | Upload a **PDF** report (export `01` to PDF from Notes / Docs) | Read the same as the text file. |
| 15 | Upload a **.docx** or **.xlsx** with a results table | Rows read; cells become columns. |
| 16 | Upload a large photo, immediately lock the phone for 10 s, unlock | Reading finishes (iOS keeps it running briefly in the background); notice appears. |
| 17 | Upload two files back-to-back quickly | Both finish; neither loses results. |
| 18 | Upload `07-unsupported.zip` | *Couldn't read*, no Try again, explanation line. |
| 18a | Upload `01-all-normal.txt` again for the same member | "You've already added this report." with **View**; no second report. Same file for another member is allowed. |
| 18b | Real phone: Add → **Scan with camera**, scan a 2-page report | Document camera finds the page edges; result is one report with both pages read. On the simulator it falls back to the plain camera. |

#### Results, editing, categories
| # | Steps | Expected |
|---|---|---|
| 19 | Open a result → **Edit** → change value 14.2 → 18 → Save | Status re-judged (*High*), marked edited. |
| 20 | Edit → **Compare with original** | Original document opens (Face ID / passcode asked once per session on a real phone). |
| 21 | In report `04`, open "Zonulin Serum" → Edit → pick category **Immunity** → Save | Moves out of Other; report becomes **Ready** once nothing needs review. |
| 22 | Upload `04-unknown-test.txt` again under another member | Zonulin is filed to Immunity automatically (learned choice). |
| 22a | Upload `03-no-printed-ranges.txt` for a member without sex set → open Hemoglobin → **Looks right** | Pill becomes "Checked · no range", "Marked as checked." notice, not marked edited; report turns **Ready** when nothing else awaits review. |
| 23 | Categories tab | **Tested** groups first (with "Not yet: …" missing key tests), then greyed **Yet to test**. Pancreas / Cancer / Hormones / Infections / Clotting show "When your doctor advises", never "missing". |
| 24 | Open a test with 2+ reports → history | Chart draws in; points match the reports. |

#### Display settings
| # | Steps | Expected |
|---|---|---|
| 25 | Display settings → **Simple mode** ON | Text ≥ 1.3× and bold, big "Add a report" button, categories grid and trends hidden. |
| 26 | Customise Home → hide sections | Hidden sections disappear; survive restart. A single report's dashboard still shows everything. |
| 27 | Theme → Light / Dark / System; pick each accent | Colours change instantly; status colours (high/low) never change; survives restart. |
| 28 | Phone text size at maximum + Simple mode | Nothing clipped or overlapping on Home, Reports, test detail. |
| 28a | Family → Display → Language → తెలుగు | App labels, categories, statuses, dates and settings switch to Telugu immediately and stay selected after restart. English and Device language options also switch correctly. iOS permission prompts follow the device language. |

#### Delete
| # | Steps | Expected |
|---|---|---|
| 29 | Report ⋯ → Delete | Action sheet explains what is removed; Cancel keeps it; Delete removes the report and its results. |

#### Account & Sync (fake data only)
| # | Steps | Expected |
|---|---|---|
| 30 | Sign in → **Create account** with your email + 8+ char password | "Check your email". Confirmation email arrives. |
| 31 | Tap the email link **on the same device** | App opens via `com.vitalog.app://login-callback`, signed in. |
| 32 | Sign out, sign in again with the password | Signed in. Wrong password → clear error. |
| 33 | Forgot password | Reset email arrives; link opens the app. |
| 34 | Upload `05-contact-details.txt`, tap **Sync** | Sync count goes to 0, success notice. |
| 35 | Supabase → Table Editor → **reports** | Row has `file_name` = `report.txt`, `lab` = `Riverside Diagnostics` (no address/phone/email), `profile_id` is an id, **no member name anywhere**. |
| 36 | **lab_results** | One row per test with name/value/unit/range/status. |
| 37 | Sync with Wi-Fi off | Clear error; nothing marked synced; works after Wi-Fi returns. |
| 38 | Sync while signed out | Asks you to sign in. |
| 39 | Create a 2nd account, sign in, look at Table Editor via the app | The 2nd account sees none of the 1st account's rows (row-level security). |
| 40 | Google sign-in (iOS) | Works once Supabase has the Google client ids (PENDING_TASKS #2). **Android: expected to fail** until an Android OAuth client exists. |

#### Privacy & security
| # | Steps | Expected |
|---|---|---|
| 41 | (Simulator) open the app's Documents folder: `xcrun simctl get_app_container booted com.app.vitalog.dev data` | `reports.json` and originals start with `FAMMO1` / `FAMMO2` and are unreadable. |
| 42 | Real iPhone with a passcode: open **Compare with original** | Face ID / passcode prompt. Cancel → original not shown, app keeps working. |
| 43 | Airplane mode, upload + read a report | Works fully offline (only Sync needs the network). |

#### Platforms
Run tests 1–29 on **both** an iPhone (or simulator) and an Android phone
(or emulator). Android extras: camera permission prompt on first photo;
PDF reading on Android 10 and on Android 11+.

### A3. Reporting a bug
Note: device + OS, steps, expected vs. actual, a screenshot, and **which
sample file** (never attach a real report).

---

## B. Staging with real user data

### B1. Not yet. These must be done first

Real health data in staging is still real health data: the same privacy law
applies as in production. Before any real report is synced:

1. **End-to-end encrypted Sync** (docs/SHARING.md) built and the old
   `reports` / `lab_results` tables dropped. Until then the server can read
   values.
2. **A separate staging Supabase project** (e.g. `vitalog-staging`), never
   the one used for development, in the Mumbai region. Its keys live in a
   `supabase.staging.json` (git-ignored, like `supabase.local.json`).
3. **Paid plan** (free projects pause and have no backups/point-in-time
   recovery) and, if any user is in the US, a signed BAA.
4. **Written consent** from every tester (India DPDP Act): what is stored,
   where, for how long, how to withdraw. Testers are adults testing with
   their own reports, or reports they are allowed to share.
5. **Delete paths work:** deleting a report removes it from the server
   (PENDING_TASKS #11) and in-app account deletion exists (#12).
6. **Access:** only named people can open the staging dashboard; MFA on the
   Supabase org; no one exports tables.

### B2. Running real-data testing **without** a server (safe today)
Everything except Sync runs on the phone and is encrypted, so real reports
can be tested **today** as long as Sync is not tapped:
- Build without Supabase keys (`flutter run` with no defines): Sync and
  Sign-in are then disabled, so nothing can leave the phone.
- Ask testers to upload their real reports from the labs you target
  (Thyrocare, SRL, Dr Lal PathLabs, Apollo, Metropolis…) and send you a
  **screenshot of what went wrong**, not the report.
- For each miss, add the lab's wording to `lab_test_catalog.dart` with a
  regression test using **made-up values** in the same layout.

This is the most valuable real-data testing right now (PENDING_TASKS #4).

### B3. Distributing staging builds
| Platform | How |
|---|---|
| iOS | Xcode → Archive → upload to App Store Connect → **TestFlight** internal testers (up to 100, no review). Needs the Apple Developer account and the bundle id registered. |
| Android | `flutter build appbundle --dart-define-from-file=supabase.staging.json` → Play Console → **Internal testing** track; or share the APK directly for a few testers. |

### B4. Staging checklist (once B1 is done)
- Every test in A2 on real devices, with real reports, on both platforms.
- Sync, then check in the staging Table Editor that only sealed (unreadable)
  data and opaque ids are stored.
- Delete a report → its rows disappear from staging.
- Delete the account → all its rows disappear.
- Restore on a second phone (once built) shows the same reports.
- Wipe the staging project when the test round ends, and tell testers.
