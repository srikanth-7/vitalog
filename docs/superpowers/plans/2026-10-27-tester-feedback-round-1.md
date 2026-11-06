# Tester Feedback Round 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the 15 items in the tester's feedback note (2026-10-27) that can be done inside the app, and add reminders that stay on this phone.

**Architecture:** Every change follows the existing layering: UI → `HealthBloc` → `FamilyHealthRepository` → `LocalReportStore` / `ReportSyncService`. Reminders get their own small store + cubit, like `SettingsCubit`. Nothing new leaves the phone.

**Tech Stack:** Flutter, flutter_bloc, intl/gen-l10n, `flutter_local_notifications` + `timezone` + `flutter_timezone` (new, Task 12 only), `image_picker` (already installed).

**Spec:** `~/Downloads/when we show the home screen to a person and wait for 10 seconds, and…/…md` (tester feedback) + `AGENTS.md`.

## Out of scope (separate plan later)

- **#8 Invite family members** and **#13 reminders that reach a family member's phone.** These need sealed Sync v2 and the sharing backend from `docs/SHARING.md`. Only `sharing_crypto.dart` exists today. Write a separate plan for them once this one ships (about 3–5 weeks).

## Feedback → task map

| # | Feedback | Task | Root cause found |
|---|---|---|---|
| 10b | Toast doesn't close | 1 | `SnackBar.persist` defaults to `true` when an action is present (Flutter `snack_bar.dart:303`) |
| 6b | Latest reports first | 2 | Timeline sorts by `uploadDate` (`reports_screen.dart:42`), not the printed report date |
| 5 | Name next to "Good morning" | 3 | Eyebrow shows only `timeGreeting()` |
| 4 | "All results" opens one category | 4 | `onAction: () => onCategoryTap(firstCategory!)` (`home_screen.dart:175`) |
| 12 | Can't delete a synced report | 5 | Reports restored from the account have no `filePath`. `isUploaded` hides the ⋯ menu and long-press (`reports_screen.dart:223`) |
| 8 | Can't delete a member who has reports | 6 | `MemberHasReports` blocks it by design. Offer "Remove with N reports" instead |
| 9 | Duplicate reports | 7 | Only an identical file is caught (`fileHash`). A new photo of the same paper report isn't |
| 14 | Sign out / Delete account design | 8 | A cramped row in `_AccountCard` |
| 3 | Profile photo + edit member | 9, 10 | No `photoPath`, no edit flow |
| 1, 2, 7 | Home: "10-second" read, better graph, categories higher | 11 | Layout |
| 15 | "Too black and white" | 12 | Colour tokens are mostly neutral |
| 13 | Reminders (own phone) | 13 | New feature |

## Design direction (Tasks 3, 8, 11, 12, 13)

References: `~/Downloads/when we show the home screen…/Designs/` (IMG_6975 "mindcare", IMG_6976/6977 green fitness app). **Adapt, don't copy:** take the ideas below, build them from our tokens, `AppRadius` shapes and existing widgets, and keep our own content.

