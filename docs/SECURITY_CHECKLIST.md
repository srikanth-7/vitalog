# SECURITY CHECKLIST — executable gates only

*Created 2026-10-24 (hardening plan). Anything not marked ✅ is pending;
owners: app = OpenCode sessions, 👤 = product owner, supa = Supabase
workstream (dashboard), both = coordination pair. Source audits live in
`../opencode/plans/`; event risk discussion lives in `THREAT_MODEL.md`.*

## Phase 1 — app hardening (audit High + Medium #1/#2)

- [x] Supabase session JSON stored in Keychain/Keystore
      (`lib/core/backend/secure_session_storage.dart`, `Backend.init` authOptions)
- [x] One-time migration deletes legacy plaintext session from
      SharedPreferences (unit-tested, `test/backend/secure_session_storage_test.dart`)
- [x] PKCE explicitly pinned; PKCE verifier moves to secure storage
      (`AuthFlowType.pkce` + `SecureGotrueAsyncStorage`)
- [x] `android:allowBackup="false"` in the manifest (no adb/cloud restore
      of the app container)
- [x] `flutter analyze` clean for the new/changed files
- [x] **Full `flutter test` green — 70/70** (verified under
      `flutter-clean` SDK, 2026-10-24 18:02; includes the 8 new storage
      tests + privacy/redaction/crypto suites)
- [ ] 👤 countersign the "Skip nonce check" tradeoff (AUTH.md §Google) so
      PENDING_TASKS #2 closes with eyes open

## Phase 2 — one-time, dashboard gates (before ANY real data) 👤/supa

- [ ] RLS sweep: `DO $$ … ENABLE ROW LEVEL SECURITY … $$` over
      `public.*` of every new project (current two pass manually)
- [ ] Return `true` for "no `anon` policies": `select * from pg_policies
      where roles @> '{anon}'` → expect 0 rows
- [ ] Email auth ON with **confirm email** ON, min password **8**,
      generic "already registered" response accepted then CAPTCHA on
      **before prod**: GoTrue captcha flag ON
- [ ] Redirect allow-list EXACTLY: `com.vitalog.app://login-callback`
      (no wildcards, no production URLs on staging project)
- [ ] Google provider: both client ids declared; "Skip nonce check" ON only
      consciously (AUTH.md)
- [ ] Third-party auth token block: `third-party-auth` OFF unless used
- [ ] Point-in-Time Recovery ON for the prod project (backups) — Supabase
      plan features, revisit tier
- [ ] Secrets rotation discipline: dashboard password changed after challege
      (typed in a chat session on 2026-10-24 ⚠), 2FA on the Supabase
      account, API keys rotated on schedule, service-role key never on a dev
      laptop
- [ ] `cleanup_test_data.sql` bulk-delete section removed once dev is clean
      (supa)

## Phase 3 / P0b — Sync v2 + sharing (docs/SHARING.md)

- [ ] Sync v2 schema implements: sealed bytea columns, profile_access with
      wrapped keys, `claim_invite` SECURITY DEFINER `SET search_path=''`,
      single-use, expiry, deny-by-default RLS on all new tables
- [ 👤 Decision recorded: key authenticity = signed statements OR
      TOFU + change warnings) — mandatory before invites ship
- [ ] Invite links blocked until Android App Links + iOS Universal Links run
      on the final domain (`InviteLink.host` placeholder today)
- [ ] Plaintext `reports`/`lab_results` tables DROPPED after v2 lands;
      `cleanup_test_data.sql` updated in lock-step
- [ ] Recovery key UX shipped (print/export) so "only phones hold keys"
      has an exit ramp 👤 product call on wording
- [ ] Account deletion Edge Function (`delete-account`) + test of cascades
      (App Store 5.1.1(v), DPDP right to erasure)

## Every release (manual review passes)

- [ ] `grep rniE "(sb_secret_|service_role|sk-[A-Za-z0-9]{16,})
      [etc]"` over repo + build outputs = 0 hits (skill secrets-and-env)
- [ ] `flutter analyze` stays at 3 pre-existing SDK-deprecation infos or
      fewer (no NEW issues; 60+ tests still green)
- [ ] Privacy tests still assert the redaction contract
      (`test/privacy/`), and no new egress path snuck in
      (grep `from('` in `_client` calls = upserts only, sync service)
- [ ] Dependency bump audit: only if lock diff reviewed line by line
      (THREAT_MODEL T-9) — hold the 40-upgrade batch (#22) until after P0b
- [ ] No new permissions in AndroidManifest/Info.plist beyond
      camera/photo-library/file-pickers already declared

## Refusal gates ("can't ship while open")

Gates that a release MUST NOT pass while the item is unchecked:

| Gate | Checked by | Champion |
|---|---|---|
| Plaintext tables hold real data | SQL row-count of `reports`/`lab_results` | both |
| V2 key authenticity undecided | SECURITY.md/THREAT_MODEL status tables | 👤 |
| CAPTCHA off in prod | dashboard auth config | supa |
| INVITE domain without App Links | `InviteLink.host` + hosting config | 👤 |
| Machine state broken (tests can't run) | `flutter test` exit 0 | both |
