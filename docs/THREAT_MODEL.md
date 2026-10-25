# THREAT MODEL — Vitalog

*Created 2026-10-24 from the first full audit (STRIDE-flavoured, pragmatic);
maintained as new surfaces appear. Status column marks what is actually
enforced TODAY vs pending in the hardening plan (../opencode/plans/).*

## Assets prioritized

1. **A1 Report content** — names, values, dates, lab, photo (worst: identity
   + health matrix). Never cost-looks: full compromise of health data.
2. **A2 Credentials** — auth refresh token = durable identity; local report
   decrypt keys.
3. **A3 Server availability & integrity** — rows wiped/tampered (backup sync
   is user trust).
4. **A4 Meta-data** — sync timing (already limited: manual sync only), email
   used for sign-up.

## Actors

| # | Actor | Capability (honest bounds) |
|---|---|---|
| 1 | Device thief / someone with the unlocked phone | Full app access while session lives; flash-drive reads |
| 2 | Rooted/jailbroken device holder | Filesystem reads of app container; Keychain on rooted iOS via keychain dump tooling |
| 3 | The device-side attacker (any installed app) | Public API surfaces only (no IPC); iOS extensions, Android intents, deep links |
| 4 | Network attacker | TLS break attempt, DNS poison (unlikely with HSTS via supabase.co) |
| 5 | Supabase platform access-looker | Row reads at the DB, platform logs unless encrypted |
| 6 | Compromised server / DBA / privileged token | Full DB writes as postgres, can mint/graft v2 wrapped keys, platform-native configuration abuse |
| 7 | Fellow family member with access (share) | All that sync/seal grants — no "admin" layers |
| 8 | Backend phishing attacker (person, e.g. "rep") | Contrast-messagee factoring access? includes social vector: needs educated user (SSO and 'account numbers' granularity) |
| 9 | Supply chain (Flutter/dart packages, Xcode toolchain, Google config) | Injected code at build/run — out of scope except for direct app-repo checks |

## Attack surfaces, mapped to mitigations

### T-1 Stolen unlocked device (A1+A2)
- Local reports + originals AES-256-GCM keyed from Keychain/Keystore
  (`report_cipher.dart`); originals additionally behind `userPresence`
  (Face ID/passcode) — thief without biometrics reads NOTHING after the
  session closes.
- Supabase session now also secure-stored, NOT in SharedPreferences
  (audit High #1; `secure_session_storage.dart`).
- Residual: 5-min window while a session is live with passcodeless phone.
- Mitigation pending: remote session revocation UX (BLOCK) — track as
  PENDING #27 (Supabase dashboard users.sessions actions are the manual
  answer for now).

### T-2 Rooted Android / repo backup dump (A2)
- Keystore-backed key wrapping (flutter_secure_storage defaults: RSA-OAEP
  key wrap + AES-GCM storage; `first_unlock_this_device` on iOS, so
  i wonder never leaves iCloud backups).
- `android:allowBackup="false"` stops `adb backup`/cloud restore attacks
  against settings.json and any not-yet-encrypted caches.
- Residual: a rooted user is root; assume-blamed as out-of-scope
  (documented, not fixable app-side).

### T-3 Curious app on the phone (deep links/claim)
- Only one exported activity; the `com.vitalog.app://login-callback` scheme
  can be claimed by any app **on iOS (competition) and Android (no
  autoVerify for custom schemes)** → PKCE pinned + verifier in
  secure storage keeps the intercepted code unusable (AUTH.md §PKCE).
- Sync v2 invite links: secret rides ONLY in `#fragment` — never sent to
  the server (SHARING.md Rule 5); claim RPC server-side triple-checks.
- Residual: iOS Universal Links/Android App Links for the FUTURE invite
  domain (`InviteLink.host` TERM placeholder today) — needed before invites
  ship (SECURITY_CHECKLIST §before-invites).

### T-4 Network / server MITM (A1 in v1, nothing in v2)
- All sync over TLS to `*.supabase.co`; no custom TLS pinning beyond what
  Supabase itself provides; session refresh pinned through the SAME
  request path internally (GoTrue refresh itself, no shield rerouting).
- In v1 the server knows plaintext health fields — residual HIGH handled by
  the "v2 before real data" gates (SHARING.md preamble 2026-10-23).

### T-5 Compromised Supabase platform staff / DBA (A1 v1, v2 partial)
- v1 plaintext = full read of every user's reports (assume-breach);
  v2 by design: only sealed blobs and wrapped keys.
- **Open, known** (audit Medium #3): direct-SQL actors can bypass claims
  (mint access via `account_keys` + `profile_access`). Fix on the pending 👤
  call (signed device key statements or TOFU on key rotations).
- Hardening in the v2 Makefile that remains INDEX: RLS sweep on new tables +
  `SECURITY DEFINER SET search_path=''` + no direct-table grants for
  claimants.

### T-6 Someone else's user accidentally paired (guest invite)/(A1)
- "Wrong person?" report assignment is manual and phone-side only
  (no server-side family-link matching in v1; invites in v2 carry ONE claim
  hash — one-use, expiry, per-invite and per-user rate limits).

### T-7 Email enumeration (A4, low)
- signUp/upload endpoints can distinguish existing emails to a scripted
  restroom inside Supabase rate limits. Accepted; revisit when shift;
  CAPTCHA ship.

### T-8 Server-side deleted-data gloating (A3)
- Supabase PITR req on prod farm (SECURITY_CHECKLIST "one-time").
- `cleanup_test_data.sql` unlocks bulk deletes with the dashboard password —
  delete that section after dev clean; avoid production share.

### T-9 Supply-chain trust in helpers (A1-A2)
- `flutter_secure_storage`, `cryptography`, `supabase_flutter` are pinned by
  pubspec.lock checksums (sha256 in lock file). Update cadence: reviewer
  must scan `flutter pub deps -- --no-dev` and re-run the privacy tests on
  any bump (PENDING_TASKS #22 — bash for now: hold the upgrades).

### T-10 Analytics/telemetry creep (A1)
- None exists; AGENTS.md hard-with-sign-off rule stays. The metric what
  would genuinely violate user trust: adding crash reporters that stream
  report text. Locked out by review (checklist §every-release).

## Accepted risks (signed-off, revisit date)

| Risk | Bound | Revisit when |
|---|---|---|
| Nonce-less Google ID tokens (1 h replay) | small, native flow only | google_sign_in nonce support lands |
| Vault stopgap on passcode-less phones | one hardware class | OS marketshare shifts |
| Email enumeration via GoTrue | low-severity | CAPTCHA/paid plan rollout |
| Server can act even in v2 (until key-authenticity) | server-compromise scale | 👤 decision on signing vs TOFU (before invites) |
| Plaintext v1 tables alive | **must be empty** when real data arrives | Sync v2 decommission step |

## Out of scope (explicit)

- Rooted/jailbroken device inside defeats (T-2 residual).
- Server-side availability/DoS beyond GoTrue and RLS sweeps (platform SLA).
- Whatever runs outside our repo (Google account hygiene, OS bugs).

Review cadence: re-run `@vibe-security audit` after any auth, sync, or
crypto change; before every store release; after P0b/Sync-v2 phases land.