| Idea in the references | How Vitalog adapts it |
|---|---|
| Soft gradient wash at the top of each screen (lavender/mint, or a green fade) | `HeaderWash`: a top-of-page gradient from `brandSoft` (accent-aware) fading into `canvas` over ~280 pt, behind the greeting and page titles. Tokens only, light and dark. No full-screen glass: health numbers need solid cards for contrast |
| "Welcome, **Alex!** here's your health snapshot" + "Today is…" | "Good morning, **Srikanth**" (name bold) / "Here's {member}'s health snapshot" / "Last tested {date}" (Task 3 + 11) |
| Avatar top-left, bell top-right | Member avatar (photo from Task 10) opens the switcher. The bell opens Reminders (Task 13) and shows a dot when one is due within 7 days |
| "Today's stats" cards: value + "Good/Average" badge + ring | "Needs attention" cards in a horizontal row: test name, value + unit, a status capsule (↑ High / ↓ Low, word + arrow, never colour only), and a small **range gauge** showing where the value sits in the printed range (replaces the ring) |
| Pastel activity tiles with a white circular icon chip | Category tiles get their own soft tint + a white icon circle (Task 12) |
| Bar chart, latest bar dark, others soft; period chips | Test-history chart (`_HistoryPainter`): bars per reading, latest bar in `brand`, earlier bars soft, printed-range band behind them, chips "All · 1 year · 6 months" (Task 11) |
| Profile: photo + name card with Age/Height/Weight tiles, grouped rows with round icon + chevron | Family/Account: identity card with avatar + name + email, tiles "Members · Reports · Last sync"; grouped rows with a round icon + chevron: Personal info (edit, Task 9), Reminders, Lock originals (toggle), Display; then Sign out; then Delete account in its own group (Task 8) |
| Black pill primary button | Primary button stays our theme's filled button in `brand` (already a capsule). No black buttons |

Not adopted: icon-only tabs (our tray keeps labels, which matter in Simple mode), the search bar (nothing worth searching yet), stock photos and illustrations of people.

## Global Constraints

- No hard-coded colours: `context.colors.<token>`. New tokens go in both `light` and `dark` in `lib/core/theme/app_theme.dart`.
- No hard-coded strings: add every new key to `lib/l10n/app_en.arb` **and** `lib/l10n/app_te.arb`, then run `flutter gen-l10n`. Never edit the generated `app_localizations*.dart` files.
- Dates go through `formatDate()`. Shapes use `AppRadius`/`AppShape`, never `BorderRadius.circular(n)`.
- Motion ≤ 250 ms, transform/opacity only, honour `MediaQuery.disableAnimationsOf(context)`.
- Destructive confirmations use `showDestructiveSheet`; item menus use `showPullDownMenu`. No `AlertDialog` / `PopupMenuButton`.
- Health data stays on the phone. Photos and reminders are stored encrypted with `ReportCipher()` and are never synced.
- Notification text on the lock screen never contains test names or values.
- After each task: `flutter analyze` → "No issues found", `flutter test` → all pass.
- After any task that changes layout: render every tab at phone, folded and open (sideways) sizes, and run it on the physical Android phone (not the simulator).
- The project isn't a git repo, so "Checkpoint" steps mean analyze + test pass. Commit there if git gets initialised.

## Review Focus

1. **Report with no printed date** (`reportDate` falls back to the upload time): it must still sort sensibly next to dated reports. Test in Task 2.
2. **Signed in with email only (no name in metadata):** the greeting must not say "Good morning, srikanth.v@akrivia.in". Test in Task 3.
3. **Deleting a member while one of their reports is still being read:** the in-flight `processReport` must save nothing (it already returns null for a vanished report). Test in Task 6.
4. **Same report, one copy reading fewer tests** (bad photo): it must not be called a duplicate unless every shared test has the same value, and the new copy has no tests the old one lacks. Test in Task 7.
5. **Reminder in the past / phone restarted / timezone changed:** a past one-off reminder isn't scheduled, and repeating reminders are rescheduled on app start. Test in Task 13.

---

### Task 1: Toast closes on its own

**Files:**
- Modify: `lib/features/family_health/presentation/pages/dash_board_screen.dart:294-319`
- Test: `test/widget_test.dart`

- [ ] **Step 1: Write the failing test** `testWidgets('report notice with View closes by itself', …)`: pump the app, upload a report through the fake recognizer (follow the existing "uploaded report → timeline" test), wait for the notice, `await tester.pump(const Duration(seconds: 5))` then `pumpAndSettle()`, `expect(find.byType(SnackBar), findsNothing)`.
- [ ] **Step 2: Run** `flutter test test/widget_test.dart --plain-name "closes by itself"`. Expected: FAIL (SnackBar still found).
- [ ] **Step 3: Implement.** Add `persist: false` to the `SnackBar(...)` in `_showNotice`, with the comment `// Flutter keeps action snackbars until tapped; ours time out.`
- [ ] **Step 4: Run** the same test. Expected: PASS.
- [ ] **Step 5: Checkpoint.**

