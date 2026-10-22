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
  String loadFailed(String message) {
    return 'Could not load family health: $message';
  }

  @override
  String get tryAgain => 'Try again';

  @override
  String get noProfiles => 'No family profiles yet.';

  @override
  String get cancel => 'Cancel';

  @override
  String get homeEyebrow => 'Family health';

  @override
  String get homeTitle => 'A clearer picture,\ntogether.';

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
  String toReviewCount(int count) {
    return '$count to review';
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
  String get noCategoriesTitle => 'No categories yet';

  @override
  String get noCategoriesMessage =>
      'Results will be grouped here after a report is read.';

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
      'Add a photo or PDF of a lab report. It\'s read on this phone and every test is filed into its category.';

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
  String get takePhoto => 'Take a photo';

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
  String get noticeNothingToSync => 'Everything is already synced.';

  @override
  String get noticeSyncFailed =>
      'Sync failed. Your reports are safe on this phone — try again later.';

  @override
  String get noticeSignInRequired => 'Sign in to sync your reports.';

  @override
  String get noticeBackendNotConfigured =>
      'Cloud sync isn\'t set up in this build yet.';

  @override
  String get familyEyebrow => 'Your household';

  @override
  String get familyTitle => 'Family profiles';

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
  String get addFamilyMemberSoon =>
      'Adding family members will be available soon.';

  @override
  String get sampleDataNote =>
      'Family profiles are sample data in this prototype. Uploaded reports are stored on this phone.';

  @override
  String get accountTitle => 'Account';

  @override
  String signedInAs(String email) {
    return 'Signed in as $email';
  }

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
  String authFailed(String message) {
    return 'Couldn\'t sign in: $message';
  }

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
  String get noticeResultEdited =>
      'Saved. Status updated from the printed range.';

  @override
  String get viewReport => 'View';

  @override
  String get readingSecurely => 'Reading on this phone · encrypted';

  @override
  String get splashTagline => 'A clearer picture, together.';

  @override
  String get customizeHome => 'Customize home';

  @override
  String get customizeHomeHint =>
      'Choose what shows on your Home screen. Hidden sections aren\'t loaded.';

  @override
  String get sectionLatestReport => 'Latest report';

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
      'Bigger text and buttons, fewer things on screen.';

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
      'That file type can\'t be read. Try a photo, PDF, Word, Excel, CSV or text file.';

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
      other: 'of $total latest results within lab range',
      one: 'of 1 latest result within lab range',
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
      'Data you already synced stays in your cloud backup.';

  @override
  String get deleteReportConfirm => 'Delete Report';
}
