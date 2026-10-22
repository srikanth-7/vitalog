import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

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
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

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
  /// **'Could not load family health: {message}'**
  String loadFailed(String message);

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

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @homeEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Family health'**
  String get homeEyebrow;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'A clearer picture,\ntogether.'**
  String get homeTitle;

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

  /// No description provided for @toReviewCount.
  ///
  /// In en, this message translates to:
  /// **'{count} to review'**
  String toReviewCount(int count);

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
  /// **'No categories yet'**
  String get noCategoriesTitle;

  /// No description provided for @noCategoriesMessage.
  ///
  /// In en, this message translates to:
  /// **'Results will be grouped here after a report is read.'**
  String get noCategoriesMessage;

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
  /// **'Add a photo or PDF of a lab report. It\'s read on this phone and every test is filed into its category.'**
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
  /// **'Take a photo'**
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

  /// No description provided for @addFamilyMemberSoon.
  ///
  /// In en, this message translates to:
  /// **'Adding family members will be available soon.'**
  String get addFamilyMemberSoon;

  /// No description provided for @sampleDataNote.
  ///
  /// In en, this message translates to:
  /// **'Family profiles are sample data in this prototype. Uploaded reports are stored on this phone.'**
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
  /// **'Couldn\'t sign in: {message}'**
  String authFailed(String message);

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

  /// No description provided for @noticeResultEdited.
  ///
  /// In en, this message translates to:
  /// **'Saved. Status updated from the printed range.'**
  String get noticeResultEdited;

  /// No description provided for @viewReport.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get viewReport;

  /// No description provided for @readingSecurely.
  ///
  /// In en, this message translates to:
  /// **'Reading on this phone · encrypted'**
  String get readingSecurely;

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
  /// **'Latest report'**
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
  /// **'Bigger text and buttons, fewer things on screen.'**
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
  /// **'That file type can\'t be read. Try a photo, PDF, Word, Excel, CSV or text file.'**
  String get noticeReportUnsupported;

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
  /// **'{total, plural, =1{of 1 latest result within lab range} other{of {total} latest results within lab range}}'**
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
  /// **'Data you already synced stays in your cloud backup.'**
  String get deleteReportSyncedNote;

  /// No description provided for @deleteReportConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete Report'**
  String get deleteReportConfirm;
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
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
