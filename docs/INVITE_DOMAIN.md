# Owning the invite domain

**Status:** ⏳ not started · **Owner:** product owner (buys the domain,
DNS, Firebase, Apple/Play consoles) + a developer (app change) ·
**Written:** 2026-11-06 · Tracks PENDING #27 "Own the invite domain".

> **Rule: nobody outside the team creates an invite until every box in
> "Done when" at the bottom is ticked.**

## Why this matters

An invite link looks like `https://<host>/i/<id>#<secret>`
(`InviteLink.toUri()` in `lib/features/family_health/data/sharing/sharing_crypto.dart`).

- The browser never sends the part after `#` to the server. But a page
  served from `<host>` can read it with JavaScript (`location.hash`). Our
  own `invite_site/public/invite.html` reads it to build the "Open in
  Vitalog" button.
- So **whoever controls `<host>` controls the page that opens the link.**
  If that isn't us, their page can read `id` + `secret`, claim the invite
  first, and get the member's profile key and **every report for that
  member**, now and in future syncs. The real recipient sees "already
  used".
- On Android the link skips the browser only once the app link is verified,
  and verification also depends on who controls the host.

The host today is the placeholder `vitalog.app`. **As of 2026-11-06 it is
registered by someone else**: it resolves to `185.104.28.27` and its
nameservers are `ns1/2/3-suspended.zxcs.*`, a suspended hosting account.
Treat it as hostile and pick a domain we can own (step 1).

## Where the host is used

Every one of these must name the same host:

| Place | What |
|---|---|
| `lib/features/family_health/data/sharing/sharing_crypto.dart` | `InviteLink.host = 'vitalog.app'` builds and accepts links |
| `android/app/src/main/AndroidManifest.xml` | `https` intent filter, `android:host="vitalog.app"`, `autoVerify="true"` |
| `invite_site/` | The site served on the host: `invite.html` for `/i/*`, `.well-known/assetlinks.json`, `.well-known/apple-app-site-association` |
| iOS (not added yet) | `applinks:<host>` in the Associated Domains entitlement |
| `test/privacy/sharing_crypto_test.dart:64` | A literal `vitalog.app` in a negative test |
| `docs/SHARING.md`, `docs/GO_LIVE.md` | Mention `vitalog.app` |

`com.vitalog.app://` (the app scheme) is **not** a domain. Leave it as is.

---

## Step 1 — Pick and buy the domain

**Options (product owner decides):**

| Option | Example | Notes |
|---|---|---|
| A. A new domain for the app | `vitalog-health.app`, `getvitalog.com`, `vitalog.in` | Also used for the privacy policy and support pages (`docs/GO_LIVE.md` §3). About $15 a year |
| B. A subdomain of a domain the company already owns | `invite.<company-domain>` | No purchase, but it ties the app to the company domain. Whoever runs that DNS can then take invites |

Whatever is chosen, check before buying:

1. Search at the registrar (Cloudflare Registrar, Google/Squarespace
   Domains, Namecheap, GoDaddy). It must show **available**, not "make an
   offer".
2. `dig +short <domain>` returns nothing, or only the registrar's parking
   page after you buy it.
3. Keep the name short: it ends up in every shared WhatsApp message.

**When buying (do every one of these):**

- [ ] Buy it in the **company's** registrar account, never a personal one.
- [ ] Turn on two-factor login for the registrar account; at least two
      team members have access.
- [ ] Turn on **auto-renew** with a company card, plus a calendar reminder
      30 days before expiry. *A domain that lapses gives the same attack to
      whoever buys it next.*
- [ ] Turn on **registrar lock** (transfer lock) and WHOIS privacy.
- [ ] Turn on **DNSSEC** if the registrar offers it.
- [ ] Note that `.app` and `.dev` only work over HTTPS (HSTS-preloaded).
      That's fine: Firebase Hosting gives a certificate.

