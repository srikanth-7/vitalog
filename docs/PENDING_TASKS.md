# Pending tasks — Vitalog

Status as of **2026-11-04**. Ordered by priority within each section.
✅ = done and verified · 🟡 = done in code, not yet checked on a phone ·
⏳ = pending · 👤 = needs the product owner · 🔒 = blocks launch
(docs/GO_LIVE.md). Item numbers are stable; other docs refer to them.
Security audit items are written **S1–S14** (docs/SECURITY_AUDIT_2026-10-26.md).

## Next up

| Order | Who | What | Why first |
|---|---|---|---|
| 1 | 👤 | **Supabase setup for Sync v2**, staging then prod: docs/plans/2026-11-04-supabase-sync-v2-setup.md | Sync fails on both projects until it's done |
| 2 | 👤 | **Plug the Android phone back in** (A015, id `00116652L000714`) so the latest build installs | Everything since 2026-11-02 is untested on a phone (see "Phone check") |
| 3 | 👤 | **S6:** change the Supabase dashboard password, turn on two-factor | The password was typed in a chat on 2026-10-24 |
| 4 | 👤 | **Git:** pick Option A (`gh auth login`) or B (macOS prompt) and a repo name | Several sessions edit the same files with no history or undo |
| 5 | 👤 | Answer two open questions: do buttons (Add member) work in the open Duo layout after a full restart? How to install the cloudflare skill past the office SSL proxy (other network / office cert / skip)? | Blocks the Duo session |
| 6 | 👤 | **Invite family (P0b)**: code done 🟡. Pick the invite domain, re-run `supabase/schema.sql` + `hardening.sql` on staging (migrates to shared ids), host `invite_site/`, then try it with two accounts | Sharing can't be tried end to end until the SQL runs |

## Phone check (after the new build is on the phone)

All 🟡 until done on the Android phone (and an iPhone where it applies).
Run against **staging** only (`--dart-define-from-file=supabase.staging.local.json`).
Only one `flutter run` / Gradle build at a time: two share `build/` and the
second fails in `mergeDebugResources`.

- [ ] **Recents / app switcher (S2):** Vitalog's preview is blank
- [ ] **Invite family:** account A long-presses a member → Share → Invite someone → share sheet; account B (other phone) opens the link → claim screen → Add to my family → Home shows the reports; A's family card lists B; Remove works; a second use of the link says it was used
- [ ] **First Sync:** "Save your recovery key" sheet appears once; Save to my passwords works
- [ ] **Restore:** reinstall + sign in + recovery key brings back members (with names) and reports
- [ ] **Reminders:** explanation sheet before Android's permission prompt; "Don't allow" → message with **Open Settings**; a reminder actually fires
- [ ] **Notification icon:** not a white square
- [ ] **Permissions text:** camera / photos / fingerprint prompts read plainly (written for older users)
- [ ] **Member photos:** add, change, denied-permission message
- [ ] **Tab bar:** sliding tile, animated icons, 250 ms, Reduce Motion = instant
- [ ] **Empty states:** picture builds in, idles ~20 s, then rests; Reduce Motion = still
- [ ] **Home 10-second rule:** "Your family's lab reports, in one place", category chips, "N outside range"
- [ ] **Overflows:** Reports dock at 375 pt / Simple mode shows "+"; category tiles; At a glance legend
- [ ] **Ten small bugs** (fixed 2026-11-03, list in "Done" below), especially chart labels and "Date not found"
- [ ] **S1:** no readable report copies left in the app cache after a scan
- [ ] **S3:** originals ask for fingerprint/face again after 2 minutes away
- [ ] **S14:** Android fingerprint/PIN lock on originals, when turned on
- [ ] **Delete account** removes the server rows (staging)
- [ ] Open Duo / sideways layout on the iPhone Duo simulator after a full restart

## Done (for context)

