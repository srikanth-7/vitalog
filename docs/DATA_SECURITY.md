# DATA SECURITY — where health data lives and who can see it

*Created 2026-10-24 (hardening plan). Cross-references: `SHARING.md` (Sync v2
sealed design), `SUPABASE_REQUIREMENTS.md` (server expectations),
`../opencode/plans/2026-10-24-security-audit.md` (found issues).*

## Data map

| Where | What | Protection |
|---|---|---|
| Documents dir, app container | `reports.json` (tests/values/dates), `category_choices.json`, members | AES-256-GCM, key `fammo.reports.key.v1` in Keychain (FAMMO1 tier) |
| Documents dir | Original lab reports/photos/PDFs — the only place names/phones/addresses exist | FAMMO2 **vault** tier: `fammo.vault.key.v1` behind Face ID/passcode (`userPresence`), never leaves the device, never backed up; on passcode-less phones falls back to FAMMO1 (documented tradeoff) |
| In memory only | Decrypted originals for OCR/compare — never re-disked | process lifetime |
| Supabase `reports`, `lab_results` (v1) | Redacted test names/values/ranges/dates; file name → `report.<ext>` | RLS owner-only by auth.uid, TLS in flight; plaintext at rest server-side ← ← state under change |
| Supabase v2 (`SHARING.md`) | Sealed blobs + wrapped keys + claim hashes | E2E: server stores only ciphertext it can't open |
| Keychain (`fammo.*`) | Local encryption keys, X25519 account private key (v2) | device-bound; never synced |
| `settings.json` | theme/simple-mode/hidden sections/onboarding/offboarded | *not* health data, intentionally unencrypted |

## In-flight redaction (the only path data takes off-phone today)

`ReportSyncService.reportRow/resultRow` `report_sync_service.dart:30-54` is
the **single** egress point:
- `file_name` → `report.<ext>` (sanitized extension, 1–5 alphanum),
- `lab` → `Redactor.labName` (cut at the first address/phone/email marker),
- test `name` → `Redactor.text` (strips phone/email/URL from unknown names),
- **never sent:** OCR text, original files, patient name (`patientName` is a
  phone-only column on `HealthReport`), profile member names (only opaque
  `profile_id`s for `FamilyMember`).
Redaction applied in the parser AND again in the sync row-builders
(defense-in-depth), covered by `test/privacy/`.

## Server-side access control (v1 tables, live)

```sql
-- schema.sql:65-79 — both tables, no per-table drift:
ALTER TABLE public.reports     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lab_results ENABLE ROW LEVEL SECURITY;
-- Owner-only, WITH CHECK so nobody can graft rows onto someone else's user_id:
CREATE POLICY "own reports" ON public.reports FOR ALL TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);
-- (same for lab_results)
```
- No `anon` policies exist: unauthenticated clients see nothing.
- Composite PKs `(user_id, id)` make cross-user collisions impossible.
- Anything added later MUST follow the same shape and get an RLS sweep —
  see `SECURITY_CHECKLIST.md` §"every table".

## Sync v2 — sealing replaces plaintext (in flight)

Per `SHARING.md` and hardening plan Phase 3:
- Profile key (AES-256) per family profile; account key-pair (X25519);
  wraps so that only the account's phone unwraps.
- **Server can't read anything** — and can't *act* either once
  key-authenticity ships (pending 👤 decision: signed key statements vs
  TOFU) — audit Medium #3: today the DB owner could still graft a wrapped
  key under its own account; RLS constrains API clients, not direct SQL.
- `claim_invite` RPC must be the only claim path: one-use, expiry, rate
  limit per user *and* per invite, `SECURITY DEFINER SET search_path = ''`.

## Retention, deletion, compliance

| Need | Mechanism |
|---|---|
| Remove one report | delete on phone → tombstone on next sync (v2) |
| Server delete of a user | `cleanup_test_data.sql` (dashboard-only, RLS-irrelevant, replace-me email placeholders; bulk-delete section to be removed after dev cleanup) |
| GDPR/DPDP erasure | PENDING_TASKS #12 Edge Function `delete-account`: deletes `auth.users` row → FK CASCADE of all v1 data; v2 data waits on the same gate |
| India DPDP Act 2023 | notices + consent surfaces; minimal egress (path above); no third-party processors today. HIPAA ⇒ only if US-market, requires Supabase paid add-on/BAA (SUPABASE_REQUIREMENTS §5) 👤 |
| Project backups | screenshots of plaintext backups only helpful with the same key; Point-in-time recovery set on prod project (checklist) |

## Concrete do-s (one-time, done or queued)

1. ✅ `flutter_secure_storage` for the auth session (was Supabase default
   plaintext — audit High #1).
2. ✅ `android:allowBackup="false"` in `AndroidManifest.xml`: no ADB/cloud
   backup of app data; Keystore keys don't survive restore anyway, so a
   restore copy of ciphertext plus no key would be worthless and of a.
   plaintext session was an occasional liability.
3. ⏳ Supabase-side: CAPTCHA before prod, no secrets in redirect URLs,
   email templates purged of destructive links (checklist §once-off).

## What we never do (hard rules)

- No third-party analytics/crash SDKs near report content (AGENTS.md hard
  rule; `THREAT_MODEL.md` T-10).
- Never log tokens, session JSON, or report values (`GO_LIVE.md` Log hygiene).
- Never call Supabase with the service-role key from Flutter. Any v2
  "unseal server-side magic" would be reviewed against rule 4 of SECURITY.md.
- Debug builds never point to the prod project (separate dart-define files,
  separate projects; the checklist blocks a prod build that has
  `allowUntrusted` debug flags).
