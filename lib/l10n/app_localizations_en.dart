// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Vitalog • Family Health';

  @override
  String get navHome => 'Home';

  @override
  String get navCategories => 'Categories';

  @override
  String get navReports => 'Reports';

  @override
  String get navFamily => 'Family';

  @override
  String get loadFailed => 'Could not load family health. Please try again.';

  @override
  String get tryAgain => 'Try again';

  @override
  String get noProfiles => 'No family profiles yet.';

  @override
  String get emptyHomeTitle => 'Your family’s lab reports, in one place';

  @override
  String get emptyHomeMessage =>
      'Results are read right on this phone and sorted into groups like these. Start by adding yourself or someone you look after.';

  @override
  String get emptyCategoriesTitle => 'Your results get sorted here';

  @override
  String get emptyCategoriesMessage =>
      'After you add a report, each test is placed in one of these groups.';

  @override
  String get emptyReportsTitle => 'Your lab reports will show here';

  @override
  String get emptyReportsMessage =>
      'Add a family member first. Then add a photo or PDF of their lab report.';

  @override
  String get emptyFamilyTitle => 'Set up your family space';

  @override
  String get emptyFamilyMessage =>
      'Add profiles to keep each person’s reports and results together. Your display and account settings are ready below.';

  @override
  String get startWalkthrough => 'Take a quick tour';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String greetingWithName(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String homeVerdict(int good, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total results are',
      one: '1 result is',
    );
    return '$good of $_temp0 in range';
  }

  @override
  String homeVerdictAll(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'All $total results are in range',
      one: 'Your 1 result is in range',
    );
    return '$_temp0';
  }

  @override
  String homeSnapshotFor(String name) {
    return 'Here’s $name’s health snapshot';
  }

  @override
  String lastTested(String date) {
    return 'Last tested $date';
  }

  @override
  String get periodAll => 'All';

  @override
  String get periodYear => '1 year';

  @override
  String get periodSixMonths => '6 months';

  @override
  String historySemantics(
      String test, int count, String from, String to, String value) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count readings',
      one: '1 reading',
    );
    return '$test: $_temp0 from $from to $to. Latest $value.';
  }

  @override
  String homeGreetingTitle(String name) {
    return 'Here’s $name’s latest';
  }

  @override
  String get tourMemberTitle => 'Start with a person';

  @override
  String get tourMemberBody =>
      'Add yourself or someone you look after. Each person keeps their own reports.';

  @override
  String get tourCategoriesTitle => 'Results, neatly grouped';

  @override
  String get tourCategoriesBody =>
      'Every test lands in its group, like Blood, Thyroid or Vitamins.';

  @override
  String get tourReportsTitle => 'Every report, by date';

  @override
  String get tourReportsBody =>
      'Add a photo or PDF. It’s read on this phone, and nothing leaves it unless you tap Sync.';

  @override
  String get tourFamilyTitle => 'Your family and settings';

  @override
  String get tourFamilyBody =>
      'Switch between people, add more, sign in for a backup, and change how the app looks.';

  @override
  String get walkthroughBack => 'Back';

  @override
  String get walkthroughNext => 'Next';

  @override
  String get walkthroughSkip => 'Skip tour';

  @override
  String get walkthroughDone => 'Done';

  @override
  String walkthroughStep(int step, int count) {
    return 'Step $step of $count';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get switchProfileTooltip => 'Switch family profile';

  @override
  String get viewingHealthFor => 'Viewing health for';

  @override
  String get latestReport => 'Latest report';

  @override
  String get noReportsYet => 'No reports yet';

  @override
  String get healthCategories => 'Health categories';

  @override
  String get seeAll => 'See all';

  @override
  String get recentResults => 'Recent results';

  @override
  String get allResults => 'All results';

  @override
  String get noResultsTitle => 'No results yet';

  @override
  String get noResultsMessage =>
      'Add a report to begin a timeline for this family member.';

  @override
  String get labRangeDisclaimer =>
      'Lab ranges can vary. Status labels reflect the range printed with each result; they are not a diagnosis.';

  @override
  String get reportEyebrow => 'Report';

  @override
  String reportDateValue(String date) {
    return 'Report date $date';
  }

  @override
  String collectionDateValue(String date) {
    return 'Collected $date';
  }

  @override
  String get labNotDetected => 'Lab not detected';

  @override
  String resultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
      zero: 'No results',
    );
    return '$_temp0';
  }

  @override
  String testsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tests',
      one: '1 test',
    );
    return '$_temp0';
  }

  @override
  String outsideRangeCount(int count) {
    return '$count outside range';
  }

  @override
  String get reportResultsHeading => 'Results in this report';

  @override
  String get statusWithinRange => 'Within lab range';

  @override
  String get statusHighPerReport => 'High · per report';

  @override
  String get statusLowPerReport => 'Low · per report';

  @override
  String get statusNeedsReview => 'Needs review';

  @override
  String get categoriesTitle => 'Categories';

  @override
  String get categoriesSubtitle =>
      'Results grouped by system. A test may appear in more than one group.';

  @override
  String resultsLatest(String results, String date) {
    return '$results · Latest $date';
  }

  @override
  String get noCategoriesTitle => 'Nothing to sort yet';

  @override
  String get noCategoriesMessage =>
      'Add a report and each test lands in its group.';

  @override
  String get homeEmptyTitle => 'No lab reports yet';

  @override
  String get homeEmptyMessage =>
      'Add their first report with the + button. Results, trends and anything that needs attention will show here.';

  @override
  String get latestValuesFirst => 'Latest values first';

  @override
  String get datePrintedNote => 'Each date is the date printed on the report.';

  @override
  String get noCategoryResultsTitle => 'No results in this category';

  @override
  String get noCategoryResultsMessage =>
      'Results will appear after a report has been read.';

  @override
  String get testHistory => 'Test history';

  @override
  String get unitNotPrinted => 'Unit not printed';

  @override
  String get latestResult => 'Latest result';

  @override
  String referenceRangePrinted(String range) {
    return 'Reference range as printed: $range';
  }

  @override
  String get rangeNotPrinted => 'not printed';

  @override
  String get history => 'History';

  @override
  String get chartNote =>
      'Values shown in the same unit from their report dates.';

  @override
  String get trendEmptyTitle => 'More results build the trend';

  @override
  String get trendEmptyMessage =>
      'A chart appears when at least two comparable numeric results are available.';

  @override
  String get notDiagnosis =>
      'This view records values printed by the lab and does not interpret them as a diagnosis.';

  @override
  String get reportsTitle => 'Reports';

  @override
  String get reportsSubtitle =>
      'Every uploaded report, newest first. Tap one to see just its results.';

  @override
  String get addReport => 'Add a report';

  @override
  String get sync => 'Sync';

  @override
  String get syncing => 'Syncing…';

  @override
  String unsyncedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reports not synced',
      one: '1 report not synced',
    );
    return '$_temp0';
  }

  @override
  String get allSynced => 'All reports synced';

  @override
  String get reportsEmptyTitle => 'No reports yet';

  @override
  String get reportsEmptyMessage =>
      'Tap Add a report below. Take a photo or choose a PDF; it\'s read on this phone only.';

  @override
  String uploadedOn(String date) {
    return 'Uploaded $date';
  }

  @override
  String get reportStatusProcessing => 'Reading…';

  @override
  String get reportStatusReady => 'Ready';

  @override
  String get reportStatusNeedsReview => 'Needs review';

  @override
  String get reportStatusFailed => 'Couldn\'t read';

  @override
  String get syncedBadge => 'Synced';

  @override
  String get onDeviceBadge => 'On this device';

  @override
  String get sampleBadge => 'Sample';

  @override
  String get retry => 'Try again';

  @override
  String get delete => 'Delete';

  @override
  String get deleteReportTitle => 'Delete this report?';

  @override
  String get deleteReportMessage =>
      'The document and its results are removed from this phone.';

  @override
  String get addReportSheetTitle => 'Add a lab report';

  @override
  String get takePhoto => 'Scan with camera';

  @override
  String get choosePhoto => 'Choose from Photos';

  @override
  String get choosePdf => 'Choose a PDF';

  @override
  String get addReportPrivacy =>
      'Reports are read on this phone. Nothing is uploaded until you tap Sync.';

  @override
  String noticeReportReady(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tests added',
      one: '1 test added',
    );
    return '$_temp0';
  }

  @override
  String noticeReportNeedsReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tests added — some details need review',
      one: '1 test added — some details need review',
    );
    return '$_temp0';
  }

  @override
  String get noticeReportFailed => 'Couldn\'t find any tests in that document.';

  @override
  String noticeSynced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reports synced',
      one: '1 report synced',
    );
    return '$_temp0';
  }

  @override
  String noticeSyncRestored(int reports, int members) {
    String _temp0 = intl.Intl.pluralLogic(
      reports,
      locale: localeName,
      other: '$reports reports',
      one: '1 report',
    );
    String _temp1 = intl.Intl.pluralLogic(
      members,
      locale: localeName,
      other: '$members family members',
      one: '1 family member',
    );
    return '$_temp0 and $_temp1 restored from your account.';
  }

  @override
  String noticeSyncRestoredSent(int reports, int members, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      reports,
      locale: localeName,
      other: '$reports reports',
      one: '1 report',
    );
    String _temp1 = intl.Intl.pluralLogic(
      members,
      locale: localeName,
      other: '$members family members',
      one: '1 family member',
    );
    String _temp2 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reports sent',
      one: '1 report sent',
    );
    return '$_temp0 and $_temp1 restored from your account · $_temp2.';
  }

  @override
  String get noticeNothingToSync => 'Everything is already synced.';

  @override
  String get noticeSyncFailed =>
      'Sync failed. Your reports are safe on this phone — try again later.';

  @override
  String get recoveryKeyTitle => 'Save your recovery key';

  @override
  String get recoveryKeyBody =>
      'Your backup is locked so only you can read it — not even Vitalog can. If you lose or reset this phone, this key unlocks your backup on the new one.';

  @override
  String get recoveryKeyICloud =>
      'It\'s also kept in your iCloud Keychain, so an iPhone signed in to the same Apple ID gets it without asking.';

  @override
  String get recoveryKeySave => 'Save to my passwords';

  @override
  String get recoveryKeyCopy => 'Copy key';

  @override
  String get recoveryKeyCopied =>
      'Recovery key copied. Paste it somewhere safe.';

  @override
  String get recoveryKeyDone => 'I\'ve saved it';

  @override
  String get recoveryKeyLater =>
      'You can see this key again on the Family tab.';

  @override
  String get recoveryKeyAskTitle => 'Enter your recovery key';

  @override
  String get recoveryKeyAskBody =>
      'Your backup is locked with the key you saved when you first synced. Tap the box to fill it from your saved passwords, or paste it.';

  @override
  String get recoveryKeyHint => 'ABCD-EFGH-…';

  @override
  String get recoveryKeyUse => 'Unlock my backup';

  @override
  String get recoveryKeyNotNow => 'Not now';

  @override
  String get recoveryKeyRow => 'Recovery key';

  @override
  String get recoveryKeyRowDetail => 'Unlocks your backup on a new phone.';

  @override
  String get noticeRecoveryKeyWrong =>
      'That key doesn\'t unlock this account\'s backup. Check it and try again.';

  @override
  String get noticeRecoveryKeyAccepted =>
      'Backup unlocked. Bringing your reports back…';

  @override
  String get noticeSignInRequired => 'Sign in to sync your reports.';

  @override
  String get noticeBackendNotConfigured =>
      'Cloud sync isn\'t set up in this build yet.';

  @override
  String get foreignAccountTitle => 'A different account signed in';

  @override
  String get foreignAccountBody =>
      'This phone already holds reports and family members for another account. Keeping them leaves those reports here, and this new account\'s data is added on top. Clearing removes everything stored on this phone only — its reports, the member list, learned test categories and their documents. The account\'s cloud backup is never touched.';

  @override
  String get foreignAccountKeep => 'Keep this phone\'s reports and continue';

  @override
  String get foreignAccountClear => 'Clear this phone, then restore';

  @override
  String get restoreFetching => 'Fetching your account data…';

  @override
  String memberRemoveNamed(String name) {
    return 'Remove “$name”?';
  }

  @override
  String get memberRemoveDetail => 'Their profile is removed from this phone.';

  @override
  String get memberRemoveSyncedNote =>
      'The account\'s cloud backup loses this profile too. If you share it with family, they keep it.';

  @override
  String get memberRemoveConfirm => 'Remove';

  @override
  String familyMemberRemoved(String name) {
    return '$name removed.';
  }

  @override
  String memberRemoveBlocked(String name) {
    return '$name still has reports here. Move or delete them first.';
  }

  @override
  String memberRemoveWithReports(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reports',
      one: '1 report',
    );
    return 'Remove $name and $_temp0?';
  }

  @override
  String get memberRemoveWithReportsDetail =>
      'Their reports, results and original files are deleted from this phone. This can’t be undone.';

  @override
  String get memberRemoveWithReportsConfirm => 'Remove with reports';

  @override
  String noticeMemberUpdated(String name) {
    return 'Saved changes to $name';
  }

  @override
  String get editMember => 'Edit details';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get photoTake => 'Take photo';

  @override
  String get photoChoose => 'Choose photo';

  @override
  String get photoRemove => 'Remove photo';

  @override
  String get remindersTitle => 'Reminders';

  @override
  String get remindersSubtitle =>
      'Nudges to get tested or add a report, set on this phone for you or anyone you look after.';

  @override
  String get remindersRowSubtitle => 'Get tested and add reports on time';

  @override
  String get remindersEmptyTitle => 'No reminders yet';

  @override
  String get remindersEmptyMessage =>
      'Set one for the next blood test, a thyroid recheck, or adding the latest report.';

  @override
  String get addReminder => 'Add reminder';

  @override
  String get editReminder => 'Edit reminder';

  @override
  String get reminderTitleLabel => 'What to remind';

  @override
  String get reminderTitleHint => 'Shown on the lock screen';

  @override
  String get reminderTitleRequired => 'Write what to remind';

  @override
  String get reminderPresetTest => 'Get tested';

  @override
  String get reminderPresetReport => 'Add the latest report';

  @override
  String get reminderForLabel => 'For';

  @override
  String get reminderWhenLabel => 'When';

  @override
  String get reminderRepeatLabel => 'Repeat';

  @override
  String get repeatOnce => 'Once';

  @override
  String get repeatMonthly => 'Every month';

  @override
  String get repeatEvery3Months => 'Every 3 months';

  @override
  String get repeatEvery6Months => 'Every 6 months';

  @override
  String get repeatYearly => 'Every year';

  @override
  String get saveReminder => 'Save reminder';

  @override
  String get deleteReminder => 'Delete reminder';

  @override
  String get deleteReminderDetail =>
      'It won’t remind you again. Reports aren’t affected.';

  @override
  String get reminderNoMore => 'No more reminders';

  @override
  String get reminderPrivacy => 'Set on this phone only. Never synced.';

  @override
  String get remindersTooltip => 'Reminders';

  @override
  String get remindersDueSoonTooltip => 'Reminders, one due this week';

  @override
  String get reminderInPast => 'Pick a time that’s still ahead';

  @override
  String get remindersNotificationsOff =>
      'Reminder saved. But Vitalog isn\'t allowed to show notifications, so it can\'t remind you. Tap Open Settings and turn on Notifications.';

  @override
  String reminderBody(String name) {
    return 'Reminder for $name';
  }

  @override
  String reminderNext(String when) {
    return 'Next: $when';
  }

  @override
  String deleteReminderTitle(String title) {
    return 'Delete “$title”?';
  }

  @override
  String get deleteAccountButton => 'Delete account';

  @override
  String get deleteAccountTitle => 'Delete this account?';

  @override
  String get deleteAccountMessage =>
      'This removes the account and everything synced with it — reports, results and family member profiles — plus this phone\'s local copy. Other accounts\' records are separate and stay untouched. This can\'t be undone.';

  @override
  String get deleteAccountConfirm => 'Delete account';

  @override
  String get accountDeletedNotice => 'Account deleted. This phone is clear.';

  @override
  String get accountDeleteFailedNotice =>
      'Couldn\'t reach the server to delete the account. Nothing changed.';

  @override
  String get familyEyebrow => 'Your household';

  @override
  String get familyTitle => 'Family profiles';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSubtitle => 'How the app looks, and your account.';

  @override
  String get familySubtitle => 'Choose whose health timeline you want to view.';

  @override
  String relationAge(String relation, int age) {
    return '$relation · $age years';
  }

  @override
  String reportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reports',
      one: '1 report',
      zero: 'No reports',
    );
    return '$_temp0';
  }

  @override
  String get addFamilyMember => 'Add family member';

  @override
  String get sampleDataNote =>
      'The first four profiles are sample data. Members you add and reports you upload stay on this phone.';

  @override
  String get accountTitle => 'Account';

  @override
  String signedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get signOutDetail => 'Your reports stay on this phone.';

  @override
  String get deleteAccountDetail => 'Removes your cloud backup for good.';

  @override
  String get accountStatMembers => 'Members';

  @override
  String get accountStatReports => 'Reports';

  @override
  String get accountStatUnsynced => 'To sync';

  @override
  String get signedOutMessage =>
      'Sign in to back up reports to the cloud with Sync.';

  @override
  String get signIn => 'Sign in';

  @override
  String get signOut => 'Sign out';

  @override
  String get signInTitle => 'Sign in';

  @override
  String get createAccountTitle => 'Create account';

  @override
  String get signInSubtitle =>
      'Your account is only used to back up reports when you tap Sync.';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get orDivider => 'or';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get signInButton => 'Sign in';

  @override
  String get createAccountButton => 'Create account';

  @override
  String get noAccount => 'New here? Create an account';

  @override
  String get haveAccount => 'Already have an account? Sign in';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get resetSent => 'Check your email for a reset link.';

  @override
  String get confirmEmailSent => 'Check your email to confirm your account.';

  @override
  String get emailInvalid => 'Enter a valid email';

  @override
  String get passwordTooShort => 'Use at least 8 characters';

  @override
  String get authFailed => 'Couldn’t sign in. Please try again.';

  @override
  String get authWrongDetails => 'Email or password is incorrect.';

  @override
  String get authTooManyTries =>
      'Too many attempts. Wait a few minutes, then try again.';

  @override
  String get authOffline =>
      'Can’t reach the server. Check your internet connection.';

  @override
  String get authWeakPassword =>
      'Choose a stronger password: at least 8 characters, with letters and numbers.';

  @override
  String get authConfirmEmail =>
      'Confirm your email first: open the link we sent you.';

  @override
  String categoryName(String id) {
    String _temp0 = intl.Intl.selectLogic(
      id,
      {
        'blood': 'Blood & CBC',
        'glucose': 'Glucose',
        'kidney': 'Kidney',
        'liver': 'Liver',
        'lipid': 'Lipid profile',
        'thyroid': 'Thyroid',
        'vitamins': 'Vitamins',
        'iron': 'Iron',
        'urine': 'Urine',
        'heart': 'Heart',
        'pancreas': 'Pancreas',
        'immunity': 'Immunity & inflammation',
        'cancer': 'Cancer markers',
        'hormones': 'Hormones',
        'infections': 'Infections',
        'clotting': 'Clotting',
        'other': 'Other',
      },
    );
    return '$_temp0';
  }

  @override
  String get editValue => 'Edit value';

  @override
  String get editResultTitle => 'Fix this result';

  @override
  String get editResultHint =>
      'Type what\'s printed on your report. We\'ll check it against the range again.';

  @override
  String get fieldTestName => 'Test name';

  @override
  String get fieldValue => 'Value';

  @override
  String get fieldUnit => 'Unit';

  @override
  String get fieldRange => 'Reference range';

  @override
  String get fieldRangeHint => 'For example, 0.4 - 4.0';

  @override
  String get fieldRequired => 'Enter what\'s printed on the report';

  @override
  String get save => 'Save';

  @override
  String get compareOriginal => 'Compare with original';

  @override
  String get editedBadge => 'Edited by you';

  @override
  String get needsReviewBanner =>
      'We couldn\'t read this one clearly. Check it against your report.';

  @override
  String get checkAndFix => 'Check & fix';

  @override
  String get looksRight => 'Looks right';

  @override
  String get statusCheckedNoRange => 'Checked · no range';

  @override
  String get noticeResultEdited =>
      'Saved. Status updated from the printed range.';

  @override
  String get noticeResultChecked => 'Marked as checked.';

  @override
  String get noticeReportDuplicate => 'You\'ve already added this report.';

  @override
  String get noticeFileTooLarge =>
      'That file is too big (over 50 MB), so it wasn\'t added.';

  @override
  String get originalsLockTitle => 'Lock your original reports?';

  @override
  String get originalsLockBody =>
      'Scanned reports show your name, address and phone number. With the lock on, opening them needs your face, fingerprint or screen-lock PIN. Your results stay visible as usual.';

  @override
  String get originalsLockNext =>
      'Next, your phone will ask you to confirm it\'s you.';

  @override
  String get originalsLockTurnOn => 'Turn on';

  @override
  String get originalsLockNotNow => 'Not now';

  @override
  String get originalsLockLater =>
      'You can change this anytime on the Family tab.';

  @override
  String get originalsLockSetting => 'Lock original reports';

  @override
  String get originalsLockSettingHint =>
      'Face, fingerprint or PIN to open scanned documents';

  @override
  String get noticeOriginalsLocked => 'Original reports are now locked.';

  @override
  String get noticeOriginalsUnlocked =>
      'Original reports no longer need unlocking.';

  @override
  String get noticeOriginalsLockUnchanged =>
      'Nothing changed: the unlock was cancelled, or this phone has no screen lock.';

  @override
  String get vaultPromptTitle => 'Open your original report';

  @override
  String get vaultPromptSubtitle =>
      'Use your fingerprint, face or screen-lock PIN, so only you can see it';

  @override
  String get viewReport => 'View';

  @override
  String get readingSecurely => 'Reading on this phone';

  @override
  String get addingReport => 'Adding your report…';

  @override
  String get splashTagline => 'A clearer picture, together.';

  @override
  String get customizeHome => 'Customize home';

  @override
  String get customizeHomeHint =>
      'Choose what shows on your Home screen. Hidden sections aren\'t loaded.';

  @override
  String get sectionLatestReport => 'Last tested date';

  @override
  String get sectionCategories => 'Health categories';

  @override
  String get sectionRecentResults => 'Recent results';

  @override
  String get sectionRangeNote => 'Lab range note';

  @override
  String get hiddenInSimpleMode => 'Hidden while Simple mode is on';

  @override
  String get simpleMode => 'Simple mode';

  @override
  String get simpleModeHint =>
      'Bigger, bolder text and buttons, plain words, fewer things on screen.';

  @override
  String get testedHeading => 'Tested';

  @override
  String get yetToTestHeading => 'Yet to test';

  @override
  String get yetToTestNote =>
      'No results yet. These are commonly checked. Ask your doctor whether you need them.';

  @override
  String keyTestsLine(String tests) {
    return 'Usually includes $tests';
  }

  @override
  String notYetLine(String tests) {
    return 'Not yet: $tests';
  }

  @override
  String get notTestedBadge => 'Not tested';

  @override
  String onAdviceLine(String tests) {
    return 'When your doctor advises · $tests';
  }

  @override
  String get fieldCategory => 'Category';

  @override
  String get chooseCategory => 'Choose a category';

  @override
  String needCategory(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count need a category',
      one: '1 needs a category',
    );
    return '$_temp0';
  }

  @override
  String get themeTitle => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageSystem => 'Device language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'हिन्दी';

  @override
  String get languageTelugu => 'తెలుగు';

  @override
  String get accentTitle => 'Accent colour';

  @override
  String get accentVitalog => 'Vitalog';

  @override
  String get accentOcean => 'Ocean';

  @override
  String get accentPlum => 'Plum';

  @override
  String get accentEmber => 'Ember';

  @override
  String get accentGraphite => 'Graphite';

  @override
  String get chooseFile => 'Choose a file (PDF, Word, Excel…)';

  @override
  String get unsupportedFileLine => 'This file type can\'t be read';

  @override
  String get noticeReportUnsupported =>
      'That file type can\'t be read, so it wasn\'t added. Try a photo, PDF, Word, Excel, CSV or text file.';

  @override
  String get noticeNotLabReport =>
      'That doesn\'t look like a lab report: no test results in it, so it wasn\'t added.';

  @override
  String get sectionOverview => 'Health at a glance';

  @override
  String get sectionTrends => 'Trends';

  @override
  String get overviewTitle => 'At a glance';

  @override
  String overviewOfTotal(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'of $total latest results within range',
      one: 'of 1 latest result within range',
    );
    return '$_temp0';
  }

  @override
  String get overviewNote => 'Counts each test\'s most recent value once.';

  @override
  String get legendWithinRange => 'Within range';

  @override
  String get legendNeedsReview => 'Needs review';

  @override
  String get legendOutsideRange => 'Outside range';

  @override
  String overviewSemantics(int good, int review, int outside) {
    return '$good within range, $review need review, $outside outside range';
  }

  @override
  String get trendsTitle => 'Trends';

  @override
  String get trendsSubtitle =>
      'Tests with more than one result. Shaded band = the lab\'s printed range.';

  @override
  String trendSince(String date) {
    return 'since $date';
  }

  @override
  String get trendNoChange => 'No change';

  @override
  String trendSemantics(
      String name, String value, String change, String status) {
    return '$name, latest $value, $change, $status';
  }

  @override
  String get shortHigh => 'High';

  @override
  String get shortLow => 'Low';

  @override
  String get moreActions => 'More actions';

  @override
  String deleteReportNamed(String name) {
    return 'Delete “$name”?';
  }

  @override
  String deleteReportDetail(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'The original document and its $count results will be removed from this phone. This can\'t be undone.',
      one:
          'The original document and its 1 result will be removed from this phone. This can\'t be undone.',
      zero:
          'The original document will be removed from this phone. This can\'t be undone.',
    );
    return '$_temp0';
  }

  @override
  String get deleteReportSyncedNote =>
      'Deleting also removes it from this account\'s cloud backup.';

  @override
  String get deleteReportConfirm => 'Delete Report';

  @override
  String get statusWithinUsual => 'Within usual range';

  @override
  String get statusHighUsual => 'High · usual range';

  @override
  String get statusLowUsual => 'Low · usual range';

  @override
  String usualRangeUsed(String range, String source) {
    return 'No range was printed, so the usual range was used: $range ($source).';
  }

  @override
  String usualRangeDiffers(String range) {
    return 'Your lab\'s range differs from the usual range ($range). Your lab\'s range is used.';
  }

  @override
  String get attentionTitle => 'Needs attention';

  @override
  String get attentionSubtitle =>
      'Outside the lab\'s range or the usual range. Not a diagnosis — talk to your doctor.';

  @override
  String attentionBelow(String value, String range) {
    return '$value is below the range ($range)';
  }

  @override
  String attentionAbove(String value, String range) {
    return '$value is above the range ($range)';
  }

  @override
  String get attentionUsualTag => 'usual range';

  @override
  String noticeReportAttention(int count, int attention) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tests added',
      one: '1 test added',
    );
    String _temp1 = intl.Intl.pluralLogic(
      attention,
      locale: localeName,
      other: '$attention need attention',
      one: '1 needs attention',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get noticeReportTimedOut =>
      'That report took too long to read. Try a clearer photo or fewer pages.';

  @override
  String noticeReportOtherPerson(String name) {
    return 'This report says $name. Check who it\'s filed under.';
  }

  @override
  String get noticeReportCancelled => 'Reading cancelled. Nothing was kept.';

  @override
  String noticeMemberAdded(String name) {
    return '$name added to your family.';
  }

  @override
  String get reviewAction => 'Review';

  @override
  String get cancelReading => 'Cancel reading';

  @override
  String get timedOutLine =>
      'Took too long to read. Try a clearer photo or fewer pages.';

  @override
  String nameMismatchLine(String name, String member) {
    return 'Name on this report: $name. It\'s filed under $member.';
  }

  @override
  String get keepHere => 'Keep here';

  @override
  String moveToMember(String name) {
    return 'Move to $name';
  }

  @override
  String get moveReport => 'Move to…';

  @override
  String get moveReportTitle => 'Whose report is this?';

  @override
  String noticeReportMoved(String name) {
    return 'Moved to $name.';
  }

  @override
  String get nameMatchesBadge => 'Name matches';

  @override
  String readingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count readings',
      one: '1 reading',
    );
    return '$_temp0';
  }

  @override
  String get addMemberTitle => 'Add family member';

  @override
  String get memberNameLabel => 'Full name, as on lab reports';

  @override
  String get memberNameRequired => 'Enter a name';

  @override
  String get relationLabel => 'Relation';

  @override
  String get relationSelf => 'You';

  @override
  String get relationPartner => 'Partner';

  @override
  String get relationChild => 'Child';

  @override
  String get relationParent => 'Parent';

  @override
  String get relationSibling => 'Sibling';

  @override
  String get relationGrandparent => 'Grandparent';

  @override
  String get relationOther => 'Other';

  @override
  String get ageLabel => 'Age (years)';

  @override
  String get ageInvalid => 'Enter an age from 0 to 120';

  @override
  String get sexLabel => 'Sex';

  @override
  String get sexFemale => 'Female';

  @override
  String get sexMale => 'Male';

  @override
  String get sexUnset => 'Not set';

  @override
  String get sexHelp =>
      'Some usual ranges differ by sex. If it\'s not set, those ranges aren\'t used.';

  @override
  String get saveMember => 'Add member';

  @override
  String get memberPrivacy => 'Saved on this phone only.';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingStart => 'Get started';

  @override
  String get onboardingTitle1 => 'Every lab report, in one place';

  @override
  String get onboardingBody1 =>
      'Take a photo, pick a PDF or any file. Each test is sorted into Blood, Thyroid, Vitamins and more.';

  @override
  String get onboardingTitle2 => 'Read right on your phone';

  @override
  String get onboardingBody2 =>
      'Reports are read here, on this phone. Nothing is sent anywhere unless you tap Sync.';

  @override
  String get onboardingTitle3 => 'Care for the whole family';

  @override
  String get onboardingBody3 =>
      'Keep a timeline for everyone you look after and see how each value changes over time.';

  @override
  String get welcomeTitle => 'Welcome to Vitalog';

  @override
  String get continueWithoutAccount => 'Continue without an account';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get statusPlainWithin => 'In range';

  @override
  String get statusPlainHigh => 'Higher than range';

  @override
  String get statusPlainLow => 'Lower than range';

  @override
  String get statusPlainReview => 'Please check';

  @override
  String onboardingPage(int page, int count) {
    return 'Page $page of $count';
  }

  @override
  String get notNow => 'Not now';

  @override
  String get createPasswordHint => 'At least 8 characters';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get nameCheckNote =>
      'This name is checked against the patient name printed on every report, so a report filed under the wrong person gets flagged.';

  @override
  String nameMustInclude(String name) {
    return 'Reports must include “$name” to match.';
  }

  @override
  String nameLooksLikeNickname(String name) {
    return '“$name” looks like a nickname. Labs print the real name, so their reports won\'t match.';
  }

  @override
  String get dateNotDetected => 'Date not found';

  @override
  String get pickerFailed =>
      'Vitalog isn\'t allowed to use the camera or your photos. To allow it, tap Open Settings and turn on Camera and Photos.';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get notifyAskTitle => 'Allow reminders?';

  @override
  String get notifyAskBody =>
      'To remind you on time, Vitalog needs to show notifications on this phone. They show only the reminder you wrote and the person\'s name, never test results.';

  @override
  String get notifyAskNext => 'Your phone will ask next. Tap “Allow”.';

  @override
  String get notifyAskContinue => 'Continue';

  @override
  String get notifyAskNotNow => 'Not now';

  @override
  String get notifyAskLater =>
      'You can change this anytime in your phone\'s Settings.';

  @override
  String shareMember(String name) {
    return 'Share $name\'s reports';
  }

  @override
  String shareIntro(String name) {
    return 'Family you invite can see $name\'s reports and add new ones from their own phone. It\'s end-to-end encrypted: only your family can read it, not even Vitalog.';
  }

  @override
  String shareUploadNote(String name) {
    return 'Inviting backs up $name\'s profile and reports to your account first, sealed.';
  }

  @override
  String get shareInvite => 'Invite someone';

  @override
  String get sharePeople => 'Who can see these reports';

  @override
  String shareYou(String name) {
    return '$name (you)';
  }

  @override
  String get shareYouPlain => 'You';

  @override
  String get shareSomeone => 'Someone in your family';

  @override
  String get sharePending => 'Invite waiting';

  @override
  String sharePendingUntil(String date) {
    return 'Link works until $date';
  }

  @override
  String get shareCancelInvite => 'Cancel invite';

  @override
  String get shareRemove => 'Remove';

  @override
  String shareRemoveTitle(String name, String person) {
    return 'Stop sharing $name\'s reports with $person?';
  }

  @override
  String shareRemoveMessage(String person) {
    return '$person won\'t get new reports. Reports already on their phone stay there.';
  }

  @override
  String get shareRemoveConfirm => 'Stop sharing';

  @override
  String shareMessage(String name, String link) {
    return 'I\'ve shared $name\'s health reports with you on Vitalog. Open this link on your phone to see them. It works once, for 7 days.\n$link';
  }

  @override
  String shareSubject(String name) {
    return '$name\'s health reports';
  }

  @override
  String get shareSignIn =>
      'Sign in to share. Your family see the reports on their own phones, through your account.';

  @override
  String get shareFailed =>
      'Couldn\'t reach your account. Check your connection and try again.';

  @override
  String get shareSample =>
      'Sample people can\'t be shared. Add your own family member first.';

  @override
  String get claimTitle => 'Family invite';

  @override
  String claimShared(String from, String name) {
    return '$from shared $name\'s reports with you';
  }

  @override
  String claimSharedNoFrom(String name) {
    return '$name\'s reports were shared with you';
  }

  @override
  String claimWho(String name) {
    return 'Who is $name to you?';
  }

  @override
  String get claimAccept => 'Add to my family';

  @override
  String get claimNotNow => 'Not now';

  @override
  String claimPrivacy(String name) {
    return 'The reports come to this phone, end-to-end encrypted. You can add reports for $name too, and everyone sharing them sees them.';
  }

  @override
  String get claimSignIn =>
      'Sign in to accept. The reports come to your account, sealed so only your family can read them.';

  @override
  String get claimAlready => 'You already have these reports.';

  @override
  String get claimOpen => 'Open';

  @override
  String get claimInvalid =>
      'This isn\'t a Vitalog invite link. Check that you copied all of it.';

  @override
  String get claimGone =>
      'This invite doesn\'t work any more. Ask for a new link.';

  @override
  String get claimUsed =>
      'Someone already used this invite. Each link works once, so ask for a new one.';

  @override
  String get claimExpired =>
      'This invite has expired. Links work for 7 days, so ask for a new one.';

  @override
  String get claimLimited =>
      'Too many tries. Wait an hour, then open the link again.';

  @override
  String get claimFailed =>
      'Couldn\'t reach Vitalog. Check your connection and try again.';

  @override
  String get claimRecoveryKey =>
      'Enter your recovery key first, then open the link again.';

  @override
  String get openInviteRow => 'Open an invite link';

  @override
  String get openInviteRowDetail => 'Family sent you a link? Paste it here.';

  @override
  String get pasteInviteTitle => 'Paste the invite link';

  @override
  String get pasteInviteOpen => 'Open';

  @override
  String noticeInviteAccepted(String name) {
    return '$name\'s reports are on your phone now';
  }
}