- ✅ On-device report reading: iOS (Apple Vision) and Android (ML Kit); photos, multi-page PDFs, Word, Excel, CSV, text, HTML, email; unsupported files flagged
- ✅ Parser: tests, values, units, ranges, H/L flags, dates, lab name (address/contacts stripped), 17 predefined categories, unknown tests → Other with a learned category picker
- ✅ Built-in usual ranges when none is printed (never guessing unit, sex or age); "Needs attention" list and upload notice
- ✅ Edit any value; "Looks right"; compare with the original
- ✅ Duplicate uploads detected per member (same file, or same paper report)
- ✅ Encryption at rest (results file + originals behind an opt-in Face ID / fingerprint / PIN lock)
- ✅ Reports timeline, single-report dashboard, charts, test history
- ✅ Simple mode, Home sections, theme + accents, language (English / Telugu), onboarding, splash, first-run tour
- ✅ Family members: add, edit, remove (with their reports), photos
- ✅ Reminders (phone-only scheduled notifications)
- ✅ Sideways / iPhone Duo two-pane layout with a side tray
- ✅ Real installs start empty: no sample members or reports (#6)
- 🟡 **Sync v2** (2026-11-03): reports, results and members sealed on the phone before upload; per-member keys locked with the account key; recovery key (iCloud Keychain on iPhone, "Save to my passwords" / Copy elsewhere); plaintext tables dropped by `schema.sql`. Server not set up yet (Next up #1)
- 🟡 **Security fixes** (2026-11-03): S2 app-switcher cover, S5 Sync v2, S7 release signing fails without `key.properties`, S8 Android backup / device-transfer exclusions, S10 `supabase-js` pinned to 2.49.4 (version unverified, see the plan), S11 `search_path` on every SQL function. Earlier (2026-10-26): S1, S3, S9, S12, S13, S14
- ✅ **S4 member names** (decided 2026-11-03): names reach the server only sealed; test in `test/privacy/sealed_sync_test.dart`
- 🟡 **Permission prompts** (2026-11-03): plain explanation before the system prompt, Open Settings after a refusal; iOS prompt texts rewritten (en + te)
- 🟡 **Ten small bugs** (2026-11-03): right pane picks by report date; restored failed reports lose "Try again"; undated reports say "Date not found"; account stats skip sample reports; Home setting renamed "Last tested date"; chart labels no longer overlap; relation saved as a fixed key; photo-picker errors handled; Android notification icon; channel name localized
- 🟡 **Design** (2026-11-02/03): new tab bar (sliding tile, painted animated icons, coral `reading` token); rounded scroll edges (`ScrollCut`); Home 10-second rule; empty-state pictures animate like onboarding; overflow fixes
- ✅ Android builds on the office network: `android/build.gradle.kts` forces AGP 8.11.1 / Kotlin 2.2.20 for every plugin (don't revert)
- ✅ 158 automated tests, analyzer clean (2026-11-04)

## P0 — needed before anyone else uses it

1. ⏳ 👤 **Supabase setup** — two projects, **staging** and **prod**. Sync v2 tables, checks and function not yet applied to either: follow docs/plans/2026-11-04-supabase-sync-v2-setup.md. Keys in git-ignored `supabase.staging.local.json` / `supabase.prod.local.json`.
2. ⏳ 👤 **Google sign-in** — ✅ native flow + client ids wired. Still to do: both client ids + "Skip nonce check" decision in Supabase (both projects); register the Android SHA-1 in Firebase (Android Google sign-in fails until then).
3. ⏳ 👤 🔒 **Final bundle id & signing** — today `com.app.vitalog.dev`. Pick the store id (can't change after release), Apple team, release keystore + `key.properties` (the release build now refuses to build without it), keep the `com.vitalog.app` URL scheme, Supabase redirect and Google client ids consistent.
4. ⏳ 👤 🔒 **Test on real reports** — target labs (Thyrocare, SRL, Dr Lal PathLabs, Apollo, Metropolis) in a build **without** Supabase keys. Add each lab's wording to `lab_test_catalog.dart` with a made-up-values regression test.
5. ✅ **Real family members** — add, edit, remove on the phone; synced sealed with Sync v2.
6. ✅ **Remove sample data** — real builds use `EmptyFamilyHealthDataSource`.

6b. ⏳ 👤 🔒 **Clinical review of built-in ranges** — docs/REFERENCE_RANGES.md signed off by a clinician / lab professional.
6c. ✅ **Sex on family profiles** — asked when adding, editable.
6d. ⏳ **Pediatric ranges** — adult-only ranges are skipped for under-18s (except the WHO haemoglobin cut-off). Needs clinical sources.
6e. ✅ **Range signing key** (2026-11-04) — public key in `signed_range_table.dart`; private seed in the dev Mac's login Keychain (`vitalog-range-signing`), move it to the server's secret store when updates ship. Range notes are still English-only.

## P0b — family sharing (docs/SHARING.md) 🔒

- ✅ Crypto core: profile keys, wrap for account, invite links (+ tests)
- 🟡 Account key + recovery key; Sync v2 sealed push + pull. ⏳ Android silent Google backup of the key (Block Store), once Gradle can fetch it
- 🟡 Shared ids + access = `profile_keys` rows (`has_profile`), migration in schema.sql
- 🟡 **Invites:** share link, claim screen, paste a link, app scheme hand-over. ⏳ combine duplicates, iOS Universal Links (paid Apple team)
- 🟡 **Family card:** who has access, pending invite / cancel, remove (leave = remove the member)
- ⏳ **Reminders on other family members' phones** (tester item #13) — needs the above
- ⏳ 👤 Decide the invite domain (`InviteLink.host`, placeholder today)

## P1 — product gaps

7. 🟡 **Android OCR** — ML Kit + `PdfRenderer`; app now builds and runs on the phone. Still to check: scanning real reports on it.
8. ✅ **"Needs review" resolution** — "Looks right".
9. ⏳ 👤 **Document scanner camera** — Android needs `play-services-mlkit-document-scanner` fetched once (Gradle 403 on the office network; try a phone hotspot), then try on both phones.
10. 🟡 **Restore from cloud** — sealed pull on sign-in (no button, decided 2026-10-25), recovery key on a new phone.
11. 🟡 **Deletes sync** — deleting a report or member removes its server rows (real deletes, not tombstones).
12. 🟡 **Account deletion in-app** — Family tab → Delete account → `delete-account` edge function (redeploy: plan A4).
13. ✅ **Settings** — theme, accent, Simple mode, Home sections, language.
14. 🟡 **More languages** — Hindi added 2026-11-04 (`app_hi.arb`, iOS `hi.lproj`). 👤 Hindi and Telugu need a native speaker's review; Telugu is missing the 17 `recoveryKey*` strings.
15. ✅ **"See all" on Home** switches to the Categories tab.

## P2 — hardening and before launch

16. ✅ **Encrypt local data at rest.**
17. ⏳ **Scale local store** — one JSON file rewritten on every save (`ponytail:` in `local_report_store.dart`); move to sqlite/drift when histories get large.
18. ⏳ **Parser edge cases** — ✅ ranges printed per sex are judged by the member's sex (2026-11-04). Still open: age-banded printed ranges (need sample rows from real reports), non-English reports.
19. ✅ **Duplicate uploads.**
20. ⏳ 👤 🔒 **Privacy policy & store disclosures** — DPDP Act, medical disclaimer, App Privacy labels, Play Data safety + Health apps declaration. Say that health data and names are stored end-to-end encrypted.
21. 🟡 **Accessibility** — code pass done 2026-11-04 (tappable cards read as buttons, tab bar/accent swatch usable by screen reader, reminder switches labelled, count-up values read once, reminder dot not colour-only). 👤 Still: try VoiceOver/TalkBack on a phone; CategoryCard reads its "N outside range" before the group name.
22. 🟡 **Dependency upgrades** — packages upgraded 2026-11-04 (bloc/flutter_bloc 9, flutter_lints 6, file_picker 13.3, archive 4.6; tests pass, needs a phone check). ⏳ Flutter SDK itself (3.38.10): `flutter upgrade` blocked by the office SSL proxy — run it on another network, then retest.
23. ⏳ 👤 🔒 **Prod-only Supabase settings** — confirm email, CAPTCHA, redirect allow-list, backups (plan C3). CAPTCHA also needs an app change to send the token once the provider is chosen.
24. ✅ **Zip size check** — archive ≥ 4.5.2 stops inflating an entry at its stated size; a forged size now fails as `UnsupportedDocument` (test in `document_reader_test.dart`).
25. ✅ **Temporary "You" name** — removed (2026-11-04).
26. ⏳ **Cleanup** — ✅ unused root-level Gradle project deleted (2026-11-04). Still: remove the bulk-delete section of `cleanup_test_data.sql` once staging is clean.

## Later (planned, not started)

- **Scans & imaging** (X-ray, CT, MRI, ECG). Waiting for the go-ahead.
- **Apple Health / Google Fit import** — docs/HEALTH_APPS_SYNC_PLAN.md.
- Known build quirk: on Xcode 27.1 `flutter build ios --simulator` fails a `lipo` check; use `flutter run` (docs/GO_LIVE.md §6).

## How to verify after changes

```bash
flutter analyze && flutter test
graphify update .        # refresh graphify-out/ for other agents
```