### Task 2: Timeline newest report first

**Files:**
- Modify: `lib/features/family_health/presentation/pages/reports_screen.dart:22,39-42`
- Modify: `lib/features/family_health/domain/entities/family_health_snapshot.dart:46-48`
- Test: `test/health_charts_test.dart` (pure snapshot tests live alongside) or a new `test/snapshot_test.dart`

**Interfaces:**
- Produces: `FamilyHealthSnapshot.reportsFor(memberId)` returns reports sorted by `reportDate` desc, ties broken by `uploadDate` desc. `ReportsScreen` uses it instead of its own sort.

- [ ] **Step 1: Write the failing test** `reportsFor sorts by printed date, then upload`: three reports for `p1`: A(report 2026-03-01, upload 2026-10-01), B(report 2026-09-01, upload 2026-09-02), C(report 2026-09-01, upload 2026-10-20). `expect(snap.reportsFor('p1').map((r) => r.id), ['C', 'B', 'A'])`.
- [ ] **Step 2: Run.** Expected: FAIL on the tie order.
- [ ] **Step 3: Implement.** Add the tie-break in `reportsFor`. In `ReportsScreen.build`, replace the local filter + sort with `snapshot.reportsFor(profile.id)` and update the class doc comment to "newest report first".
- [ ] **Step 4: Run.** Expected: PASS.
- [ ] **Step 5: Checkpoint.**

### Task 3: "Good morning, Srikanth"

