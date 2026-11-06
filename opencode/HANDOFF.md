# HANDOFF — read this first

*Last updated: 2026-10-25 10:33 IST · by session ses_e8e9c8e61ffeU3fTg4DeazApnP ("brave-cactus")*

## Where things stand right now

| Workstream | State | Owner session |
|---|---|---|
| Security audit of app + Supabase | ✅ done (read-only) — `plans/2026-10-24-security-audit.md` | ses_e92690c… "swift-garden" |
| **Security hardening Phase 1** | ✅ COMPLETE 18:02: keychain session storage + migration, PKCE pin, `allowBackup=false` — **`flutter test` 70/70 green**, analyze clean (evidence in log). Only the owner countersign on "skip nonce" remains | ses_e92690c… "swift-garden" |
| Security docs (5) | ✅ SECURITY / AUTH / DATA_SECURITY / THREAT_MODEL / SECURITY_CHECKLIST in `docs/` (18:50) | ses_e92690c… "swift-garden" |
| Supabase staging/prod infra | ⚠ dashboard manual creation still pending (Management API 403); org "Vitalog Apps" exists | ses_e928512… "main-supabase" |
| Test environment | ✅ unblocked by MAIN-SUPABASE 17:55 (zombie dartvm processes killed; PATH flutter's cache was half-extracted; `flutter-clean` is complete) + swift-garden 17:48 (ownership sweep + snapshot copy) — run tests with `~/Developer/flutter-clean/bin/flutter test` | both |
| Sync v2 / sharing (P0b) | ✅ **Do this first, owner: open the staging SQL Editor and run `supabase/schema_restore.sql`** — the minimal restore build is finished 2026-10-25 10:33 (pull reports+results+members → under-lock merge (local wins) → push; usual ranges re-judged; restore notice; 4 tests, analyze + **74/74** green). PostgREST probe says the table is missing on **both** staging and dev, so Sync will show "Sync failed" there until the SQL runs. Full sealed v2 still 📋 PLANNING (`plans/2026-10-24-sync-v2.md`, awaiting owner sign-offs) | ses_e8e9c… "brave-cactus" |
| Repo hygiene / push readiness | ✅ DONE and superseded by commits: `4fdae0a` absorbed the 27-file staged set (android port incl. allowBackup=false + wrapper), `30eb378` lifecycle; tip `30eb378`; worktree now holds the 2026-10-26 vault/biometric batch (uncommitted, 82/82 green per swift-garden 20:13) | ses_e92690c… "swift-garden" |
| Security batch (2026-10-26, in-flight) | ⚠ awaiting owner: fixes for audit findings #1/#3/#9/#12/#13/#14 sit uncommitted (vault biometric + re-lock, 50 MB cap, zip-bomb cap, temp-copy discard, originals-lock UI); #2 (app-switcher cover) NOT attempted yet; #4 (member names synced) needs product call; #5/#6 stay gated | session unknown (zip handoff) + swift-garden verify |

## Known OpenCode sessions (this project)

| Session ID | Slug / title | Did what |
|---|---|---|
| `ses_e92690c9dffeEwlTVXAabr6Fep` | swift-garden | vibe-security install, full audit + docs, hardening plan, Phase 1 fixes, repo hygiene (android unstub), **2026-10-26: weekend reconciliation + 3 failing-test repairs, 82/82 green** |
| `ses_e928512f0ffe5ye7NZhiz2b9eT` | sunny-meadow / **main-supabase** | Supabase setup: dev project, schema, cleanup SQL, Management-API attempts for staging/prod (blocked by 403), org "Vitalog Apps" (`hlkaxbaeeckmyontiyni`) |
| `ses_e8e9c8e61ffeU3fTg4DeazApnP` | brave-cactus | Commit `30eb378` (server-side deletes, delete-account edge fn, auto-restore, keychain hardening); found edge fn NOT deployed on staging (404) — owner to deploy; 74/74 at its time |
| (unknown id — zip handoff) | security-fix session | `docs/SECURITY_AUDIT_2026-10-26.md` + `HANDOFF_SECURITY_2026-10-26.md`; in-flight vault/biometric/size-cap batch left in the worktree (89/89 claim not reproducible in tree) |

To catch up on a session without its chat transcript, its messages live in
OpenCode's local DB (`~/.local/share/opencode/opencode.db`, table
`session_message`), or the agent can read the shared log below.

## Active-workstream coordination (two workstreams, one repo)

- **Supabase workstream** (main-supabase session): dashboard, org/project
  creation, keys, auth provider settings.
  - **Conflict zones:** `supabase.local.json`, `supabase/*.sql`,
    `docs/HANDOFF.md`, the dashboard itself.
  - Before touching any of those, verify that session's latest state.
- **Security workstream** (this plan): `lib/core/backend/`,
  `report_cipher.dart`, `sharing_crypto.dart`, Android manifest, new docs.
  Safe to run in parallel — touches nothing the Supabase workstream edits.

## Open questions for the product owner 👤

1. **Free tier = 2 active projects**, dev project already counts as one.
   Recommended: keep dev until Sync v2 schema is ready, then delete the
   plaintext-v1 dev project (also removes the plaintext attack surface).
2. **Rotate Supabase dashboard password** (it was typed into a plain chat
   log) + enable 2FA/MFA on the account. Do this after infra is set up.
3. **"Skip nonce check"** on Google provider: accepted 1-hour ID-token
   replay window (tooling limitation of google_sign_in v7) — needs a
   conscious sign-off; recorded in plan Phase 1.4.
4. **Sync v2 key authenticity**: signed key statements vs TOFU pinning —
   decide before invites ship (plan Phase 3.2, see audit Medium #3).
5. **Invite domain** for `InviteLink.host` (also tracked in
   `docs/PENDING_TASKS.md` P0b).

## If you take over, start here

1. Read `plans/2026-10-24-security-hardening.md` (Phase 1: code done,
   verify = full `flutter test`) **and** `plans/2026-10-24-sync-v2.md` (the
   newer main-supabase plan awaiting sign-offs).
2. Entry format for any change: see `log/changes.md` header — append-only,
   newest first, session ID mandatory.
3. Verify after code changes
   (`~/Developer/flutter-clean/bin/flutter analyze && flutter test`,
   then `graphify update .`). Never run flutter as root; if a lock file
   blocks you, check `ps aux | grep dart` for zombies first.
4. Docs are split by owner: `docs/SECURITY*.md`, `AUTH.md`,
   `DATA_SECURITY.md`, `THREAT_MODEL.md` are the security workstream's
   (early state lives beside); Supabase dashboard changes belong to
   main-supabase checkpointing in `docs/HANDOFF.md`.
