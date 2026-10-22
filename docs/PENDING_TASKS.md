# Pending tasks — Vitalog

Status as of 2026-10-22. Ordered by priority within each section.
✅ = done and verified · ⏳ = pending.

## Done (for context)

- ✅ On-device report reading (iOS, Apple Vision; images + multi-page PDFs)
- ✅ Parser: tests, values, units, ranges, H/L flags, report/collection dates, lab name, auto-categorisation
- ✅ Reports timeline per family member, status (Reading / Ready / Needs review / Couldn't read), retry, delete
- ✅ Tap a report → same dashboard showing only that report's data
- ✅ Local on-device storage; Sync uploads only on tap; synced/on-device badges
- ✅ Sign-in screen: Google (OAuth) + email/password, sign-up, reset password
- ✅ Light + dark themes from tokens; all strings localised (English ARB)
- ✅ Animations: press feedback, tab fade, selection, status transitions (reduced-motion aware)
- ✅ Tests: parser (incl. real OCR output), bloc flow, widgets — `flutter test` all green

## P0 — needed before anyone else uses it

1. ⏳ **Supabase setup** — follow `docs/SUPABASE_REQUIREMENTS.md` §6, then run with the two `--dart-define`s. Sign-in and Sync are untested against a real project.
2. ⏳ **Google OAuth credentials** — Google Cloud OAuth client + Supabase provider config.
3. ⏳ **Real bundle id & signing** — bundle id is now `com.vitalog.app` (Android `applicationId` too); select an Apple team to run on a physical iPhone. Keep the `com.vitalog.app` URL scheme in sync.
4. ⏳ **Test OCR on real reports** — photograph/scan actual reports from your target labs (e.g. Thyrocare, SRL, Dr Lal PathLabs, Apollo, Metropolis). Add each lab's odd wording to `lab_test_catalog.dart` and a regression test. Verified so far only on a rendered sample + synthetic rows.
5. ⏳ **Real family members** — members are still sample data (`data/mock`). Need add/edit/remove members stored on-device (and synced). Uploaded reports attach to the selected member's id.
6. ⏳ **Remove sample data** once real members exist (mock reports/results show a "Sample" badge today).

## P1 — product gaps

7. ⏳ **Android OCR** — implement `vitalog/report_ocr` on Android (Google ML Kit Text Recognition + `PdfRenderer` for PDFs). Today uploads on Android are marked *Couldn't read*. Also: Android camera permission, auth deep-link intent filter (`com.vitalog.app://login-callback`).
8. ⏳ **"Needs review" resolution** — there is no way to clear a flag (no manual entry by design). Decide: "Looks right" confirm button, or re-scan with better photo.
9. ⏳ **Better photo capture** — use VisionKit's document scanner (`VNDocumentCameraViewController`) for auto-crop/deskew; noticeably better OCR on phone photos than the plain camera.
10. ⏳ **Restore from cloud** — Sync is push-only. Add pull on sign-in / new device.
11. ⏳ **Deletes don't sync** — deleting a synced report removes it locally only. Needs tombstones (see Supabase doc §4).
12. ⏳ **Account deletion in-app** — required by App Store for apps with sign-up (Edge Function `delete-account`).
13. ⏳ **Settings screen** — theme (system/light/dark) and language picker; `FamilyHealthApp.themeMode` and `supportedLocales` are already wired.
14. ⏳ **More languages** — add `lib/l10n/app_hi.arb` etc. Test names stay as printed.
15. ✅ **"See all" on Home** now switches to the Categories tab (covered by a widget test).

## P2 — hardening

16. ✅ **Encrypt local data at rest** — `reports.json` and every original document are AES-256-GCM encrypted (`report_cipher.dart`), key in Keychain/Keystore bound to this device; older plaintext files migrate on first load. OCR reads decrypted bytes in memory only.
17. ⏳ **Scale local store** — single JSON file rewritten on each save (marked `ponytail:` in `local_report_store.dart`); move to sqlite/drift for large histories.
18. ⏳ **Parser edge cases** — count ranges like `2-3 /hpf` (pus cells) are mis-split; reference ranges printed on the next line; two tests side by side in one row; ranges with age/sex bands; non-English reports.
19. ⏳ **Duplicate uploads** — same file uploaded twice creates two reports; detect by file hash.
20. ⏳ **Privacy policy & store disclosures** — health data, App Privacy labels, Play data safety.
21. ⏳ **Design review** — animations and layouts (owner to review); accessibility pass (Dynamic Type, VoiceOver labels on cards/pills, contrast in dark mode).
22. ⏳ **Dependency upgrades** — `flutter pub outdated` lists 41 newer versions; also Flutter itself is ~250 days old.

## How to verify after changes

```bash
flutter analyze && flutter test
graphify update .        # refresh graphify-out/ for other agents
```
