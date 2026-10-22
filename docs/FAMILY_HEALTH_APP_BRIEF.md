# Vitalog — Family Health App Brief

## Product idea

Vitalog is a private family health-record app for collecting laboratory reports and following test results over time. A user selects a family member, adds a PDF or photo of a lab report, and sees its extracted results organized by category and report date. Reports remain on the device by default. Cloud backup is an explicit user action.

The app helps people find and compare what their laboratory reports say. It is not a medical provider and must not diagnose conditions or invent a health score.

## Current product direction

The supplied `vitalog.zip` is the current implementation/source of truth. It defines an **offline-first** design:

- Original reports and extracted health data are stored locally and encrypted at rest.
- Report text extraction and OCR run on the device. On iOS, the archive uses Apple Vision; Android OCR remains a pending task.
- Supabase is used for sign-in and optional backup only when the user explicitly taps **Sync**.
- The current direction does not send report content to cloud OCR or AI. Do not add cloud OCR/LLM processing without the owner’s explicit decision.
- Reports that the parser cannot confidently interpret are marked `needsReview`. The archive currently says there is no manual data entry by design; see `docs/PENDING_TASKS.md` for the unresolved review flow decision.

This replaces the earlier server-side OCR/AI proposal for the current project version.

## Main features

- Family profiles and profile switching.
- Dashboard with categories and recent report results.
- Report upload from camera, photo library, or PDF picker.
- On-device parsing of test names, values, units, printed reference ranges/status, lab name, report date, and collection date when available.
- Categories: Blood/CBC, Glucose, Kidney, Liver, Lipid, Thyroid, Vitamins, Iron, and Urine. One result may have multiple category IDs.
- Reports timeline with processing/review status; opening a report shows its results in a report-scoped dashboard.
- Chronological history and trend charts for comparable results.
- Google or email/password authentication and user-triggered Supabase sync.

Family member records are still sample data in the archive. Real family-member management and robust shared-family permissions are future work.

## Data and safety requirements

- Keep report date, sample collection date, and upload timestamp as separate values. Never substitute upload date for a medical date.
- Preserve result values, units, reference ranges, and abnormality flags as printed. A report value is not a diagnosis.
- Keep uncertain extraction results visibly marked for review; do not present OCR as authoritative.
- Keep report contents out of analytics, logs, and external AI/OCR services unless the owner approves a change in data handling.
- Never include Supabase service-role keys or other provider secrets in the Flutter app. Client builds may use only the public/publishable key and project URL.
- Supabase rows must be protected by Row Level Security. Any report-file backup must use private storage and owner-scoped access.

## Technology and architecture

- Flutter/Dart for iOS and Android.
- BLoC for presentation state.
- Clean architecture: presentation → domain contracts/use cases → data implementations.
- Supabase Auth, PostgreSQL, and RLS for optional cloud sync.
- Local encrypted report store and modular on-device extraction/parser components.
- Current app architecture and conventions are documented in `AGENTS.md`; backend setup is in `docs/SUPABASE_REQUIREMENTS.md`.

## Design direction

Use the supplied design references when available. Keep the UI polished, readable, responsive, and accessible, with clear status labels that do not rely on color alone. Support light and dark themes, respect reduced-motion/accessibility settings, and localize user-facing strings using the existing localization setup.

## Current repository state

- Existing Flutter repository and Git history are preserved; work remains on `family-health-architecture`.
- The supplied archive’s project files have replaced the prior prototype implementation. The archive’s bundled `.git` was not imported.
- Agent skills installed at `.agents/skills/` and the source setup kit at `docs/agent-kit/` were retained.
- This environment has not run the replaced app. The user plans to run it on their Mac.
- The archive included generated iOS environment files pointing to another machine; those were removed so Flutter can regenerate them locally.
- `docs/PENDING_TASKS.md` is the current prioritized task list. Do not assume every “done” item in the archive has been independently verified in this checkout.

## Recommended next steps

1. On the user’s Mac, run `flutter pub get`, then `flutter analyze` and `flutter test` as documented in `AGENTS.md`.
2. Run the app in the iOS simulator and review the main dashboard, profile switching, report picker, OCR/review states, history, and theme behavior.
3. Fix build/runtime issues and gather product feedback before configuring Supabase.
4. Follow `docs/SUPABASE_REQUIREMENTS.md` to configure a Supabase project and verify sign-in, RLS, and explicit Sync. Never put a service-role key in the app.
5. Prioritize Android OCR, review resolution, family-member management, restore/pull, delete sync, and other remaining work from `docs/PENDING_TASKS.md`.

## Instructions for future agents

- Read `AGENTS.md` and the relevant docs before changing code.
- Inspect the current branch, working tree, and relevant implementation first. Preserve Git history and unrelated local files.
- Keep the offline-first and user-triggered sync behavior unless the owner explicitly changes it.
- Do not run the app or simulator without the owner’s go-ahead. Report exactly which checks were run and whether they passed.
- Do not add paid services, upload real reports, or expose secrets without explicit approval.
