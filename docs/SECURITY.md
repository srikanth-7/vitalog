# SECURITY — Vitalog

*Created 2026-10-24 after the first full security audit. Companion docs:
`AUTH.md` (how sign-in works and fails), `DATA_SECURITY.md` (where data
lives and who can read it), `THREAT_MODEL.md` (who might attack and what
stops them), `SECURITY_CHECKLIST.md` (executable gates). The audit and the
phased remediation plan live in `../opencode/plans/`.*

## What we are defending

A family health record. The content of lab reports — names, values, test
results, medicines implied by ranges — is the asset. Medical data outranks
almost every other datapoint a phone holds: loss of confidentiality is
steady harm forever (insurers, employers, vaults of leaked health corpora).

## The five rules

1. **On-device first.** Reading (OCR on Apple Vision / ML Kit) happens on the
   phone. Nothing about a report leaves the device unless the user taps
   **Sync** (AGENTS.md hard rule; enforced today, servers can't push/claim
   anything because nothing is sent).
2. **Never trust the client.** Every row the server stores is owned by the
   authenticated user; RLS on the server is the enforcement point, never
   app-side checks.
3. **Encrypt what leaves.** Sync v1 sends the minimum (redacted field set —
   `report_sync_service.dart`). Sync v2 must seal everything before it hits
   the wire: profile keys + wrapped access per `docs/SHARING.md`.
4. **Keys stay on Keychain/Keystore.** Report encryption keys and now the
   Supabase session live in secure storage (`report_cipher.dart`,
   `secure_session_storage.dart`); nothing long-lived rides plaintext disk
   or backup.
5. **No secrets in the app.** Only the publishable key ships
   (`--dart-define`s, `supabase*.local.json`); service-role keys never enter
   the app, git history or docs (verified in the 2026-10-24 audit).

## Current status (honest summary)

| Area | State |
|---|---|
| Secrets | ✅ none in repo or history; publishable key only |
| Session storage | ✅ Keychain/Keystore now (`secure_session_storage.dart`) — Phase 1 of the hardening plan |
| Database access | ✅ RLS owner-scoped on the two v1 tables (schema.sql:65–79) |
| Plaintext health data on server | ⚠ v1 tables are plaintext by design; sealed Sync v2 (docs/SHARING.md) must land **before real data** syncs — the project's own gate |
| Server can mint access (v2) | ⚠ design gate: wrapped keys need authenticity (signed statements or TOFU) — decide before invites |
| Payments / LLM / analytics | n/a — none exist |
| Account deletion in-app | ⏳ App-Store requirement; Edge Function in PENDING_TASKS #12 |

## Where to look when something breaks or sounds scary

- What did I change today? → `../opencode/log/changes.md` (append-only)
- Why is X built this way? → `AUTH.md`, `DATA_SECURITY.md` each carry a
  "Decisions" table with dates
- Is this exploitable? → `THREAT_MODEL.md` (actors → mitigations → residual)
- Am I allowed to ship? → `SECURITY_CHECKLIST.md`, plus `GO_LIVE.md`

## Incident / key-rotation quick reference

| Event | Action |
|---|---|
| Supabase access token leaked (publishable key) | RLS still stands; rotate via dashboard **API keys → Rotate**, update dart-defines. Low urgency but do it same-day. |
| Service-role key suspected leaked | Emergency: rotate **immediately**, audit `storage.objects`/tables for foreign rows, force sign-out of all users (`auth.logs` → Sessions), then re-shortlink the publishable key anyway. |
| User reports phone lost | They sign out remote? Not possible remotely today (no user-facing session revoke) — they must change password; sign the session out via Supabase dashboard → users → sessions (manual). |
| Supabase project compromised | Restore isn't useful for v1 plaintext (attackers get plain rows) — assume breach, notify users (DPDP §8), rebuild on new project. |
