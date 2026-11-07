# Sharing family profiles — end-to-end encrypted

Decided 2026-10-23 (product owner). Supersedes the 2026-10-22 note that
"family names stay on the phone" for profiles that are **shared**; unshared
profiles still never leave the phone.

## Decisions

1. **No ownership.** Everyone linked to a profile has equal access: read,
   upload, correct values, invite. There is no owner or admin role.
2. **"You" is per account.** On Dad's phone his profile is his primary
   profile ("You"); on yours the same profile is "Dad". Relation and
   "this is me" are stored per account, never on the profile.
3. **End-to-end encryption.** The server stores only sealed data. It can't
   read names, sex, birth year, lab, test names, values, ranges or dates.
4. **No email matching.** Emails are never sent for matching (a hash of an
   email can be reversed by hashing known addresses). Inviting by email means
   sending the invite link from the user's own mail app.
5. **Links, not short codes.** An invite carries a 256-bit secret in the
   link's `#fragment`, which browsers and apps never send to a server. A
   6-digit code would be guessable against a stolen database.
6. **The name on a report** is still checked against the profile's name
   (warning only), on the phone, after decryption. It is never used to link
   accounts.

## Keys (implemented: `lib/features/family_health/data/sharing/sharing_crypto.dart`)

| Key | Made on | Stored | Purpose |
|---|---|---|---|
| Profile key (AES-256-GCM) | the phone that creates the profile | only wrapped (below) | seals everything about one profile |
| Account key pair (X25519) | each account's first phone | private: Keychain/Keystore; public: server | receives wrapped profile keys |
| Wrapped profile key | any phone with access | server, one row per (profile, account) | = access |
| Invite secret (32 random bytes) | inviting phone | only inside the shared link | opens the invite's wrapped key |

Sealed boxes are `nonce ‖ ciphertext ‖ mac`, with the row id as AAD so a box
can't be moved to another row. Wrapping uses an ephemeral X25519 key →
HKDF-SHA256 → AES-GCM. Tests: `test/privacy/sharing_crypto_test.dart`.

## Flows

**Invite.** On Dad's card → *Share Dad's profile* → the phone makes an invite
(`SharingCrypto.newInvite`), uploads `{id, wrapped_key, claim_hash,
expires_at}`, and opens the share sheet with
`https://vitalog.app/i/<id>#<secret>`. One use, expires in 7 days, can be
cancelled ("Invite pending" on the card).

**Dad has no account.** Link → store → install (deferred deep link; fallback:
paste the link / scan a QR on your phone) → sign in with any Google account
or email → *"[You] shared Ramesh Kumar (Dad) with you · 6 reports — This is
me / Not me"* → his phone opens the invite, wraps the profile key for his own
public key, marks it "You" in his account → Home shows his reports.

**Dad already has an account.**
- No profile of himself yet → same confirmation; the profile becomes his "You".
- He already made his own profile → after "This is me": *Combine them
  (recommended) / Keep separate*. Combining runs on his phone: his reports are
  re-sealed with the shared profile key, duplicates (same file hash) kept
  once, his old profile deleted, his spelling/sex/birth year kept. Others see
  "Ramesh combined his own reports into this profile."

**Claim check.** The server accepts a claim only if the claimant sends the
token whose hash equals `claim_hash` (`SharingCrypto.claimHashFor`), only
once, before `expires_at`, rate-limited per account and per invite.

**Leaving / removing.** Anyone can leave. Anyone can remove someone else
(equal access); everyone with access is notified. After a removal the next
upload rotates the profile key: new key, re-wrapped for the remaining
accounts, new data sealed with it. Data the removed person already saw can't
be taken back.

**Recovery.** Only phones hold keys. When Sync is turned on, the app offers a
one-time recovery key (print / password manager). Any family member with
access also keeps a working copy.

## What the server sees

Sees: account login emails (Supabase Auth), which accounts share which
profile id, number of reports, sizes, timestamps.
Never sees: names, sex, birth year, relation, lab, file names, test names,
values, ranges, dates, original documents, invite secrets.

## Server schema (Supabase)