From here on `<host>` means the exact host the links will use, for example
`vitalog-health.app` (no `www`).

---

## Step 2 — Host `invite_site/` on the domain

`invite_site/firebase.json` is ready for Firebase Hosting. It rewrites
`/i/**` to `invite.html` and sets the JSON content type for the Apple file.
It also sends `Referrer-Policy: no-referrer`, a strict CSP and `noindex`.
Any static host with the same rewrite and headers works. These steps use
Firebase.

### 2a. Deploy the site

The Google sign-in Firebase project can be reused, or create one named
`vitalog-invite`.

```bash
npm install -g firebase-tools       # once
firebase login                      # company Google account
cd invite_site
firebase deploy --only hosting --project <firebase-project-id>
```

Expect "Deploy complete!" and a `https://<project>.web.app` URL. Open
`https://<project>.web.app/i/AAAAAAAAAAAAAAAAAAAAAA#AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA`:
the page shows the "Open in Vitalog" card, not "This link is incomplete".

### 2b. Connect the domain

1. Firebase console → **Hosting** → **Add custom domain** → enter `<host>`
   (don't tick "redirect to another domain").
2. Firebase shows a **TXT** record. Add it at the registrar's DNS page →
   **Verify**.
3. Firebase shows **A** records (and sometimes AAAA). Add them exactly.
   Delete any parking A/AAAA/CNAME records the registrar added for the bare
   domain.
4. Wait for status **Connected**. The certificate takes minutes, up to
   24 hours.

### 2c. Check it from the Mac

```bash
curl -sI https://<host>/i/x | grep -iE 'HTTP/|referrer-policy|content-security-policy|x-robots'
curl -s  https://<host>/.well-known/assetlinks.json
curl -sI https://<host>/.well-known/apple-app-site-association | grep -iE 'HTTP/|content-type'
```

Expect: `HTTP/2 200` for all three; `referrer-policy: no-referrer`; the CSP
starts `default-src 'none'`; the Apple file has
`content-type: application/json` and **no redirect** (Apple won't follow
one).

---

## Step 3 — Point the app at the new host

Developer, one change:

1. `sharing_crypto.dart`: `static const host = '<host>';` and remove the
   `ponytail: placeholder…` comment above it.
2. `AndroidManifest.xml`: `android:host="<host>"` in the `https` invite
   intent filter.
3. `test/privacy/sharing_crypto_test.dart:64`: use `${InviteLink.host}`
   instead of the literal.
4. `docs/SHARING.md` (line 44 and "The invite domain"), `docs/GO_LIVE.md`
   §3: replace `vitalog.app`.
5. Check nothing still names the old host:

   ```bash
   grep -rn "vitalog\.app" lib android ios test invite_site docs | grep -v "com\.vitalog\.app"
   flutter analyze && flutter test
   ```

   Only historical notes may remain.

**Links made by older builds** still point at `vitalog.app`. They expire
after 7 days. Make sure no build with the old host reached anyone outside
the team. If one did, ask those people to update and to cancel pending
invites (family card → pending invite → Cancel).

---

## Step 4 — Android: verified App Links

Once verified, Android opens `https://<host>/i/…` straight in Vitalog and
never shows the web page.

### 4a. Put the right signing keys in `assetlinks.json`

`invite_site/public/.well-known/assetlinks.json` lists only this Mac's
**debug** key today. Get the SHA-256 of each key that signs a build
outsiders install:

| Key | Where to get the SHA-256 |
|---|---|
| Play App Signing key (what Play Store users get) | Play Console → app → **Setup → App integrity → App signing** → "App signing key certificate" → SHA-256. That page also shows a ready Digital Asset Links snippet |
| Upload key (if testers sideload the release APK) | `keytool -list -v -keystore ~/vitalog-upload.jks -alias upload` |
| Debug key (team testing only) | `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android` |

Put the release fingerprints in `sha256_cert_fingerprints`, upper case and
colon-separated. **Remove the debug key before the first outside tester.**
Debug keystores sit unprotected on laptops.

`package_name` must be the store id. Today that's `com.app.vitalog.dev`.
If the final id changes (`docs/GO_LIVE.md` §2.5), update it here too.

Redeploy (`firebase deploy --only hosting` from `invite_site/`) and check
with Google's checker:

```
https://digitalassetlinks.googleapis.com/v1/statements:list?source.web.site=https://<host>&relation=delegate_permission/common.handle_all_urls
```

Expect your package and fingerprint in the answer.

### 4b. Check on the phone

Install a build made after step 3, then:

```bash
adb shell pm verify-app-links --re-verify com.app.vitalog.dev
adb shell pm get-app-links com.app.vitalog.dev
```

Expect `<host>: verified`. `none` or `1024` means the fingerprint or
package doesn't match the installed build; fix 4a. Then send yourself an
invite on WhatsApp and tap it: Vitalog opens directly, with no browser.

---

## Step 5 — iOS: Universal Links (needs the paid Apple team)

A free personal team can't use Associated Domains. Until there's a paid
team, iPhones open the web page, whose button hands over through
`com.vitalog.app://invite/…`. That route is the second open item in
PENDING #27. Once the Apple Developer Program account exists:

1. developer.apple.com → Identifiers → the app id → enable **Associated
   Domains**.
2. Xcode → Runner target → **Signing & Capabilities** → **+ Capability →
   Associated Domains** → add `applinks:<host>`. This creates
   `ios/Runner/Runner.entitlements`; commit it.
3. In `invite_site/public/.well-known/apple-app-site-association`, replace
   `TEAMID` with the paid team's id (Membership page; 10 characters) and
   the bundle id with the final one. Redeploy.
4. Check what Apple's CDN fetched (it caches for hours):
   `curl -s https://app-site-association.cdn-apple.com/a/v1/<host>`
5. Delete and reinstall the app. Tap an invite in Messages or Notes:
   Vitalog opens directly. Long-press shows "Open in Vitalog".

---

## Step 6 — Afterwards (the other half of PENDING #27)

When both platforms open links directly (steps 4 and 5), remove the
`com.vitalog.app://invite/…` button from `invite.html` and the
`com.vitalog.app` `invite` intent filter. Another app can register the same
scheme and catch the secret. The page then only says "Install Vitalog"
and offers "Copy link" (paste in Family → Open an invite link). Do this as
its own change, with a test that `InviteLink.parse` no longer accepts the
scheme form.

## Keeping it safe

- Auto-renew stays on. Whoever leaves the team hands over registrar access
  first.
- Only the team deploys `invite_site/`. Never add analytics, chat widgets,
  fonts or any third-party script to it: any script on that page can read
  the `#secret`. The CSP (`default-src 'none'`) blocks them. Don't loosen
  it.
- Don't put anything else on `<host>` that runs other people's code (blog
  platform, CMS, user uploads). If the main website needs those, use a
  separate subdomain (`www.`), never the invite host.
- If the domain ever changes: keep the old one live and on auto-renew
  until every link made with it has expired (7 days after the last build
  using it is gone). Don't let it lapse.

## Done when

- [ ] 1. Domain bought in the company account; 2FA, auto-renew, lock and
      DNSSEC on
- [ ] 2. `invite_site/` live on `https://<host>`; the three `curl` checks
      pass
- [ ] 3. App uses `<host>`; grep is clean; `flutter analyze` + `flutter test`
      green
- [ ] 4. `assetlinks.json` has the release keys only; `get-app-links` says
      `verified`
- [ ] 5. iOS Universal Links (after the paid Apple team)
- [ ] 6. Scheme hand-over removed (after 4 and 5)

Items 1–4 must be done before **anyone outside the team creates an
invite**. 5–6 must be done before the public release.
