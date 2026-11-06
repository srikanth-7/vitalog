# Security hardening plan — Vitalog

*Created: 2026-10-24 · Session: ses_e92690c9dffeEwlTVXAabr6Fep (swift-garden)
· Audit source: `plans/2026-10-24-security-audit.md`
· Coordinates with Supabase workstream: session ses_e928512f0ffe5ye7NZhiz2b9eT ("main-supabase")*

## Status

| Phase | Item | State |
|---|---|---|
| 0 | Coordination & hygiene | ✅ 18:28 — android unstubbed + ignore lanes + audit redaction (staged, owner holds commit/push); `graphify update .` still pending (no CLI) |
| 1 | App-side hardening | ✅ **COMPLETE** (2026-10-24 18:02): code done + `flutter test` **70/70 green** + analyze clean; only 1.4 nonce countersign await the owner |
| 2 | Supabase workstream handoff checklist | ⏳ awaiting staging/prod projects |
| 3 | Sync v2 security gates | ⏳ blocked on P0b go-ahead |
| 4 | Launch 🔒 leftovers | ⏳ |

## Ground rule — two workstreams, one repo

The **Supabase workstream** (main-supabase session) owns the dashboard, orgs,
projects, keys, auth settings. **This plan** owns app code, crypto, repo docs.
Before touching shared files (`supabase/*.sql`, `supabase.local.json`,
`docs/HANDOFF.md`), re-check that session's latest state. If it is mid-turn,
wait; if idle, proceed and announce in `log/changes.md`.

**Snapshot of that session at plan creation:** idle. Created org
"Vitalog Apps" (`hlkaxbaeeckmyontiyni`); Management-API project creation
blocked (403 "Resource context not found") — staging/prod must be created
manually in the dashboard; region planned `ap-south-1`; free-tier
2-active-project limit flagged. **No staging/prod keys exist yet.**

## Phase 0 — Coordination & hygiene (no repo changes)

| # | Item | Owner |
|---|---|---|
| 0.1 | Rotate Supabase dashboard password (was typed into a chat log) + enable 2FA/MFA 👤 | product owner, after infra setup |
| 0.2 | Never edit `supabase/*.sql`, `supabase.local.json`, `docs/HANDOFF.md`, or the dashboard live without checking the other session's state first | both |
| 0.3 | Free-tier math: dev (plaintext v1) + staging + prod = 3 > 2. Keep dev until Sync v2 schema is ready, then **delete the plaintext dev project** (stays in limits + removes plaintext attack surface) 👤 | product owner |

## Phase 1 — App-side hardening (start now, no Supabase dependency)

| # | Item | File(s) | Acceptance |
|---|---|---|---|
| 1.1 | Secure session storage: `FlutterSecureStorage`-backed `LocalStorage` (implement the package:gotrue `LocalStorage` contract), wired via `FlutterAuthClientOptions` in `Backend.init` | `lib/core/backend/backend.dart` + new file | After restart the session restores; `sb-*-auth-token` key no longer exists in SharedPreferences |
| 1.2 | Android backup hardening: `allowBackup` off or `dataExtractionRules` excluding app data; iOS unchanged (Keychain-backed) | `android/app/src/main/AndroidManifest.xml`, `android/app/src/main/res/xml/` | `adb backup` yields nothing for this app |
| 1.3 | Pin PKCE: explicit `authFlowType: FlowType.pkce` + comment forbidding implicit; move `pkceAsyncStorage` to secure storage too | `backend.dart` | Comment + test asserts the flow |
| 1.4 | Decision record for "Skip nonce check": document the 1-hour replay-window tradeoff in AGENTS.md and `docs/SUPABASE_REQUIREMENTS.md` §2 **after checking main-supabase session isn't mid-edit of those docs**; 👤 sign-off | AGENTS.md, docs | Recorded where dashboard setup happens |
| 1.5 | Tests: session restore round-trip; cipher unaffected | `test/` | `flutter analyze && flutter test` green |

## Phase 2 — Handoff checklist for the Supabase workstream

Fold into `docs/PENDING_TASKS.md` #1/#2. In dashboard order, per env
(staging then prod):

1. Create `vitalog-staging` / `vitalog-prod` **manually** (API blocked),
   region `ap-south-1`, strong DB password.
2. Apply `supabase/schema.sql`, then run the RLS completeness sweep
   (`DO $$ … ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY … $$` loop) to
   catch any unlisted table; confirm no `anon` policies.
3. Auth: email confirm **on**, min password **8**, **CAPTCHA on sign-up
   before prod**, redirect URL `com.vitalog.app://login-callback`.
4. Google provider: both client ids + consciously-accepted
   "Skip nonce check" (per Phase 1.4).
5. Key hygiene: `supabase.staging.json` / `supabase.prod.json` passed via
   `--dart-define-from-file`; git-ignored; publishable key only;
   service-role key touched only server-side, never in the app.
6. PITR/daily backups; keep report contents out of logs
   (`SUPABASE_REQUIREMENTS.md` §5).
7. When Sync v2 schema ships: **drop plaintext `reports`/`lab_results`**,
   re-run the RLS sweep, and check `cleanup_test_data.sql` is updated (see
   Phase 4).

## Phase 3 — Sync v2 security gates (slots into P0b; items #10, #11, #12)

Build order lives in `docs/SHARING.md`. This plan adds gates on top:

1. **Server schema** per `SHARING.md` with hardening baked in, not bolted on:
   length/data caps on all columns, `CHECK`-constrained ids,
   `claim_invite` RPC done right (`SECURITY DEFINER` + `SET search_path = ''`,
   single-use, expiry, rate limit per user *and* per invite), no direct
   `invites` SELECT except for `created_by`.
2. **Key authenticity** (audit Medium #3: a compromised DB can mint wrapped
   keys as `postgres`): 👤 product-owner decision between **signed key
   statements** (device signs pubkey; claimant verifies) and **TOFU pinning +
   change warnings**. Decide **before** invites ship.
3. **Client work** follows SHARING.md order: account key pair + recovery key
   → sealed push/pull → tombstones → invites → family card
   (`PENDING_TASKS.md` P0b bullets).
4. **Decommission**: drop plaintext tables, delete the bulk-delete section of
   `cleanup_test_data.sql`, resolve Phase 0.3 project deletion.

## Phase 4 — Launch 🔒 leftovers

- Invite domain chosen + Android App Links / iOS Universal Links **before**
  invites go live (`sharing_crypto.dart:143`, P0b bullet 5).
- Dashboard password rotated + 2FA on (0.1); CAPTCHA live in prod;
  email-enumeration limitation accepted/known.
- Column caps verified live; final re-audit with `@vibe-security` against
  the v2 schema; empty "Vitalog Apps" org deleted from dashboard manually
  (5 seconds, Settings → Delete org — flagged by the main-supabase session).

## Verification after any change (project rule)

```bash
flutter analyze && flutter test && graphify update .
```