```sql
create table account_keys (
  user_id uuid primary key references auth.users on delete cascade,
  public_key bytea not null                      -- X25519, 32 bytes
);

create table profiles (
  id uuid primary key,                           -- random, made on the phone
  sealed bytea not null,                         -- name, sex, birth year…
  updated_at timestamptz not null default now()
);

create table profile_access (
  profile_id uuid references profiles on delete cascade,
  user_id uuid references auth.users on delete cascade,
  wrapped_key bytea not null,                    -- profile key for this user
  sealed_meta bytea not null,                    -- relation, "this is me" (own key)
  key_version int not null default 1,
  primary key (profile_id, user_id)
);

create table invites (
  id text primary key,                           -- link id (not secret)
  profile_id uuid references profiles on delete cascade,
  wrapped_key bytea not null,                    -- opens only with the #secret
  claim_hash text not null,
  created_by uuid references auth.users,
  expires_at timestamptz not null,
  used_by uuid references auth.users,
  used_at timestamptz
);

create table reports (
  id uuid primary key,
  profile_id uuid references profiles on delete cascade,
  sealed bytea not null,                         -- report + its results
  key_version int not null,
  uploaded_by uuid references auth.users,
  updated_at timestamptz not null default now(),
  deleted boolean not null default false         -- tombstone for sync
);
```

RLS: a row in `profiles`, `reports`, `profile_access` is visible/writable
when `exists (select 1 from profile_access a where a.profile_id = … and
a.user_id = auth.uid())`. Invites are claimed only through an RPC
(`claim_invite(id, token)`) that checks the hash, expiry, single use and rate
limit, then inserts the claimant's `profile_access` row; no direct select on
`invites` except by `created_by`.

This replaces the plaintext `reports` / `lab_results` tables in
SUPABASE_REQUIREMENTS.md before any real data is synced.

## Build order

1. ✅ Crypto core + tests (`sharing_crypto.dart`).
2. 🟡 Account key pair + recovery key (`account_key.dart`).
3. 🟡 Sync v2: sealed push + pull (real deletes, not tombstones).
4. 🟡 Invites (2026-11-04): global profile ids, `invites` + `open_invite()`
   (supabase/schema.sql), long-press a member → *Share {name}'s reports* →
   *Invite someone* (uploads that member, opens the share sheet), claim
   screen (`claim_invite_screen.dart`), links via app_links, Family tab →
   *Open an invite link* (paste).
5. 🟡 Family card (`share_profile_sheet.dart`): who can see it, pending
   invites with Cancel, Remove someone. Leaving = removing the member from
   your phone (your access row goes; the data stays for the others).

### How it was built (differences from the flows above)

- **Claim screen** asks "Who is Ramesh to you?" with the relation chips
  (You, Parent, …) instead of a separate *This is me / Not me* step.
- **Relation is per account**: stored in your own `profile_keys.sealed_meta`
  (sealed with the profile key, with the name you go by — that's what the
  family card shows). It overrides the relation inside the shared profile box.
- **Invite preview** (who shared whom, report count) is sealed with the
  link's secret, so the claim screen can show it before anything is used up.
- **The claim token** is HKDF(secret, id, "vitalog/claim/v1"), sent as hex;
  the server stores `base64url(sha256(token))`.
- **Combine** (2026-11-06): accepting as "You" while the phone already has
  a "You" offers *Combine / Keep separate* on the claim screen.
  `combineMembers` moves the old profile's reports (unsynced, so the next
  Sync seals them with the shared key), drops a file already in the shared
  profile (same `fileHash`), keeps the old name/sex/birth year, photo and
  reminders, then leaves the old profile on the server. No notice to the
  others yet (see Notifications).
- **Removing a member from your phone** never deletes the shared reports on
  the server; deleting one *report* deletes it for everyone (equal access).

### Not built yet

- **Key rotation after a removal**: RLS already stops the removed account
  reading new rows; rotation only matters against a server breach plus an
  old key. ⏳ (`ponytail:` note in `report_sync_service.dart`)
- **Notifications** to the others on remove/combine. ⏳
- **Edits by others** to a report you already have don't replace your copy
  (the merge keeps the local row); new reports do arrive. ⏳
- **iOS Universal Links** need an Associated Domains entitlement, which a
  free (personal) Apple team can't use. Until then iPhones open the link's
  web page, whose button hands over via `com.vitalog.app://invite/…`.

### The invite domain (👤 open — steps in `docs/INVITE_DOMAIN.md`)

`InviteLink.host` (placeholder `vitalog.app`) and the `https` intent filter in
`AndroidManifest.xml` must name the same host, which serves `invite_site/`:
`invite.html` for `/i/*` and `.well-known/assetlinks.json` (+ the Apple file
once there's a paid team: replace `TEAMID`). `assetlinks.json` lists this
Mac's **debug** key; add the release key's SHA-256 before shipping.
`firebase.json` is ready for Firebase Hosting (`firebase deploy --only
hosting` from `invite_site/`); any static host with the same rewrite works.
