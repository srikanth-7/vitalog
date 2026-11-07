# Vitalog: complete test guide

**Updated:** 2026-11-06. This merges `docs/TEST_PLAN.md`,
`docs/TEST_USER_RUNBOOK.md`, the Sync v2 setup plan's Part B, and what each
working session reported it built (sessions -8d, -ce and -61; -96 added only
the manual screenshot run; -60 made no app changes). Where those older docs disagree with this one (for example their
"Sync v1 uploads readable values"), **this guide wins**. Sync is now sealed
(v2).

Mark each case **Pass / Fail / Blocked / Not run**.

| Tag | Meaning |
|---|---|
| 📴 | Offline build, no account. Safe with real reports as long as you never tap Sync |
| ☁️ | Needs the staging Supabase project + a test account. **Fake data only** |
| 👥 | Needs two accounts (two phones, or a phone + a simulator) |
| 📱 | Needs a real phone (camera, Face ID/fingerprint, screen reader, notifications) |
| 🛑 | Blocked today; the reason is given |

---

## 0. Set up once

1. **Code checks first** (on the Mac, in the project folder):

   ```bash
   flutter pub get
   flutter analyze          # expect: No issues found
   flutter test -j 2        # expect: All tests passed
   ```

   Use `-j 2`. At full speed one random widget test sometimes times out
   (known, see §3).
2. **Devices.** `flutter devices` lists them. The usual targets are the
   Android phone `00116652L000714`, the iPhone simulator
   `"iPhone 16 Plus"`, and the iPhone `00008120-000E48CE0CBBA01E`. Run only
   one build at a time.
3. **Offline build (📴):** `flutter run -d <device>`. Sign in and Sync
   then say "Cloud sync isn't set up in this build yet."
