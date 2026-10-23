# Pending tasks — Vitalog

Status as of 2026-10-23. Ordered by priority within each section.
✅ = done and verified · ⏳ = pending · 👤 = needs the product owner ·
🔒 = blocks launch (docs/GO_LIVE.md). Item numbers are stable; other docs
refer to them.

## Next up

| Who | Items |
|---|---|
| 👤 Product owner | Hotspot once for the Android scanner library (#9) · try sign-up + Sync with fake reports (#1) · Google sign-in setup (#2) · Apple team + final app id (#3) · real lab reports on a phone (#4) · clinician sign-off of ranges (#6b) · privacy policy (#20) · design review (#21) · invite domain (P0b) |
| Next (after the owner's go-ahead) | P0b encrypted Sync v2 + sharing, which brings #10, #11, #12 · edit/remove members (#5, #6c). Only the crypto core exists so far. |
| After that | Remove sample data (#6) |
| Can be done now, no input | Pick the sex band from the member's sex (#18) · age-banded ranges (#18) · range signing key (#6e) · dependency upgrades (#22) |

## Done (for context)

- ✅ On-device report reading: iOS (Apple Vision) and Android (ML Kit); photos, multi-page PDFs, Word, Excel, CSV, text, HTML, email; unsupported files flagged
- ✅ Parser: tests, values, units, ranges, H/L flags, dates, lab name (address/contacts stripped), 17 predefined categories, unknown tests → Other with a learned category picker
- ✅ Built-in usual ranges when none is printed (never guessing unit, sex or age); "Needs attention" list and upload notice
- ✅ Edit any value; "Looks right" to confirm one that can't be judged; compare with the original
- ✅ Duplicate uploads detected per member
- ✅ Document scanner camera (iOS done; Android needs the library download, #9)
- ✅ Encryption at rest (results file + originals behind Face ID/passcode); temp copies deleted after storing
- ✅ Reports timeline, single-report dashboard, charts (at a glance, trends), test history
- ✅ Simple mode, hide Home sections, light/dark/system theme + accents, onboarding, animated logo splash
- ✅ Add family members (name, relation, age, sex), on the phone
- ✅ Sign-in screen (email + Google) and Sync (plaintext v1, fake data only); dev Supabase project
- ✅ Docs: TEST_PLAN, GO_LIVE, HOW_IT_WORKS; fake sample reports in `test-data/reports/`
- ✅ 60 automated tests, analyzer clean

## P0 — needed before anyone else uses it

1. ⏳ 👤 **Supabase setup** — ✅ dev project created (tables, email auth, redirect URL); keys in git-ignored `supabase.local.json`, run with `--dart-define-from-file=supabase.local.json`. Still to do: test sign-up and Sync end to end (fake data only — docs/TEST_PLAN.md). A separate production project comes later (docs/GO_LIVE.md §4).
2. ⏳ 👤 **Google sign-in** — ✅ native flow + client ids wired. Still to do: add both client ids + "Skip nonce check" in Supabase; register the Android SHA-1 in Firebase (Android sign-in fails until then).
3. ⏳ 👤 🔒 **Final bundle id & signing** — today `com.app.vitalog.dev` on iOS and Android. Pick the store id (can't change after release), select an Apple team, keep the `com.vitalog.app` URL scheme, Supabase redirect and Google client ids consistent.
4. ⏳ 👤 🔒 **Test on real reports** — scan/photograph reports from target labs (Thyrocare, SRL, Dr Lal PathLabs, Apollo, Metropolis) in a build **without** Supabase keys (nothing can leave the phone). Add each lab's wording to `lab_test_catalog.dart` with a made-up-values regression test.
5. ⏳ **Real family members** — ✅ add on-device. Still to do: edit/remove members, members API sync. *(with P0b)*
6. ⏳ 🔒 **Remove sample data** — sample members and reports (shown with a "Sample" badge). After #5.

6b. ⏳ 👤 🔒 **Clinical review of built-in ranges** — docs/REFERENCE_RANGES.md (edition 2026-10) signed off by a clinician/lab professional.
6c. ⏳ **Sex on family profiles** — ✅ asked when adding. Still to do: editing it (with #5). *(with P0b)*
6d. ⏳ **Pediatric ranges** — adult-only ranges are skipped for under-18s (except the WHO haemoglobin cut-off). Needs clinical sources.
6e. ⏳ **Range signing key** — generate the Ed25519 key pair before shipping server-side range updates; range notes are English-only (localise with the rest).

## P0b — family sharing & encrypted Sync (docs/SHARING.md) — next, awaiting go-ahead 🔒

- ✅ Crypto core: profile keys, wrap for account, invite links (+ tests)
- ⏳ Account key pair + recovery key
- ⏳ Sync v2 (sealed push + pull, tombstones) — replaces plaintext Sync; drop the old `reports` / `lab_results` tables
- ⏳ Invites: share link, app links on the invite domain, claim screen, combine duplicates
- ⏳ Family card: access list, pending invite, leave / remove
- ⏳ 👤 Decide the invite domain (`InviteLink.host`)

## P1 — product gaps

7. ✅ **Android OCR** — ML Kit + `PdfRenderer` in `MainActivity.kt`, sign-in deep link in the manifest. Still to verify on a real Android phone.
8. ✅ **"Needs review" resolution** — "Looks right" marks a result checked (`LabResult.reviewed`, phone-only) without marking it edited; the report turns Ready once nothing awaits review.
9. ⏳ 👤 **Document scanner camera** — ✅ "Scan with camera": VisionKit (iOS, builds) / ML Kit document scanner (Android), PDF out, plain camera fallback. Still to do: download `play-services-mlkit-document-scanner` (Gradle gets 403 on the office network — **the Android build fails until this is fetched once**, e.g. on a phone hotspot), then try both on real phones.
10. ⏳ 🔒 **Restore from cloud** — Sync is push-only. Part of Sync v2. *(with P0b)*
11. ⏳ 🔒 **Deletes don't sync** — tombstones in Sync v2. *(with P0b)*
12. ⏳ 🔒 **Account deletion in-app** — App Store rule; Edge Function `delete-account`. *(with P0b)*
13. ⏳ **Settings** — ✅ theme, accent, Simple mode, Home sections. Still to do: language picker (with #14).
14. ⏳ **More languages** — `lib/l10n/app_hi.arb` etc.; a native speaker should check. Test names stay as printed.
15. ✅ **"See all" on Home** switches to the Categories tab.

## P2 — hardening

16. ✅ **Encrypt local data at rest** — AES-256-GCM, keys in Keychain/Keystore, originals behind Face ID/passcode, plaintext temp copies deleted after storing.
17. ⏳ **Scale local store** — single JSON file rewritten on each save (`ponytail:` in `local_report_store.dart`); move to sqlite/drift when histories get large.
18. ⏳ **Parser edge cases** — ✅ Indian-grouped ranges, "L" of `µL` read as Low, count spans (`2-3 /hpf`), range on the next line, two tests side by side, sex-banded ranges (kept whole, left for review). Still open: pick the band from the member's sex, age-banded ranges, non-English reports.
19. ✅ **Duplicate uploads** — SHA-256 of the file (phone-only) per member; "You've already added this report" with View, or a retry if it had failed.
20. ⏳ 👤 🔒 **Privacy policy & store disclosures** — DPDP Act, medical disclaimer, App Privacy labels, Play Data safety + Health apps declaration (docs/GO_LIVE.md §5).
21. ⏳ 👤 **Design review** — animations and layouts; accessibility pass (Dynamic Type, VoiceOver labels, dark-mode contrast).
22. ⏳ **Dependency upgrades** — ~40 newer package versions; Flutter itself is old. Needs a full retest.

## Later (planned, not started)

- **Scans & imaging** (X-ray, CT, MRI, ECG): store and view images, read the radiology report's Impression; DICOM with patient details stripped as a second step. Waiting for the go-ahead.
- **Apple Health / Google Fit import** — docs/HEALTH_APPS_SYNC_PLAN.md.
- Known build quirk: on Xcode 27.1 `flutter build ios --simulator` fails a two-architecture `lipo` check; use `flutter run` or an arm64-only `xcodebuild` (docs/GO_LIVE.md §6).

## How to verify after changes

```bash
flutter analyze && flutter test
graphify update .        # refresh graphify-out/ for other agents
```
