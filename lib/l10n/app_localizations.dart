import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_te.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('te')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Vitalog • Family Health'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get navCategories;

  /// No description provided for @navReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get navReports;

  /// No description provided for @navFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get navFamily;

  /// No description provided for @loadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load family health. Please try again.'**
  String get loadFailed;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @noProfiles.
  ///
  /// In en, this message translates to:
  /// **'No family profiles yet.'**
  String get noProfiles;

  /// No description provided for @emptyHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your family’s lab reports, in one place'**
  String get emptyHomeTitle;

  /// No description provided for @emptyHomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Results are read right on this phone and sorted into groups like these. Start by adding yourself or someone you look after.'**
  String get emptyHomeMessage;

  /// No description provided for @emptyCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Your results get sorted here'**
  String get emptyCategoriesTitle;

  /// No description provided for @emptyCategoriesMessage.
  ///
  /// In en, this message translates to:
  /// **'After you add a report, each test is placed in one of these groups.'**
  String get emptyCategoriesMessage;

  /// No description provided for @emptyReportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your lab reports will show here'**
  String get emptyReportsTitle;

  /// No description provided for @emptyReportsMessage.
  ///
  /// In en, this message translates to:
  /// **'Add a family member first. Then add a photo or PDF of their lab report.'**
  String get emptyReportsMessage;

  /// No description provided for @emptyFamilyTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up your family space'**
  String get emptyFamilyTitle;

  /// No description provided for @emptyFamilyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add profiles to keep each person’s reports and results together. Your display and account settings are ready below.'**
  String get emptyFamilyMessage;

  /// No description provided for @startWalkthrough.
  ///
  /// In en, this message translates to:
  /// **'Take a quick tour'**
  String get startWalkthrough;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @greetingWithName.
  ///
  /// In en, this message translates to:
  /// **'{greeting}, {name}'**
  String greetingWithName(String greeting, String name);

  /// No description provided for @homeVerdict.
  ///
  /// In en, this message translates to:
  /// **'{good} of {total, plural, =1{1 result is} other{{total} results are}} in range'**
  String homeVerdict(int good, int total);

  /// No description provided for @homeVerdictAll.
  ///
  /// In en, this message translates to:
  /// **'{total, plural, =1{Your 1 result is in range} other{All {total} results are in range}}'**
  String homeVerdictAll(int total);

  /// No description provided for @homeSnapshotFor.
  ///
  /// In en, this message translates to:
  /// **'Here’s {name}’s health snapshot'**
  String homeSnapshotFor(String name);

  /// No description provided for @lastTested.
  ///
  /// In en, this message translates to:
  /// **'Last tested {date}'**
  String lastTested(String date);

  /// No description provided for @periodAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get periodAll;

  /// No description provided for @periodYear.
  ///
  /// In en, this message translates to:
  /// **'1 year'**
  String get periodYear;

  /// No description provided for @periodSixMonths.
  ///
  /// In en, this message translates to:
  /// **'6 months'**
  String get periodSixMonths;

  /// No description provided for @historySemantics.
  ///
  /// In en, this message translates to:
  /// **'{test}: {count, plural, =1{1 reading} other{{count} readings}} from {from} to {to}. Latest {value}.'**
  String historySemantics(
      String test, int count, String from, String to, String value);

  /// No description provided for @homeGreetingTitle.
  ///
  /// In en, this message translates to:
  /// **'Here’s {name}’s latest'**
  String homeGreetingTitle(String name);

  /// No description provided for @tourMemberTitle.
  ///
  /// In en, this message translates to:
  /// **'Start with a person'**
  String get tourMemberTitle;

  /// No description provided for @tourMemberBody.
  ///
  /// In en, this message translates to:
  /// **'Add yourself or someone you look after. Each person keeps their own reports.'**
  String get tourMemberBody;

  /// No description provided for @tourCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Results, neatly grouped'**
  String get tourCategoriesTitle;

  /// No description provided for @tourCategoriesBody.
  ///
  /// In en, this message translates to:
  /// **'Every test lands in its group, like Blood, Thyroid or Vitamins.'**
  String get tourCategoriesBody;

  /// No description provided for @tourReportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Every report, by date'**
  String get tourReportsTitle;

  /// No description provided for @tourReportsBody.
  ///
  /// In en, this message translates to:
  /// **'Add a photo or PDF. It’s read on this phone, and nothing leaves it unless you tap Sync.'**
  String get tourReportsBody;

  /// No description provided for @tourFamilyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your family and settings'**
  String get tourFamilyTitle;

  /// No description provided for @tourFamilyBody.
  ///
  /// In en, this message translates to:
  /// **'Switch between people, add more, sign in for a backup, and change how the app looks.'**
  String get tourFamilyBody;

  /// No description provided for @walkthroughBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get walkthroughBack;

  /// No description provided for @walkthroughNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get walkthroughNext;

  /// No description provided for @walkthroughSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip tour'**
  String get walkthroughSkip;

  /// No description provided for @walkthroughDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get walkthroughDone;

  /// No description provided for @walkthroughStep.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {count}'**
  String walkthroughStep(int step, int count);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @switchProfileTooltip.
  ///
  /// In en, this message translates to:
  /// **'Switch family profile'**
  String get switchProfileTooltip;

  /// No description provided for @viewingHealthFor.
  ///
  /// In en, this message translates to:
  /// **'Viewing health for'**
  String get viewingHealthFor;

  /// No description provided for @latestReport.
  ///
  /// In en, this message translates to:
  /// **'Latest report'**
  String get latestReport;

  /// No description provided for @noReportsYet.
  ///
  /// In en, this message translates to:
  /// **'No reports yet'**
  String get noReportsYet;

  /// No description provided for @healthCategories.
  ///
  /// In en, this message translates to:
  /// **'Health categories'**
  String get healthCategories;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @recentResults.
  ///
  /// In en, this message translates to:
  /// **'Recent results'**
  String get recentResults;

  /// No description provided for @allResults.
  ///
  /// In en, this message translates to:
  /// **'All results'**
  String get allResults;

  /// No description provided for @noResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'No results yet'**
  String get noResultsTitle;

  /// No description provided for @noResultsMessage.
  ///
  /// In en, this message translates to:
  /// **'Add a report to begin a timeline for this family member.'**
  String get noResultsMessage;

  /// No description provided for @labRangeDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Lab ranges can vary. Status labels reflect the range printed with each result; they are not a diagnosis.'**
  String get labRangeDisclaimer;

  /// No description provided for @reportEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get reportEyebrow;

  /// No description provided for @reportDateValue.
  ///
  /// In en, this message translates to:
  /// **'Report date {date}'**
  String reportDateValue(String date);

  /// No description provided for @collectionDateValue.
  ///
  /// In en, this message translates to:
  /// **'Collected {date}'**
  String collectionDateValue(String date);

  /// No description provided for @labNotDetected.
  ///
  /// In en, this message translates to:
  /// **'Lab not detected'**
  String get labNotDetected;

  /// No description provided for @resultsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No results} =1{1 result} other{{count} results}}'**
  String resultsCount(int count);

  /// No description provided for @testsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 test} other{{count} tests}}'**
  String testsCount(int count);

  /// No description provided for @outsideRangeCount.
  ///
  /// In en, this message translates to:
  /// **'{count} outside range'**
  String outsideRangeCount(int count);

  /// No description provided for @reportResultsHeading.
  ///
  /// In en, this message translates to:
  /// **'Results in this report'**
  String get reportResultsHeading;

  /// No description provided for @statusWithinRange.
  ///
  /// In en, this message translates to:
  /// **'Within lab range'**
  String get statusWithinRange;

  /// No description provided for @statusHighPerReport.
  ///
  /// In en, this message translates to:
  /// **'High · per report'**
  String get statusHighPerReport;

  /// No description provided for @statusLowPerReport.
  ///
  /// In en, this message translates to:
  /// **'Low · per report'**
  String get statusLowPerReport;

  /// No description provided for @statusNeedsReview.
  ///
  /// In en, this message translates to:
  /// **'Needs review'**
  String get statusNeedsReview;

  /// No description provided for @categoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categoriesTitle;

  /// No description provided for @categoriesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Results grouped by system. A test may appear in more than one group.'**
  String get categoriesSubtitle;

  /// No description provided for @resultsLatest.
  ///
  /// In en, this message translates to:
  /// **'{results} · Latest {date}'**
  String resultsLatest(String results, String date);

  /// No description provided for @noCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to sort yet'**
  String get noCategoriesTitle;

  /// No description provided for @noCategoriesMessage.
  ///
  /// In en, this message translates to:
  /// **'Add a report and each test lands in its group.'**
  String get noCategoriesMessage;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No lab reports yet'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add their first report with the + button. Results, trends and anything that needs attention will show here.'**
  String get homeEmptyMessage;

  /// No description provided for @latestValuesFirst.
  ///
  /// In en, this message translates to:
  /// **'Latest values first'**
  String get latestValuesFirst;

  /// No description provided for @datePrintedNote.
  ///
  /// In en, this message translates to:
  /// **'Each date is the date printed on the report.'**
  String get datePrintedNote;

  /// No description provided for @noCategoryResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'No results in this category'**
  String get noCategoryResultsTitle;

  /// No description provided for @noCategoryResultsMessage.
  ///
  /// In en, this message translates to:
  /// **'Results will appear after a report has been read.'**
  String get noCategoryResultsMessage;

  /// No description provided for @testHistory.
  ///
  /// In en, this message translates to:
  /// **'Test history'**
  String get testHistory;

  /// No description provided for @unitNotPrinted.
  ///
  /// In en, this message translates to:
  /// **'Unit not printed'**
  String get unitNotPrinted;

  /// No description provided for @latestResult.
  ///
  /// In en, this message translates to:
  /// **'Latest result'**
  String get latestResult;

  /// No description provided for @referenceRangePrinted.
  ///
  /// In en, this message translates to:
  /// **'Reference range as printed: {range}'**
  String referenceRangePrinted(String range);

  /// No description provided for @rangeNotPrinted.
  ///
  /// In en, this message translates to:
  /// **'not printed'**
  String get rangeNotPrinted;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @chartNote.
  ///
  /// In en, this message translates to:
  /// **'Values shown in the same unit from their report dates.'**
  String get chartNote;

  /// No description provided for @trendEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'More results build the trend'**
  String get trendEmptyTitle;

  /// No description provided for @trendEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'A chart appears when at least two comparable numeric results are available.'**
  String get trendEmptyMessage;

  /// No description provided for @notDiagnosis.
  ///
  /// In en, this message translates to:
  /// **'This view records values printed by the lab and does not interpret them as a diagnosis.'**
  String get notDiagnosis;

  /// No description provided for @reportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsTitle;

  /// No description provided for @reportsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every uploaded report, newest first. Tap one to see just its results.'**
  String get reportsSubtitle;

  /// No description provided for @addReport.
  ///
  /// In en, this message translates to:
  /// **'Add a report'**
  String get addReport;

  /// No description provided for @sync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get sync;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get syncing;

  /// No description provided for @unsyncedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 report not synced} other{{count} reports not synced}}'**
  String unsyncedCount(int count);

  /// No description provided for @allSynced.
  ///
  /// In en, this message translates to:
  /// **'All reports synced'**
  String get allSynced;

  /// No description provided for @reportsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No reports yet'**
  String get reportsEmptyTitle;

  /// No description provided for @reportsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Tap Add a report below. Take a photo or choose a PDF; it\'s read on this phone only.'**
  String get reportsEmptyMessage;

  /// No description provided for @uploadedOn.
  ///
  /// In en, this message translates to:
  /// **'Uploaded {date}'**
  String uploadedOn(String date);

  /// No description provided for @reportStatusProcessing.
  ///
  /// In en, this message translates to:
  /// **'Reading…'**
  String get reportStatusProcessing;

  /// No description provided for @reportStatusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get reportStatusReady;

  /// No description provided for @reportStatusNeedsReview.
  ///
  /// In en, this message translates to:
  /// **'Needs review'**
  String get reportStatusNeedsReview;

  /// No description provided for @reportStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read'**
  String get reportStatusFailed;

  /// No description provided for @syncedBadge.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get syncedBadge;

  /// No description provided for @onDeviceBadge.
  ///
  /// In en, this message translates to:
  /// **'On this device'**
  String get onDeviceBadge;

  /// No description provided for @sampleBadge.
  ///
  /// In en, this message translates to:
  /// **'Sample'**
  String get sampleBadge;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this report?'**
  String get deleteReportTitle;

  /// No description provided for @deleteReportMessage.
  ///
  /// In en, this message translates to:
  /// **'The document and its results are removed from this phone.'**
  String get deleteReportMessage;

  /// No description provided for @addReportSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a lab report'**
  String get addReportSheetTitle;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Scan with camera'**
  String get takePhoto;

  /// No description provided for @choosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose from Photos'**
  String get choosePhoto;

  /// No description provided for @choosePdf.
  ///
  /// In en, this message translates to:
  /// **'Choose a PDF'**
  String get choosePdf;

  /// No description provided for @addReportPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Reports are read on this phone. Nothing is uploaded until you tap Sync.'**
  String get addReportPrivacy;

  /// No description provided for @noticeReportReady.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 test added} other{{count} tests added}}'**
  String noticeReportReady(int count);

  /// No description provided for @noticeReportNeedsReview.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 test added — some details need review} other{{count} tests added — some details need review}}'**
  String noticeReportNeedsReview(int count);

  /// No description provided for @noticeReportFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t find any tests in that document.'**
  String get noticeReportFailed;

  /// No description provided for @noticeSynced.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 report synced} other{{count} reports synced}}'**
  String noticeSynced(int count);

  /// No description provided for @noticeSyncRestored.
  ///
  /// In en, this message translates to:
  /// **'{reports, plural, =1{1 report} other{{reports} reports}} and {members, plural, =1{1 family member} other{{members} family members}} restored from your account.'**
  String noticeSyncRestored(int reports, int members);

  /// No description provided for @noticeSyncRestoredSent.
  ///
  /// In en, this message translates to:
  /// **'{reports, plural, =1{1 report} other{{reports} reports}} and {members, plural, =1{1 family member} other{{members} family members}} restored from your account · {count, plural, =1{1 report sent} other{{count} reports sent}}.'**
  String noticeSyncRestoredSent(int reports, int members, int count);

  /// No description provided for @noticeNothingToSync.
  ///
  /// In en, this message translates to:
  /// **'Everything is already synced.'**
  String get noticeNothingToSync;

  /// No description provided for @noticeSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed. Your reports are safe on this phone — try again later.'**
  String get noticeSyncFailed;

  /// No description provided for @recoveryKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Save your recovery key'**
  String get recoveryKeyTitle;

  /// No description provided for @recoveryKeyBody.
  ///
  /// In en, this message translates to:
  /// **'Your backup is locked so only you can read it — not even Vitalog can. If you lose or reset this phone, this key unlocks your backup on the new one.'**
  String get recoveryKeyBody;

  /// No description provided for @recoveryKeyICloud.
  ///
  /// In en, this message translates to:
  /// **'It\'s also kept in your iCloud Keychain, so an iPhone signed in to the same Apple ID gets it without asking.'**
  String get recoveryKeyICloud;

  /// No description provided for @recoveryKeySave.
  ///
  /// In en, this message translates to:
  /// **'Save to my passwords'**
  String get recoveryKeySave;

  /// No description provided for @recoveryKeyCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy key'**
  String get recoveryKeyCopy;

  /// No description provided for @recoveryKeyCopied.
  ///
  /// In en, this message translates to:
  /// **'Recovery key copied. Paste it somewhere safe.'**
  String get recoveryKeyCopied;

  /// No description provided for @recoveryKeyDone.
  ///
  /// In en, this message translates to:
  /// **'I\'ve saved it'**
  String get recoveryKeyDone;

  /// No description provided for @recoveryKeyLater.
  ///
  /// In en, this message translates to:
  /// **'You can see this key again on the Family tab.'**
  String get recoveryKeyLater;

  /// No description provided for @recoveryKeyAskTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your recovery key'**
  String get recoveryKeyAskTitle;

  /// No description provided for @recoveryKeyAskBody.
  ///
  /// In en, this message translates to:
  /// **'Your backup is locked with the key you saved when you first synced. Tap the box to fill it from your saved passwords, or paste it.'**
  String get recoveryKeyAskBody;

  /// No description provided for @recoveryKeyHint.
  ///
  /// In en, this message translates to:
  /// **'ABCD-EFGH-…'**
  String get recoveryKeyHint;

  /// No description provided for @recoveryKeyUse.
  ///
  /// In en, this message translates to:
  /// **'Unlock my backup'**
  String get recoveryKeyUse;

  /// No description provided for @recoveryKeyNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get recoveryKeyNotNow;

  /// No description provided for @recoveryKeyRow.
  ///
  /// In en, this message translates to:
  /// **'Recovery key'**
  String get recoveryKeyRow;

  /// No description provided for @recoveryKeyRowDetail.
  ///
  /// In en, this message translates to:
  /// **'Unlocks your backup on a new phone.'**
  String get recoveryKeyRowDetail;

  /// No description provided for @noticeRecoveryKeyWrong.
  ///
  /// In en, this message translates to:
  /// **'That key doesn\'t unlock this account\'s backup. Check it and try again.'**
  String get noticeRecoveryKeyWrong;

  /// No description provided for @noticeRecoveryKeyAccepted.
  ///
  /// In en, this message translates to:
  /// **'Backup unlocked. Bringing your reports back…'**
  String get noticeRecoveryKeyAccepted;

  /// No description provided for @noticeSignInRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in to sync your reports.'**
  String get noticeSignInRequired;

  /// No description provided for @noticeBackendNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Cloud sync isn\'t set up in this build yet.'**
  String get noticeBackendNotConfigured;

  /// No description provided for @foreignAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'A different account signed in'**
  String get foreignAccountTitle;

  /// No description provided for @foreignAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This phone already holds reports and family members for another account. Keeping them leaves those reports here, and this new account\'s data is added on top. Clearing removes everything stored on this phone only — its reports, the member list, learned test categories and their documents. The account\'s cloud backup is never touched.'**
  String get foreignAccountBody;

  /// No description provided for @foreignAccountKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep this phone\'s reports and continue'**
  String get foreignAccountKeep;

  /// No description provided for @foreignAccountClear.
  ///
  /// In en, this message translates to:
  /// **'Clear this phone, then restore'**
  String get foreignAccountClear;

  /// No description provided for @restoreFetching.
  ///
  /// In en, this message translates to:
  /// **'Fetching your account data…'**
  String get restoreFetching;

  /// No description provided for @memberRemoveNamed.
  ///
  /// In en, this message translates to:
  /// **'Remove “{name}”?'**
  String memberRemoveNamed(String name);

  /// No description provided for @memberRemoveDetail.
  ///
  /// In en, this message translates to:
  /// **'Their profile is removed from this phone.'**
  String get memberRemoveDetail;

  /// No description provided for @memberRemoveSyncedNote.
  ///
  /// In en, this message translates to:
  /// **'The account\'s cloud backup loses this profile too. If you share it with family, they keep it.'**
  String get memberRemoveSyncedNote;

  /// No description provided for @memberRemoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get memberRemoveConfirm;

  /// No description provided for @familyMemberRemoved.
  ///
  /// In en, this message translates to:
  /// **'{name} removed.'**
  String familyMemberRemoved(String name);

  /// No description provided for @memberRemoveBlocked.
  ///
  /// In en, this message translates to:
  /// **'{name} still has reports here. Move or delete them first.'**
  String memberRemoveBlocked(String name);

  /// No description provided for @memberRemoveWithReports.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} and {count, plural, =1{1 report} other{{count} reports}}?'**
  String memberRemoveWithReports(String name, int count);

  /// No description provided for @memberRemoveWithReportsDetail.
  ///
  /// In en, this message translates to:
  /// **'Their reports, results and original files are deleted from this phone. This can’t be undone.'**
  String get memberRemoveWithReportsDetail;

  /// No description provided for @memberRemoveWithReportsConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove with reports'**
  String get memberRemoveWithReportsConfirm;

  /// No description provided for @noticeMemberUpdated.
  ///
  /// In en, this message translates to:
  /// **'Saved changes to {name}'**
  String noticeMemberUpdated(String name);

  /// No description provided for @editMember.
  ///
  /// In en, this message translates to:
  /// **'Edit details'**
  String get editMember;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @photoTake.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get photoTake;

  /// No description provided for @photoChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose photo'**
  String get photoChoose;

  /// No description provided for @photoRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get photoRemove;

  /// No description provided for @remindersTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get remindersTitle;

  /// No description provided for @remindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Nudges to get tested or add a report, set on this phone for you or anyone you look after.'**
  String get remindersSubtitle;

  /// No description provided for @remindersRowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get tested and add reports on time'**
  String get remindersRowSubtitle;

  /// No description provided for @remindersEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No reminders yet'**
  String get remindersEmptyTitle;

  /// No description provided for @remindersEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Set one for the next blood test, a thyroid recheck, or adding the latest report.'**
  String get remindersEmptyMessage;

  /// No description provided for @addReminder.
  ///
  /// In en, this message translates to:
  /// **'Add reminder'**
  String get addReminder;

  /// No description provided for @editReminder.
  ///
  /// In en, this message translates to:
  /// **'Edit reminder'**
  String get editReminder;

  /// No description provided for @reminderTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'What to remind'**
  String get reminderTitleLabel;

  /// No description provided for @reminderTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Shown on the lock screen'**
  String get reminderTitleHint;

  /// No description provided for @reminderTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Write what to remind'**
  String get reminderTitleRequired;

  /// No description provided for @reminderPresetTest.
  ///
  /// In en, this message translates to:
  /// **'Get tested'**
  String get reminderPresetTest;

  /// No description provided for @reminderPresetReport.
  ///
  /// In en, this message translates to:
  /// **'Add the latest report'**
  String get reminderPresetReport;

  /// No description provided for @reminderForLabel.
  ///
  /// In en, this message translates to:
  /// **'For'**
  String get reminderForLabel;

  /// No description provided for @reminderWhenLabel.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get reminderWhenLabel;

  /// No description provided for @reminderRepeatLabel.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get reminderRepeatLabel;

  /// No description provided for @repeatOnce.
  ///
  /// In en, this message translates to:
  /// **'Once'**
  String get repeatOnce;

  /// No description provided for @repeatMonthly.
  ///
  /// In en, this message translates to:
  /// **'Every month'**
  String get repeatMonthly;

  /// No description provided for @repeatEvery3Months.
  ///
  /// In en, this message translates to:
  /// **'Every 3 months'**
  String get repeatEvery3Months;

  /// No description provided for @repeatEvery6Months.
  ///
  /// In en, this message translates to:
  /// **'Every 6 months'**
  String get repeatEvery6Months;

  /// No description provided for @repeatYearly.
  ///
  /// In en, this message translates to:
  /// **'Every year'**
  String get repeatYearly;

  /// No description provided for @saveReminder.
  ///
  /// In en, this message translates to:
  /// **'Save reminder'**
  String get saveReminder;

  /// No description provided for @deleteReminder.
  ///
  /// In en, this message translates to:
  /// **'Delete reminder'**
  String get deleteReminder;

  /// No description provided for @deleteReminderDetail.
  ///
  /// In en, this message translates to:
  /// **'It won’t remind you again. Reports aren’t affected.'**
  String get deleteReminderDetail;

  /// No description provided for @reminderNoMore.
  ///
  /// In en, this message translates to:
  /// **'No more reminders'**
  String get reminderNoMore;

  /// No description provided for @reminderPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Set on this phone only. Never synced.'**
  String get reminderPrivacy;

  /// No description provided for @remindersTooltip.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get remindersTooltip;

  /// Tooltip/screen-reader name of the Home bell when its dot shows a reminder due within 7 days.
  ///
  /// In en, this message translates to:
  /// **'Reminders, one due this week'**
  String get remindersDueSoonTooltip;

  /// No description provided for @reminderInPast.
  ///
  /// In en, this message translates to:
  /// **'Pick a time that’s still ahead'**
  String get reminderInPast;

  /// No description provided for @remindersNotificationsOff.
  ///
  /// In en, this message translates to:
  /// **'Reminder saved. But Vitalog isn\'t allowed to show notifications, so it can\'t remind you. Tap Open Settings and turn on Notifications.'**
  String get remindersNotificationsOff;

  /// No description provided for @reminderBody.
  ///
  /// In en, this message translates to:
  /// **'Reminder for {name}'**
  String reminderBody(String name);

  /// No description provided for @reminderNext.
  ///
  /// In en, this message translates to:
  /// **'Next: {when}'**
  String reminderNext(String when);

  /// No description provided for @deleteReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete “{title}”?'**
  String deleteReminderTitle(String title);

  /// No description provided for @deleteAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccountButton;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountMessage.
  ///
  /// In en, this message translates to:
  /// **'This removes the account and everything synced with it — reports, results and family member profiles — plus this phone\'s local copy. Other accounts\' records are separate and stay untouched. This can\'t be undone.'**
  String get deleteAccountMessage;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccountConfirm;

  /// No description provided for @accountDeletedNotice.
  ///
  /// In en, this message translates to:
  /// **'Account deleted. This phone is clear.'**
  String get accountDeletedNotice;

  /// No description provided for @accountDeleteFailedNotice.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach the server to delete the account. Nothing changed.'**
  String get accountDeleteFailedNotice;

  /// No description provided for @familyEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Your household'**
  String get familyEyebrow;

  /// No description provided for @familyTitle.
  ///
  /// In en, this message translates to:
  /// **'Family profiles'**
  String get familyTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How the app looks, and your account.'**
  String get settingsSubtitle;

  /// No description provided for @familySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose whose health timeline you want to view.'**
  String get familySubtitle;

  /// No description provided for @relationAge.
  ///
  /// In en, this message translates to:
  /// **'{relation} · {age} years'**
  String relationAge(String relation, int age);

  /// No description provided for @reportCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No reports} =1{1 report} other{{count} reports}}'**
  String reportCount(int count);

  /// No description provided for @addFamilyMember.
  ///
  /// In en, this message translates to:
  /// **'Add family member'**
  String get addFamilyMember;

  /// No description provided for @sampleDataNote.
  ///
  /// In en, this message translates to:
  /// **'The first four profiles are sample data. Members you add and reports you upload stay on this phone.'**
  String get sampleDataNote;

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountTitle;

  /// No description provided for @signedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String signedInAs(String email);

  /// No description provided for @signOutDetail.
  ///
  /// In en, this message translates to:
  /// **'Your reports stay on this phone.'**
  String get signOutDetail;

  /// No description provided for @deleteAccountDetail.
  ///
  /// In en, this message translates to:
  /// **'Removes your cloud backup for good.'**
  String get deleteAccountDetail;

  /// No description provided for @accountStatMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get accountStatMembers;

  /// No description provided for @accountStatReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get accountStatReports;

  /// No description provided for @accountStatUnsynced.
  ///
  /// In en, this message translates to:
  /// **'To sync'**
  String get accountStatUnsynced;

  /// No description provided for @signedOutMessage.
  ///
  /// In en, this message translates to:
  /// **'Sign in to back up reports to the cloud with Sync.'**
  String get signedOutMessage;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInTitle;

  /// No description provided for @createAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccountTitle;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your account is only used to back up reports when you tap Sync.'**
  String get signInSubtitle;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orDivider;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @signInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInButton;

  /// No description provided for @createAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccountButton;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'New here? Create an account'**
  String get noAccount;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get haveAccount;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @resetSent.
  ///
  /// In en, this message translates to:
  /// **'Check your email for a reset link.'**
  String get resetSent;

  /// No description provided for @confirmEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Check your email to confirm your account.'**
  String get confirmEmailSent;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get emailInvalid;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters'**
  String get passwordTooShort;

  /// No description provided for @authFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t sign in. Please try again.'**
  String get authFailed;

  /// No description provided for @authWrongDetails.
  ///
  /// In en, this message translates to:
  /// **'Email or password is incorrect.'**
  String get authWrongDetails;

  /// No description provided for @authTooManyTries.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait a few minutes, then try again.'**
  String get authTooManyTries;

  /// No description provided for @authOffline.
  ///
  /// In en, this message translates to:
  /// **'Can’t reach the server. Check your internet connection.'**
  String get authOffline;

  /// No description provided for @authWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Choose a stronger password: at least 8 characters, with letters and numbers.'**
  String get authWeakPassword;

  /// No description provided for @authConfirmEmail.
  ///
  /// In en, this message translates to:
  /// **'Confirm your email first: open the link we sent you.'**
  String get authConfirmEmail;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'{id, select, blood{Blood & CBC} glucose{Glucose} kidney{Kidney} liver{Liver} lipid{Lipid profile} thyroid{Thyroid} vitamins{Vitamins} iron{Iron} urine{Urine} heart{Heart} pancreas{Pancreas} immunity{Immunity & inflammation} cancer{Cancer markers} hormones{Hormones} infections{Infections} clotting{Clotting} other{Other}}'**
  String categoryName(String id);

  /// No description provided for @editValue.
  ///
  /// In en, this message translates to:
  /// **'Edit value'**
  String get editValue;

  /// No description provided for @editResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Fix this result'**
  String get editResultTitle;

  /// No description provided for @editResultHint.
  ///
  /// In en, this message translates to:
  /// **'Type what\'s printed on your report. We\'ll check it against the range again.'**
  String get editResultHint;

  /// No description provided for @fieldTestName.
  ///
  /// In en, this message translates to:
  /// **'Test name'**
  String get fieldTestName;

  /// No description provided for @fieldValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get fieldValue;

  /// No description provided for @fieldUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get fieldUnit;

  /// No description provided for @fieldRange.
  ///
  /// In en, this message translates to:
  /// **'Reference range'**
  String get fieldRange;

  /// No description provided for @fieldRangeHint.
  ///
  /// In en, this message translates to:
  /// **'For example, 0.4 - 4.0'**
  String get fieldRangeHint;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter what\'s printed on the report'**
  String get fieldRequired;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @compareOriginal.
  ///
  /// In en, this message translates to:
  /// **'Compare with original'**
  String get compareOriginal;

  /// No description provided for @editedBadge.
  ///
  /// In en, this message translates to:
  /// **'Edited by you'**
  String get editedBadge;

  /// No description provided for @needsReviewBanner.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t read this one clearly. Check it against your report.'**
  String get needsReviewBanner;

  /// No description provided for @checkAndFix.
  ///
  /// In en, this message translates to:
  /// **'Check & fix'**
  String get checkAndFix;

  /// No description provided for @looksRight.
  ///
  /// In en, this message translates to:
  /// **'Looks right'**
  String get looksRight;

  /// No description provided for @statusCheckedNoRange.
  ///
  /// In en, this message translates to:
  /// **'Checked · no range'**
  String get statusCheckedNoRange;

  /// No description provided for @noticeResultEdited.
  ///
  /// In en, this message translates to:
  /// **'Saved. Status updated from the printed range.'**
  String get noticeResultEdited;

  /// No description provided for @noticeResultChecked.
  ///
  /// In en, this message translates to:
  /// **'Marked as checked.'**
  String get noticeResultChecked;

  /// No description provided for @noticeReportDuplicate.
  ///
  /// In en, this message translates to:
  /// **'You\'ve already added this report.'**
  String get noticeReportDuplicate;

  /// No description provided for @noticeFileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'That file is too big (over 50 MB), so it wasn\'t added.'**
  String get noticeFileTooLarge;

  /// No description provided for @originalsLockTitle.
  ///
  /// In en, this message translates to:
  /// **'Lock your original reports?'**
  String get originalsLockTitle;

  /// No description provided for @originalsLockBody.
  ///
  /// In en, this message translates to:
  /// **'Scanned reports show your name, address and phone number. With the lock on, opening them needs your face, fingerprint or screen-lock PIN. Your results stay visible as usual.'**
  String get originalsLockBody;

  /// No description provided for @originalsLockNext.
  ///
  /// In en, this message translates to:
  /// **'Next, your phone will ask you to confirm it\'s you.'**
  String get originalsLockNext;

  /// No description provided for @originalsLockTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get originalsLockTurnOn;

  /// No description provided for @originalsLockNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get originalsLockNotNow;

  /// No description provided for @originalsLockLater.
  ///
  /// In en, this message translates to:
  /// **'You can change this anytime on the Family tab.'**
  String get originalsLockLater;

  /// No description provided for @originalsLockSetting.
  ///
  /// In en, this message translates to:
  /// **'Lock original reports'**
  String get originalsLockSetting;

  /// No description provided for @originalsLockSettingHint.
  ///
  /// In en, this message translates to:
  /// **'Face, fingerprint or PIN to open scanned documents'**
  String get originalsLockSettingHint;

  /// No description provided for @noticeOriginalsLocked.
  ///
  /// In en, this message translates to:
  /// **'Original reports are now locked.'**
  String get noticeOriginalsLocked;

  /// No description provided for @noticeOriginalsUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Original reports no longer need unlocking.'**
  String get noticeOriginalsUnlocked;

  /// No description provided for @noticeOriginalsLockUnchanged.
  ///
  /// In en, this message translates to:
  /// **'Nothing changed: the unlock was cancelled, or this phone has no screen lock.'**
  String get noticeOriginalsLockUnchanged;

  /// No description provided for @vaultPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Open your original report'**
  String get vaultPromptTitle;

  /// No description provided for @vaultPromptSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use your fingerprint, face or screen-lock PIN, so only you can see it'**
  String get vaultPromptSubtitle;

  /// No description provided for @viewReport.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get viewReport;

  /// No description provided for @readingSecurely.
  ///
  /// In en, this message translates to:
  /// **'Reading on this phone'**
  String get readingSecurely;

  /// No description provided for @addingReport.
  ///
  /// In en, this message translates to:
  /// **'Adding your report…'**
  String get addingReport;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'A clearer picture, together.'**
  String get splashTagline;

  /// No description provided for @customizeHome.
  ///
  /// In en, this message translates to:
  /// **'Customize home'**
  String get customizeHome;

  /// No description provided for @customizeHomeHint.
  ///
  /// In en, this message translates to:
  /// **'Choose what shows on your Home screen. Hidden sections aren\'t loaded.'**
  String get customizeHomeHint;

  /// No description provided for @sectionLatestReport.
  ///
  /// In en, this message translates to:
  /// **'Last tested date'**
  String get sectionLatestReport;

  /// No description provided for @sectionCategories.
  ///
  /// In en, this message translates to:
  /// **'Health categories'**
  String get sectionCategories;

  /// No description provided for @sectionRecentResults.
  ///
  /// In en, this message translates to:
  /// **'Recent results'**
  String get sectionRecentResults;

  /// No description provided for @sectionRangeNote.
  ///
  /// In en, this message translates to:
  /// **'Lab range note'**
  String get sectionRangeNote;

  /// No description provided for @hiddenInSimpleMode.
  ///
  /// In en, this message translates to:
  /// **'Hidden while Simple mode is on'**
  String get hiddenInSimpleMode;

  /// No description provided for @simpleMode.
  ///
  /// In en, this message translates to:
  /// **'Simple mode'**
  String get simpleMode;

  /// No description provided for @simpleModeHint.
  ///
  /// In en, this message translates to:
  /// **'Bigger, bolder text and buttons, plain words, fewer things on screen.'**
  String get simpleModeHint;

  /// No description provided for @testedHeading.
  ///
  /// In en, this message translates to:
  /// **'Tested'**
  String get testedHeading;

  /// No description provided for @yetToTestHeading.
  ///
  /// In en, this message translates to:
  /// **'Yet to test'**
  String get yetToTestHeading;

  /// No description provided for @yetToTestNote.
  ///
  /// In en, this message translates to:
  /// **'No results yet. These are commonly checked. Ask your doctor whether you need them.'**
  String get yetToTestNote;

  /// No description provided for @keyTestsLine.
  ///
  /// In en, this message translates to:
  /// **'Usually includes {tests}'**
  String keyTestsLine(String tests);

  /// No description provided for @notYetLine.
  ///
  /// In en, this message translates to:
  /// **'Not yet: {tests}'**
  String notYetLine(String tests);

  /// No description provided for @notTestedBadge.
  ///
  /// In en, this message translates to:
  /// **'Not tested'**
  String get notTestedBadge;

  /// No description provided for @onAdviceLine.
  ///
  /// In en, this message translates to:
  /// **'When your doctor advises · {tests}'**
  String onAdviceLine(String tests);

  /// No description provided for @fieldCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get fieldCategory;

  /// No description provided for @chooseCategory.
  ///
  /// In en, this message translates to:
  /// **'Choose a category'**
  String get chooseCategory;

  /// No description provided for @needCategory.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 needs a category} other{{count} need a category}}'**
  String needCategory(int count);

  /// No description provided for @themeTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeTitle;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'Device language'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageHindi.
  ///
  /// In en, this message translates to:
  /// **'हिन्दी'**
  String get languageHindi;

  /// No description provided for @languageTelugu.
  ///
  /// In en, this message translates to:
  /// **'తెలుగు'**
  String get languageTelugu;

  /// No description provided for @accentTitle.
  ///
  /// In en, this message translates to:
  /// **'Accent colour'**
  String get accentTitle;

  /// No description provided for @accentVitalog.
  ///
  /// In en, this message translates to:
  /// **'Vitalog'**
  String get accentVitalog;

  /// No description provided for @accentOcean.
  ///
  /// In en, this message translates to:
  /// **'Ocean'**
  String get accentOcean;

  /// No description provided for @accentPlum.
  ///
  /// In en, this message translates to:
  /// **'Plum'**
  String get accentPlum;

  /// No description provided for @accentEmber.
  ///
  /// In en, this message translates to:
  /// **'Ember'**
  String get accentEmber;

  /// No description provided for @accentGraphite.
  ///
  /// In en, this message translates to:
  /// **'Graphite'**
  String get accentGraphite;

  /// No description provided for @chooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose a file (PDF, Word, Excel…)'**
  String get chooseFile;

  /// No description provided for @unsupportedFileLine.
  ///
  /// In en, this message translates to:
  /// **'This file type can\'t be read'**
  String get unsupportedFileLine;

  /// No description provided for @noticeReportUnsupported.
  ///
  /// In en, this message translates to:
  /// **'That file type can\'t be read, so it wasn\'t added. Try a photo, PDF, Word, Excel, CSV or text file.'**
  String get noticeReportUnsupported;

  /// No description provided for @noticeNotLabReport.
  ///
  /// In en, this message translates to:
  /// **'That doesn\'t look like a lab report: no test results in it, so it wasn\'t added.'**
  String get noticeNotLabReport;

  /// No description provided for @sectionOverview.
  ///
  /// In en, this message translates to:
  /// **'Health at a glance'**
  String get sectionOverview;

  /// No description provided for @sectionTrends.
  ///
  /// In en, this message translates to:
  /// **'Trends'**
  String get sectionTrends;

  /// No description provided for @overviewTitle.
  ///
  /// In en, this message translates to:
  /// **'At a glance'**
  String get overviewTitle;

  /// No description provided for @overviewOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{total, plural, =1{of 1 latest result within range} other{of {total} latest results within range}}'**
  String overviewOfTotal(int total);

  /// No description provided for @overviewNote.
  ///
  /// In en, this message translates to:
  /// **'Counts each test\'s most recent value once.'**
  String get overviewNote;

  /// No description provided for @legendWithinRange.
  ///
  /// In en, this message translates to:
  /// **'Within range'**
  String get legendWithinRange;

  /// No description provided for @legendNeedsReview.
  ///
  /// In en, this message translates to:
  /// **'Needs review'**
  String get legendNeedsReview;

  /// No description provided for @legendOutsideRange.
  ///
  /// In en, this message translates to:
  /// **'Outside range'**
  String get legendOutsideRange;

  /// No description provided for @overviewSemantics.
  ///
  /// In en, this message translates to:
  /// **'{good} within range, {review} need review, {outside} outside range'**
  String overviewSemantics(int good, int review, int outside);

  /// No description provided for @trendsTitle.
  ///
  /// In en, this message translates to:
  /// **'Trends'**
  String get trendsTitle;

  /// No description provided for @trendsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tests with more than one result. Shaded band = the lab\'s printed range.'**
  String get trendsSubtitle;

  /// No description provided for @trendSince.
  ///
  /// In en, this message translates to:
  /// **'since {date}'**
  String trendSince(String date);

  /// No description provided for @trendNoChange.
  ///
  /// In en, this message translates to:
  /// **'No change'**
  String get trendNoChange;

  /// No description provided for @trendSemantics.
  ///
  /// In en, this message translates to:
  /// **'{name}, latest {value}, {change}, {status}'**
  String trendSemantics(
      String name, String value, String change, String status);

  /// No description provided for @shortHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get shortHigh;

  /// No description provided for @shortLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get shortLow;

  /// No description provided for @moreActions.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get moreActions;

  /// No description provided for @deleteReportNamed.
  ///
  /// In en, this message translates to:
  /// **'Delete “{name}”?'**
  String deleteReportNamed(String name);

  /// No description provided for @deleteReportDetail.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{The original document will be removed from this phone. This can\'t be undone.} =1{The original document and its 1 result will be removed from this phone. This can\'t be undone.} other{The original document and its {count} results will be removed from this phone. This can\'t be undone.}}'**
  String deleteReportDetail(int count);

  /// No description provided for @deleteReportSyncedNote.
  ///
  /// In en, this message translates to:
  /// **'Deleting also removes it from this account\'s cloud backup.'**
  String get deleteReportSyncedNote;

  /// No description provided for @deleteReportConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete Report'**
  String get deleteReportConfirm;

  /// No description provided for @statusWithinUsual.
  ///
  /// In en, this message translates to:
  /// **'Within usual range'**
  String get statusWithinUsual;

  /// No description provided for @statusHighUsual.
  ///
  /// In en, this message translates to:
  /// **'High · usual range'**
  String get statusHighUsual;

  /// No description provided for @statusLowUsual.
  ///
  /// In en, this message translates to:
  /// **'Low · usual range'**
  String get statusLowUsual;

  /// No description provided for @usualRangeUsed.
  ///
  /// In en, this message translates to:
  /// **'No range was printed, so the usual range was used: {range} ({source}).'**
  String usualRangeUsed(String range, String source);

  /// No description provided for @usualRangeDiffers.
  ///
  /// In en, this message translates to:
  /// **'Your lab\'s range differs from the usual range ({range}). Your lab\'s range is used.'**
  String usualRangeDiffers(String range);

  /// No description provided for @attentionTitle.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get attentionTitle;

  /// No description provided for @attentionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Outside the lab\'s range or the usual range. Not a diagnosis — talk to your doctor.'**
  String get attentionSubtitle;

  /// No description provided for @attentionBelow.
  ///
  /// In en, this message translates to:
  /// **'{value} is below the range ({range})'**
  String attentionBelow(String value, String range);

  /// No description provided for @attentionAbove.
  ///
  /// In en, this message translates to:
  /// **'{value} is above the range ({range})'**
  String attentionAbove(String value, String range);

  /// No description provided for @attentionUsualTag.
  ///
  /// In en, this message translates to:
  /// **'usual range'**
  String get attentionUsualTag;

  /// No description provided for @noticeReportAttention.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 test added} other{{count} tests added}} · {attention, plural, =1{1 needs attention} other{{attention} need attention}}'**
  String noticeReportAttention(int count, int attention);

  /// No description provided for @noticeReportTimedOut.
  ///
  /// In en, this message translates to:
  /// **'That report took too long to read. Try a clearer photo or fewer pages.'**
  String get noticeReportTimedOut;

  /// No description provided for @noticeReportOtherPerson.
  ///
  /// In en, this message translates to:
  /// **'This report says {name}. Check who it\'s filed under.'**
  String noticeReportOtherPerson(String name);

  /// No description provided for @noticeReportCancelled.
  ///
  /// In en, this message translates to:
  /// **'Reading cancelled. Nothing was kept.'**
  String get noticeReportCancelled;

  /// No description provided for @noticeMemberAdded.
  ///
  /// In en, this message translates to:
  /// **'{name} added to your family.'**
  String noticeMemberAdded(String name);

  /// No description provided for @reviewAction.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get reviewAction;

  /// No description provided for @cancelReading.
  ///
  /// In en, this message translates to:
  /// **'Cancel reading'**
  String get cancelReading;

  /// No description provided for @timedOutLine.
  ///
  /// In en, this message translates to:
  /// **'Took too long to read. Try a clearer photo or fewer pages.'**
  String get timedOutLine;

  /// No description provided for @nameMismatchLine.
  ///
  /// In en, this message translates to:
  /// **'Name on this report: {name}. It\'s filed under {member}.'**
  String nameMismatchLine(String name, String member);

  /// No description provided for @keepHere.
  ///
  /// In en, this message translates to:
  /// **'Keep here'**
  String get keepHere;

  /// No description provided for @moveToMember.
  ///
  /// In en, this message translates to:
  /// **'Move to {name}'**
  String moveToMember(String name);

  /// No description provided for @moveReport.
  ///
  /// In en, this message translates to:
  /// **'Move to…'**
  String get moveReport;

  /// No description provided for @moveReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Whose report is this?'**
  String get moveReportTitle;

  /// No description provided for @noticeReportMoved.
  ///
  /// In en, this message translates to:
  /// **'Moved to {name}.'**
  String noticeReportMoved(String name);

  /// No description provided for @nameMatchesBadge.
  ///
  /// In en, this message translates to:
  /// **'Name matches'**
  String get nameMatchesBadge;

  /// No description provided for @readingsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 reading} other{{count} readings}}'**
  String readingsCount(int count);

  /// No description provided for @addMemberTitle.
  ///
  /// In en, this message translates to:
  /// **'Add family member'**
  String get addMemberTitle;

  /// No description provided for @memberNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name, as on lab reports'**
  String get memberNameLabel;

  /// No description provided for @memberNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get memberNameRequired;

  /// No description provided for @relationLabel.
  ///
  /// In en, this message translates to:
  /// **'Relation'**
  String get relationLabel;

  /// No description provided for @relationSelf.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get relationSelf;

  /// No description provided for @relationPartner.
  ///
  /// In en, this message translates to:
  /// **'Partner'**
  String get relationPartner;

  /// No description provided for @relationChild.
  ///
  /// In en, this message translates to:
  /// **'Child'**
  String get relationChild;

  /// No description provided for @relationParent.
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get relationParent;

  /// No description provided for @relationSibling.
  ///
  /// In en, this message translates to:
  /// **'Sibling'**
  String get relationSibling;

  /// No description provided for @relationGrandparent.
  ///
  /// In en, this message translates to:
  /// **'Grandparent'**
  String get relationGrandparent;

  /// No description provided for @relationOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get relationOther;

  /// No description provided for @ageLabel.
  ///
  /// In en, this message translates to:
  /// **'Age (years)'**
  String get ageLabel;

  /// No description provided for @ageInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter an age from 0 to 120'**
  String get ageInvalid;

  /// No description provided for @sexLabel.
  ///
  /// In en, this message translates to:
  /// **'Sex'**
  String get sexLabel;

  /// No description provided for @sexFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get sexFemale;

  /// No description provided for @sexMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get sexMale;

  /// No description provided for @sexUnset.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get sexUnset;

  /// No description provided for @sexHelp.
  ///
  /// In en, this message translates to:
  /// **'Some usual ranges differ by sex. If it\'s not set, those ranges aren\'t used.'**
  String get sexHelp;

  /// No description provided for @saveMember.
  ///
  /// In en, this message translates to:
  /// **'Add member'**
  String get saveMember;

  /// No description provided for @memberPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Saved on this phone only.'**
  String get memberPrivacy;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingStart.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingStart;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Every lab report, in one place'**
  String get onboardingTitle1;

  /// No description provided for @onboardingBody1.
  ///
  /// In en, this message translates to:
  /// **'Take a photo, pick a PDF or any file. Each test is sorted into Blood, Thyroid, Vitamins and more.'**
  String get onboardingBody1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Read right on your phone'**
  String get onboardingTitle2;

  /// No description provided for @onboardingBody2.
  ///
  /// In en, this message translates to:
  /// **'Reports are read here, on this phone. Nothing is sent anywhere unless you tap Sync.'**
  String get onboardingBody2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Care for the whole family'**
  String get onboardingTitle3;

  /// No description provided for @onboardingBody3.
  ///
  /// In en, this message translates to:
  /// **'Keep a timeline for everyone you look after and see how each value changes over time.'**
  String get onboardingBody3;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Vitalog'**
  String get welcomeTitle;

  /// No description provided for @continueWithoutAccount.
  ///
  /// In en, this message translates to:
  /// **'Continue without an account'**
  String get continueWithoutAccount;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @statusPlainWithin.
  ///
  /// In en, this message translates to:
  /// **'In range'**
  String get statusPlainWithin;

  /// No description provided for @statusPlainHigh.
  ///
  /// In en, this message translates to:
  /// **'Higher than range'**
  String get statusPlainHigh;

  /// No description provided for @statusPlainLow.
  ///
  /// In en, this message translates to:
  /// **'Lower than range'**
  String get statusPlainLow;

  /// No description provided for @statusPlainReview.
  ///
  /// In en, this message translates to:
  /// **'Please check'**
  String get statusPlainReview;

  /// No description provided for @onboardingPage.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {count}'**
  String onboardingPage(int page, int count);

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @createPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get createPasswordHint;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @nameCheckNote.
  ///
  /// In en, this message translates to:
  /// **'This name is checked against the patient name printed on every report, so a report filed under the wrong person gets flagged.'**
  String get nameCheckNote;

  /// No description provided for @nameMustInclude.
  ///
  /// In en, this message translates to:
  /// **'Reports must include “{name}” to match.'**
  String nameMustInclude(String name);

  /// No description provided for @nameLooksLikeNickname.
  ///
  /// In en, this message translates to:
  /// **'“{name}” looks like a nickname. Labs print the real name, so their reports won\'t match.'**
  String nameLooksLikeNickname(String name);

  /// No description provided for @dateNotDetected.
  ///
  /// In en, this message translates to:
  /// **'Date not found'**
  String get dateNotDetected;

  /// No description provided for @pickerFailed.
  ///
  /// In en, this message translates to:
  /// **'Vitalog isn\'t allowed to use the camera or your photos. To allow it, tap Open Settings and turn on Camera and Photos.'**
  String get pickerFailed;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @notifyAskTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow reminders?'**
  String get notifyAskTitle;

  /// No description provided for @notifyAskBody.
  ///
  /// In en, this message translates to:
  /// **'To remind you on time, Vitalog needs to show notifications on this phone. They show only the reminder you wrote and the person\'s name, never test results.'**
  String get notifyAskBody;

  /// No description provided for @notifyAskNext.
  ///
  /// In en, this message translates to:
  /// **'Your phone will ask next. Tap “Allow”.'**
  String get notifyAskNext;

  /// No description provided for @notifyAskContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get notifyAskContinue;

  /// No description provided for @notifyAskNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notifyAskNotNow;

  /// No description provided for @notifyAskLater.
  ///
  /// In en, this message translates to:
  /// **'You can change this anytime in your phone\'s Settings.'**
  String get notifyAskLater;

  /// No description provided for @shareMember.
  ///
  /// In en, this message translates to:
  /// **'Share {name}\'s reports'**
  String shareMember(String name);

  /// No description provided for @shareIntro.
  ///
  /// In en, this message translates to:
  /// **'Family you invite can see {name}\'s reports and add new ones from their own phone. It\'s end-to-end encrypted: only your family can read it, not even Vitalog.'**
  String shareIntro(String name);

  /// No description provided for @shareUploadNote.
  ///
  /// In en, this message translates to:
  /// **'Inviting backs up {name}\'s profile and reports to your account first, sealed.'**
  String shareUploadNote(String name);

  /// No description provided for @shareInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite someone'**
  String get shareInvite;

  /// No description provided for @sharePeople.
  ///
  /// In en, this message translates to:
  /// **'Who can see these reports'**
  String get sharePeople;

  /// No description provided for @shareYou.
  ///
  /// In en, this message translates to:
  /// **'{name} (you)'**
  String shareYou(String name);

  /// No description provided for @shareYouPlain.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get shareYouPlain;

  /// No description provided for @shareSomeone.
  ///
  /// In en, this message translates to:
  /// **'Someone in your family'**
  String get shareSomeone;

  /// No description provided for @sharePending.
  ///
  /// In en, this message translates to:
  /// **'Invite waiting'**
  String get sharePending;

  /// No description provided for @sharePendingUntil.
  ///
  /// In en, this message translates to:
  /// **'Link works until {date}'**
  String sharePendingUntil(String date);

  /// No description provided for @shareCancelInvite.
  ///
  /// In en, this message translates to:
  /// **'Cancel invite'**
  String get shareCancelInvite;

  /// No description provided for @shareRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get shareRemove;

  /// No description provided for @shareRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop sharing {name}\'s reports with {person}?'**
  String shareRemoveTitle(String name, String person);

  /// No description provided for @shareRemoveMessage.
  ///
  /// In en, this message translates to:
  /// **'{person} won\'t get new reports. Reports already on their phone stay there.'**
  String shareRemoveMessage(String person);

  /// No description provided for @shareRemoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Stop sharing'**
  String get shareRemoveConfirm;

  /// No description provided for @shareMessage.
  ///
  /// In en, this message translates to:
  /// **'I\'ve shared {name}\'s health reports with you on Vitalog. Open this link on your phone to see them. It works once, for 7 days.\n{link}'**
  String shareMessage(String name, String link);

  /// No description provided for @shareSubject.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s health reports'**
  String shareSubject(String name);

  /// No description provided for @shareSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in to share. Your family see the reports on their own phones, through your account.'**
  String get shareSignIn;

  /// No description provided for @shareFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach your account. Check your connection and try again.'**
  String get shareFailed;

  /// No description provided for @shareSample.
  ///
  /// In en, this message translates to:
  /// **'Sample people can\'t be shared. Add your own family member first.'**
  String get shareSample;

  /// No description provided for @claimTitle.
  ///
  /// In en, this message translates to:
  /// **'Family invite'**
  String get claimTitle;

  /// No description provided for @claimShared.
  ///
  /// In en, this message translates to:
  /// **'{from} shared {name}\'s reports with you'**
  String claimShared(String from, String name);

  /// No description provided for @claimSharedNoFrom.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s reports were shared with you'**
  String claimSharedNoFrom(String name);

  /// No description provided for @claimWho.
  ///
  /// In en, this message translates to:
  /// **'Who is {name} to you?'**
  String claimWho(String name);

  /// No description provided for @claimAccept.
  ///
  /// In en, this message translates to:
  /// **'Add to my family'**
  String get claimAccept;

  /// No description provided for @claimNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get claimNotNow;

  /// No description provided for @claimPrivacy.
  ///
  /// In en, this message translates to:
  /// **'The reports come to this phone, end-to-end encrypted. You can add reports for {name} too, and everyone sharing them sees them.'**
  String claimPrivacy(String name);

  /// No description provided for @claimSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in to accept. The reports come to your account, sealed so only your family can read them.'**
  String get claimSignIn;

  /// No description provided for @claimAlready.
  ///
  /// In en, this message translates to:
  /// **'You already have these reports.'**
  String get claimAlready;

  /// No description provided for @claimOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get claimOpen;

  /// No description provided for @claimInvalid.
  ///
  /// In en, this message translates to:
  /// **'This isn\'t a Vitalog invite link. Check that you copied all of it.'**
  String get claimInvalid;

  /// No description provided for @claimGone.
  ///
  /// In en, this message translates to:
  /// **'This invite doesn\'t work any more. Ask for a new link.'**
  String get claimGone;

  /// No description provided for @claimUsed.
  ///
  /// In en, this message translates to:
  /// **'Someone already used this invite. Each link works once, so ask for a new one.'**
  String get claimUsed;

  /// No description provided for @claimExpired.
  ///
  /// In en, this message translates to:
  /// **'This invite has expired. Links work for 7 days, so ask for a new one.'**
  String get claimExpired;

  /// No description provided for @claimLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many tries. Wait an hour, then open the link again.'**
  String get claimLimited;

  /// No description provided for @claimFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach Vitalog. Check your connection and try again.'**
  String get claimFailed;

  /// No description provided for @claimRecoveryKey.
  ///
  /// In en, this message translates to:
  /// **'Enter your recovery key first, then open the link again.'**
  String get claimRecoveryKey;

  /// No description provided for @openInviteRow.
  ///
  /// In en, this message translates to:
  /// **'Open an invite link'**
  String get openInviteRow;

  /// No description provided for @openInviteRowDetail.
  ///
  /// In en, this message translates to:
  /// **'Family sent you a link? Paste it here.'**
  String get openInviteRowDetail;

  /// No description provided for @pasteInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Paste the invite link'**
  String get pasteInviteTitle;

  /// No description provided for @pasteInviteOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get pasteInviteOpen;

  /// No description provided for @noticeInviteAccepted.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s reports are on your phone now'**
  String noticeInviteAccepted(String name);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'te'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
