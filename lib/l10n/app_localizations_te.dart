// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Telugu (`te`).
class AppLocalizationsTe extends AppLocalizations {
  AppLocalizationsTe([String locale = 'te']) : super(locale);

  @override
  String get appTitle => 'వైటలాగ్ • కుటుంబ ఆరోగ్యం';

  @override
  String get navHome => 'హోమ్';

  @override
  String get navCategories => 'వర్గాలు';

  @override
  String get navReports => 'నివేదికలు';

  @override
  String get navFamily => 'కుటుంబం';

  @override
  String get loadFailed =>
      'కుటుంబ ఆరోగ్య వివరాలను లోడ్ చేయలేకపోయాం. మళ్లీ ప్రయత్నించండి.';

  @override
  String get tryAgain => 'మళ్లీ ప్రయత్నించండి';

  @override
  String get noProfiles => 'ఇంకా కుటుంబ ప్రొఫైళ్లు లేవు.';

  @override
  String get emptyHomeTitle => 'మీకు ముఖ్యమైన వారి నుంచే ప్రారంభించండి';

  @override
  String get emptyHomeMessage =>
      'ప్రతి ఒక్కరి నివేదికలు, ఫలితాలను ఒకేచోట ఉంచడానికి ప్రొఫైల్ జోడించండి.';

  @override
  String get emptyCategoriesTitle => 'ఫలితాలు క్రమంగా వర్గీకరించబడతాయి';

  @override
  String get emptyCategoriesMessage =>
      'నివేదికలు జోడించిన తర్వాత, ఫలితాలు ఆరోగ్య విభాగాలుగా క్రమబద్ధీకరించబడతాయి.';

  @override
  String get emptyReportsTitle => 'స్పష్టమైన కాలక్రమం ఇక్కడ మొదలవుతుంది';

  @override
  String get emptyReportsMessage =>
      'ముందుగా కుటుంబ ప్రొఫైల్ జోడించండి. తర్వాత ప్రైవేట్ కాలక్రమం కోసం ల్యాబ్ నివేదిక ఫోటో లేదా PDF ఎంచుకోండి.';

  @override
  String get emptyFamilyTitle => 'మీ కుటుంబ విభాగాన్ని సెటప్ చేయండి';

  @override
  String get emptyFamilyMessage =>
      'ప్రతి ఒక్కరి నివేదికలు, ఫలితాలు వేరుగా ఉంచడానికి ప్రొఫైళ్లు జోడించండి. దిగువన ప్రదర్శన, ఖాతా సెట్టింగ్‌లు అందుబాటులో ఉన్నాయి.';

  @override
  String get startWalkthrough => 'చిన్న పరిచయం చూడండి';

  @override
  String get walkthroughBack => 'వెనుకకు';

  @override
  String get walkthroughNext => 'తర్వాత';

  @override
  String get walkthroughSkip => 'పరిచయాన్ని దాటవేయండి';

  @override
  String get walkthroughDone => 'పూర్తి';

  @override
  String walkthroughStep(int step, int count) {
    return '$countలో $stepవ దశ';
  }

  @override
  String get cancel => 'రద్దు చేయండి';

  @override
  String get homeEyebrow => 'కుటుంబ ఆరోగ్యం';

  @override
  String get homeTitle => 'ఆరోగ్యంపై స్పష్టమైన అవగాహన,\nకలిసి.';

  @override
  String get switchProfileTooltip => 'కుటుంబ ప్రొఫైల్ మార్చండి';

  @override
  String get viewingHealthFor => 'వీరి ఆరోగ్యాన్ని చూస్తున్నారు';

  @override
  String get latestReport => 'తాజా నివేదిక';

  @override
  String get noReportsYet => 'ఇంకా నివేదికలు లేవు';

  @override
  String get healthCategories => 'ఆరోగ్య విభాగాలు';

  @override
  String get seeAll => 'అన్నీ చూడండి';

  @override
  String get recentResults => 'ఇటీవలి ఫలితాలు';

  @override
  String get allResults => 'అన్ని ఫలితాలు';

  @override
  String get noResultsTitle => 'ఇంకా ఫలితాలు లేవు';

  @override
  String get noResultsMessage =>
      'ఈ కుటుంబ సభ్యుని ఆరోగ్య చరిత్రను ప్రారంభించడానికి నివేదికను జోడించండి.';

  @override
  String get labRangeDisclaimer =>
      'ల్యాబ్‌లను బట్టి సూచించిన పరిధులు మారవచ్చు. స్థితి లేబుళ్లు ఫలితంతో ముద్రించిన పరిధిని చూపుతాయి; అవి వైద్య నిర్ధారణ కావు.';

  @override
  String get reportEyebrow => 'నివేదిక';

  @override
  String reportDateValue(String date) {
    return 'నివేదిక తేదీ $date';
  }

