# Health apps sync: implementation plan

Status: **plan only, nothing built yet.** Written 2026-10-22. Start after the
current project (P0 items in `docs/PENDING_TASKS.md`) is finished.

**Goal (owner's words):** "connect his own tracking apps like Google Fitness
apps and Apple Health and Fitness app and sync those data into our app and
display those."

**In one line:** read-only import from **Apple HealthKit** (iOS) and **Health
Connect** (Android) into an encrypted on-device store, attached to the **one
family profile that owns this phone**, shown as a Fitness section on Home plus
trend screens. Data does not leave the phone in v1.

---

## 0. Facts this plan relies on

✅ = checked on the web or in this repo on 2026-10-22. ⚠️ = assumed (from
platform knowledge or third-party sources). Re-check ⚠️ items before starting.

### Repo
- ✅ Flutter 3.38.10 (`flutter --version`). iOS deployment target 15.0 (`ios/Podfile`, pbxproj).
- ✅ Local store is `LocalReportStore` → one AES-256-GCM file (`reports.json`) through `ReportCipher`, key in Keychain/Keystore, atomic writes. We copy this pattern.
- ✅ The trend chart is `_HistoryPainter` (private) in `presentation/pages/health_subscreens.dart`. It spaces points by index, not by time, and labels every point with a hand-built `day/month`. That breaks the `formatDate()` rule and won't scale past about 10 points.
- ✅ Family members are still mock data (`data/mock`, relation `'You'` marks the phone holder). PENDING_TASKS #5 (real members) must land first.
- ✅ **The Android host is not in a buildable state for this work.** The Gradle files are at the repo root (`build.gradle`, `settings.gradle`, `app/`) and use AGP 7.2.0, Kotlin 1.7.10 and the legacy `apply from: flutter.gradle`. `app/build.gradle` has `flutter { source '../..' }`, which points outside the repo. `android/` holds only `local.properties` and a generated registrant. `MainActivity` extends `FlutterActivity`. The Flutter tool's default minSdk is 24 (`FlutterExtension.kt`).
- ⚠️ "Home customization toggles" are not in the repo or docs yet. This plan assumes they will be per-section show/hide switches on Home, and it registers Fitness as one of them.

### Android / Google
- ✅ **Google Fit APIs:** no new sign-ups since **1 May 2024**. Google's migration FAQ says the APIs are "deprecated in 2026" and points everyone to Health Connect. ⚠️ I found no exact turn-off date on an official page. An old 30 Jun 2025 date in the press was superseded. **Do not build against Fit.** Google Fit, Samsung Health, Fitbit and most Android trackers write into Health Connect (⚠️ per-app; the user may have to enable it in each app). So "connect Google Fit" in the UI really means Health Connect.
- ✅ Health Connect Jetpack library `androidx.health.connect:connect-client` 1.1.0 went stable on 8 Oct 2025.
- ✅ **Read window:** by default, reads are limited to **30 days before the first permission grant**. `readRecord` errors; list/aggregate/`getChanges` are silently trimmed. Older data needs `android.permission.health.READ_HEALTH_DATA_HISTORY`, gated by `FEATURE_READ_HEALTH_DATA_HISTORY` on the installed Health Connect version. Uninstalling the app revokes everything and resets the window.
- ✅ Background reads need `READ_HEALTH_DATA_IN_BACKGROUND` (not used in v1).
- ✅ Health Connect has change tokens (`getChangesToken`/`getChanges`), and tokens expire if they go unused for "an extended period". ⚠️ About 30 days; the exact figure wasn't found.
- ✅ **Play Console:** fill in the **Health apps declaration** (App content page). Give a justification per data type and request only types behind user-facing features. The privacy policy on the Play listing must match the one linked inside Health Connect. You can't submit updates until the declaration is done.
- ⚠️ Health Connect is part of the OS on Android 14+. On Android 9 to 13 (minSdk 26 per Jetpack docs) it's a separate Play Store app the user must install or update.
- ⚠️ Android 14+ needs an `activity-alias` for `android.intent.action.VIEW_PERMISSION_USAGE` (category `android.intent.category.HEALTH_PERMISSIONS`). Android 13 and lower need an activity handling `androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE`. Both show our privacy policy. (The `health` package README documents both ✅.)

### Apple
- ✅ Turn on the HealthKit capability (entitlement `com.apple.developer.healthkit`). Clinical records need the extra **Clinical Health Records** capability (`com.apple.developer.healthkit.access` = `health-records`), which Apple must approve, plus an extra purpose string. ⚠️ The key name is `NSHealthClinicalHealthRecordsShareUsageDescription`.
- ✅ Background delivery uses `enableBackgroundDelivery` with observer queries registered at launch, plus the `com.apple.developer.healthkit.background-delivery` entitlement (not used in v1).
- ✅ **Review guideline 5.1.3** (quoted on Apple forums; Apple's page timed out here): no advertising or data-mining use of health data, no disclosure to third parties except for health management or research with permission, disclose exactly what you collect, and **(ii) no personal health information in iCloud**. ⚠️ Guideline 2.5.1: apps using HealthKit must say so clearly in their marketing text and UI.
- ⚠️ HealthKit never tells an app whether **read** access was denied. A denied type looks the same as "no data". The UI must handle this (see §5).
- ⚠️ Health Records (clinical/lab records) is available only in the US, UK and Canada; the latest sources I found are 2020 to 2022. **No India support was found**, so it would add nothing for Vitalog's lab-report users. It's out of v1.

### Flutter package
- ✅ **`health` 13.3.2** (verified publisher carp.dk, MIT, about 2 months old). iOS minimum 15.0, which matches ours. Since 13.2.0 it needs compileSdk 36, Kotlin 2.1.0 and Gradle 8.9.1, and since 13.3.0 Health Connect client 1.2.0-alpha02. It supports history and background permissions (12.1/12.2), all the v1 types below, and needs `FlutterFragmentActivity`. Since 12.0, `Health` is not a singleton; create one instance.
- ✅ It has **no anchored query or change-token API** and **no clinical records**. §4 is designed around that.

**Recommendation: use `health: 13.3.2` (pin exactly), not hand-written channels.**
- Two native codebases (Swift HealthKit + Kotlin Health Connect), with permission UIs, unit handling and about 11 types, would take an estimated 2 to 3 weeks more. The package does it today and is actively maintained.
- What we give up: anchors/change tokens (replaced by a rolling re-read window, §4) and clinical records (not useful in India).
- How to upgrade later: if deletion-accurate sync or background delivery becomes a requirement, add one small native channel per platform (`HKAnchoredObjectQuery` / `getChanges`) next to the package. The repo already does this for OCR (`vitalog/report_ocr`).

---

## 1. v1 scope

**Read-only. iOS + Android. One profile per phone. No cloud upload.**

| Metric | `HealthDataType` (package) | Daily rollup stored | Unit |
|---|---|---|---|
| Steps | `STEPS` via `getTotalStepsInInterval` per day (⚠️ dedupes iPhone + Watch overlap; raw samples double-count) | sum | count |
| Heart rate | `HEART_RATE` | avg, min, max | bpm |
| Resting heart rate | `RESTING_HEART_RATE` | avg | bpm |
| HRV | iOS `HEART_RATE_VARIABILITY_SDNN`, Android `HEART_RATE_VARIABILITY_RMSSD` | avg | ms (label SDNN/RMSSD; the two are different measures) |
| Sleep | `SLEEP_ASLEEP` (+ stage types where present) | minutes, assigned to the **wake-up day**; if sources overlap, keep the single source with the most minutes that night | min |
| Weight | `WEIGHT` | latest of day | kg |
| BMI | `BODY_MASS_INDEX` | latest of day | kg/m² (⚠️ verify on Android; if the package needs height, add `HEIGHT` or drop BMI on Android) |
| Blood pressure | `BLOOD_PRESSURE_SYSTOLIC` + `_DIASTOLIC` | avg sys/dia, count | mmHg |
| Blood glucose | `BLOOD_GLUCOSE` | avg, min, max, count | mg/dL |
| SpO₂ | `BLOOD_OXYGEN` | avg, min | % |
| Workouts | `WORKOUT` | total minutes, sessions, latest type | min |

**Out of v1:** writing to Health/Health Connect, clinical records, background
delivery/reads, nutrition/cycle/mindfulness, per-sample raw storage, cloud
backup of fitness data, importing data for anyone other than the phone holder.

**First import depth:** 90 days for activity-type metrics (steps, HR, HRV,
sleep, SpO₂, workouts) and 12 months for readings (weight, BMI, BP, glucose).
On Android, without the history permission, everything is capped at 30 days
before the first grant. **(Open question Q2.)**

---

## 2. Who the data belongs to

HealthKit and Health Connect hold **the phone holder's** data only. Vitalog
manages several family profiles from one phone, so:

- **One "linked profile" per device.** It's stored as `ownerMemberId` in the
  fitness store (below) and is never inferred silently.
- **Picking it:** the first step of the connect flow is *"Whose health data is
  on this phone?"* It lists the family members and pre-selects the one whose
  relation is `You`. No guess is possible until real members exist (PENDING #5).
- **Showing it clearly:**
  - The Fitness section and every metric screen show a source line: *"From
    Apple Health on this phone · Maya"* (or Health Connect).
  - When another member is selected, Home shows no Fitness numbers. It shows a
    one-line empty state: *"Fitness data comes from Maya's phone. Each person
    can connect on their own phone."* Never show the owner's numbers under
    someone else's profile.
- **Changing the owner:** a confirm dialog, then **delete all imported
  fitness data** and re-import for the new owner. Data is never re-labelled
  from one person to another.
- Later (not v1): a family member's own phone signs in to the same account and
  imports for their own profile. That needs cloud sync of fitness data (Q4)
  and the shared-family account model.

---

## 3. Data model and storage

Domain (`lib/features/family_health/domain/entities/fitness_day.dart`):

```dart
enum FitnessMetric { steps, heartRate, restingHeartRate, hrv, sleep, weight,
  bmi, bloodPressure, bloodGlucose, oxygenSaturation, workouts }

class FitnessDay {           // one rollup per profile × metric × local date
  final String profileId;
  final FitnessMetric metric;
  final DateTime day;        // local date, time 00:00
  final double value;        // sum / avg / latest (per table in §1); BP = systolic
  final double? value2;      // BP diastolic; otherwise null
  final double? min, max;
  final int count;           // samples/sessions behind the rollup
  final String unit;
  final List<String> sources; // e.g. ["Apple Watch", "Withings"], shown on detail screen
}
```

Store (`data/local/fitness_store.dart`):
- A **separate file `fitness.json`**, encrypted with the **existing
  `ReportCipher`** (same key, same `FAMMO1` header, same atomic write). Report
  saves must not rewrite fitness data, and the reverse.
- Content: `{version, source: "healthkit"|"healthConnect", ownerMemberId,
  connectedAt, syncedThrough: {metric: isoDate}, days: [FitnessDay...]}`.
- Upsert key: `profileId|metric|yyyy-MM-dd`.
- Size: about 11 metrics × 365 days ≈ 4k rows/year, which fits one JSON file.
  Mark it with `// ponytail: single file; move to sqlite with reports (PENDING #17)`.
- No mixing with `LabResult`. Lab glucose and meter glucose stay separate
  (different context, fasting state unknown).

Snapshot: add `List<FitnessDay> fitness` and `String? fitnessOwnerId` to
`FamilyHealthSnapshot`. Add `fitnessFor(profileId, metric, {from})` next to
the existing `resultsFor`.

Repository (`FamilyHealthRepository` + impl): add `connectFitness(ownerId)`,
`refreshFitness({bool full = false})`, `disconnectFitness()`. Load them in
`loadFamilyHealth()` from the new store. Inject `FitnessStore` and
`FitnessSource` in `family_health_dependencies.dart`, following the existing
`store:/recognizer:/sync:` pattern. One concrete class each, no interfaces;
tests pass fakes through the constructor as they do today.

`data/fitness/fitness_source.dart` is the only file that imports
`package:health`. It maps package types to `FitnessMetric` and does the daily
rollups (pure functions, unit-tested).

---

## 4. Sync strategy

The package has no anchors, so v1 uses **a per-metric high-water mark plus a
rolling re-read window**:

1. For each metric, `from = max(syncedThrough[metric] − 3 days, importStart)`
   and `to = now`.
2. Read samples in `[from, to]`, recompute daily rollups, and **replace** those
   days in the store (upsert by key; delete keys in the window that now have
   no data).
3. Set `syncedThrough[metric] = today`. Save once, atomically.

The 3-day overlap catches late Watch/scale syncs and edits made in the source
app. **Known limit:** deletions older than 3 days in the source app are not
reflected. The connection settings get a **"Re-import all"** button (calls
`full: true`). If that limit matters later, upgrade to anchors via a native
channel (§0).

**When it runs:**
- On app open (`LoadHealthData`) and on `AppLifecycleState.resumed`, throttled
  to at most once every 15 minutes.
- Pull-to-refresh on Home and a "Refresh" action in fitness settings.
- **No polling, no timers, no background delivery** in v1.
- In the bloc: a new `RefreshFitness` event. Keep `isRefreshingFitness`
  separate from `isSyncing`, which belongs to Supabase Sync. Failures are a
  quiet `HealthNotice`; never block the dashboard.

**Android specifics:** call `getHealthConnectSdkStatus()` before connecting
(⚠️ method name per package). If it's missing or outdated, show an "Install
Health Connect" step that opens Play. Request `READ_HEALTH_DATA_HISTORY` only
when the feature is available and only for the first full import.

**Units:** request the units in §1 explicitly, never the device locale.
Display can convert later (Q5).

---

## 5. UI

All strings go in `app_en.arb`, all colours come from `context.colors`, and
dates go through `formatDate()`, per AGENTS.md.

**Entry points:** a "Connect Apple Health / Health Connect" card in Family
(profile screen) and a one-time dismissible prompt card on Home.

**Connect flow (bottom sheet, 3 steps):**
1. **Whose data?** Pick the member (§2).
2. **What we read, and where it goes.** A plain list of the metrics, plus:
   *"Read-only. Stays on this phone, encrypted. Not uploaded when you tap Sync.
   You can disconnect and delete it any time."* Then a "Continue" button.
3. **The system permission sheet** (HealthKit / Health Connect). Request only
   the §1 types.

After the grant, run the first import with a progress row, then land on Home.

**iOS denied reads look like "no data".** If a metric returns nothing, the
card shows *"No data yet. If you turned this off, enable it in Health →
Sharing → Apps → Vitalog."* Don't claim "permission denied".

**Home, Fitness section** (owner profile only; not shown in the report-scoped
`HomeScreen(report:)`):
- `SectionHeading("Fitness")`, then a 2-column grid of compact tiles that
  reuse the `CategoryCard`/`TapCard` look. Each tile shows the metric name,
  the latest value + unit, "today" or the last date, and a small 7-day
  sparkline.
- Only metrics that have data appear. A source line sits under the heading.
- It's hidden for non-owner members (one-line empty state instead, §2).
- **Home customization:** register as a section `fitness` (default **on**
  once connected). Turning it off hides the section, not the connection.
  Until the customization feature lands, the section is simply shown when
  connected.

**Metric detail screen** (`fitness_metric_screen.dart`): a 7D / 30D / 90D / 1Y
segmented control, a "latest" card like the test-history page, the chart, a
list of days, and a sources line. Show the `notDiagnosis` footer. Don't colour
values as high/low in v1, since there are no clinical ranges for most of
these (Q6).

**Chart reuse:** move `_HistoryPainter` to `widgets/health_widgets.dart` as a
public `HistoryChart` with no visual change. Then add:
- x position by date, not index (gaps show as gaps);
- an optional second series (BP diastolic) in a second token colour;
- label thinning (at most about 6 labels) using `intl` `MMMd` instead of the
  manual `day/month`.

The test-history screen keeps using it, so both look the same.

**Fitness settings** (from the Family screen card): connected source, linked
member, last refreshed, Refresh, Re-import all, Change member, **Disconnect
and delete**.

---

## 6. Privacy, consent, revocation, deletion

- **Same posture as reports:** on-device only, encrypted at rest. **Not**
  included in Supabase Sync in v1 (`ReportSyncService` is unchanged). No
  analytics, logs or crash reports containing values (AGENTS.md hard rule).
- **Consent:** explicit in-app step (§5, step 2) before the OS sheet. Store
  `connectedAt` and the consent copy version in the store, so changed wording
  can trigger re-consent.
- **Disconnect and delete:** delete `fitness.json` and clear the owner and
  marks. On Android, also call the package's permission revoke (⚠️
  `revokePermissions()`). On iOS an app can't revoke its own permissions, so
  show *"Also turn off access in Health → Sharing → Apps → Vitalog"* and offer a
  button to open Settings.
- **Revoked outside the app:** on Android, a refresh that finds no granted
  permissions shows a reconnect card. Imported data is kept until the user
  deletes it; say so in the settings screen (Q7). On iOS it can't be detected
  (see §5).
- **Account deletion and "delete all data"** (PENDING #12) must also wipe
  `fitness.json`.
- **App Privacy label / Play Data safety:** while fitness data never leaves
  the device it's not "collected" under Apple's definition (⚠️ re-check).
  It must still be described in the privacy policy. If Q4 enables upload, the
  labels change to Health & Fitness → collected, linked to the user, not used
  for tracking.

---

## 7. Store requirements checklist

**iOS**
- [ ] Xcode → Signing & Capabilities → **HealthKit** (no Clinical Records, no Background Delivery). This adds `Runner.entitlements` with `com.apple.developer.healthkit = true`.
- [ ] `Info.plist`: `NSHealthShareUsageDescription` (needed for reading), e.g. *"Vitalog reads steps, heart rate, sleep, weight, blood pressure, glucose, oxygen and workouts to show your trends. It stays on this phone."* Add `NSHealthUpdateUsageDescription` too, because the package README asks for it, even though we never write.
- [ ] Real bundle ID and team first (PENDING #3); HealthKit needs a provisioned App ID.
- [ ] Marketing text and screenshots mention Apple Health integration (2.5.1 ⚠️). The UI says "Apple Health" with Apple's naming rules.
- [ ] Privacy policy URL describing HealthKit use (5.1.1, 5.1.3). Review notes say: read-only, on-device, no third parties, no iCloud.
- [ ] Never write HealthKit data to iCloud. The iOS device backup of the app container holds only ciphertext, and the key is `first_unlock_this_device` (not migrated). ⚠️ Confirm with App Review if unsure.

**Android**
- [ ] Phase 0 Android host rebuild (§8).
- [ ] `MainActivity : FlutterFragmentActivity`.
- [ ] Manifest: one `<uses-permission android:name="android.permission.health.READ_*"/>` per §1 type (STEPS, HEART_RATE, RESTING_HEART_RATE, HEART_RATE_VARIABILITY, SLEEP, WEIGHT, [HEIGHT], BLOOD_PRESSURE, BLOOD_GLUCOSE, OXYGEN_SATURATION, EXERCISE) + `READ_HEALTH_DATA_HISTORY`; `<queries><package android:name="com.google.android.apps.healthdata"/></queries>`; rationale intent-filter + `VIEW_PERMISSION_USAGE` activity-alias (copy from the package README).
- [ ] Check whether `ACTIVITY_RECOGNITION` is really needed for read-only steps. The README mentions it; don't request it unless it is required.
- [ ] Play Console → App content → **Health apps declaration** with a per-type justification; privacy policy identical in Play and in the rationale screen; Data safety form.
- [ ] Budget for Health Connect permission review time (⚠️ often 1 to 2+ weeks) before release.

---

## 8. Milestones

| # | Milestone | Main work | Effort |
|---|---|---|---|
| 0 | **Prerequisites** | Real members (PENDING #5), real bundle ID/signing (#3). **Rebuild the Android host:** regenerate `android/` with `flutter create --platforms=android .`, port the manifest and `MainActivity` (as FlutterFragmentActivity), set minSdk 26 and compileSdk 36, use the declarative plugins block with AGP 8.x + Kotlin 2.1, delete the root `build.gradle`/`settings.gradle`/`app/`. Do this with PENDING #7 (Android OCR), which needs the same fix. | 2–3 d (Android part) |
| 1 | **Data layer** | Add `health: 13.3.2`, platform config, `FitnessSource` + rollups, `FitnessStore`, repository methods, snapshot fields. Unit tests. | 3–4 d |
| 2 | **Connect + ownership + privacy** | Connect sheet (3 steps), owner pick/change, settings screen, disconnect and delete, Android install/availability states, `RefreshFitness` event + resume throttle. | 3 d |
| 3 | **Display** | Public `HistoryChart` (date-x, 2 series, label thinning), Home Fitness section + sparklines, metric detail screen, Home-customization hook. | 3–4 d |
| 4 | **Store compliance** | Privacy policy text, App Privacy/Data safety, Play Health apps declaration, review notes, screenshots. | 1–2 d + review wait |
| 5 | **Device QA + hardening** | Device matrix below, unit edge cases, accessibility labels on tiles/charts. | 2–3 d |

About **3 developer-weeks** after M0, plus store review lead time. M1 can
start on iOS while the Android host is being rebuilt.

---

## 9. Testing

- **Unit (`test/fitness/`):** rollups per metric (step dedupe via the interval
  total, sleep assigned to the wake-up day and overlapping sources, BP
  pairing, latest-of-day), window maths (`syncedThrough − 3 d`, 30-day
  Android cap), upsert/replace removes days that vanished, store round-trip
  through `ReportCipher`, and disconnect deletes the file.
- **Bloc:** `RefreshFitness` throttling, never runs concurrently, failure gives
  a notice and keeps old data, owner change wipes data.
- **Widget:** Fitness section visible only for the owner, the non-owner empty
  state, the connect sheet steps, and the customization toggle hiding it.
- **Manual devices:**
  - iOS simulator: add samples in the Health app.
  - Physical iPhone + Apple Watch: dedupe and late sync.
  - Android 14 emulator with the **Health Connect Toolbox** for seeded data.
  - Android 13 device: Health Connect APK install path.
  - Samsung device with Samsung Health → Health Connect.
  - Deny/partial-grant and revoke-in-settings paths on both platforms.

Run `flutter analyze && flutter test` per AGENTS.md, then `graphify update .`.

---

## 10. Risks

| Risk | Mitigation |
|---|---|
| The Android host needs rebuilding before anything Android works | M0, shared with Android OCR |
| iOS can't tell "denied" from "no data" | Neutral empty-state copy (§5) |
| Health Connect 30-day window, so a thin first import on Android | Request the history permission when available; explain "older data may not be available" |
| Double counting (phone + watch, several sleep apps) | Interval totals for steps; one source per night for sleep |
| Source-side deletions older than 3 days stay | "Re-import all"; anchors via a native channel if needed |
| Package lag behind OS changes (it's on a Health Connect alpha client) | Pin the exact version; all usage sits in one file (`fitness_source.dart`), so swapping is cheap |
| Play Health Connect review rejects broad scopes | Request only the §1 types, each tied to a visible tile |
| Fitness numbers appearing under the wrong family member | Explicit owner, per-tile source line, wipe on owner change |
| Users expect clinical judgement (high BP and so on) | No flags in v1, `notDiagnosis` footer (Q6) |

---

## 11. Open questions for the product owner

1. **Metric list:** are all 11 wanted in v1, or a smaller first cut (steps, sleep, resting HR, weight, BP, glucose)?
2. **Import depth:** 90 days activity / 12 months readings OK? On Android, ask for the extra "history" permission (one more consent screen) or accept 30 days?
3. **Owner model:** is "one linked member per phone" acceptable? Should there be a way to link a second phone (spouse) later, which requires cloud sync and a shared family account?
4. **Cloud backup:** should fitness data ever be included in Sync? If yes, it needs a `fitness_days` Supabase table (same RLS pattern), privacy-label changes, and explicit opt-in. The default in this plan is **no**.
5. **Units:** always kg and mg/dL, or follow the device or an in-app setting (lb, mmol/L)?
6. **Ranges/flags:** show guidance bands (for example BP ≥ 130/80) or keep v1 purely descriptive?
7. **After revocation:** keep the already-imported history until the user deletes it, or auto-delete?
8. **Clinical records:** confirm they're out of scope (no Indian Health Records support found; Apple entitlement review needed).
9. **Naming:** in UI and marketing, say "Apple Health" / "Health Connect". "Google Fit" is being retired, so don't promise it by name.

---

## Sources (checked 2026-10-22)
- `health` package: https://pub.dev/packages/health and https://pub.dev/packages/health/changelog
- Google Fit migration FAQ: https://developer.android.com/health-and-fitness/health-connect/migration/fit/faq
- Health Connect read limits/history: https://developer.android.com/health-and-fitness/health-connect/read-data
- Health Connect sync (change tokens): https://developer.android.com/health-and-fitness/health-connect/sync-data
- Health Connect Jetpack 1.1.0 stable: https://developer.android.com/jetpack/androidx/releases/health-connect
- Play health apps declaration: https://developer.android.com/health-and-fitness/health-connect/publish and https://support.google.com/googleplay/android-developer/answer/12991134
- HealthKit access/entitlements: https://developer.apple.com/documentation/xcode/configuring-healthkit-access
- HealthKit background delivery: https://developer.apple.com/documentation/healthkit/executing-observer-queries
- App Review 5.1.3 (as quoted): https://developer.apple.com/forums/thread/838022, https://developer.apple.com/forums/thread/838493. Live page to re-check: https://developer.apple.com/app-store/review/guidelines/
- Health Records countries (older): https://register.apple.com/resources/ehr/Getting_Started_Guide.pdf