4. **Staging build (☁️):** create `supabase.staging.local.json` in the
   project root (the URL and the publishable key only; it's git-ignored),
   then:

   ```bash
   flutter run -d <device> --dart-define-from-file=supabase.staging.local.json
   ```

   The staging SQL must have run first: `schema.sql` and `hardening.sql`
   (done 2026-11-04), plus `delete-account` deployed (not done yet). See
   `docs/plans/2026-11-04-supabase-sync-v2-setup.md`.
5. **Sample files** are in `test-data/reports/`. All names in them are fake.
   - iOS simulator: drag the file onto the window; it lands in Files.
   - Android emulator: drag it onto the emulator; it lands in Downloads.
   - Real phone: AirDrop, email or Drive, then save it to Files.
6. **Start clean:** delete the app and reinstall. This wipes reports, keys
   and settings, so never do it on a phone with data you need.

### Sample files: what each must do

| File | Expected |
|---|---|
| `01-all-normal.txt` | **Ready**, 5 tests, all *Within range*, confetti, "5 tests added". Lab Greenleaf Diagnostics, reported 21 Oct 2026, collected 20 Oct |
| `02-needs-attention.csv` | **Ready**, "6 tests added · 6 need attention", **no confetti**. Total cholesterol, LDL, triglycerides, HbA1c *High*; HDL, Vitamin D *Low* |
| `03-no-printed-ranges.txt` | TSH 9.9 → *High · usual range*; fasting glucose 92 → *Within range · usual range*; Hemoglobin 11.0 → judged by sex if set, else *Needs review* |
| `04-unknown-test.txt` | **Needs review**; "Zonulin Serum" in **Other tests** with "needs a category"; TSH *Within range* |
| `05-contact-details.txt` | Lab shows only "Riverside Diagnostics" (address, phone and email cut); Creatinine, Urea *Within range* |
| `06-no-date.txt` | **Needs review** (no report date); HDL, LDL *Within range* |
| `07-unsupported.zip` | **Couldn't read**, "this file type can't be read", **no Try again** |

---

## 1. Automated tests (what `flutter test` checks)

Runs on the Mac with no device or network: 33 files, **169 tests, all passing on 2026-11-06** (`flutter test -j 2`, 48 s).
Run one file with `flutter test test/<path>`. If one fails, the name
printed says what broke.

| File | What it proves |
|---|---|
| `extraction/lab_report_parser_test.dart` (10) | Typical Indian report; date fallbacks and month names; grouped ranges and µL; spans as values; range on the next line; per-sex ranges (left for review, or picked by sex); two tests side by side; bare numbers ignored; real Apple Vision output with misread units |
| `extraction/document_reader_test.dart` (7) | Zip bomb refused; lying zip entry refused; photos/PDF go to OCR by content; CSV/HTML tables become rows; Word/Excel read directly; .eml read from its PDF attachment; no-text files rejected |
| `report_flow_test.dart` (19) | Cancel mid-read keeps nothing; no tests = not kept; errors stay listed for Try again; 90 s timeout; printed patient name checked (closest full name wins); move report; members saved with age; removing a member clears all of theirs (also mid-read); duplicates by content (re-take, fewer tests) vs. new report (changed value, extra test); editing a member re-judges by sex; photos encrypted, removed with the member, kept on edit |
| `report_store_test.dart` (9) | Size cap; files unreadable on disk; tampered file rejected; old plaintext migrated; unknown test → Other and the category is learned; same file twice caught per member; **combine profiles** moves reports and keeps a file once; reminders encrypted and wiped |
| `report_sync_restore_test.dart` (5) | Restore: undated stays undated; local wins on an id clash; restored member tints; report with no original fails safely |
| `health_bloc_test.dart` (7) | Upload → stored → read → notice; non-report turned away; move says where; Sync without backend says so; re-scan = "already here"; edit member; member photo |
| `health_charts_test.dart` (9) | At-a-glance tally uses latest values; trends need 2 same-unit numbers; outside-range first; range parsing; range position; period filter; **trend streak** (3+ same-way moves); units never mixed |
| `reference_ranges_test.dart` (10) | Vitamin D 7 low; sex ranges skipped without sex; children not judged by adult ranges; TSH age-adjusted; units converted, never guessed; every range names a real test; signed range table (accept newer, reject 1 changed byte, downgrade, other key); upload judged by usual range |
| `privacy/sealed_sync_test.dart` (4) | Recovery key round-trip, forgiving of typos; recovered key opens old boxes; sealed rows hide data and reject tampering, moved boxes and planted results; member names only inside the sealed box |
| `privacy/sharing_crypto_test.dart` (6) | Profile box opens only with its key and row; wrapped key opens only for its account; invite needs the link (the server copy is useless); only full Vitalog links accepted; links found in pasted text and in the app scheme; claim hash matches |
| `privacy/sync_payload_test.dart` (2) | Sync sends no file name, address or contacts; member data only sealed |
| `privacy/redactor_test.dart` (2) | Lab names lose address and contacts; free text loses phones, emails and links |
| `privacy/vault_keys_test.dart` (6) | Originals lock: off by default, on/off keeps the same key, a cancel loses nothing, old Android keys kept, never a new key on a settings edit |
| `privacy/leftover_copies_test.dart` (2) | Leftover `scan-*.pdf` swept; copied recovery key cleared after a minute |
| `backend/secure_session_storage_test.dart` (7) | Sign-in session kept in Keychain/Keystore; migrated from plaintext prefs once; PKCE verifier storage |
| `backend/auth_problem_test.dart` (1) | Auth errors become actionable messages |
| `reminders/reminder_test.dart` (6) | One-off fires once; off never fires; monthly from the 31st clamps; every 3 months; 29 Feb; survives save/load |
| `reminders/reminders_cubit_test.dart` (7) | Add schedules; delete/off cancels; removed member's reminders go; rescheduled on start; past one-off refused; notifications off = saved + says so; a scheduling failure never loses it |
| `reminders/reminder_sync_test.dart` | Reminders follow member changes |
| `widget_test.dart` (18) | Tour once; switch profiles; upload → timeline → report dashboard; delete restored report; Home order; chart spoken summary; All results; hide sections + Simple mode; edit value re-judged; Categories order; sideways two panes; theme/accent; onboarding; edit member; Share sheet + link → claim screen; reminder from Family; small phone Simple mode; add member |
| `presentation/*` (12) | Account card signed in/out; attention cards (screen reader, big text, no gauge when flag disagrees); **category card reads its name first**; tints/contrast in all themes; greeting uses first name never email; avatar photo/initials; notices (auto-close, 10 s in Simple mode, wait for the screen reader) |
| Others | `empty_art_test`, `readable_width_test` (Duo 669 pt full width, tablet column), `relation_test`, `settings_accent_test` (onboarding stays done, old `fammo` accent), `snapshot_test`, `vitalog_nav_bar_test` |

**Screenshot run (not a pass/fail test).** Session -96 added this for the
user manual. It drives the app with the sample family and saves PNGs to
`docs/manual/screens/`. It uses a temp folder and fixed test keys, so it
doesn't touch real data. iOS only so far:

```bash
flutter drive --driver test_driver/manual_screenshots.dart \
  --target integration_test/manual_screenshots_test.dart -d "iPhone 16 Plus"
```

---

## 2. Manual tests, step by step

### A. First launch, onboarding, tour 📴

| ID | Steps | Expected |
|---|---|---|
| A01 | Fresh install, open the app | Logo animates (lines slide in, the pulse draws, the dot pops and beats) → welcome pages. No sample people or reports |
| A02 | Swipe the 3 welcome pages | Pictures assemble with the swipe; dots follow |
| A03 | At the sign-in offer tap **Continue without an account** | Empty start screen with **Add family member**; the spotlight tour dims around it, then each tab |
| A04 | Force-close and reopen | Splash goes straight to the app; no onboarding, no tour |
| A05 | Family → **Take a quick tour** | Tour plays again |
| A06 | 📱 Phone Settings → Reduce Motion on, restart | No splash animation or confetti; everything still works |

### B. Family members 📴

| ID | Steps | Expected |
|---|---|---|
| B01 | Add family member: made-up name, relation **You**, birth year, sex → Save | Created and selected; tabs appear |
| B02 | Family tab → add a second member | Appears and becomes selected |
| B03 | Switch member from the bottom dock (person button) | Tab stays the same; Home/Categories/Reports follow the person |
| B04 | Switch member from the Family list | Goes to Home for that person |
| B05 | Add a member with sex not set | Saves; no sex is guessed (see C03) |
| B06 | Long-press a member → **Edit details** → change the name and sex | Name changes everywhere; results re-judged by the new sex (usual ranges) |
| B07 | Edit → add a photo; then remove it | Photo shows on the avatar; removed → initials |
| B08 | Long-press a member with reports → Remove | One sheet names how many reports go. Cancel keeps all; Remove deletes the member, reports, originals, photo and reminders |
| B09 | Remove a member while one of their reports is still "Reading…" | Nothing of theirs comes back when reading ends |
| B10 | Force-close and reopen | Members, ages and photos remain |

### C. Uploading and reading reports 📴

| ID | Steps | Expected |
|---|---|---|
| C01 | Reports → Add → **Choose a file** → `01` | Card says **Reading…** with a scan beam; you can switch tabs; then "5 tests added" + **View** + confetti |
| C02 | Tap **View** | That report's own dashboard: only its 5 results |
| C03 | Upload `02` to `07` one by one | As in the sample table above. `03` to a no-sex member → Hemoglobin *Needs review* |
| C04 | Upload `01` again to the same member | "You've already added this report." + View; no second copy. Same file to another member is allowed |
| C05 | 📱 Photograph a printed report (or `01` printed) | Same result as the file (iOS Vision / Android ML Kit) |
| C06 | 📱 Retake a photo of the same paper report | Caught as a duplicate after reading; View opens the one kept |
| C07 | Upload a PDF (export `01` to PDF) | Same results |
| C08 | Upload a .docx and an .xlsx with a results table | Rows read; cells become columns |
| C09 | Upload a forged/corrupt .docx | **Couldn't read**; no crash, no hang |
| C10 | 📱 Add → **Scan with camera**, 2 pages | Page edges found; one report with both pages. 🛑 Android: scanner library download blocked by the office proxy, so it may fall back to the plain camera |
| C11 | 📱 Upload a big photo, lock the phone 10 s, unlock | Reading finishes; the notice appears |
| C12 | Upload two files quickly | Both finish; nothing lost |
| C13 | During **Reading…** tap Cancel | Report disappears; nothing is kept |
| C14 | A read that fails → **Try again** | Reads again. A read longer than 90 s fails as timed out with Try again |
| C15 | Upload a report whose printed patient name is another member's | Timeline offers **Keep here / Move to…**; Move files it, and its results, under the other member |
| C16 | Airplane mode: add a member and upload | Everything works; only Sync needs the network |
| C17 | 📱 Android: kill the app right after a scan returns, before "Reading…"; relaunch; `adb shell run-as com.app.vitalog.dev ls -R cache` | No `scan-*.pdf` left (check whether the scanner leaves its own PDF too) |

### D. Results, editing, ranges 📴

| ID | Steps | Expected |
|---|---|---|
| D01 | Open a result → **Edit** → 14.2 → 18 → Save | Re-judged (*High*), marked edited |
| D02 | Edit → **Compare with original** | Original opens from memory (lock: see I03) |
| D03 | In `04`, open Zonulin → Edit → category **Immunity** → Save | Leaves Other; report becomes **Ready** |
| D04 | Upload `04` to another member | Zonulin is filed under Immunity automatically |
| D05 | `03` on a no-sex member → Hemoglobin → **Looks right** | "Checked · no range", "Marked as checked.", not marked edited; report Ready when nothing else awaits |
| D06 | Female member, report with "Hemoglobin 13.5 g/dL M: 13.0-17.0 F: 12.0-15.5" | *Within range*. No sex set → *Needs review*. Male with 11 → *Low* |
| D07 | Test detail of a usual-range result | Says "usual range" and its source, never "per report" |

### E. Home, Categories, trends 📴

| ID | Steps | Expected |
|---|---|---|
| E01 | Home with results | Headline "Here's <name>'s health snapshot"; order: At a glance / Needs attention → trends → latest report → categories → recent |
| E02 | At a glance | Hero count of results within range + stacked bar + legend with icons and labels (not colour only) |
| E03 | Categories tab | **Tested** groups first ("Not yet: …" for missing key tests), then greyed **Yet to test**. Pancreas, Cancer markers, Hormones, Infections, Clotting say "When your doctor advises", never missing |
| E04 | Open a test with 2+ reports | History lists every dated value; the chart draws same-unit values only |
| E05 | 4 reports, same test and unit, rising each time (HbA1c 5.6, 5.8, 6.0, 6.3) | Home trend tile and test page say **"Up 3 times in a row"** |
| E06 | Same with 3 reports, up/down/up, or mixed mg/dL and mmol/L | No streak note |
| E07 | Home → **All results** | Tests from every category |
| E08 | Reports → pull down | Refreshes without a loading flash |

### F. Display settings, language, layout 📴

| ID | Steps | Expected |
|---|---|---|
| F01 | Family → Display → **Simple mode** on | Text ≥1.3× and bold, big "Add a report", categories grid and trends hidden, plain status words, notices stay 10 s |
| F02 | **Customize home** → hide sections → restart | They stay hidden; a single report's dashboard still shows everything |
| F03 | Theme Light/Dark/System + each accent → restart | Changes instantly and persists; High/Low colours never change; logo colours never change |
| F04 | 📱 Biggest phone text + Simple mode | Nothing clipped on Home, Reports, test detail; check the trend tile with a streak note |
| F05 | Language → తెలుగు, then हिन्दी, then English / Device | Everything switches immediately and persists; dates localised; no `{name}`/`{count}` shown raw |
| F06 | 📱 Device language Hindi: first camera/photo/Face ID prompt | System prompt text in Hindi (iOS `hi.lproj`) |
| F07 | Small phone + Simple mode | "Add report" drops its label to fit |
| F08 | 📱 Phone sideways (or iPhone Duo open / tablet) | Side tray on the LEFT; two panes on every tab (Home status / history, Categories groups / results, Reports timeline / report, Family people / settings); back works inside the right pane |

### G. Reminders 📱

| ID | Steps | Expected |
|---|---|---|
| G01 | Home bell (or Family) → add a reminder for a member, 2 minutes ahead | Notification arrives with your title + "Reminder for {name}"; never a test name or value |
| G02 | Monthly on the 31st, every 3 months, yearly on 29 Feb | Next dates clamp correctly (shown in the list) |
| G03 | A one-off time already past | Refused with a message |
| G04 | Notifications turned off in phone Settings, add a reminder | Saved, and the app says notifications are off |
| G05 | Turn a reminder off; delete one; remove its member | Each cancels; the removed member's reminders are gone |
| G06 | One due within 7 days | Bell shows a dot; screen reader says "Reminders, one due this week" |

### H. Accessibility 📱 (VoiceOver on iPhone, TalkBack on Android)

| ID | Steps | Expected |
|---|---|---|
| H01 | Swipe across the tab bar | Each tab is named and opens on double-tap |
| H02 | Report, result and category cards | Each reads as one button |
| H03 | Home category tile with flagged results | Reads "<group>, N outside range, N tests · <date>"; no count when nothing is flagged. Also check the Categories tab cards (not covered yet) |
| H04 | Reminder switch; accent swatches; member switcher; member tile | Switch says its title; swatches selectable; switcher named; tile says selected; initials not read |
| H05 | Count-up numbers; charts | Read once; the chart has a spoken summary |
| H06 | A notice with a screen reader on | Stays until dismissed |

### I. Privacy and on-phone security 📴📱

| ID | Steps | Expected |
|---|---|---|
| I01 | Simulator: `xcrun simctl get_app_container booted com.app.vitalog.dev data` → open Documents | `reports.json`, `members.json`, `reminders.json` and originals start with `FAMMO1`/`FAMMO2`; unreadable |
| I02 | Before the first report | Asked once "Lock your original reports?"; **Not now** = no prompt; **Turn on** → system prompt |
| I03 | Lock on → Compare with original | Face ID / fingerprint / PIN asked; Cancel → not shown, app fine; re-locks after 2 min away |
| I04 | Family → **Lock original reports** off, then on | No data lost; older originals still open |
| I05 | Upload `05`, check Home and report header | Lab name without address, phone or email |

### J. Account and sign-in ☁️

| ID | Steps | Expected |
|---|---|---|
| J01 | Family → Sign in → **Create account** (any inbox you own, 8+ characters) | "Check your email"; the mail arrives |
| J02 | Open the link **on the same phone** | App opens via `com.vitalog.app://login-callback`, signed in |
| J03 | Sign out; wrong password; right password | Clear error, then signed in; local data untouched |
| J04 | **Forgot password** | Reset mail arrives; link opens the app |
| J05 | 5 wrong passwords within 15 min | 🛑 until the lockout hook is on (optional on staging; on in prod). Then: "Too many attempts. Wait a few minutes"; Forgot password still works |
| J06 | Google sign-in on iOS | Works once Supabase lists both client ids. The "You" member keeps its own name; the Home greeting uses the account name. 🛑 Android: needs the app's SHA-1 in Firebase |
| J07 | Family → session check (iOS simulator): `security find-generic-password -s flutter_secure_storage -a vitalog` | Session in the Keychain, not in SharedPreferences |

### K. Sealed Sync, restore, recovery key ☁️ (fake data only)

| ID | Steps | Expected |
|---|---|---|
| K01 | Upload `05`, tap **Sync** (first time) | "Save your recovery key" sheet, once. Save it to passwords |
| K02 | Recovery key → **Copy** | Snackbar says it clears in 1 minute; paste works within the minute; after ~60 s the clipboard is empty (check both platforms, also with the app in the background) |
| K03 | Supabase → Table Editor → `sealed_reports`, `sealed_profiles` | `sealed` column is gibberish: no names, labs, dates, values or file names |
| K04 | Tap Sync again with no changes | No duplicate rows |
| K05 | Sync with Wi-Fi off; Sync signed out | Clear error, nothing marked synced; signed out → asked to sign in |
| K06 | Sign out, delete the app, reinstall, sign in | iPhone with iCloud Keychain: restores quietly. Otherwise asked for the recovery key → members **with names** and reports come back. No Restore button; nothing uploads |
| K07 | Enter a wrong recovery key | Refused; nothing overwritten |
| K08 | Delete a report, Sync | Its row is gone from `sealed_reports` |
| K09 | 👥 Second account | Sees none of the first account's rows |
| K10 | Throwaway account → **Delete account** | 🛑 until `delete-account` is deployed (setup A4). Then: rows gone from all tables and from Authentication → Users |

### L. Family sharing / invites ☁️👥

🛑 **Outside the team: blocked** until the invite domain is owned
(`docs/INVITE_DOMAIN.md`). `vitalog.app` belongs to someone else, so
invite only between team phones. The web page won't load; use **Family →
Open an invite link** and paste the link.

| ID | Steps | Expected |
|---|---|---|
| L01 | Account A: long-press a member you added → **Share** | Family card: who has access, pending invites, **Invite someone** |
| L02 | Invite someone | Share sheet with `https://<host>/i/<id>#<secret>`; card shows "Invite pending" |
| L03 | Account B: Family → Open an invite link → paste | Claim screen: "Who is X to you?" with relation chips, report count, **Add to my family / Not now** |
| L04 | B picks **Parent** → Add | Member and reports arrive; Home opens on them. No combine sheet |
| L05 | B already has "You" with 2 reports (one is file X, also in A's member) → accept as **You** | "Combine with your own profile?" naming "Me" and 2 reports |
| L06 | **Combine** | One "You": B's name, age, photo and reminders; reports = A's + B's, X once; Sync without error; A sees B's moved report after their next pull |
| L07 | Repeat L05 with **Keep separate** | Two profiles stay |
| L08 | A removes B within 10 min; B re-opens the same link | Claim fails (already used); no access |
| L09 | From another account open the link with a wrong `#secret` 6+ times, then the real link | Real link still works (an invite can't be burned) |
| L10 | Garbled or partial link | "isn't a Vitalog invite link" error (translated) |
| L11 | Cancel a pending invite, then open it | Refused |
| L12 | Expired (7 days), already used, too many tries, recovery key needed | Each shows its own clear message (hard to trigger; not checked yet) |
| L13 | B removes the shared member from their phone | B leaves; A's reports stay on the server. Deleting one **report** deletes it for everyone |
| L14 | Translations: L01–L10 in Telugu and Hindi | No English left; names, dates and counts filled in; Combine plural right for 0/1/many |

### M. Platform pass

Run A–I on **both** an iPhone (or simulator) and the Android phone.
Android extras:
- the camera permission prompt on the first photo;
- PDFs on Android 10 and 11+;
- fingerprint/PIN for the originals lock.

After the package upgrade (bloc 9, file_picker 13.3, archive 4.6), smoke
test on both phones: photo, PDF, Word and Excel upload, the file picker,
Sync and reminders.

---

## 3. Known gaps (from the sessions, as of 2026-11-06)

- **Not yet tried on a phone:** package upgrade, screen readers, Hindi and
  Telugu, combine, clipboard clear, scan sweep, trend notes, the new
  `schema.sql` (first staging run is its real syntax check).
- **Translations are machine drafts.** A native speaker must review
  `docs/translations_review.csv`. New combine / clipboard / streak strings
  are English-only in Hindi and Telugu. Long Telugu may wrap on small
  phones.
- **Combine:** errors are swallowed (both profiles stay, no retry). If the
  old profile was also shared, Sync may hit row-level security. No notice
  to other sharers.
- **Clipboard clear** wipes anything copied during that minute.
- A result isn't re-judged when a member's sex changes later; age-banded
  printed ranges aren't supported.
- **Flaky suite:** at full concurrency one random widget test may fail;
  `-j 2` passes.
- **Security open (PENDING #27):** invite domain, the `com.vitalog.app://`
  hand-over can be intercepted, the invite key isn't bound to its profile,
  no key rotation after a removal.

## 4. Reporting a bug

```text
Case ID:
Result: Pass / Fail / Blocked / Not run
Device and OS:
Build (offline / staging) and date:
Steps and what happened:
Screenshot (crop out emails and personal details):
```

Never attach a real report, a password, a recovery key or any secret key.
For a misread report, name the sample file or describe its layout.