  @override
  String collectionDateValue(String date) {
    return 'నమూనా సేకరణ $date';
  }

  @override
  String get labNotDetected => 'ల్యాబ్ పేరు గుర్తించలేదు';

  @override
  String resultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ఫలితాలు',
      one: '1 ఫలితం',
      zero: 'ఫలితాలు లేవు',
    );
    return '$_temp0';
  }

  @override
  String testsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count పరీక్షలు',
      one: '1 పరీక్ష',
    );
    return '$_temp0';
  }

  @override
  String toReviewCount(int count) {
    return 'సమీక్షించాల్సినవి: $count';
  }

  @override
  String get reportResultsHeading => 'ఈ నివేదికలోని ఫలితాలు';

  @override
  String get statusWithinRange => 'ల్యాబ్ పరిధిలో ఉంది';

  @override
  String get statusHighPerReport => 'ఎక్కువ · నివేదిక ప్రకారం';

  @override
  String get statusLowPerReport => 'తక్కువ · నివేదిక ప్రకారం';

  @override
  String get statusNeedsReview => 'సమీక్షించాలి';

  @override
  String get categoriesTitle => 'వర్గాలు';

  @override
  String get categoriesSubtitle =>
      'వ్యవస్థల వారీగా ఫలితాలు. ఒక పరీక్ష ఒకటి కంటే ఎక్కువ వర్గాల్లో కనిపించవచ్చు.';

  @override
  String resultsLatest(String results, String date) {
    return '$results · తాజా తేదీ $date';
  }

  @override
  String get noCategoriesTitle => 'ఇంకా వర్గాలు లేవు';

  @override
  String get noCategoriesMessage =>
      'నివేదిక చదివిన తర్వాత ఫలితాలు ఇక్కడ వర్గాలుగా కనిపిస్తాయి.';

  @override
  String get latestValuesFirst => 'తాజా ఫలితాలు ముందుగా';

  @override
  String get datePrintedNote => 'ప్రతి తేదీ నివేదికపై ముద్రించిన తేదీ.';

  @override
  String get noCategoryResultsTitle => 'ఈ వర్గంలో ఫలితాలు లేవు';

  @override
  String get noCategoryResultsMessage =>
      'నివేదిక చదివిన తర్వాత ఫలితాలు ఇక్కడ కనిపిస్తాయి.';

  @override
  String get testHistory => 'పరీక్ష చరిత్ర';

  @override
  String get unitNotPrinted => 'యూనిట్ ముద్రించలేదు';

  @override
  String get latestResult => 'తాజా ఫలితం';

  @override
  String referenceRangePrinted(String range) {
    return 'ముద్రించిన సాధారణ పరిధి: $range';
  }

  @override
  String get rangeNotPrinted => 'ముద్రించలేదు';

  @override
  String get history => 'చరిత్ర';

  @override
  String get chartNote =>
      'నివేదిక తేదీల ప్రకారం, ఒకే యూనిట్‌లోని విలువలు చూపబడతాయి.';

  @override
  String get trendEmptyTitle => 'మరిన్ని ఫలితాలతో మార్పు తెలుస్తుంది';

  @override
  String get trendEmptyMessage =>
      'పోల్చదగిన కనీసం రెండు సంఖ్యాత్మక ఫలితాలు ఉన్నప్పుడు చార్ట్ కనిపిస్తుంది.';

  @override
  String get notDiagnosis =>
      'ఈ స్క్రీన్ ల్యాబ్ ముద్రించిన విలువలను నమోదు చేస్తుంది; వాటిని వైద్య నిర్ధారణగా అర్థం చేసుకోదు.';

  @override
  String get reportsTitle => 'నివేదికలు';

  @override
  String get reportsSubtitle =>
      'అప్‌లోడ్ చేసిన నివేదికలు, కొత్తవి ముందు. ఒక్క నివేదిక ఫలితాలను చూడటానికి దాన్ని నొక్కండి.';

  @override
  String get addReport => 'నివేదికను జోడించండి';

  @override
  String get sync => 'సింక్';

  @override
  String get syncing => 'సింక్ అవుతోంది…';

  @override
  String unsyncedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count నివేదికలు సింక్ కాలేదు',
      one: '1 నివేదిక సింక్ కాలేదు',
    );
    return '$_temp0';
  }

  @override
  String get allSynced => 'అన్ని నివేదికలు సింక్ అయ్యాయి';

  @override
  String get reportsEmptyTitle => 'ఇంకా నివేదికలు లేవు';

  @override
  String get reportsEmptyMessage =>
      'ల్యాబ్ నివేదిక ఫోటో లేదా PDF జోడించండి. అది ఈ ఫోన్‌లోనే చదవబడుతుంది; ప్రతి పరీక్ష తన వర్గంలో చేరుతుంది.';

  @override
  String uploadedOn(String date) {
    return 'అప్‌లోడ్ చేసిన తేదీ $date';
  }

  @override
  String get reportStatusProcessing => 'చదువుతోంది…';

  @override
  String get reportStatusReady => 'సిద్ధం';

  @override
  String get reportStatusNeedsReview => 'సమీక్షించాలి';

  @override
  String get reportStatusFailed => 'చదవలేకపోయాం';

  @override
  String get syncedBadge => 'సింక్ అయింది';

  @override
  String get onDeviceBadge => 'ఈ పరికరంలో';

  @override
  String get sampleBadge => 'నమూనా';

  @override
  String get retry => 'మళ్లీ ప్రయత్నించండి';

  @override
  String get delete => 'తొలగించండి';

  @override
  String get deleteReportTitle => 'ఈ నివేదికను తొలగించాలా?';

  @override
  String get deleteReportMessage =>
      'ఈ ఫోన్ నుంచి పత్రం మరియు దాని ఫలితాలు తొలగించబడతాయి.';

  @override
  String get addReportSheetTitle => 'ల్యాబ్ నివేదికను జోడించండి';

  @override
  String get takePhoto => 'కెమెరాతో స్కాన్ చేయండి';

  @override
  String get choosePhoto => 'ఫోటోల నుంచి ఎంచుకోండి';

  @override
  String get choosePdf => 'PDF ఎంచుకోండి';

  @override
  String get addReportPrivacy =>
      'నివేదికలు ఈ ఫోన్‌లోనే చదవబడతాయి. మీరు Sync నొక్కేవరకు ఏదీ అప్‌లోడ్ కాదు.';

  @override
  String noticeReportReady(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count పరీక్షలు జోడించబడ్డాయి',
      one: '1 పరీక్ష జోడించబడింది',
    );
    return '$_temp0';
  }

  @override
  String noticeReportNeedsReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count పరీక్షలు జోడించబడ్డాయి — కొన్ని వివరాలు సమీక్షించాలి',
      one: '1 పరీక్ష జోడించబడింది — కొన్ని వివరాలు సమీక్షించాలి',
    );
    return '$_temp0';
  }

  @override
  String get noticeReportFailed => 'ఆ పత్రంలో పరీక్షలు కనుగొనలేకపోయాం.';

  @override
  String noticeSynced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count నివేదికలు సింక్ అయ్యాయి',
      one: '1 నివేదిక సింక్ అయింది',
    );
    return '$_temp0';
  }

  @override
  String noticeSyncRestored(int reports, int members) {
    String _temp0 = intl.Intl.pluralLogic(
      reports,
      locale: localeName,
      other: '$reports నివేదికలు',
      one: '1 నివేదిక',
    );
    String _temp1 = intl.Intl.pluralLogic(
      members,
      locale: localeName,
      other: '$members కుటుంబ సభ్యులు',
      one: '1 కుటుంబ సభ్యుడు',
    );
    return 'మీ ఖాతా నుంచి $_temp0, $_temp1 తిరిగి వచ్చాయి.';
  }

  @override
  String noticeSyncRestoredSent(int reports, int members, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      reports,
      locale: localeName,
      other: '$reports నివేదికలు',
      one: '1 నివేదిక',
    );
    String _temp1 = intl.Intl.pluralLogic(
      members,
      locale: localeName,
      other: '$members కుటుంబ సభ్యులు',
      one: '1 కుటుంబ సభ్యుడు',
    );
    String _temp2 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count నివేదికలు పంపబడ్డాయి',
      one: '1 నివేదిక పంపబడింది',
    );
    return 'మీ ఖాతా నుంచి $_temp0, $_temp1 తిరిగి వచ్చాయి · $_temp2.';
  }

  @override
  String get noticeNothingToSync => 'అన్నీ ఇప్పటికే సింక్ అయ్యాయి.';

  @override
  String get noticeSyncFailed =>
      'సింక్ విఫలమైంది. నివేదికలు ఈ ఫోన్‌లో సురక్షితంగా ఉన్నాయి — తర్వాత మళ్లీ ప్రయత్నించండి.';

  @override
  String get noticeSignInRequired =>
      'మీ నివేదికలను సింక్ చేయడానికి సైన్ ఇన్ చేయండి.';

  @override
  String get noticeBackendNotConfigured =>
      'ఈ బిల్డ్‌లో క్లౌడ్ సింక్ ఇంకా సెటప్ కాలేదు.';

  @override
  String get foreignAccountTitle => 'భిన్న ఖాతా సైన్ ఇన్ అయింది';

  @override
  String get foreignAccountBody =>
      'ఈ ఫోన్‌లో ఇప్పటికే మరో ఖాతా నివేదికలు, కుటుంబ సభ్యులు ఉన్నారు. వాటిని ఉంచితే ఈ ఖాతా డేటా కూడా జోడించబడుతుంది. తుడిచితే ఈ ఫోన్‌లో ఉన్నవి మాత్రమే తొలగిపోతాయి — నివేదికలు, సభ్యుల జాబితా, నేర్చుకున్న టెస్ట్ విభాగాలు, వాటి డాక్యుమెంట్లు. ఖాతా క్లౌడ్ బ్యాకప్‌ను ఎక్కువగా ముట్టుకోబోము.';

  @override
  String get foreignAccountKeep => 'ఈ ఫోన్ నివేదికలు ఉంచి, కొనసాగించు';

  @override
  String get foreignAccountClear => 'ఫోన్ తుడిచి, తిరిగి తెచ్చుకో';

  @override
  String get restoreFetching => 'మీ ఖాతా డేటా తీసుకోబడుతోంది…';

  @override
  String memberRemoveNamed(String name) {
    return '“$name” తొలగించాలా?';
  }

  @override
  String get memberRemoveDetail => 'వారి వివరాలు ఈ ఫోన్ నుంచి తొలగించబడతాయి.';

  @override
  String get memberRemoveSyncedNote =>
      'ఖాతా క్లౌడ్ బ్యాకప్ నుంచి కూడా ఇది తొలగించబడుతుంది.';

  @override
  String get memberRemoveConfirm => 'తొలగించు';

  @override
  String familyMemberRemoved(String name) {
    return '$name తొలగించబడింది.';
  }

  @override
  String memberRemoveBlocked(String name) {
    return '$name పేరుపై ఇంకా నివేదికలు ఉన్నాయి. ముందుగా వాటిని మార్చండి లేదా తొలగించండి.';
  }

  @override
  String get deleteAccountButton => 'ఖాతాను తొలగించు';

  @override
  String get deleteAccountTitle => 'ఈ ఖాతాను తొలగించాలా?';

  @override
  String get deleteAccountMessage =>
      'ఇది ఖాతాను, దానితో సింక్ అయిన ప్రతిదీ (నివేదికలు, ఫలితాలు, కుటుంబ సభ్యులు) తొలగిస్తుంది — అలాగే ఈ ఫోన్‌లోని కాపీనీ. మరో ఖాతా డేటా వేరుగా ఉండి అలాగే ఉంటుంది. ఇది అనూహ్యంగా (undo చేయలేనిది).';

  @override
  String get deleteAccountConfirm => 'ఖాతాను తొలగించు';

  @override
  String get accountDeletedNotice => 'ఖాతా తొలగించబడింది. ఈ ఫోన్ ఖాళీగా ఉంది.';

  @override
  String get accountDeleteFailedNotice =>
      'ఖాతాను తొలగించడానికి సర్వర్‌ను చేరలేదు. ఏమీ మారలేదు.';

  @override
  String get familyEyebrow => 'మీ కుటుంబం';

  @override
  String get familyTitle => 'కుటుంబ ప్రొఫైళ్లు';

  @override
  String get familySubtitle => 'ఎవరి ఆరోగ్య చరిత్రను చూడాలో ఎంచుకోండి.';

  @override
  String relationAge(String relation, int age) {
    return '$relation · $age సంవత్సరాలు';
  }

  @override
  String reportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count నివేదికలు',
      one: '1 నివేదిక',
      zero: 'నివేదికలు లేవు',
    );
    return '$_temp0';
  }

  @override
  String get addFamilyMember => 'కుటుంబ సభ్యుడిని జోడించండి';

  @override
  String get sampleDataNote =>
      'మొదటి నాలుగు ప్రొఫైళ్లు నమూనా డేటా. మీరు జోడించే సభ్యులు, అప్‌లోడ్ చేసే నివేదికలు ఈ ఫోన్‌లోనే ఉంటాయి.';

  @override
  String get accountTitle => 'ఖాతా';

  @override
  String signedInAs(String email) {
    return '$emailగా సైన్ ఇన్ అయ్యారు';
  }

  @override
  String get signedOutMessage =>
      'నివేదికలను క్లౌడ్‌లో బ్యాకప్ చేయడానికి Sync ద్వారా సైన్ ఇన్ చేయండి.';

  @override
  String get signIn => 'సైన్ ఇన్';

  @override
  String get signOut => 'సైన్ అవుట్';

  @override
  String get signInTitle => 'సైన్ ఇన్';

  @override
  String get createAccountTitle => 'ఖాతా సృష్టించండి';

  @override
  String get signInSubtitle =>
      'మీరు Sync నొక్కినప్పుడు నివేదికలను బ్యాకప్ చేయడానికి మాత్రమే ఖాతా ఉపయోగించబడుతుంది.';

  @override
  String get continueWithGoogle => 'Googleతో కొనసాగించండి';

  @override
  String get orDivider => 'లేదా';

  @override
  String get emailLabel => 'ఇమెయిల్';

  @override
  String get passwordLabel => 'పాస్‌వర్డ్';

  @override
  String get signInButton => 'సైన్ ఇన్';

  @override
  String get createAccountButton => 'ఖాతా సృష్టించండి';

  @override
  String get noAccount => 'కొత్తవారా? ఖాతా సృష్టించండి';

  @override
  String get haveAccount => 'ఇప్పటికే ఖాతా ఉందా? సైన్ ఇన్ చేయండి';

  @override
  String get forgotPassword => 'పాస్‌వర్డ్ మర్చిపోయారా?';

  @override
  String get resetSent => 'పాస్‌వర్డ్ రీసెట్ లింక్ కోసం ఇమెయిల్ చూడండి.';

  @override
  String get confirmEmailSent => 'ఖాతాను నిర్ధారించడానికి ఇమెయిల్ చూడండి.';

  @override
  String get emailInvalid => 'చెల్లుబాటు అయ్యే ఇమెయిల్ నమోదు చేయండి';

  @override
  String get passwordTooShort => 'కనీసం 8 అక్షరాలు ఉపయోగించండి';

  @override
  String get authFailed =>
      'సైన్ ఇన్ కాలేదు. మీ వివరాలు తనిఖీ చేసి మళ్లీ ప్రయత్నించండి.';

  @override
  String categoryName(String id) {
    String _temp0 = intl.Intl.selectLogic(
      id,
      {
        'blood': 'రక్తం & CBC',
        'glucose': 'గ్లూకోజ్',
        'kidney': 'మూత్రపిండాలు',
        'liver': 'కాలేయం',
        'lipid': 'లిపిడ్ ప్రొఫైల్',
        'thyroid': 'థైరాయిడ్',
        'vitamins': 'విటమిన్లు',
        'iron': 'ఐరన్',
        'urine': 'మూత్రం',
        'heart': 'గుండె',
        'pancreas': 'క్లోమం',
        'immunity': 'రోగనిరోధక శక్తి & వాపు',
        'cancer': 'క్యాన్సర్ సూచికలు',
        'hormones': 'హార్మోన్లు',
        'infections': 'సంక్రమణలు',
        'clotting': 'రక్తం గడ్డకట్టడం',
        'other': 'ఇతర',
      },
    );
    return '$_temp0';
  }

  @override
  String get editValue => 'విలువను మార్చండి';

  @override
  String get editResultTitle => 'ఈ ఫలితాన్ని సరిచేయండి';

  @override
  String get editResultHint =>
      'నివేదికలో ముద్రించినదాన్ని నమోదు చేయండి. మళ్లీ పరిధితో పోల్చి చూస్తాం.';

  @override
  String get fieldTestName => 'పరీక్ష పేరు';

  @override
  String get fieldValue => 'విలువ';

  @override
  String get fieldUnit => 'యూనిట్';

  @override
  String get fieldRange => 'సూచించిన పరిధి';

  @override
  String get fieldRangeHint => 'ఉదాహరణకు, 0.4 - 4.0';

  @override
  String get fieldRequired => 'నివేదికలో ముద్రించినదాన్ని నమోదు చేయండి';

  @override
  String get save => 'భద్రపరచండి';

  @override
  String get compareOriginal => 'అసలు నివేదికతో పోల్చండి';

  @override
  String get editedBadge => 'మీరు మార్చారు';

  @override
  String get needsReviewBanner =>
      'ఈ ఫలితాన్ని స్పష్టంగా చదవలేకపోయాం. నివేదికతో సరిపోల్చండి.';

  @override
  String get checkAndFix => 'పరిశీలించి సరిచేయండి';

  @override
  String get looksRight => 'సరిగ్గా ఉంది';

  @override
  String get statusCheckedNoRange => 'తనిఖీ చేశారు · పరిధి లేదు';

  @override
  String get noticeResultEdited =>
      'భద్రపరచాం. ముద్రించిన పరిధి ఆధారంగా స్థితి నవీకరించబడింది.';

  @override
  String get noticeResultChecked => 'తనిఖీ చేసినట్లు గుర్తించబడింది.';

  @override
  String get noticeReportDuplicate => 'ఈ నివేదికను ఇప్పటికే జోడించారు.';

  @override
  String get viewReport => 'చూడండి';

  @override
  String get readingSecurely => 'ఈ ఫోన్‌లో సురక్షితంగా చదువుతోంది';

  @override
  String get splashTagline => 'ఆరోగ్యంపై స్పష్టమైన అవగాహన, కలిసి.';

  @override
  String get customizeHome => 'హోమ్‌ను అనుకూలీకరించండి';

  @override
  String get customizeHomeHint =>
      'హోమ్ స్క్రీన్‌లో ఏమి కనిపించాలో ఎంచుకోండి. దాచిన విభాగాలు లోడ్ కావు.';

  @override
  String get sectionLatestReport => 'తాజా నివేదిక';

  @override
  String get sectionCategories => 'ఆరోగ్య వర్గాలు';

  @override
  String get sectionRecentResults => 'ఇటీవలి ఫలితాలు';

  @override
  String get sectionRangeNote => 'ల్యాబ్ పరిధి గమనిక';

  @override
  String get hiddenInSimpleMode => 'సరళ మోడ్‌లో దాచబడుతుంది';

  @override
  String get simpleMode => 'సరళ మోడ్';

  @override
  String get simpleModeHint =>
      'పెద్ద అక్షరాలు, స్పష్టమైన పదాలు, పెద్ద బటన్లు; తక్కువ అంశాలు.';

  @override
  String get testedHeading => 'పరీక్షించినవి';

  @override
  String get yetToTestHeading => 'ఇంకా పరీక్షించనివి';

  @override
  String get yetToTestNote =>
      'ఇంకా ఫలితాలు లేవు. వీటిని సాధారణంగా పరీక్షిస్తారు. మీకు అవసరమా అని వైద్యుడిని అడగండి.';

  @override
  String keyTestsLine(String tests) {
    return 'సాధారణంగా ఇందులో $tests ఉంటాయి';
  }

  @override
  String notYetLine(String tests) {
    return 'ఇంకా చేయనివి: $tests';
  }

  @override
  String get notTestedBadge => 'పరీక్షించలేదు';

  @override
  String onAdviceLine(String tests) {
    return 'వైద్యుడు సూచించినప్పుడు · $tests';
  }

  @override
  String get fieldCategory => 'వర్గం';

  @override
  String get chooseCategory => 'వర్గాన్ని ఎంచుకోండి';

  @override
  String needCategory(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count పరీక్షలకు వర్గం కావాలి',
      one: '1 పరీక్షకు వర్గం కావాలి',
    );
    return '$_temp0';
  }

  @override
  String get themeTitle => 'రూపం';

  @override
  String get themeSystem => 'సిస్టమ్ ప్రకారం';

  @override
  String get themeLight => 'లైట్';

  @override
  String get themeDark => 'డార్క్';

  @override
  String get languageTitle => 'భాష';

  @override
  String get languageSystem => 'పరికరం భాష';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageTelugu => 'తెలుగు';

  @override
  String get accentTitle => 'ప్రధాన రంగు';

  @override
  String get accentVitalog => 'వైటలాగ్';

  @override
  String get accentOcean => 'సముద్ర నీలం';

  @override
  String get accentPlum => 'ప్లమ్';

  @override
  String get accentEmber => 'ఎంబర్';

  @override
  String get accentGraphite => 'గ్రాఫైట్';

  @override
  String get chooseFile => 'ఫైల్ ఎంచుకోండి (PDF, Word, Excel…)';

  @override
  String get unsupportedFileLine => 'ఈ ఫైల్ రకాన్ని చదవలేం';

  @override
  String get noticeReportUnsupported =>
      'ఈ ఫైల్ రకాన్ని చదవలేం. ఫోటో, PDF, Word, Excel, CSV లేదా టెక్స్ట్ ఫైల్ ప్రయత్నించండి.';

  @override
  String get sectionOverview => 'ఆరోగ్యం ఒక చూపులో';

  @override
  String get sectionTrends => 'మార్పులు';

  @override
  String get overviewTitle => 'ఒక చూపులో';

  @override
  String overviewOfTotal(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'తాజా $total ఫలితాల్లో పరిధిలో ఉన్నాయి',
      one: 'తాజా 1 ఫలితంలో పరిధిలో ఉంది',
    );
    return '$_temp0';
  }

  @override
  String get overviewNote =>
      'ప్రతి పరీక్షలో అత్యంత ఇటీవలి విలువను ఒక్కసారి మాత్రమే లెక్కిస్తుంది.';

  @override
  String get legendWithinRange => 'పరిధిలో';

  @override
  String get legendNeedsReview => 'సమీక్షించాలి';

  @override
  String get legendOutsideRange => 'పరిధికి బయట';

  @override
  String overviewSemantics(int good, int review, int outside) {
    return 'పరిధిలో $good, సమీక్షించాల్సినవి $review, పరిధికి బయట $outside';
  }

  @override
  String get trendsTitle => 'మార్పుల ధోరణి';

  @override
  String get trendsSubtitle =>
      'ఒకటి కంటే ఎక్కువ ఫలితాలున్న పరీక్షలు. నీడ ప్రాంతం = ల్యాబ్ ముద్రించిన పరిధి.';

  @override
  String trendSince(String date) {
    return '$date నుంచి';
  }

  @override
  String get trendNoChange => 'మార్పు లేదు';

  @override
  String trendSemantics(
      String name, String value, String change, String status) {
    return '$name, తాజా $value, $change, $status';
  }

  @override
  String get shortHigh => 'ఎక్కువ';

  @override
  String get shortLow => 'తక్కువ';

  @override
  String get moreActions => 'మరిన్ని చర్యలు';

  @override
  String deleteReportNamed(String name) {
    return '“$name”ను తొలగించాలా?';
  }

  @override
  String deleteReportDetail(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'అసలు పత్రం మరియు దాని $count ఫలితాలు ఈ ఫోన్ నుంచి తొలగించబడతాయి. తిరిగి పొందలేరు.',
      one:
          'అసలు పత్రం మరియు దాని 1 ఫలితం ఈ ఫోన్ నుంచి తొలగించబడతాయి. తిరిగి పొందలేరు.',
      zero: 'అసలు పత్రం ఈ ఫోన్ నుంచి తొలగించబడుతుంది. దీన్ని తిరిగి పొందలేరు.',
    );
    return '$_temp0';
  }

  @override
  String get deleteReportSyncedNote =>
      'తొలగిస్తే ఈ ఖాతా క్లౌడ్ బ్యాకప్ నుంచి కూడా ఇది తొలగించబడుతుంది.';

  @override
  String get deleteReportConfirm => 'నివేదికను తొలగించండి';

  @override
  String get statusWithinUsual => 'సాధారణ పరిధిలో';

  @override
  String get statusHighUsual => 'ఎక్కువ · సాధారణ పరిధి';

  @override
  String get statusLowUsual => 'తక్కువ · సాధారణ పరిధి';

  @override
  String usualRangeUsed(String range, String source) {
    return 'ముద్రించిన పరిధి లేదు; అందువల్ల సాధారణ పరిధి ఉపయోగించబడింది: $range ($source).';
  }

  @override
  String usualRangeDiffers(String range) {
    return 'మీ ల్యాబ్ పరిధి సాధారణ పరిధి ($range) కంటే భిన్నంగా ఉంది. ల్యాబ్ పరిధినే ఉపయోగిస్తున్నాం.';
  }

  @override
  String get attentionTitle => 'శ్రద్ధ అవసరం';

  @override
  String get attentionSubtitle =>
      'ల్యాబ్ లేదా సాధారణ పరిధికి బయట ఉంది. ఇది నిర్ధారణ కాదు — వైద్యుడిని సంప్రదించండి.';

  @override
  String attentionBelow(String value, String range) {
    return '$value పరిధి ($range) కంటే తక్కువగా ఉంది';
  }

  @override
  String attentionAbove(String value, String range) {
    return '$value పరిధి ($range) కంటే ఎక్కువగా ఉంది';
  }

  @override
  String get attentionUsualTag => 'సాధారణ పరిధి';

  @override
  String noticeReportAttention(int count, int attention) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count పరీక్షలు జోడించబడ్డాయి',
      one: '1 పరీక్ష జోడించబడింది',
    );
    String _temp1 = intl.Intl.pluralLogic(
      attention,
      locale: localeName,
      other: '$attention పరీక్షలకు శ్రద్ధ అవసరం',
      one: '1 పరీక్షకు శ్రద్ధ అవసరం',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get noticeReportTimedOut =>
      'ఆ నివేదిక చదవడానికి చాలా సమయం పట్టింది. స్పష్టమైన ఫోటో లేదా తక్కువ పేజీలు ప్రయత్నించండి.';

  @override
  String noticeReportOtherPerson(String name) {
    return 'ఈ నివేదికలో $name అని ఉంది. ఇది ఎవరి ప్రొఫైల్‌లో ఉందో తనిఖీ చేయండి.';
  }

  @override
  String get noticeReportCancelled => 'చదవడం రద్దయింది. ఏదీ భద్రపరచలేదు.';

  @override
  String noticeMemberAdded(String name) {
    return '$name మీ కుటుంబానికి జోడించబడ్డారు.';
  }

  @override
  String get reviewAction => 'సమీక్షించండి';

  @override
  String get cancelReading => 'చదవడాన్ని రద్దు చేయండి';

  @override
  String get timedOutLine =>
      'చదవడానికి చాలా సమయం పట్టింది. స్పష్టమైన ఫోటో లేదా తక్కువ పేజీలు ప్రయత్నించండి.';

  @override
  String nameMismatchLine(String name, String member) {
    return 'ఈ నివేదికలో పేరు: $name. ఇది $member పేరుతో దాఖలైంది.';
  }

  @override
  String get keepHere => 'ఇక్కడే ఉంచండి';

  @override
  String moveToMember(String name) {
    return '$name వద్దకు మార్చండి';
  }

  @override
  String get moveReport => 'మార్చండి…';

  @override
  String get moveReportTitle => 'ఈ నివేదిక ఎవరిది?';

  @override
  String get nameMatchesBadge => 'పేరు సరిపోలింది';

  @override
  String readingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count రీడింగ్‌లు',
      one: '1 రీడింగ్',
    );
    return '$_temp0';
  }

  @override
  String get addMemberTitle => 'కుటుంబ సభ్యుడిని జోడించండి';

  @override
  String get memberNameLabel => 'ల్యాబ్ నివేదికల్లో ఉన్న పూర్తి పేరు';

  @override
  String get memberNameRequired => 'పేరు నమోదు చేయండి';

  @override
  String get relationLabel => 'సంబంధం';

  @override
  String get relationSelf => 'మీరు';

  @override
  String get relationPartner => 'భాగస్వామి';

  @override
  String get relationChild => 'పిల్లలు';

  @override
  String get relationParent => 'తల్లిదండ్రులు';

  @override
  String get relationSibling => 'తోబుట్టువు';

  @override
  String get relationGrandparent => 'తాతయ్య / నానమ్మ';

  @override
  String get relationOther => 'ఇతరులు';

  @override
  String get ageLabel => 'వయసు (సంవత్సరాలు)';

  @override
  String get ageInvalid => '0 నుంచి 120 మధ్య వయసు నమోదు చేయండి';

  @override
  String get sexLabel => 'లింగం';

  @override
  String get sexFemale => 'స్త్రీ';

  @override
  String get sexMale => 'పురుషుడు';

  @override
  String get sexUnset => 'ఎంచుకోలేదు';

  @override
  String get sexHelp =>
      'కొన్ని సాధారణ పరిధులు లింగాన్ని బట్టి మారతాయి. లింగం ఎంచుకోకపోతే ఆ పరిధులు ఉపయోగించబడవు.';

  @override
  String get saveMember => 'సభ్యుడిని జోడించండి';

  @override
  String get memberPrivacy => 'ఈ ఫోన్‌లో మాత్రమే భద్రపరచబడుతుంది.';

  @override
  String get onboardingSkip => 'దాటవేయండి';

  @override
  String get onboardingNext => 'తర్వాత';

  @override
  String get onboardingStart => 'ప్రారంభించండి';

  @override
  String get onboardingTitle1 => 'ప్రతి ల్యాబ్ నివేదిక ఒకేచోట';

  @override
  String get onboardingBody1 =>
      'ఫోటో తీయండి, PDF లేదా ఏదైనా ఫైల్ ఎంచుకోండి. ప్రతి పరీక్ష రక్తం, థైరాయిడ్, విటమిన్లు వంటి వర్గాల్లో చేరుతుంది.';

  @override
  String get onboardingTitle2 => 'మీ ఫోన్‌లోనే చదవబడుతుంది';

  @override
  String get onboardingBody2 =>
      'నివేదికలు ఈ ఫోన్‌లోనే చదవబడతాయి. మీరు Sync నొక్కితే తప్ప ఏదీ పంపబడదు.';

  @override
  String get onboardingTitle3 => 'కుటుంబమంతటికీ ఆరోగ్య సంరక్షణ';

  @override
  String get onboardingBody3 =>
      'మీరు చూసుకునే ప్రతి ఒక్కరికీ చరిత్రను ఉంచి, కాలక్రమంలో విలువల మార్పును చూడండి.';

  @override
  String get welcomeTitle => 'వైటలాగ్‌కు స్వాగతం';

  @override
  String get continueWithoutAccount => 'ఖాతా లేకుండా కొనసాగండి';

  @override
  String get showPassword => 'పాస్‌వర్డ్ చూపించండి';

  @override
  String get hidePassword => 'పాస్‌వర్డ్ దాచండి';

  @override
  String get statusPlainWithin => 'పరిధిలో ఉంది';

  @override
  String get statusPlainHigh => 'పరిధి కంటే ఎక్కువ';

  @override
  String get statusPlainLow => 'పరిధి కంటే తక్కువ';

  @override
  String get statusPlainReview => 'దయచేసి తనిఖీ చేయండి';

  @override
  String onboardingPage(int page, int count) {
    return '$countలో $pageవ పేజీ';
  }

  @override
  String get notNow => 'ఇప్పుడు వద్దు';

  @override
  String get createPasswordHint => 'కనీసం 8 అక్షరాలు';

  @override
  String get welcomeBack => 'తిరిగి స్వాగతం';

  @override
  String get nameCheckNote =>
      'ప్రతి నివేదికలో ముద్రించిన రోగి పేరుతో ఈ పేరును పోలుస్తాం. తప్పు వ్యక్తి కింద దాఖలైన నివేదికను గుర్తించడానికి ఇది సహాయపడుతుంది.';

  @override
  String nameMustInclude(String name) {
    return 'సరిపోలడానికి నివేదికలో “$name” ఉండాలి.';
  }

  @override
  String nameLooksLikeNickname(String name) {
    return '“$name” ముద్దుపేరులా ఉంది. ల్యాబ్‌లు పూర్తి పేరును ముద్రిస్తాయి; అందువల్ల వాటి నివేదికలు సరిపోలకపోవచ్చు.';
  }
}
