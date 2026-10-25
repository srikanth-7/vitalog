# Vitalog — monetization and end-to-end test plan

**Status:** Proposal; no product/code changes or Supabase operations are authorized by this document alone.  
**Product principle:** Let people get value from private, on-device report reading before asking for an account or payment.

This plan combines a privacy-first business model with a safe, screen-ordered QA checklist. It reflects the current project notes: OCR is on-device; report originals stay on the phone; Sync is explicit; the current Sync v1 is plaintext and is permitted only with synthetic reports; sealed Sync v2, cloud restore, deletion tombstones, in-app account deletion, and family sharing are not complete.

## 1. Product and monetization recommendation

### Product promise

Vitalog helps a household keep, understand, and review its lab-report history. It organizes what the report says; it does not diagnose or replace a clinician. The app should earn trust through clear privacy boundaries and reliable access to a user's own records.

### Proposed tiers

| Tier | What it includes | Why it belongs there |
|---|---|---|
| **Free — private health log** | Continue without an account; on-device OCR; review/correct extracted results; local family profiles; local reports, categories, history, and trends | The core value and local access should remain useful without an account or subscription. |
| **Vitalog Family — subscription per household** | Encrypted cross-device backup/restore; shared family profiles; multiple authorized family members; sync history; export and household conveniences | These are recurring cloud, support, and security costs. One household subscription avoids charging every relative separately. |
| **Later, optional** | Carefully scoped clinic/lab partnerships or employer wellness integrations | Only after consumer product-market fit, security review, clinical/legal review, and a strict ban on selling identifiable health data. Not part of the first launch. |

Do not sell health data, target ads from health information, or paywall deletion/export of a user's own records. Do not market a health score or clinical interpretation as a paid benefit.

### Privacy and launch gate for paid cloud features

Current project documentation says Sync v1 sends readable test names, values, ranges, and dates. It is for fake reports only. The product decision is to replace it with end-to-end encrypted Sync v2 before syncing real medical data. The crypto core exists, but sealed push/pull, restore, tombstones/deletes, invites, and account deletion are still pending. Therefore:

- Do not sync real reports during this test round.
- Do not launch or sell cloud backup/sharing until Sync v2, access control, recovery, deletion, and security tests pass.
- Keep original documents local unless the product owner separately approves a future encrypted-file-backup design.
- Explain in the UI whether a record is only on this phone or protected by a tested cloud backup.

### Validate willingness to pay before choosing a price

1. Interview 10–15 target households about how they currently store and share lab results, what causes friction, and what they would trust an app to store.
2. Show a clickable or working prototype of local OCR and the Family subscription benefits; test comprehension of “on device” versus “synced”.
3. Ask for a concrete choice between monthly, annual, and free-local-only plans. Avoid asking only whether people “like” the idea.
4. Run a small opt-in beta and measure activation, repeat report use, Sync intent, conversion, cancellation, and support burden. Do not collect report contents for analytics.
5. Set price only after estimating the fully loaded cost per paid household and checking store fees, taxes, support, backups, and compliance.

### Unit economics

Use this model before setting a price:

```text
net revenue per paid household
  = subscription price − store/payment fees − taxes/refunds

monthly break-even paid households
  = (developer + support + security/compliance + platform + other fixed costs)
    ÷ net revenue per paid household

variable cost per household
  = database/compute + bandwidth + backup/storage + email/support allocation
```

Supabase's published Pro plan currently starts at USD 25/month, with quota-based usage and possible overages; the free plan is useful for development but can pause inactive projects. Treat these as a starting reference, not a production quote. Apple lists a USD 99 annual developer membership and a 15% rate for eligible Small Business Program transactions/qualifying subscriptions; Google Play fees depend on the applicable program and transaction. Recheck current platform terms before launch.