**Files:**
- Modify: `lib/features/family_health/presentation/health_presentation.dart:57-61`
- Modify: `lib/features/family_health/presentation/pages/home_screen.dart:257` (`_Greeting`)
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_te.arb`. Add `"greetingWithName": "{greeting}, {name}"`.
- Test: `test/health_charts_test.dart` (or a new `test/presentation_test.dart`)

**Interfaces:**
- Produces: `String? greetingName(String? displayName)`: the first word of the display name, or null when it's null, blank or contains `@`.

- [ ] **Step 1: Write the failing test** `greetingName`: `'Srikanth V'` → `'Srikanth'`; `'  '` → null; `null` → null; `'srikanth.v@akrivia.in'` → null.
- [ ] **Step 2: Run.** Expected: FAIL (undefined).
- [ ] **Step 3: Implement** `greetingName` next to `timeGreeting`. In `_Greeting`, wrap the eyebrow in a `StreamBuilder` on `Backend.authChanges` (as `_AccountCard` does). When `greetingName(Backend.displayName)` is non-null, show `l10n.greetingWithName(timeGreeting(l10n), name)`; otherwise show `timeGreeting(l10n)`.
- [ ] **Step 4: Run** the tests plus `flutter gen-l10n`. Expected: PASS.
- [ ] **Step 5: Checkpoint.**

### Task 4: "All results" opens all results

**Files:**
- Modify: `lib/features/family_health/presentation/pages/health_subscreens.dart:246-302` (`CategoryResultsScreen`)
- Modify: `lib/features/family_health/presentation/pages/navigation.dart` (add `openAllResults`)
- Modify: `lib/features/family_health/presentation/pages/home_screen.dart:170-175` and the home screen's callbacks (add `onAllResultsTap`)
- Test: `test/widget_test.dart`

**Interfaces:**
- Produces: `CategoryResultsScreen.category` becomes `HealthCategory?`. Null = every test for the member, titled `l10n.allResults`. `void openAllResults(BuildContext context, {required FamilyHealthSnapshot scoped, required FamilyHealthSnapshot full, required FamilyMember profile})`.

- [ ] **Step 1: Write the failing test** `All results lists tests from every category`: with mock data, tap `find.text('All results')`, expect the AppBar title to be 'All results', and expect a test from each of two different categories (pick two names from the mock results) to be visible after scrolling.
- [ ] **Step 2: Run.** Expected: FAIL (title is a category name).
- [ ] **Step 3: Implement.** When `category` is null, skip the `categoryIds` filter. Wire the Home action to `openAllResults`. Show the action whenever results exist (drop the `firstCategory != null` condition).
- [ ] **Step 4: Run.** Expected: PASS.
- [ ] **Step 5: Checkpoint**, plus check that the two-pane (sideways) layout opens it in the right pane.

### Task 5: Delete synced (restored) reports

**Files:**
- Modify: `lib/features/family_health/presentation/pages/reports_screen.dart:223,252,273` and `_EntryMenu` (~520-556), `_showEntryActions` (~476)
- Test: `test/widget_test.dart`

- [ ] **Step 1: Write the failing test** `restored report can be deleted`: seed the store with a ready, `synced: true` report with `filePath: null` (as a restore leaves it). Open Reports, expect `find.byType(MoreButton)` to find one, tap it → Delete → confirm, and expect the report to disappear.
- [ ] **Step 2: Run.** Expected: FAIL (no MoreButton).
- [ ] **Step 3: Implement.** Show the menu and long-press when `!processing` (drop the `isUploaded` gate). Inside the menu and the sheet, show **Retry** only when `report.filePath != null && !report.unsupported`, because a restored report has no original to re-read. Move and Delete are always shown.
- [ ] **Step 4: Run.** Expected: PASS. The existing synced note (`deleteReportSyncedNote`) already explains that the cloud copy goes too.
- [ ] **Step 5: Checkpoint.**

### Task 6: Remove a member together with their reports

**Files:**
- Modify: `lib/features/family_health/domain/repositories/family_health_repository.dart:83-87`
- Modify: `lib/features/family_health/data/repositories/family_health_repository_impl.dart:286-303`
- Modify: `lib/features/family_health/presentation/bloc/health_event.dart:41-44`, `health_bloc.dart:245-255`
- Modify: `lib/features/family_health/presentation/pages/profile_screen.dart:217-234`
- Modify: arb files. Add `"memberRemoveWithReports": "Remove {name} and {count, plural, =1{1 report} other{{count} reports}}?"`, `"memberRemoveWithReportsDetail": "Their reports, results and original files are deleted from this phone."`, and `"memberRemoveWithReportsConfirm": "Remove with reports"`.
- Test: `test/health_bloc_test.dart`

**Interfaces:**
- Produces: `Future<void> deleteMember(String memberId, {bool withReports = false})`. With `withReports`, it deletes each of the member's reports through the same path as `deleteReport` (local + originals + server when signed in) inside the same `_locked` block, then the member. Without it, it still throws `MemberHasReports`. `DeleteFamilyMember(member, {this.withReports = false})`.

- [ ] **Step 1: Write the failing tests**: (a) `deleteMember withReports removes member, reports, results and originals`: add a member, add + process a report for them, `deleteMember(id, withReports: true)`, then expect no member, no reports/results for that profile, and the original file gone. (b) `report being read when its member is removed saves nothing`: start `processReport` with `_SlowRecognizer`, call `deleteMember(id, withReports: true)`, let it finish, expect `processReport` → null and no results.
- [ ] **Step 2: Run.** Expected: FAIL (no named parameter).
- [ ] **Step 3: Implement.** Pull the body of `deleteReport` into a private `_deleteReportsUnlocked(Iterable<String> ids)` so both methods use it without re-entering `_locked`. In `confirmRemoveMember`, when `reportCount > 0` show `showDestructiveSheet` with the new strings, and on confirm send `DeleteFamilyMember(member, withReports: true)`. `memberRemoveBlocked` stays only as the fallback for the exception.
- [ ] **Step 4: Run.** Expected: PASS.
- [ ] **Step 5: Checkpoint.**

### Task 7: Catch duplicates by content, not only by file

**Files:**
- Modify: `lib/features/family_health/data/repositories/family_health_repository_impl.dart` (`processReport`, after results are parsed and before they are saved)
- Modify: `lib/features/family_health/domain/repositories/family_health_repository.dart` (doc on `processReport`)
- Modify: `lib/features/family_health/presentation/bloc/health_bloc.dart` (`_process`: catch `DuplicateReport`)
- Test: `test/report_flow_test.dart`

**Interfaces:**
- Produces: `bool sameReading(List<LabResult> a, List<LabResult> b)` (top-level in the repository impl file, so it can be tested). It's true when `b` is non-empty, every test in `b` (by lowercased name) is in `a`, and the values for those tests are equal. `processReport` throws `DuplicateReport(existing)` when an existing report for the same profile has the same calendar `reportDate`, the same lab, and `sameReading(existingResults, newResults)`. Before throwing, it deletes the new report and its original. The bloc turns that into the existing `reportDuplicate` notice with `reportId: existing.id`, so "View" opens the one already there.

- [ ] **Step 1: Write the failing tests**: (a) `same paper report, different photo, is a duplicate`: process two different files whose recognizer output is the same rows; expect the second → `DuplicateReport` and one report left. (b) `a re-take that reads fewer tests is still a duplicate` (subset, same values). (c) `same date and lab but a changed value is not a duplicate`. (d) `new copy with an extra test is not a duplicate`.
- [ ] **Step 2: Run.** Expected: (a), (b) FAIL.
- [ ] **Step 3: Implement** as in Interfaces.
- [ ] **Step 4: Run.** Expected: all four PASS, and the existing duplicate-file tests still pass.
- [ ] **Step 5: Checkpoint.**

### Task 8: Account section redesign (sign out / delete account)

**Files:**
- Modify: `lib/features/family_health/presentation/pages/profile_screen.dart:114-172` (`_AccountCard`)
- Modify: arb files. Add `"signOutDetail": "Your reports stay on this phone."` and `"deleteAccountDetail": "Removes your cloud backup for good."`.
- Test: `test/widget_test.dart`

Layout (see Design direction, profile row): card 1 is the identity card: avatar (initials, brand-soft), display name, email, and three small tiles "Members · Reports · Last sync". Then a grouped list (iOS settings style, one `TapCard` with dividers): **Sign out** row (`Icons.logout`, neutral, subtitle `signOutDetail`). Then a separate group below with the **Delete account** row (`c.danger` text + icon, subtitle `deleteAccountDetail`, opens the existing `confirmDeleteAccount`). Signed out: one card with the explanation and a full-width filled **Sign in** button.

- [ ] **Step 1: Write the failing test** `account rows are separate and labelled`: signed in (fake auth as other auth tests do), expect `find.widgetWithText(ListTile, 'Sign out')` and `'Delete account'` as separate tappable rows with a gap between them, and expect that tapping Delete account opens the destructive sheet.
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement** the layout above.
- [ ] **Step 4: Run.** Expected: PASS. Render the Family tab in light, dark and Simple mode.
- [ ] **Step 5: Checkpoint.**

### Task 9: Edit a family member

**Files:**
- Modify: `lib/features/family_health/domain/repositories/family_health_repository.dart`, `family_health_repository_impl.dart` (add `updateMember`)
- Modify: `health_event.dart` / `health_bloc.dart` (add `UpdateFamilyMember`, notice `memberUpdated`)
- Modify: `lib/features/family_health/presentation/pages/profile_screen.dart` (the profile card's ⋯ / long-press gains **Edit**. Reuse the existing add-member sheet, pre-filled; find it with `grep -rn AddFamilyMember lib/`)
- Modify: arb files (`editMember`, `noticeMemberUpdated`)
- Test: `test/health_bloc_test.dart`

**Interfaces:**
- Produces: `Future<FamilyMember> updateMember(FamilyMember member)`. It saves the change to `members.json` and recomputes `initials`. When `sex` changes, it re-judges that member's usual-range results, reusing the re-judge that `assignReport` runs.

- [ ] **Step 1: Write the failing test** `updateMember renames and re-judges`: add a member with no sex and a haemoglobin result judged without a usual range. Update with `sex: Sex.female`, then expect the name and initials changed and the result now carries `usualRange`.
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run.** Expected: PASS.
- [ ] **Step 5: Checkpoint.**

### Task 10: Profile photos (phone only)

**Files:**
- Modify: `lib/features/family_health/domain/entities/family_member.dart` (add `final String? photoPath`)
- Modify: `lib/features/family_health/data/local/local_report_store.dart:284-300` (`memberToJson`/`memberFromJson`; add `keepPhoto(String sourcePath, String memberId)` and `Future<Uint8List?> readPhoto(String memberId)`, encrypted with `ReportCipher()`)
- Modify: `lib/features/family_health/data/sync/report_sync_service.dart`. Assert that the member payload never includes the photo.
- Modify: avatar widget in `presentation/widgets/health_widgets.dart` (find the initials avatar with `grep -n initials`). Show the photo when present, otherwise initials.
- Modify: edit sheet from Task 9 (Add photo / Remove photo via `image_picker`, camera or library)
- Test: `test/report_store_test.dart`, `test/privacy/sync_payload_test.dart`

**Interfaces:**
- Consumes: `updateMember` (Task 9).
- Produces: `FamilyMember.photoPath`. `FamilyHealthRepository.setMemberPhoto(String memberId, String? sourcePath)` (null removes it). `Future<Uint8List?> memberPhoto(String memberId)`.

- [ ] **Step 1: Write the failing tests**: (a) `photo is stored encrypted and reads back` (the bytes on disk start with the `FAMMO1` tag, and `readPhoto` returns the original bytes). (b) `member sync payload has no photo` (the member row's keys don't include anything photo-related). (c) `deleting a member deletes their photo`.
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement.** Decode in memory only (`Image.memory`), never write the decrypted bytes to disk. `clearLocalData` also removes the photos.
- [ ] **Step 4: Run.** Expected: PASS.
- [ ] **Step 5: Checkpoint**, plus check the dock member switcher, Family list and Home greeting avatar on the phone.

### Task 11: Home redesign: the "10-second" screen

**Files:**
- Modify: `lib/features/family_health/presentation/pages/home_screen.dart` (section order)
- Modify: `lib/features/family_health/presentation/widgets/health_charts.dart` (`HealthOverviewCard`)
- Modify: `lib/core/settings/settings_cubit.dart` (`HomeSection` order, if it's order-dependent)
- Modify: arb files (`homeVerdictAllClear`, `homeVerdictAttention`, `homeVerdictSince`)
- Test: `test/health_charts_test.dart`, `test/widget_test.dart`

Target: after 10 seconds a person can repeat three facts: **how many results are fine, which ones aren't, when the last test was.**

New order (family Home only; a single report's view keeps its current layout). See Design direction for the reference ideas behind each part:
1. `HeaderWash` behind a header row: avatar (left, opens the switcher) and bell (right, Reminders). Then the greeting (Task 3), "Here's {member}'s health snapshot", and "Last tested {date}" (`formatDate`).
2. **Verdict card** (replaces the "At a glance" hero). One sentence in large text: "12 of 14 results are in range" or "All 14 results are in range". Keep the stacked status bar, but make it thicker (12 px) with the legend counts inline.
3. **Needs attention row**: horizontally scrolling cards, up to 3 plus a "See all" card. Each has the test name, value + unit, a status capsule (↑/↓ + word), and a `RangeGauge` (a printed-range bar with a marker at the value; hidden when no range can be parsed). Tap → test detail. In Simple mode it becomes a vertical list.
4. **Health categories**, moved up from below the latest report and the trends (tester item 7). Flagged categories sort first.
5. Trends. Improve the graph (tester item 2): bigger sparkline (56 px), the printed-range band labelled "usual" at its edges, and the latest dot annotated with its value. Still hidden in Simple mode. The test-history page chart becomes bars (latest in `brand`, earlier soft, range band behind) with period chips "All · 1 year · 6 months".
6. Recent results.
7. The latest-report banner is removed (its date moved into the header).

**Additional files:** create `lib/features/family_health/presentation/widgets/header_wash.dart` (`HeaderWash({required Widget child})`, used by Home and every tab's title area in Task 12). Add `RangeGauge({required LabResult result})` to `health_charts.dart` (reuses `parseRange`). Modify `_HistoryPainter` in `health_subscreens.dart`.

**Additional tests:** `RangeGauge places the marker at the value's position` (value 150 in a range of 100–200 → 0.5, clamped at the ends). `RangeGauge hides without a parseable range`. `history period chip filters readings`.

