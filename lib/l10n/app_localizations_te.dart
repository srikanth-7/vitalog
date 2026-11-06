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
  String get emptyHomeTitle => 'మీ కుటుంబ ల్యాబ్ నివేదికలు, ఒకే చోట';

  @override
  String get emptyHomeMessage =>
      'ఫలితాలు ఈ ఫోన్‌లోనే చదవబడి, ఇలాంటి విభాగాలుగా సర్దబడతాయి. ముందుగా మిమ్మల్ని లేదా మీరు చూసుకునే వారిని జోడించండి.';

  @override
  String get emptyCategoriesTitle => 'మీ ఫలితాలు ఇక్కడ వర్గీకరించబడతాయి';

  @override
  String get emptyCategoriesMessage =>
      'నివేదిక జోడించిన తర్వాత, ప్రతి పరీక్ష ఈ గ్రూపుల్లో ఒకదానిలో చేరుతుంది.';

  @override
  String get emptyReportsTitle => 'మీ ల్యాబ్ నివేదికలు ఇక్కడ కనిపిస్తాయి';

  @override
  String get emptyReportsMessage =>
      'ముందుగా కుటుంబ సభ్యుడిని జోడించండి. తర్వాత వారి ల్యాబ్ నివేదిక ఫోటో లేదా PDF జోడించండి.';

  @override
  String get emptyFamilyTitle => 'మీ కుటుంబ విభాగాన్ని సెటప్ చేయండి';

  @override
  String get emptyFamilyMessage =>
      'ప్రతి ఒక్కరి నివేదికలు, ఫలితాలు వేరుగా ఉంచడానికి ప్రొఫైళ్లు జోడించండి. దిగువన ప్రదర్శన, ఖాతా సెట్టింగ్‌లు అందుబాటులో ఉన్నాయి.';

  @override
  String get startWalkthrough => 'చిన్న పరిచయం చూడండి';

  @override
  String get greetingMorning => 'శుభోదయం';

  @override
  String get greetingAfternoon => 'శుభ మధ్యాహ్నం';

  @override
  String get greetingEvening => 'శుభ సాయంత్రం';

  @override
  String greetingWithName(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String homeVerdict(int good, int total) {
    return '$total ఫలితాల్లో $good పరిధిలో ఉన్నాయి';
  }

  @override
  String homeVerdictAll(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'మొత్తం $total ఫలితాలు పరిధిలో ఉన్నాయి',
      one: 'మీ 1 ఫలితం పరిధిలో ఉంది',
    );
    return '$_temp0';
  }

  @override
  String homeSnapshotFor(String name) {
    return '$name ఆరోగ్య సారాంశం ఇదిగో';
  }

  @override
  String lastTested(String date) {
    return 'చివరి పరీక్ష $date';
  }

  @override
  String get periodAll => 'అన్నీ';

  @override
  String get periodYear => '1 సంవత్సరం';

  @override
  String get periodSixMonths => '6 నెలలు';

  @override
  String historySemantics(
      String test, int count, String from, String to, String value) {
    return '$test: $from నుండి $to వరకు $count రీడింగ్‌లు. తాజాది $value.';
  }

  @override
  String homeGreetingTitle(String name) {
    return '$name తాజా వివరాలు';
  }

  @override
  String get tourMemberTitle => 'ఒక వ్యక్తితో మొదలుపెట్టండి';

  @override
  String get tourMemberBody =>
      'మిమ్మల్ని లేదా మీరు చూసుకునే వారిని జోడించండి. ప్రతి ఒక్కరి నివేదికలు వేరుగా ఉంటాయి.';

  @override
  String get tourCategoriesTitle => 'ఫలితాలు చక్కగా విభజించబడతాయి';

  @override
  String get tourCategoriesBody =>
      'ప్రతి పరీక్ష రక్తం, థైరాయిడ్, విటమిన్లు వంటి దాని సమూహంలోకి వెళ్తుంది.';

  @override
  String get tourReportsTitle => 'అన్ని నివేదికలు, తేదీ వారీగా';

  @override
  String get tourReportsBody =>
      'ఫోటో లేదా PDF జోడించండి. ఇది ఈ ఫోన్‌లోనే చదవబడుతుంది; మీరు సింక్ నొక్కితే తప్ప ఏదీ బయటకు వెళ్లదు.';

  @override
  String get tourFamilyTitle => 'మీ కుటుంబం, సెట్టింగ్‌లు';

  @override
  String get tourFamilyBody =>
      'వ్యక్తుల మధ్య మారండి, మరిన్ని జోడించండి, బ్యాకప్ కోసం సైన్ ఇన్ చేయండి, యాప్ రూపాన్ని మార్చండి.';

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
  String outsideRangeCount(int count) {
    return 'పరిధి దాటినవి: $count';
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
  String get noCategoriesTitle => 'ఇంకా వర్గీకరించడానికి ఏమీ లేదు';

  @override
  String get noCategoriesMessage =>
      'నివేదిక జోడిస్తే, ప్రతి పరీక్ష దాని గ్రూపులో చేరుతుంది.';

  @override
  String get homeEmptyTitle => 'ఇంకా ల్యాబ్ నివేదికలు లేవు';

  @override
  String get homeEmptyMessage =>
      '+ బటన్‌తో వారి మొదటి నివేదికను జోడించండి. ఫలితాలు, ధోరణులు, శ్రద్ధ అవసరమైనవి ఇక్కడ కనిపిస్తాయి.';

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
      'కింద ఉన్న “నివేదికను జోడించండి” నొక్కండి. ఫోటో తీయండి లేదా PDF ఎంచుకోండి; ఇది ఈ ఫోన్‌లోనే చదవబడుతుంది.';

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
  String memberRemoveWithReports(String name, int count) {
    return '$name మరియు $count నివేదికలను తీసివేయాలా?';
  }

  @override
  String get memberRemoveWithReportsDetail =>
      'వారి నివేదికలు, ఫలితాలు, అసలు ఫైళ్లు ఈ ఫోన్ నుండి తొలగించబడతాయి. దీన్ని రద్దు చేయలేరు.';

  @override
  String get memberRemoveWithReportsConfirm => 'నివేదికలతో సహా తీసివేయండి';

  @override
  String noticeMemberUpdated(String name) {
    return '$name మార్పులు సేవ్ అయ్యాయి';
  }

  @override
  String get editMember => 'వివరాలు మార్చండి';

  @override
  String get saveChanges => 'మార్పులు సేవ్ చేయండి';

  @override
  String get photoTake => 'ఫోటో తీయండి';

  @override
  String get photoChoose => 'ఫోటో ఎంచుకోండి';

  @override
  String get photoRemove => 'ఫోటో తీసివేయండి';

  @override
  String get remindersTitle => 'రిమైండర్లు';

  @override
  String get remindersSubtitle =>
      'పరీక్ష చేయించుకోవడానికి లేదా నివేదిక జోడించడానికి గుర్తుచేసేవి, మీకోసం లేదా మీరు చూసుకునే వారికోసం ఈ ఫోన్‌లో.';

  @override
  String get remindersRowSubtitle => 'సమయానికి పరీక్షలు, నివేదికలు';

  @override
  String get remindersEmptyTitle => 'ఇంకా రిమైండర్లు లేవు';

  @override
  String get remindersEmptyMessage =>
      'తదుపరి రక్త పరీక్ష, థైరాయిడ్ రీచెక్ లేదా తాజా నివేదిక జోడించడానికి ఒకటి పెట్టండి.';

  @override
  String get addReminder => 'రిమైండర్ జోడించండి';

  @override
  String get editReminder => 'రిమైండర్ మార్చండి';

  @override
  String get reminderTitleLabel => 'ఏమి గుర్తుచేయాలి';

  @override
  String get reminderTitleHint => 'లాక్ స్క్రీన్‌పై కనిపిస్తుంది';

  @override
  String get reminderTitleRequired => 'ఏమి గుర్తుచేయాలో రాయండి';

  @override
  String get reminderPresetTest => 'పరీక్ష చేయించుకోండి';

  @override
  String get reminderPresetReport => 'తాజా నివేదిక జోడించండి';

  @override
  String get reminderForLabel => 'ఎవరికి';

  @override
  String get reminderWhenLabel => 'ఎప్పుడు';

  @override
  String get reminderRepeatLabel => 'మళ్ళీ';

  @override
  String get repeatOnce => 'ఒక్కసారి';

  @override
  String get repeatMonthly => 'ప్రతి నెల';

  @override
  String get repeatEvery3Months => 'ప్రతి 3 నెలలకు';

  @override
  String get repeatEvery6Months => 'ప్రతి 6 నెలలకు';

  @override
  String get repeatYearly => 'ప్రతి సంవత్సరం';

  @override
  String get saveReminder => 'రిమైండర్ సేవ్ చేయండి';

  @override
  String get deleteReminder => 'రిమైండర్ తొలగించండి';

  @override
  String get deleteReminderDetail =>
      'ఇది మళ్ళీ గుర్తుచేయదు. నివేదికలపై ప్రభావం లేదు.';

  @override
  String get reminderNoMore => 'ఇక రిమైండర్లు లేవు';

  @override
  String get reminderPrivacy => 'ఈ ఫోన్‌లో మాత్రమే. ఎప్పుడూ సింక్ కాదు.';

  @override
  String get remindersTooltip => 'రిమైండర్లు';

  @override
  String get remindersDueSoonTooltip => 'రిమైండర్లు, ఈ వారం ఒకటి ఉంది';

  @override
  String get reminderInPast => 'ఇంకా రాని సమయాన్ని ఎంచుకోండి';

  @override
  String get remindersNotificationsOff =>
      'రిమైండర్ సేవ్ అయింది. కానీ Vitalogకి నోటిఫికేషన్లు చూపడానికి అనుమతి లేదు, కాబట్టి గుర్తు చేయలేదు. సెట్టింగ్స్ తెరవండి నొక్కి నోటిఫికేషన్లను ఆన్ చేయండి.';

  @override
  String reminderBody(String name) {
    return '$name కోసం రిమైండర్';
  }

  @override
  String reminderNext(String when) {
    return 'తదుపరి: $when';
  }

  @override
  String deleteReminderTitle(String title) {
    return '“$title” తొలగించాలా?';
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
  String get settingsTitle => 'సెట్టింగ్‌లు';

  @override
  String get settingsSubtitle => 'యాప్ ఎలా కనిపిస్తుంది, మీ ఖాతా.';

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
  String get signOutDetail => 'మీ నివేదికలు ఈ ఫోన్‌లోనే ఉంటాయి.';

  @override
  String get deleteAccountDetail =>
      'మీ క్లౌడ్ బ్యాకప్‌ను శాశ్వతంగా తొలగిస్తుంది.';

  @override
  String get accountStatMembers => 'సభ్యులు';

  @override
  String get accountStatReports => 'నివేదికలు';

  @override
  String get accountStatUnsynced => 'సింక్ చేయాలి';

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
  String get authFailed => 'సైన్ ఇన్ కాలేదు. దయచేసి మళ్లీ ప్రయత్నించండి.';

  @override
  String get authWrongDetails => 'ఇమెయిల్ లేదా పాస్‌వర్డ్ తప్పు.';

  @override
  String get authTooManyTries =>
      'చాలా ప్రయత్నాలు జరిగాయి. కొన్ని నిమిషాలు ఆగి మళ్లీ ప్రయత్నించండి.';

  @override
  String get authOffline =>
      'సర్వర్‌ను చేరుకోలేకపోయాము. మీ ఇంటర్నెట్ కనెక్షన్‌ను చూడండి.';

  @override
  String get authWeakPassword =>
      'బలమైన పాస్‌వర్డ్ ఎంచుకోండి: కనీసం 8 అక్షరాలు, అక్షరాలు మరియు అంకెలతో.';

  @override
  String get authConfirmEmail =>
      'ముందుగా మీ ఇమెయిల్‌ను నిర్ధారించండి: మేము పంపిన లింక్‌ను తెరవండి.';

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
  String get noticeFileTooLarge =>
      'ఈ ఫైల్ చాలా పెద్దది (50 MB కంటే ఎక్కువ), కాబట్టి జోడించలేదు.';

  @override
  String get originalsLockTitle => 'మీ అసలు నివేదికలను లాక్ చేయాలా?';

  @override
  String get originalsLockBody =>
      'స్కాన్ చేసిన నివేదికల్లో మీ పేరు, చిరునామా, ఫోన్ నంబర్ ఉంటాయి. లాక్ ఆన్ చేస్తే, వాటిని తెరవడానికి మీ ముఖం, వేలిముద్ర లేదా స్క్రీన్-లాక్ PIN అవసరం. మీ ఫలితాలు ఎప్పటిలాగే కనిపిస్తాయి.';

  @override
  String get originalsLockNext =>
      'తర్వాత, ఇది మీరేనని నిర్ధారించమని మీ ఫోన్ అడుగుతుంది.';

  @override
  String get originalsLockTurnOn => 'ఆన్ చేయండి';

  @override
  String get originalsLockNotNow => 'ఇప్పుడు కాదు';

  @override
  String get originalsLockLater =>
      'దీన్ని ఎప్పుడైనా కుటుంబం ట్యాబ్‌లో మార్చవచ్చు.';

  @override
  String get originalsLockSetting => 'అసలు నివేదికలను లాక్ చేయండి';

  @override
  String get originalsLockSettingHint =>
      'స్కాన్ చేసిన పత్రాలు తెరవడానికి ముఖం, వేలిముద్ర లేదా PIN';

  @override
  String get noticeOriginalsLocked => 'అసలు నివేదికలు ఇప్పుడు లాక్ అయ్యాయి.';

  @override
  String get noticeOriginalsUnlocked =>
      'అసలు నివేదికలకు ఇక అన్‌లాక్ అవసరం లేదు.';

  @override
  String get noticeOriginalsLockUnchanged =>
      'ఏమీ మారలేదు: అన్‌లాక్ రద్దయింది, లేదా ఈ ఫోన్‌కు స్క్రీన్ లాక్ లేదు.';

  @override
  String get vaultPromptTitle => 'మీ అసలు నివేదికను తెరవండి';

  @override
  String get vaultPromptSubtitle =>
      'మీరు మాత్రమే చూడగలిగేలా వేలిముద్ర, ముఖం లేదా స్క్రీన్-లాక్ PIN ఉపయోగించండి';

  @override
  String get viewReport => 'చూడండి';

  @override
  String get readingSecurely => 'ఈ ఫోన్‌లో సురక్షితంగా చదువుతోంది';

  @override
  String get addingReport => 'మీ నివేదికను జోడిస్తోంది…';

  @override
  String get splashTagline => 'ఆరోగ్యంపై స్పష్టమైన అవగాహన, కలిసి.';

  @override
  String get customizeHome => 'హోమ్‌ను అనుకూలీకరించండి';

  @override
  String get customizeHomeHint =>
      'హోమ్ స్క్రీన్‌లో ఏమి కనిపించాలో ఎంచుకోండి. దాచిన విభాగాలు లోడ్ కావు.';

  @override
  String get sectionLatestReport => 'చివరి పరీక్ష తేదీ';

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
  String get languageHindi => 'हिन्दी';

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
      'ఈ ఫైల్ రకాన్ని చదవలేం, కాబట్టి జోడించలేదు. ఫోటో, PDF, Word, Excel, CSV లేదా టెక్స్ట్ ఫైల్ ప్రయత్నించండి.';

  @override
  String get noticeNotLabReport =>
      'ఇది ల్యాబ్ నివేదికలా లేదు: ఇందులో పరీక్ష ఫలితాలు లేవు, కాబట్టి జోడించలేదు.';

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
  String noticeReportMoved(String name) {
    return '$nameకి తరలించబడింది.';
  }

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

  @override
  String get dateNotDetected => 'తేదీ కనబడలేదు';

  @override
  String get pickerFailed =>
      'Vitalogకి కెమెరా లేదా మీ ఫోటోలను ఉపయోగించడానికి అనుమతి లేదు. అనుమతించడానికి, సెట్టింగ్స్ తెరవండి నొక్కి కెమెరా, ఫోటోలను ఆన్ చేయండి.';

  @override
  String get openSettings => 'సెట్టింగ్స్ తెరవండి';

  @override
  String get notifyAskTitle => 'రిమైండర్లను అనుమతించాలా?';

  @override
  String get notifyAskBody =>
      'సమయానికి గుర్తు చేయడానికి, Vitalog ఈ ఫోన్‌లో నోటిఫికేషన్లు చూపాలి. అవి మీరు రాసిన రిమైండర్, వ్యక్తి పేరు మాత్రమే చూపిస్తాయి, పరీక్ష ఫలితాలు ఎప్పుడూ కాదు.';

  @override
  String get notifyAskNext =>
      'తర్వాత మీ ఫోన్ అడుగుతుంది. “అనుమతించు” నొక్కండి.';

  @override
  String get notifyAskContinue => 'కొనసాగించు';

  @override
  String get notifyAskNotNow => 'ఇప్పుడు కాదు';

  @override
  String get notifyAskLater =>
      'దీన్ని మీ ఫోన్ సెట్టింగ్స్‌లో ఎప్పుడైనా మార్చవచ్చు.';

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