References: [Supabase pricing](https://supabase.com/pricing), [Apple Developer Program and fees](https://developer.apple.com/programs/whats-included), [Google Play service fee](https://support.google.com/googleplay/android-developer/answer/11131145).

## 2. Pre-test implementation and setup plan

Complete these in order, asking the product owner before each code or cloud mutation:

1. **Inspect only:** Confirm current branch, working tree, `docs/TEST_PLAN.md`, `docs/SUPABASE_REQUIREMENTS.md`, `docs/SHARING.md`, app configuration, and onboarding/sample-data wiring.
2. **Onboarding behavior:** Verify completion persists across normal relaunches. Add a development-only skip option for repetitive QA if needed; never force-skip onboarding for a genuine first-run production user. Keep a documented way to test both first-run and returning-user behavior.
3. **Disable runtime dummy data:** Stop injecting sample family members/reports into the normal app launch. Keep deterministic mock fixtures for automated tests and the synthetic files in `test-data/reports/` for QA. Verify the new-user empty state supports adding a real test profile.
4. **Verify Supabase staging configuration:** Use the existing ignored `supabase.local.json` if present; confirm it points to the development project and contains only the URL and publishable key. Never request, print, commit, or place a service-role key in the app.
5. **Check provider readiness:** Email confirmation is enabled and deliverable; Google provider has required client IDs, callback URLs, and nonce configuration. Android Google sign-in also needs its signing SHA-1 registered. Test only platforms whose setup is ready.
6. **Check database readiness:** Apply/verify schema and RLS from the current development docs. Because Sync v1 is plaintext, restrict this round to synthetic report files and temporary accounts.
7. **Build the test matrix:** Run first on iOS simulator/device, then Android once the scanner dependency/build setup is available. Use fake report files only. Record each case as Pass, Fail, Blocked, or Not Run with build/device and notes.
8. **Cleanup:** After tests, list the exact temporary account IDs and related test rows. Ask for fresh confirmation immediately before deleting them. Verify the test identities and rows are gone. Never delete the project, schema, or unrelated user records as part of cleanup.

## 3. Detailed test cases

### How to use this checklist

- Run cases in order so later tests start from a known state.
- Use only accounts and inboxes controlled by the tester.
- Use only synthetic reports from `test-data/reports/`; never upload real patient records while Sync v1 is active.
- For every case record: **Pass / Fail / Blocked / Not Run**, platform, app build, date, and a short observation.
- No passwords or secret keys go into test notes or chat.

### A. First launch, onboarding, and guest mode

| ID | Steps | Expected result |
|---|---|---|
| A01 | Install a fresh test build with empty app storage; launch it. | Splash completes and onboarding appears once. No seeded family member or lab result is shown. |
| A02 | Complete onboarding and choose **Continue without an account**. | App reaches the local Home experience without requiring Supabase or Google. |
| A03 | Fully close and relaunch without clearing app data. | Onboarding does not repeat; local app opens. |
| A04 | Relaunch with the proposed QA-only onboarding skip enabled. | QA build reaches the app directly; first-run onboarding remains testable when the flag is off. Production default does not silently skip first-run onboarding. |
| A05 | Launch without Supabase URL/key, then open Sign-in and Sync. | Local features remain available; cloud actions explain that cloud sync is not configured. No crash or endless spinner. |
| A06 | Enable Reduce Motion / system accessibility settings and relaunch. | Splash and celebratory motion respect reduced-motion settings; navigation remains usable. |

### B. New family profile and empty screens

| ID | Steps | Expected result |
|---|---|---|
| B01 | Open Family and add a synthetic test member with name/relation and optional birth year/sex. | Member is saved locally, selected visibly, and shown on Home. No backend request is made just by adding the member. |
| B02 | Open Home, Categories, and Reports for a member with no reports. | Clear empty states; no mock results, fake categories marked tested, health score, or fake latest report. |
| B03 | Add a second test member and switch between them from Family and the bottom member switcher. | Selected member is clear. Their reports/results are isolated. Dock switching keeps the current tab; Family-list selection returns to Home if that is the intended behavior. |
| B04 | Restart the app and revisit Family. | Locally stored profiles remain; no sample profiles reappear. |

### C. Email and Google authentication

| ID | Steps | Expected result |
|---|---|---|
| C01 | Open sign-up and submit an invalid email. | Inline validation; no auth request. |
| C02 | Submit a password shorter than the configured minimum (8 characters per current docs). | Inline validation; no account created. |
| C03 | Create an account with a controlled temporary email and valid password. | Supabase creates the staging account; app reports the confirmation step clearly if email confirmation is on. |
| C04 | Before confirming the email, attempt sign-in. | Message accurately explains the confirmation requirement; no misleading “success”. |
| C05 | Confirm using the email link, return to the app, and sign in. | Callback opens Vitalog via the configured deep link; authenticated state is shown. |
| C06 | Attempt to sign up again with the same email. | Clear duplicate/account-exists handling; no second profile or duplicate data is created. |
| C07 | Sign in with a wrong password. | Generic, localized failure; no raw server details, stack trace, or account-sensitive disclosure. |
| C08 | Use **Forgot password**, open the reset message, and set a new password. | Reset link returns to the app/site correctly; new password works and old password fails. |
| C09 | Tap Google sign-in and complete one successful flow on a configured platform. | Supabase session is established for the expected account; no duplicate session or account. |
| C10 | Cancel Google consent or simulate provider/network failure. | User returns safely; app shows a temporary error and stays usable. No partial account/profile is created. |
| C11 | Sign out, relaunch, and sign in again. | Session state is correct; local reports remain on device. Sign-in itself does not trigger Sync. |
| C12 | Use an email-only test account with no Google account. | Email/password signup, email confirmation, login, reset, and sign-out work without Google. Guest use remains available. |

### D. Upload, scan, and report status

Use `test-data/reports/01-all-normal.txt` through `07-unsupported.zip` as referenced in `docs/TEST_PLAN.md`.

| ID | Steps | Expected result |
|---|---|---|
| D01 | From Home, Categories, or Family, launch Add report and choose `01-all-normal.txt`. | After the picker returns a file, app switches to Reports immediately and shows the report as Reading/Processing. |
| D02 | Wait for `01-all-normal.txt` to finish. | Report shows Ready and the expected synthetic tests; report and collection dates are distinct; no upload date is substituted for either. |
| D03 | Observe the success notice and do not tap it. | Notice dismisses after its defined duration (4 seconds normally; 10 seconds in Simple mode). It does not remain until manually dismissed, including when it has a View action. |
| D04 | Upload `02-needs-attention.csv`. | Expected printed high/low flags and values are shown; attention is explicit in words, not color alone; no “all clear” celebration. |
| D05 | Upload `03-no-printed-ranges.txt` for profiles with/without required demographic data. | No range is invented. Applicable usual range is labeled as such; unresolved fields remain Needs review. |
| D06 | Upload `04-unknown-test.txt`; open the unknown test. | Test is filed under Other/Needs review and can be assigned a category. Learned category behavior matches the design. |
| D07 | Upload `05-contact-details.txt`. | Lab address, phone, email, and URL are redacted from stored/synced metadata; synthetic test values still parse. |
| D08 | Upload `06-no-date.txt`. | Missing report date is not replaced with upload date; report is marked Needs review. |
| D09 | Upload `07-unsupported.zip`. | Clear unsupported-file result; no crash and no misleading OCR success. |
| D10 | Upload the same supported file twice for one member, then once for a different member. | Duplicate is detected per member; retry is offered only for eligible prior failures; a different member can keep their own copy. |
| D11 | From a result page or another tab, upload an image and a multi-page PDF. | Reports tab shows processing; OCR handles supported image/PDF; page results remain associated with one report. |
| D12 | On iOS, scan a synthetic printed report with the document scanner; on Android, repeat after scanner dependency is available. | Correct platform OCR path is used; captured report appears in Reports; cancellation leaves no partial report. |
| D13 | Upload a file, then cancel/delete while it is processing. | Processing stops or safely completes without resurrecting a deleted report/results. Temporary readable copies are removed. |
| D14 | Trigger OCR failure/timeout and select retry. | Failed/timed-out state is explicit; retry reprocesses the same stored original without duplicating the report. |

### E. Review, categories, history, and display

| ID | Steps | Expected result |
|---|---|---|
| E01 | Open a Needs review report; edit a synthetic test value, unit, range, category, and date; save. | Edits persist; status is re-judged from the supplied printed range; no clinical claim beyond the report is introduced. |
| E02 | Mark an uncertain result as checked without changing it. | It is marked checked, not edited; report becomes Ready only after all review items are resolved. |
| E03 | Open Compare with original on a device requiring biometric/passcode access. | Original opens only after device authentication; decrypted bytes are not written back to disk. |
| E04 | Open Categories and select a tested category/test. | Latest result and date match the selected member; missing key tests are informational, not diagnoses. |
| E05 | Open a test with multiple report dates. | History is chronological by medical report date; chart uses comparable units only and point labels match dates/values. |
| E06 | Switch Simple mode, dark/light theme, accent, and language (English/Telugu). | Preferences persist; status meaning remains explicit; layout remains readable and translated strings appear correctly. |
| E07 | Trigger every notice type that can be generated (auth, sync, upload, edit, member). | Each notice dismisses on time; a new notice replaces the old one without an old timer hiding the new one. |

### F. Supabase Sync v1 — synthetic data only

> **Hard safety gate:** the current documentation says Sync v1 sends readable test names, values, ranges, and dates. Run only with synthetic `test-data/reports/` and temporary accounts. Do not use a real medical report or a real patient's profile.

| ID | Steps | Expected result |
|---|---|---|
| F01 | With Supabase configured but signed out, tap Sync. | App asks for sign-in; no database rows are created. |
| F02 | Sign in with temporary Account A, add/upload one synthetic report, then tap Sync explicitly. | Sync succeeds only after the user action; expected synthetic report/results rows are written to the configured dev project. Original document bytes are not uploaded. |
| F03 | Inspect staging rows using the dashboard with an authorized admin. | Row user IDs belong to Account A; IDs/conflict keys match schema; only synthetic content appears. No secret key is in the client build. |
| F04 | Tap Sync again without new data. | Idempotent upsert; no duplicate report/result rows. |
| F05 | Disable network during Sync, restore network, retry. | Failure is visible and temporary; retry succeeds; no partial duplicate records. |
| F06 | Sign in as Account B and try to read/update/delete Account A rows using the app/client session. | RLS rejects cross-account access. Test both read and write paths. |
| F07 | Confirm no automatic Sync occurs on upload, sign-in, app start, or profile switching. | Local changes remain local until explicit Sync. |
| F08 | Sign out after syncing synthetic data. | Current user's remote rows remain only under that account; local data behavior is clear; another account cannot see them. |
| F09 | Try destructive actions (report deletion/account deletion) in this version. | Record whether local/server deletes are supported. Do not claim remote deletion if tombstones/account deletion are still pending. |
| F10 | Before any real-data test request, check the release gate. | Test is blocked until sealed Sync v2, restore, tombstones/deletes, account deletion, and RLS/security review are complete. |

### G. Cleanup and closeout

| ID | Steps | Expected result |
|---|---|---|
| G01 | Prepare a cleanup manifest with exact temporary account UUIDs/emails and synthetic row counts. | Owner reviews the list; no broad table/project deletion. |
| G02 | Obtain fresh product-owner confirmation immediately before deletion. | No deletion is attempted without this confirmation. |
| G03 | Delete only approved temporary auth users and their synthetic rows using the supported staging procedure. | Only the listed test data is removed; schema, settings, other accounts, and project remain intact. |
| G04 | Verify auth users and related rows are gone; sign-in with deleted test account fails. | Staging is clean and evidence is recorded without retaining passwords or report contents. |
| G05 | Remove test-only app data from simulator/device after preserving required test notes. | No synthetic report or test account session remains on the test device. |

## 4. Exit criteria and release blockers

A test phase is complete only when every case is Pass or explicitly accepted as Blocked/Not Applicable with a reason. Before inviting external families:

- Runtime sample members/results are disconnected; mock fixtures remain test-only.
- Onboarding is first-run once, with a QA-only bypass and reproducible first-run test.
- iOS and Android sign-in/OCR paths are tested on their target devices.
- Email and Google provider configuration, deep links, RLS, and account isolation pass.
- Sync v2 is end-to-end encrypted; restore, tombstones, account deletion, and recovery are tested.
- Privacy policy, data disclosures, medical disclaimer, and clinician review of usual ranges are complete.
- No real reports are processed by cloud services; originals remain local unless an explicitly approved secure-backup design is later implemented.

## 5. Decisions to make before paid launch

- Which cloud capabilities are included in Family, and what remains local/free?
- Is there a free limit on cloud history/storage, and what happens to access after cancellation?
- How will invited family members receive a household entitlement without creating health-data ownership or access surprises?
- Which launch countries and data-residency requirements apply?
- What support, recovery, export, and deletion service levels can the team actually provide?
- What price and annual discount are supported by interviews and unit economics?

These are product-owner decisions; this document does not change the app or enable billing.

## 6. Abandonment offer for Family — psychological analysis (planned)

**Planning only.** No paywall, offer, or decline-tracking exists in the app today. Anything in this section describes *what psychology recommends and what this app's rules forbid*; it authorizes no code, no offers, and no data collection. No part of it may ship before the Sync v2 release gate in §1 — the Family capabilities an offer would sell (backup/restore, shared profiles, sync history) do not exist before then.

**What an abandonment offer means here.** An offer presented when a household would otherwise walk away from the Family subscription. Three moments apply in Vitalog's structure: (a) a **decline at the paywall** (Sync/Restore tapped while unauthenticated or unbilled), (b) the **cancellation flow** (after paid billing exists), and (c) a quiet **win-back before renewal** (needs notification consent; deferred). The analysis is one core trade-off: the same mechanisms that recover honest intent (loss aversion, anchoring, simpler choice) destroy trust when misapplied — and in a health app whose promise is "your records, your control", trust destroyed is unrecoverable.

### 6.1 Constraints the offer inherits (non-negotiable)

- **No analytics.** The AGENTS hard rule forbids tracking without sign-off; this doc further bans collecting report contents for analytics. So the offer can never be event-driven from cloud telemetry. Any decline signal must be on-device state (e.g., "paywall declined" flag in the app's own settings storage), never a server call with identifiers.
- **Banned content** (§1): no selling health data, no health-context ads, no paywalling of a user's own records, deletion, or export, no health-score marketing. A save offer may *mention* your own banned boundaries as reassurance, never blur them.
- **Store honesty rules.** App Store / Play require explicit auto-renew disclosure for trials and offers (price, duration, when billing starts). The offer is legally simple, never "clever".
- **DPDP Act (India).** Any personalization beyond what the user has directly tapped requires notice and consent. Default design: no personalization at all.
- **Tone ceiling.** Vitalog's audience is families managing health under stress. Fear-adjacent motivation ("don't put your family at risk") is out of bounds — even when it would raise conversion.

### 6.2 Mechanisms: what psychology recommends, and where this app stops it

| Effect | Finding | Honest use in Vitalog | Hard limit adopted |
|---|---|---|---|
| **Anchoring / denomination** | The first price seen and the *unit* used shape value judgment; per-month framing of an annual price lowers perceived size | Paywall shows the annual plan first with an honest "≈ ₹X/month" equivalent and the exact renewal date and price | No invented "was/now" prices; no rounding "₹99 vs ₹499" tricks unless the arithmetic is real |
| **Loss aversion** | Losses hurt roughly twice as much as equal gains; only true *losses* drive action | At cancellation only: name concretely what stops working — "New phones won't get cloud restore; annual restore stops; invited members lose shared history" | Never imply the data itself is lost. The truth is the opposite (docs stay local; free tier unchanged) and saying it is both honest *and* calming |
| **Choice reduction (Hick)** | Decision time grows with options; a second price in the same screen doubles the decision | One offer per encounter. Decline = defer (no repeat ask for a set period, e.g., 30 days), Simple mode uses the same plain words rules as everywhere else | No back-to-back monthly-then-annual stack in one sheet |
| **Commitment & consistency** | Small, transparent commitments convert better than blind ones; kept promises make the next ask easier | Trial (if approved) states the exact auto-renew price and date; post-cancel flow reaffirms the free tier so a future resubscribe is low-regret | No commitments disguised as free; nothing the user didn't knowingly tap |
| **Default / endowment** | People keep what they already feel they own | Emphasis on continuity at cancel: "your history stays on this phone" | Never pre-enable anything; a cancel must require exactly the user's tap, nothing pre-selected |
| **Family framing (unity)** | Household-frame pricing raises willingness to pay and fits the product ("the family's records") | Offer copy speaks of the household, not the account — consistent with the per-household tier already chosen in §1 | Never manufacture guilt about family safety; unity framing is warm, not frightening |
| **Social proof** | Others' behavior persuades — only when the evidence is real | **Skipped at launch.** There are no honestly sourced household counts without analytics, and this app will not fabricate them | No invented reviews, counts, or "families trust us" claims |

### 6.3 Offer candidates (ranked; validate per §"Validate willingness to pay" and §5)

| # | Offer | Where it shows | Psychological basis | Cost/risk | Verdict to test |
|---|---|---|---|---|---|
| A | Annual-first paywall with honest monthly equivalent and exact renewal price | Always on at the paywall | Anchoring, denomination | None; a layout rule, not an offer | Default at launch |
| B | Calm decline = defer | Paywall declined | Reactance budget; *less* pressure, more long-run trust | None | Default at launch |
| C | Trial with full auto-renew disclosure | Paywall | Commitment; store handles mechanics | Needs store config; clear disclosure strings (l10n) | Test length (7–14 d) in interviews |
| D | Downsell: monthly after a declined annual | Same encounter, only if annual was declined | Anchoring | Second price = second decision; risk of both | Only if the 10–15 interviews support two prices |
| E | Cancel-flow save card naming exactly what turns off | Cancellation, once | Loss aversion | Feels like retention pressure if repeated — therefore once per cancel action | Test copy with owner sign-off |
| F | Win-back offer before renewal | Notification | Audience targeting | Requires push consent; absent consent, don't | Defer until push consent exists |
| G | Post-cancel autonomy card: "Local use is unaffected" | After cancel completes | Consistency; reduces regret, keeps resubscribe path open | None; cheap and principled | Default at launch |

### 6.4 Techniques that are out of bounds for this app

- Countdown timers, "only 2 left", or any manufactured scarcity
- Popularity claims without a source, or reviews that never existed
- Pre-checked consent, negative-option flow, or anything that hides the renewal price
- Guilt or fear framing about family health ("your family depends on you subscribing") — coercive with a health product
- Copy that contradicts §1 (e.g., is silent about the fact that records stay local on cancel)

### 6.5 Measurement without analytics

- **No funnel telemetry will be built.** Decline/save outcomes live on-device only; there is no backend payoff for them and none is requested.
- Acceptable evidence: platform-provided aggregates (App Store Connect / Play conversion, trial starts, offer redemptions, refunds), which never carry report content; plus debug-only on-device counters for QA rounds.
- Primary evidence remains qualitative: the §1 interview protocol already asks for a concrete choice between monthly, annual, and free-local-only plans; a follow-up question on what would change the answer tests offer value directly.
- Judged fields: redemption rate, cancel-save rate with honest copy, refund/complaint rate as the trust probe.

### 6.6 Owner decisions required before any offer is built (extends §5)

1. Whether an abandonment offer exists at launch at all, or only candidates A/B/G (framing, defer, autonomy card) which cost nothing and sell nothing.
2. Trial length, price, and disclosure copy (EN + Telugu; all offer strings go through `app_en.arb` / `app_te.arb` per the l10n rule).
3. Annual-discount magnitude — tied to the §5 unvalidated price/discount decision; no offer until the interviews result stands.
4. Frequency budget: how often, if ever, an offer may reappear after a decline (proposed: never within 30 days, once per billing cycle thereafter).
5. Cancellation experience details: save card (E) allowed or not; exact wording, subject to medical-restraint and Simple-mode legibility review.
6. Timing gate: nothing in this section goes live before the §1 Sync v2 release gate is passed; paywall-for-local-features is already banned by §1 and remains so.