Rules from AGENTS.md still apply: summarise what the lab printed, no health score, no confetti when anything needs attention.

**Interfaces:**
- Produces: `({int inRange, int total, List<LabResult> attention, DateTime? lastTested}) homeVerdict(List<LabResult> latest)`. `attention` is sorted high/low first, then by date desc, and capped at 3 by the UI, not the helper.

- [ ] **Step 1: Write the failing tests**: (a) `homeVerdict counts latest-per-test only` (two readings of the same test count once, using the latest). (b) `lastTested is the newest reportDate`. (c) widget test `home shows verdict sentence and categories before trends` (find the verdict text, and check that the "Health categories" heading's dy < the trends heading's dy).
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run.** Expected: PASS. Update the golden images under `test/` if any cover Home (`flutter test --update-goldens`, then inspect the diffs by eye).
- [ ] **Step 5: Checkpoint**, then show the tester the screen for 10 s and ask the three questions. Record the answers in `docs/TEST_PLAN.md`.

### Task 12: More colour across the app

**Files:**
- Modify: `lib/core/theme/app_theme.dart` (`AppColors`: add per-category tint tokens `catBlood`, `catGlucose`, `catKidney`, `catLiver`, `catLipid`, `catThyroid`, `catVitamins`, `catIron`, `catUrine`, `catOther`, each with a soft background variant `…Soft`, in light **and** dark)
- Modify: `lib/features/family_health/presentation/health_presentation.dart` (add `Color categoryColor(AppColors c, String id)` and `categorySoftColor`, next to the category icon map)
- Modify: `presentation/widgets/health_widgets.dart` (`CategoryCard`, `ResultTile` leading icon tile), `health_subscreens.dart` (category headers), `reports_screen.dart` (timeline dots tinted by the report's main category), the Home verdict card (brand-tinted hero)
- Test: `test/settings_accent_test.dart` (contrast)

Also: `HeaderWash` (Task 11) goes behind every tab's title area. Category tiles take the "pastel tile + white icon circle" treatment from the references, and grouped settings rows get round tinted icon chips.

Rules: status colours (high/low/normal) stay fixed and keep meaning only status. Category tints are decoration, so text on them must keep 4.5:1. `withAccent` doesn't re-hue category tints.

- [ ] **Step 1: Write the failing test** `category tints keep text contrast`: for every category in both themes, check that the contrast of `textPrimary` on `…Soft` is ≥ 4.5 and the icon colour on `…Soft` is ≥ 3.0 (reuse the contrast helper in `settings_accent_test.dart`).
- [ ] **Step 2: Run.** Expected: FAIL (tokens missing).
- [ ] **Step 3: Implement** the tokens and apply them. Pick hues spaced around the wheel, avoiding the status red, amber and green.
- [ ] **Step 4: Run.** Expected: PASS. Render every tab in light and dark, at phone, folded and open sizes, and on the Android phone.
- [ ] **Step 5: Checkpoint.**

### Task 13: Reminders on this phone

**Files:**
- Create: `lib/features/reminders/reminder.dart` (entity + JSON)
- Create: `lib/features/reminders/reminder_store.dart` (`reminders.json`, `ReportCipher()`)
- Create: `lib/features/reminders/reminder_scheduler.dart` (thin wrapper over `flutter_local_notifications`)
- Create: `lib/features/reminders/reminders_cubit.dart`
- Create: `lib/features/reminders/reminders_screen.dart` (list + add/edit sheet)
- Modify: `pubspec.yaml` (`flutter_local_notifications`, `timezone`, `flutter_timezone`)
- Modify: `lib/main.dart` (init the scheduler, provide `RemindersCubit`, reschedule all on start)
- Modify: `profile_screen.dart` (a "Reminders" row on the Family tab), `home_screen.dart` (the header bell from Task 11 opens `RemindersScreen` and shows a dot when one is due within 7 days)
- Modify: `android/app/src/main/AndroidManifest.xml` (`POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED` + the plugin's receivers). iOS: request permission at first add, not at launch.
- Modify: arb files (all reminder copy)
- Test: `test/reminders/reminder_test.dart`, `test/reminders/reminders_cubit_test.dart`

**Interfaces:**
- Produces:
  - `class Reminder { String id; String memberId; String title; DateTime firstAt; ReminderRepeat repeat; bool enabled; }` and `enum ReminderRepeat { once, monthly, every3Months, every6Months, yearly }`.
  - `DateTime? nextFire(Reminder r, DateTime now)`: null for a past `once`. Monthly steps clamp to the month's last day (Jan 31 → Feb 28/29).
  - `abstract class ReminderScheduler { Future<void> schedule(Reminder r, DateTime at); Future<void> cancel(String id); Future<bool> requestPermission(); }`. Only the plugin implementation exists, plus a fake in the tests.
  - `RemindersCubit(store, scheduler)` with `add`, `update`, `delete`, `toggle`, `rescheduleAll()`.
- Notification text: title = the user's reminder title as typed (they choose what's on the lock screen), body = `l10n.reminderBody(memberName)` ("Reminder for {name}"). The add sheet hints: "Shown on the lock screen".
- Suggested presets in the add sheet: "Get tested" and "Add latest report", each for the chosen member, with repeat presets.

- [ ] **Step 1: Write the failing tests**: `nextFire` cases: once in future → itself; once in past → null; monthly from Jan 31 asked on Feb 1 → Feb 28 (or 29); every3Months skips past dates to the next future one; yearly on Feb 29 → Feb 28 in non-leap years. Cubit: `add` schedules once with the fake, `delete` cancels, `rescheduleAll` schedules only enabled reminders with a non-null `nextFire`, and a reminder for a removed member is dropped.
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement.** On Android without exact-alarm permission, fall back to inexact scheduling rather than failing. Removing a member (Task 6) deletes their reminders via the cubit.
- [ ] **Step 4: Run.** Expected: PASS. Then on the Android phone: set a reminder 2 min out, lock the phone, and check it fires. Restart the phone with a reminder pending and check it still fires.
- [ ] **Step 5: Checkpoint.** Update `AGENTS.md` (new feature section) and `docs/PENDING_TASKS.md` (mark these items done, add the out-of-scope plan).

---

## Order and estimate

Product owner's order (2026-10-27): design bugs and the redesign first, then the rest.

| Batch | Tasks | Estimate |
|---|---|---|
| A. Design bugs | 1, 2, 3, 4, 5, 8 | ~2 days |
| B. Redesign | 11, 12 | ~5–8 days |
| C. Remaining | 6, 7, 9, 10, 13 | ~6–8 days |
| **Total** | | **~2.5–3.5 weeks** |

Until Task 10 lands, the header avatar in Task 11 shows initials.

Show the tester after each batch. Tasks 11 and 12 are the ones most likely to need another design round.
