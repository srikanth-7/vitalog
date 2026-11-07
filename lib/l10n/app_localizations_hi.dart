// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'Vitalog • परिवार की सेहत';

  @override
  String get navHome => 'होम';

  @override
  String get navCategories => 'समूह';

  @override
  String get navReports => 'रिपोर्ट';

  @override
  String get navFamily => 'परिवार';

  @override
  String get loadFailed =>
      'परिवार की सेहत की जानकारी नहीं खुल सकी। कृपया फिर से कोशिश करें।';

  @override
  String get tryAgain => 'फिर से कोशिश करें';

  @override
  String get noProfiles => 'अभी तक परिवार का कोई सदस्य नहीं जोड़ा गया।';

  @override
  String get emptyHomeTitle => 'आपके परिवार की लैब रिपोर्ट, एक ही जगह';

  @override
  String get emptyHomeMessage =>
      'नतीजे इसी फ़ोन पर पढ़े जाते हैं और ऐसे समूहों में रखे जाते हैं। शुरू करने के लिए खुद को या जिनकी आप देखभाल करते हैं, उन्हें जोड़ें।';

  @override
  String get emptyCategoriesTitle => 'आपके नतीजे यहाँ समूहों में दिखेंगे';

  @override
  String get emptyCategoriesMessage =>
      'रिपोर्ट जोड़ने के बाद, हर टेस्ट इनमें से किसी एक समूह में रखा जाता है।';

  @override
  String get emptyReportsTitle => 'आपकी लैब रिपोर्ट यहाँ दिखेंगी';

  @override
  String get emptyReportsMessage =>
      'पहले परिवार का कोई सदस्य जोड़ें। फिर उनकी लैब रिपोर्ट की फ़ोटो या PDF जोड़ें।';

  @override
  String get emptyFamilyTitle => 'अपने परिवार की जगह तैयार करें';

  @override
  String get emptyFamilyMessage =>
      'हर व्यक्ति की रिपोर्ट और नतीजे साथ रखने के लिए सदस्य जोड़ें। दिखावट और खाते की सेटिंग नीचे तैयार हैं।';

  @override
  String get startWalkthrough => 'ऐप को जल्दी से समझें';

  @override
  String get greetingMorning => 'सुप्रभात';

  @override
  String get greetingAfternoon => 'नमस्ते';

  @override
  String get greetingEvening => 'शुभ संध्या';

  @override
  String greetingWithName(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String homeVerdict(int good, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total में से $good नतीजे',
      one: '1 में से $good नतीजा',
    );
    return '$_temp0 सीमा के अंदर हैं';
  }

  @override
  String homeVerdictAll(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'सभी $total नतीजे सीमा के अंदर हैं',
      one: 'आपका 1 नतीजा सीमा के अंदर है',
    );
    return '$_temp0';
  }

  @override
  String homeSnapshotFor(String name) {
    return 'यह रही $name की सेहत की झलक';
  }

  @override
  String lastTested(String date) {
    return 'आखिरी टेस्ट $date';
  }

  @override
  String get periodAll => 'सभी';

  @override
  String get periodYear => '1 साल';

  @override
  String get periodSixMonths => '6 महीने';

  @override
  String historySemantics(
      String test, int count, String from, String to, String value) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count रीडिंग',
      one: '1 रीडिंग',
    );
    return '$test: $from से $to तक $_temp0। ताज़ा $value।';
  }

  @override
  String homeGreetingTitle(String name) {
    return 'यह रहा $name का ताज़ा हाल';
  }

  @override
  String get tourMemberTitle => 'किसी व्यक्ति से शुरू करें';

  @override
  String get tourMemberBody =>
      'खुद को या जिनकी आप देखभाल करते हैं, उन्हें जोड़ें। हर व्यक्ति की रिपोर्ट अलग रहती हैं।';

  @override
  String get tourCategoriesTitle => 'नतीजे, सही समूहों में';

  @override
  String get tourCategoriesBody =>
      'हर टेस्ट अपने समूह में जाता है, जैसे खून, थायरॉइड या विटामिन।';

  @override
  String get tourReportsTitle => 'हर रिपोर्ट, तारीख के हिसाब से';

  @override
  String get tourReportsBody =>
      'फ़ोटो या PDF जोड़ें। यह इसी फ़ोन पर पढ़ी जाती है, और जब तक आप Sync न दबाएँ, कुछ भी बाहर नहीं जाता।';

  @override
  String get tourFamilyTitle => 'आपका परिवार और सेटिंग';

  @override
  String get tourFamilyBody =>
      'एक व्यक्ति से दूसरे पर जाएँ, और लोग जोड़ें, बैकअप के लिए साइन इन करें, और ऐप की दिखावट बदलें।';

  @override
  String get walkthroughBack => 'पीछे';

  @override
  String get walkthroughNext => 'आगे';

  @override
  String get walkthroughSkip => 'टूर छोड़ें';

  @override
  String get walkthroughDone => 'हो गया';

  @override
  String walkthroughStep(int step, int count) {
    return '$count में से चरण $step';
  }

  @override
  String get cancel => 'रद्द करें';

  @override
  String get switchProfileTooltip => 'परिवार का सदस्य बदलें';

  @override
  String get viewingHealthFor => 'किसकी सेहत देख रहे हैं';

  @override
  String get latestReport => 'ताज़ा रिपोर्ट';

  @override
  String get noReportsYet => 'अभी कोई रिपोर्ट नहीं';

  @override
  String get healthCategories => 'सेहत के समूह';

  @override
  String get seeAll => 'सब देखें';

  @override
  String get recentResults => 'हाल के नतीजे';

  @override
  String get allResults => 'सभी नतीजे';

  @override
  String get noResultsTitle => 'अभी कोई नतीजा नहीं';

  @override
  String get noResultsMessage =>
      'इस सदस्य की टाइमलाइन शुरू करने के लिए एक रिपोर्ट जोड़ें।';

  @override
  String get labRangeDisclaimer =>
      'लैब की सीमाएँ अलग-अलग हो सकती हैं। स्थिति हर नतीजे के साथ छपी सीमा के हिसाब से बताई गई है; यह कोई बीमारी की पहचान (डायग्नोसिस) नहीं है।';

  @override
  String get reportEyebrow => 'रिपोर्ट';

  @override
  String reportDateValue(String date) {
    return 'रिपोर्ट की तारीख $date';
  }

  @override
  String collectionDateValue(String date) {
    return 'सैंपल लिया गया $date';
  }

  @override
  String get labNotDetected => 'लैब का नाम नहीं मिला';

  @override
  String resultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count नतीजे',
      one: '1 नतीजा',
      zero: 'कोई नतीजा नहीं',
    );
    return '$_temp0';
  }

  @override
  String testsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count टेस्ट',
      one: '1 टेस्ट',
    );
    return '$_temp0';
  }

  @override
  String outsideRangeCount(int count) {
    return '$count सीमा से बाहर';
  }

  @override
  String get reportResultsHeading => 'इस रिपोर्ट के नतीजे';

  @override
  String get statusWithinRange => 'लैब की सीमा के अंदर';

  @override
  String get statusHighPerReport => 'ज़्यादा · रिपोर्ट के अनुसार';

  @override
  String get statusLowPerReport => 'कम · रिपोर्ट के अनुसार';

  @override
  String get statusNeedsReview => 'जाँच ज़रूरी';

  @override
  String get categoriesTitle => 'समूह';

  @override
  String get categoriesSubtitle =>
      'नतीजे शरीर के अंगों के हिसाब से समूहों में। एक टेस्ट एक से ज़्यादा समूह में दिख सकता है।';

  @override
  String resultsLatest(String results, String date) {
    return '$results · ताज़ा $date';
  }

  @override
  String get noCategoriesTitle => 'अभी बाँटने को कुछ नहीं';

  @override
  String get noCategoriesMessage =>
      'रिपोर्ट जोड़ें, हर टेस्ट अपने समूह में चला जाएगा।';

  @override
  String get homeEmptyTitle => 'अभी कोई लैब रिपोर्ट नहीं';

  @override
  String get homeEmptyMessage =>
      '+ बटन से उनकी पहली रिपोर्ट जोड़ें। नतीजे, बदलाव और जिन पर ध्यान देना है, वे सब यहाँ दिखेंगे।';

  @override
  String get latestValuesFirst => 'ताज़ा नतीजे पहले';

  @override
  String get datePrintedNote => 'हर तारीख वही है जो रिपोर्ट पर छपी है।';

  @override
  String get noCategoryResultsTitle => 'इस समूह में कोई नतीजा नहीं';

  @override
  String get noCategoryResultsMessage =>
      'रिपोर्ट पढ़े जाने के बाद नतीजे यहाँ दिखेंगे।';

  @override
  String get testHistory => 'टेस्ट का इतिहास';

  @override
  String get unitNotPrinted => 'यूनिट नहीं छपी';

  @override
  String get latestResult => 'ताज़ा नतीजा';

  @override
  String referenceRangePrinted(String range) {
    return 'छपी हुई सामान्य सीमा: $range';
  }

  @override
  String get rangeNotPrinted => 'नहीं छपी';

  @override
  String get history => 'इतिहास';

  @override
  String get chartNote =>
      'एक ही यूनिट वाले नतीजे, उनकी रिपोर्ट की तारीख के हिसाब से।';

  @override
  String get trendEmptyTitle => 'और नतीजों से बदलाव दिखेगा';

  @override
  String get trendEmptyMessage =>
      'चार्ट तब दिखेगा जब कम से कम दो मिलते-जुलते नंबर वाले नतीजे हों।';

  @override
  String get notDiagnosis =>
      'यहाँ सिर्फ़ लैब के छापे हुए नतीजे दर्ज हैं; इन्हें बीमारी की पहचान (डायग्नोसिस) न समझें।';

  @override
  String get reportsTitle => 'रिपोर्ट';

  @override
  String get reportsSubtitle =>
      'हर जोड़ी गई रिपोर्ट, नई पहले। सिर्फ़ उसके नतीजे देखने के लिए किसी पर टैप करें।';

  @override
  String get addReport => 'रिपोर्ट जोड़ें';

  @override
  String get sync => 'Sync';

  @override
  String get syncing => 'Sync हो रहा है…';

  @override
  String unsyncedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count रिपोर्ट Sync नहीं हुईं',
      one: '1 रिपोर्ट Sync नहीं हुई',
    );
    return '$_temp0';
  }

  @override
  String get allSynced => 'सभी रिपोर्ट Sync हो गईं';

  @override
  String get reportsEmptyTitle => 'अभी कोई रिपोर्ट नहीं';

  @override
  String get reportsEmptyMessage =>
      'नीचे रिपोर्ट जोड़ें दबाएँ। फ़ोटो लें या PDF चुनें; यह सिर्फ़ इसी फ़ोन पर पढ़ी जाती है।';

  @override
  String uploadedOn(String date) {
    return '$date को जोड़ी गई';
  }

  @override
  String get reportStatusProcessing => 'पढ़ी जा रही है…';

  @override
  String get reportStatusReady => 'तैयार';

  @override
  String get reportStatusNeedsReview => 'जाँच ज़रूरी';

  @override
  String get reportStatusFailed => 'पढ़ी नहीं जा सकी';

  @override
  String get syncedBadge => 'Sync हो गई';

  @override
  String get onDeviceBadge => 'इसी फ़ोन पर';

  @override
  String get sampleBadge => 'नमूना';

  @override
  String get retry => 'फिर से कोशिश करें';

  @override
  String get delete => 'हटाएँ';

  @override
  String get deleteReportTitle => 'यह रिपोर्ट हटाएँ?';

  @override
  String get deleteReportMessage =>
      'कागज़ और उसके नतीजे इस फ़ोन से हटा दिए जाएँगे।';

  @override
  String get addReportSheetTitle => 'लैब रिपोर्ट जोड़ें';

  @override
  String get takePhoto => 'कैमरे से स्कैन करें';

  @override
  String get choosePhoto => 'फ़ोटो में से चुनें';

  @override
  String get choosePdf => 'PDF चुनें';

  @override
  String get addReportPrivacy =>
      'रिपोर्ट इसी फ़ोन पर पढ़ी जाती हैं। जब तक आप Sync न दबाएँ, कुछ भी अपलोड नहीं होता।';

  @override
  String noticeReportReady(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count टेस्ट जोड़े गए',
      one: '1 टेस्ट जोड़ा गया',
    );
    return '$_temp0';
  }

  @override
  String noticeReportNeedsReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count टेस्ट जोड़े गए — कुछ बातें जाँचनी हैं',
      one: '1 टेस्ट जोड़ा गया — कुछ बातें जाँचनी हैं',
    );
    return '$_temp0';
  }

  @override
  String get noticeReportFailed => 'उस कागज़ में कोई टेस्ट नहीं मिला।';

  @override
  String noticeSynced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count रिपोर्ट Sync हुईं',
      one: '1 रिपोर्ट Sync हुई',
    );
    return '$_temp0';
  }

  @override
  String noticeSyncRestored(int reports, int members) {
    String _temp0 = intl.Intl.pluralLogic(
      reports,
      locale: localeName,
      other: '$reports रिपोर्ट',
      one: '1 रिपोर्ट',
    );
    String _temp1 = intl.Intl.pluralLogic(
      members,
      locale: localeName,
      other: 'परिवार के $members सदस्य',
      one: 'परिवार का 1 सदस्य',
    );
    return 'आपके खाते से $_temp0 और $_temp1 वापस लाए गए।';
  }

  @override
  String noticeSyncRestoredSent(int reports, int members, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      reports,
      locale: localeName,
      other: '$reports रिपोर्ट',
      one: '1 रिपोर्ट',
    );
    String _temp1 = intl.Intl.pluralLogic(
      members,
      locale: localeName,
      other: 'परिवार के $members सदस्य',
      one: 'परिवार का 1 सदस्य',
    );
    String _temp2 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count रिपोर्ट भेजी गईं',
      one: '1 रिपोर्ट भेजी गई',
    );
    return 'आपके खाते से $_temp0 और $_temp1 वापस लाए गए · $_temp2।';
  }

  @override
  String get noticeNothingToSync => 'सब कुछ पहले से Sync है।';

  @override
  String get noticeSyncFailed =>
      'Sync नहीं हो सका। आपकी रिपोर्ट इस फ़ोन पर सुरक्षित हैं — थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get recoveryKeyTitle => 'अपनी रिकवरी की सेव करें';

  @override
  String get recoveryKeyBody =>
      'आपका बैकअप लॉक है ताकि सिर्फ़ आप उसे पढ़ सकें — Vitalog भी नहीं। अगर यह फ़ोन खो जाए या रीसेट हो जाए, तो यह की नए फ़ोन पर आपका बैकअप खोलती है।';

  @override
  String get recoveryKeyICloud =>
      'यह आपके iCloud Keychain में भी रखी है, इसलिए उसी Apple ID वाले iPhone को यह बिना पूछे मिल जाती है।';

  @override
  String get recoveryKeySave => 'मेरे पासवर्ड में सेव करें';

  @override
  String get recoveryKeyCopy => 'की कॉपी करें';

  @override
  String get recoveryKeyCopiedClears =>
      'Recovery key copied. Paste it somewhere safe now: it\'s cleared from the clipboard in 1 minute.';

  @override
  String get recoveryKeyDone => 'मैंने सेव कर ली';

  @override
  String get recoveryKeyLater => 'यह की आप परिवार टैब पर फिर से देख सकते हैं।';

  @override
  String get recoveryKeyAskTitle => 'अपनी रिकवरी की डालें';

  @override
  String get recoveryKeyAskBody =>
      'आपका बैकअप उस की से लॉक है जो आपने पहली बार Sync करते समय सेव की थी। सेव किए पासवर्ड से भरने के लिए बॉक्स पर टैप करें, या पेस्ट करें।';

  @override
  String get recoveryKeyHint => 'ABCD-EFGH-…';

  @override
  String get recoveryKeyUse => 'मेरा बैकअप खोलें';

  @override
  String get recoveryKeyNotNow => 'अभी नहीं';

  @override
  String get recoveryKeyRow => 'रिकवरी की';

  @override
  String get recoveryKeyRowDetail => 'नए फ़ोन पर आपका बैकअप खोलती है।';

  @override
  String get noticeRecoveryKeyWrong =>
      'यह की इस खाते का बैकअप नहीं खोलती। जाँचकर फिर से कोशिश करें।';

  @override
  String get noticeRecoveryKeyAccepted =>
      'बैकअप खुल गया। आपकी रिपोर्ट वापस ला रहे हैं…';

  @override
  String get noticeSignInRequired => 'रिपोर्ट Sync करने के लिए साइन इन करें।';

  @override
  String get noticeBackendNotConfigured =>
      'इस वर्शन में अभी क्लाउड Sync चालू नहीं है।';

  @override
  String get foreignAccountTitle => 'किसी दूसरे खाते से साइन इन हुआ है';

  @override
  String get foreignAccountBody =>
      'इस फ़ोन पर पहले से किसी दूसरे खाते की रिपोर्ट और परिवार के सदस्य हैं। रखने पर वे रिपोर्ट यहीं रहेंगी, और इस नए खाते का डेटा उनके साथ जुड़ जाएगा। मिटाने पर सिर्फ़ इस फ़ोन पर रखा सब कुछ हट जाएगा — इसकी रिपोर्ट, सदस्यों की सूची, सीखे गए टेस्ट समूह और उनके कागज़। खाते का क्लाउड बैकअप कभी नहीं छुआ जाता।';

  @override
  String get foreignAccountKeep => 'इस फ़ोन की रिपोर्ट रखें और आगे बढ़ें';

  @override
  String get foreignAccountClear => 'यह फ़ोन खाली करें, फिर वापस लाएँ';

  @override
  String get restoreFetching => 'आपके खाते का डेटा ला रहे हैं…';

  @override
  String memberRemoveNamed(String name) {
    return '“$name” को हटाएँ?';
  }

  @override
  String get memberRemoveDetail => 'उनकी प्रोफ़ाइल इस फ़ोन से हटा दी जाएगी।';

  @override
  String get memberRemoveSyncedNote =>
      'खाते के क्लाउड बैकअप से भी यह प्रोफ़ाइल हट जाएगी।';

  @override
  String get memberRemoveConfirm => 'हटाएँ';

  @override
  String familyMemberRemoved(String name) {
    return '$name को हटा दिया गया।';
  }

  @override
  String memberRemoveBlocked(String name) {
    return '$name की रिपोर्ट अभी यहाँ हैं। पहले उन्हें दूसरी जगह ले जाएँ या हटाएँ।';
  }

  @override
  String memberRemoveWithReports(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count रिपोर्ट',
      one: '1 रिपोर्ट',
    );
    return '$name और $_temp0 हटाएँ?';
  }

  @override
  String get memberRemoveWithReportsDetail =>
      'उनकी रिपोर्ट, नतीजे और असली फ़ाइलें इस फ़ोन से मिटा दी जाएँगी। यह वापस नहीं हो सकता।';

  @override
  String get memberRemoveWithReportsConfirm => 'रिपोर्ट के साथ हटाएँ';

  @override
  String noticeMemberUpdated(String name) {
    return '$name के बदलाव सेव हो गए';
  }

  @override
  String get editMember => 'जानकारी बदलें';

  @override
  String get saveChanges => 'बदलाव सेव करें';

  @override
  String get photoTake => 'फ़ोटो लें';

  @override
  String get photoChoose => 'फ़ोटो चुनें';

  @override
  String get photoRemove => 'फ़ोटो हटाएँ';

  @override
  String get remindersTitle => 'रिमाइंडर';

  @override
  String get remindersSubtitle =>
      'टेस्ट करवाने या रिपोर्ट जोड़ने की याद, इसी फ़ोन पर, आपके लिए या जिनकी आप देखभाल करते हैं।';

  @override
  String get remindersRowSubtitle => 'समय पर टेस्ट करवाएँ और रिपोर्ट जोड़ें';

  @override
  String get remindersEmptyTitle => 'अभी कोई रिमाइंडर नहीं';

  @override
  String get remindersEmptyMessage =>
      'अगले ब्लड टेस्ट, थायरॉइड की दोबारा जाँच, या ताज़ा रिपोर्ट जोड़ने के लिए एक रिमाइंडर लगाएँ।';

  @override
  String get addReminder => 'रिमाइंडर जोड़ें';

  @override
  String get editReminder => 'रिमाइंडर बदलें';

  @override
  String get reminderTitleLabel => 'किस बात की याद दिलाएँ';

  @override
  String get reminderTitleHint => 'लॉक स्क्रीन पर दिखेगा';

  @override
  String get reminderTitleRequired => 'लिखें कि किस बात की याद दिलानी है';

  @override
  String get reminderPresetTest => 'टेस्ट करवाएँ';

  @override
  String get reminderPresetReport => 'ताज़ा रिपोर्ट जोड़ें';

  @override
  String get reminderForLabel => 'किसके लिए';

  @override
  String get reminderWhenLabel => 'कब';

  @override
  String get reminderRepeatLabel => 'दोहराएँ';

  @override
  String get repeatOnce => 'एक बार';

  @override
  String get repeatMonthly => 'हर महीने';

  @override
  String get repeatEvery3Months => 'हर 3 महीने';

  @override
  String get repeatEvery6Months => 'हर 6 महीने';

  @override
  String get repeatYearly => 'हर साल';

  @override
  String get saveReminder => 'रिमाइंडर सेव करें';

  @override
  String get deleteReminder => 'रिमाइंडर हटाएँ';

  @override
  String get deleteReminderDetail =>
      'यह फिर याद नहीं दिलाएगा। रिपोर्ट पर कोई असर नहीं पड़ेगा।';

  @override
  String get reminderNoMore => 'आगे कोई रिमाइंडर नहीं';

  @override
  String get reminderPrivacy => 'सिर्फ़ इसी फ़ोन पर। कभी Sync नहीं होता।';

  @override
  String get remindersTooltip => 'रिमाइंडर';

  @override
  String get remindersDueSoonTooltip => 'रिमाइंडर, इस हफ़्ते एक बाकी है';

  @override
  String get reminderInPast => 'आगे का कोई समय चुनें';

  @override
  String get remindersNotificationsOff =>
      'रिमाइंडर सेव हो गया। लेकिन Vitalog को सूचनाएँ दिखाने की अनुमति नहीं है, इसलिए वह याद नहीं दिला पाएगा। सेटिंग खोलें दबाएँ और Notifications चालू करें।';

  @override
  String reminderBody(String name) {
    return '$name के लिए रिमाइंडर';
  }

  @override
  String reminderNext(String when) {
    return 'अगला: $when';
  }

  @override
  String deleteReminderTitle(String title) {
    return '“$title” हटाएँ?';
  }

  @override
  String get deleteAccountButton => 'खाता हटाएँ';

  @override
  String get deleteAccountTitle => 'यह खाता हटाएँ?';

  @override
  String get deleteAccountMessage =>
      'इससे खाता और उसके साथ Sync हुआ सब कुछ हट जाएगा — रिपोर्ट, नतीजे और परिवार के सदस्यों की प्रोफ़ाइल — और इस फ़ोन पर रखी कॉपी भी। दूसरे खातों का डेटा अलग है और वैसा ही रहेगा। यह वापस नहीं हो सकता।';

  @override
  String get deleteAccountConfirm => 'खाता हटाएँ';

  @override
  String get accountDeletedNotice => 'खाता हटा दिया गया। यह फ़ोन खाली है।';

  @override
  String get accountDeleteFailedNotice =>
      'खाता हटाने के लिए सर्वर से जुड़ नहीं सके। कुछ नहीं बदला।';

  @override
  String get familyEyebrow => 'आपका घर';

  @override
  String get familyTitle => 'परिवार के सदस्य';

  @override
  String get settingsTitle => 'सेटिंग';

  @override
  String get settingsSubtitle => 'ऐप कैसा दिखे, और आपका खाता।';

  @override
  String get familySubtitle => 'चुनें कि किसकी सेहत की टाइमलाइन देखनी है।';

  @override
  String relationAge(String relation, int age) {
    return '$relation · $age साल';
  }

  @override
  String reportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count रिपोर्ट',
      one: '1 रिपोर्ट',
      zero: 'कोई रिपोर्ट नहीं',
    );
    return '$_temp0';
  }

  @override
  String get addFamilyMember => 'परिवार का सदस्य जोड़ें';

  @override
  String get sampleDataNote =>
      'पहले चार सदस्य नमूने के लिए हैं। आपके जोड़े सदस्य और रिपोर्ट इसी फ़ोन पर रहते हैं।';

  @override
  String get accountTitle => 'खाता';

  @override
  String signedInAs(String email) {
    return '$email से साइन इन है';
  }

  @override
  String get signOutDetail => 'आपकी रिपोर्ट इसी फ़ोन पर रहेंगी।';

  @override
  String get deleteAccountDetail =>
      'आपका क्लाउड बैकअप हमेशा के लिए हटा देता है।';

  @override
  String get accountStatMembers => 'सदस्य';

  @override
  String get accountStatReports => 'रिपोर्ट';

  @override
  String get accountStatUnsynced => 'Sync बाकी';

  @override
  String get signedOutMessage =>
      'Sync से रिपोर्ट का क्लाउड में बैकअप रखने के लिए साइन इन करें।';

  @override
  String get signIn => 'साइन इन';

  @override
  String get signOut => 'साइन आउट';

  @override
  String get signInTitle => 'साइन इन';

  @override
  String get createAccountTitle => 'खाता बनाएँ';

  @override
  String get signInSubtitle =>
      'आपका खाता सिर्फ़ तब इस्तेमाल होता है जब आप Sync दबाकर रिपोर्ट का बैकअप लेते हैं।';

  @override
  String get continueWithGoogle => 'Google से आगे बढ़ें';

  @override
  String get orDivider => 'या';

  @override
  String get emailLabel => 'ईमेल';

  @override
  String get passwordLabel => 'पासवर्ड';

  @override
  String get signInButton => 'साइन इन करें';

  @override
  String get createAccountButton => 'खाता बनाएँ';

  @override
  String get noAccount => 'नए हैं? खाता बनाएँ';

  @override
  String get haveAccount => 'पहले से खाता है? साइन इन करें';

  @override
  String get forgotPassword => 'पासवर्ड भूल गए?';

  @override
  String get resetSent => 'पासवर्ड बदलने का लिंक अपने ईमेल में देखें।';

  @override
  String get confirmEmailSent => 'खाता पक्का करने के लिए अपना ईमेल देखें।';

  @override
  String get emailInvalid => 'सही ईमेल डालें';

  @override
  String get passwordTooShort => 'कम से कम 8 अक्षर रखें';

  @override
  String get authFailed => 'साइन इन नहीं हो सका। कृपया फिर से कोशिश करें।';

  @override
  String get authWrongDetails => 'ईमेल या पासवर्ड गलत है।';

  @override
  String get authTooManyTries =>
      'बहुत बार कोशिश हो गई। कुछ मिनट रुककर फिर कोशिश करें।';

  @override
  String get authOffline => 'सर्वर से नहीं जुड़ पा रहे। अपना इंटरनेट देखें।';

  @override
  String get authWeakPassword =>
      'मज़बूत पासवर्ड चुनें: कम से कम 8 अक्षर, अक्षरों और अंकों के साथ।';

  @override
  String get authConfirmEmail =>
      'पहले अपना ईमेल पक्का करें: हमारे भेजे लिंक को खोलें।';

  @override
  String categoryName(String id) {
    String _temp0 = intl.Intl.selectLogic(
      id,
      {
        'blood': 'खून और CBC',
        'glucose': 'शुगर (ग्लूकोज़)',
        'kidney': 'किडनी',
        'liver': 'लिवर',
        'lipid': 'लिपिड प्रोफ़ाइल',
        'thyroid': 'थायरॉइड',
        'vitamins': 'विटामिन',
        'iron': 'आयरन',
        'urine': 'पेशाब',
        'heart': 'दिल',
        'pancreas': 'पैंक्रियास',
        'immunity': 'रोग-प्रतिरोधक क्षमता और सूजन',
        'cancer': 'कैंसर मार्कर',
        'hormones': 'हार्मोन',
        'infections': 'संक्रमण',
        'clotting': 'खून का जमना',
        'other': 'अन्य',
      },
    );
    return '$_temp0';
  }

  @override
  String get editValue => 'नतीजा बदलें';

  @override
  String get editResultTitle => 'यह नतीजा ठीक करें';

  @override
  String get editResultHint =>
      'जो आपकी रिपोर्ट पर छपा है, वही लिखें। हम उसे सीमा से फिर जाँचेंगे।';

  @override
  String get fieldTestName => 'टेस्ट का नाम';

  @override
  String get fieldValue => 'नतीजा';

  @override
  String get fieldUnit => 'यूनिट';

  @override
  String get fieldRange => 'सामान्य सीमा (रेफ़रेंस रेंज)';

  @override
  String get fieldRangeHint => 'जैसे, 0.4 - 4.0';

  @override
  String get fieldRequired => 'रिपोर्ट पर जो छपा है, वह डालें';

  @override
  String get save => 'सेव करें';

  @override
  String get compareOriginal => 'असली रिपोर्ट से मिलाएँ';

  @override
  String get editedBadge => 'आपने बदला';

  @override
  String get needsReviewBanner =>
      'यह साफ़ नहीं पढ़ा जा सका। अपनी रिपोर्ट से मिलाकर देखें।';

  @override
  String get checkAndFix => 'जाँचें और ठीक करें';

  @override
  String get looksRight => 'सही है';

  @override
  String get statusCheckedNoRange => 'जाँच लिया · सीमा नहीं';

  @override
  String get noticeResultEdited => 'सेव हो गया। छपी सीमा से स्थिति बदल दी गई।';

  @override
  String get noticeResultChecked => 'जाँचा हुआ मान लिया गया।';

  @override
  String get noticeReportDuplicate => 'यह रिपोर्ट आप पहले ही जोड़ चुके हैं।';

  @override
  String get noticeFileTooLarge =>
      'यह फ़ाइल बहुत बड़ी है (50 MB से ज़्यादा), इसलिए नहीं जोड़ी गई।';

  @override
  String get originalsLockTitle => 'असली रिपोर्ट लॉक करें?';

  @override
  String get originalsLockBody =>
      'स्कैन की गई रिपोर्ट में आपका नाम, पता और फ़ोन नंबर होता है। लॉक चालू होने पर उन्हें खोलने के लिए आपका चेहरा, फ़िंगरप्रिंट या स्क्रीन-लॉक PIN लगेगा। आपके नतीजे हमेशा की तरह दिखते रहेंगे।';

  @override
  String get originalsLockNext => 'अब आपका फ़ोन पूछेगा कि यह आप ही हैं।';

  @override
  String get originalsLockTurnOn => 'चालू करें';

  @override
  String get originalsLockNotNow => 'अभी नहीं';

  @override
  String get originalsLockLater => 'आप इसे कभी भी परिवार टैब पर बदल सकते हैं।';

  @override
  String get originalsLockSetting => 'असली रिपोर्ट लॉक करें';

  @override
  String get originalsLockSettingHint =>
      'स्कैन किए कागज़ खोलने के लिए चेहरा, फ़िंगरप्रिंट या PIN';

  @override
  String get noticeOriginalsLocked => 'असली रिपोर्ट अब लॉक हैं।';

  @override
  String get noticeOriginalsUnlocked =>
      'असली रिपोर्ट खोलने के लिए अब अनलॉक की ज़रूरत नहीं।';

  @override
  String get noticeOriginalsLockUnchanged =>
      'कुछ नहीं बदला: अनलॉक रद्द हुआ, या इस फ़ोन पर स्क्रीन लॉक नहीं है।';

  @override
  String get vaultPromptTitle => 'अपनी असली रिपोर्ट खोलें';

  @override
  String get vaultPromptSubtitle =>
      'अपना फ़िंगरप्रिंट, चेहरा या स्क्रीन-लॉक PIN इस्तेमाल करें, ताकि सिर्फ़ आप इसे देख सकें';

  @override
  String get viewReport => 'देखें';

  @override
  String get readingSecurely => 'इसी फ़ोन पर पढ़ी जा रही है';

  @override
  String get addingReport => 'आपकी रिपोर्ट जोड़ी जा रही है…';

  @override
  String get splashTagline => 'साथ मिलकर, सेहत की साफ़ तस्वीर।';

  @override
  String get customizeHome => 'होम अपने हिसाब से बनाएँ';

  @override
  String get customizeHomeHint =>
      'चुनें कि होम स्क्रीन पर क्या दिखे। छिपे हिस्से लोड नहीं होते।';

  @override
  String get sectionLatestReport => 'आखिरी टेस्ट की तारीख';

  @override
  String get sectionCategories => 'सेहत के समूह';

  @override
  String get sectionRecentResults => 'हाल के नतीजे';

  @override
  String get sectionRangeNote => 'लैब सीमा के बारे में';

  @override
  String get hiddenInSimpleMode => 'आसान मोड चालू होने पर छिपा है';

  @override
  String get simpleMode => 'आसान मोड';

  @override
  String get simpleModeHint =>
      'बड़े और मोटे अक्षर और बटन, सीधे शब्द, स्क्रीन पर कम चीज़ें।';

  @override
  String get testedHeading => 'टेस्ट हो चुके';

  @override
  String get yetToTestHeading => 'अभी टेस्ट नहीं हुए';

  @override
  String get yetToTestNote =>
      'अभी कोई नतीजा नहीं। ये टेस्ट अक्सर करवाए जाते हैं। डॉक्टर से पूछें कि क्या आपको इनकी ज़रूरत है।';

  @override
  String keyTestsLine(String tests) {
    return 'आम तौर पर इसमें $tests';
  }

  @override
  String notYetLine(String tests) {
    return 'अभी नहीं: $tests';
  }

  @override
  String get notTestedBadge => 'टेस्ट नहीं हुआ';

  @override
  String onAdviceLine(String tests) {
    return 'डॉक्टर की सलाह पर · $tests';
  }

  @override
  String get fieldCategory => 'समूह';

  @override
  String get chooseCategory => 'समूह चुनें';

  @override
  String needCategory(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count के लिए समूह चुनना है',
      one: '1 के लिए समूह चुनना है',
    );
    return '$_temp0';
  }

  @override
  String get themeTitle => 'थीम';

  @override
  String get themeSystem => 'फ़ोन के अनुसार';

  @override
  String get themeLight => 'हल्की';

  @override
  String get themeDark => 'गहरी';

  @override
  String get languageTitle => 'भाषा';

  @override
  String get languageSystem => 'फ़ोन की भाषा';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'हिन्दी';

  @override
  String get languageTelugu => 'తెలుగు';

  @override
  String get accentTitle => 'मुख्य रंग';

  @override
  String get accentVitalog => 'Vitalog';

  @override
  String get accentOcean => 'समुद्र';

  @override
  String get accentPlum => 'जामुनी';

  @override
  String get accentEmber => 'अंगारा';

  @override
  String get accentGraphite => 'स्लेटी';

  @override
  String get chooseFile => 'फ़ाइल चुनें (PDF, Word, Excel…)';

  @override
  String get unsupportedFileLine => 'इस तरह की फ़ाइल पढ़ी नहीं जा सकती';

  @override
  String get noticeReportUnsupported =>
      'इस तरह की फ़ाइल पढ़ी नहीं जा सकती, इसलिए नहीं जोड़ी गई। फ़ोटो, PDF, Word, Excel, CSV या टेक्स्ट फ़ाइल आज़माएँ।';

  @override
  String get noticeNotLabReport =>
      'यह लैब रिपोर्ट नहीं लगती: इसमें टेस्ट के नतीजे नहीं हैं, इसलिए नहीं जोड़ी गई।';

  @override
  String get sectionOverview => 'सेहत एक नज़र में';

  @override
  String get sectionTrends => 'बदलाव';

  @override
  String get overviewTitle => 'एक नज़र में';

  @override
  String overviewOfTotal(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total ताज़ा नतीजों में से सीमा के अंदर',
      one: '1 ताज़ा नतीजे में से सीमा के अंदर',
    );
    return '$_temp0';
  }

  @override
  String get overviewNote =>
      'हर टेस्ट का सबसे ताज़ा नतीजा एक बार गिना जाता है।';

  @override
  String get legendWithinRange => 'सीमा के अंदर';

  @override
  String get legendNeedsReview => 'जाँच ज़रूरी';

  @override
  String get legendOutsideRange => 'सीमा से बाहर';

  @override
  String overviewSemantics(int good, int review, int outside) {
    return '$good सीमा के अंदर, $review की जाँच ज़रूरी, $outside सीमा से बाहर';
  }

  @override
  String get trendsTitle => 'बदलाव';

  @override
  String get trendsSubtitle =>
      'जिन टेस्ट के एक से ज़्यादा नतीजे हैं। छायादार पट्टी = लैब की छपी सीमा।';

  @override
  String trendSince(String date) {
    return '$date से';
  }

  @override
  String get trendNoChange => 'कोई बदलाव नहीं';

  @override
  String trendUpStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count times',
    );
    return 'Up $_temp0 in a row';
  }

  @override
  String trendDownStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count times',
    );
    return 'Down $_temp0 in a row';
  }

  @override
  String trendSemantics(
      String name, String value, String change, String status) {
    return '$name, ताज़ा $value, $change, $status';
  }

  @override
  String get shortHigh => 'ज़्यादा';

  @override
  String get shortLow => 'कम';

  @override
  String get moreActions => 'और विकल्प';

  @override
  String deleteReportNamed(String name) {
    return '“$name” हटाएँ?';
  }

  @override
  String deleteReportDetail(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'असली कागज़ और उसके $count नतीजे इस फ़ोन से हटा दिए जाएँगे। यह वापस नहीं हो सकता।',
      one:
          'असली कागज़ और उसका 1 नतीजा इस फ़ोन से हटा दिए जाएँगे। यह वापस नहीं हो सकता।',
      zero: 'असली कागज़ इस फ़ोन से हटा दिया जाएगा। यह वापस नहीं हो सकता।',
    );
    return '$_temp0';
  }

  @override
  String get deleteReportSyncedNote =>
      'हटाने से यह इस खाते के क्लाउड बैकअप से भी हट जाएगी।';

  @override
  String get deleteReportConfirm => 'रिपोर्ट हटाएँ';

  @override
  String get statusWithinUsual => 'आम सीमा के अंदर';

  @override
  String get statusHighUsual => 'ज़्यादा · आम सीमा';

  @override
  String get statusLowUsual => 'कम · आम सीमा';

  @override
  String usualRangeUsed(String range, String source) {
    return 'रिपोर्ट पर सीमा नहीं छपी थी, इसलिए आम सीमा ली गई: $range ($source)।';
  }

  @override
  String usualRangeDiffers(String range) {
    return 'आपकी लैब की सीमा आम सीमा ($range) से अलग है। आपकी लैब की सीमा ही ली गई है।';
  }

  @override
  String get attentionTitle => 'ध्यान दें';

  @override
  String get attentionSubtitle =>
      'लैब की सीमा या आम सीमा से बाहर। यह डायग्नोसिस नहीं है — अपने डॉक्टर से बात करें।';

  @override
  String attentionBelow(String value, String range) {
    return '$value सीमा ($range) से कम है';
  }

  @override
  String attentionAbove(String value, String range) {
    return '$value सीमा ($range) से ज़्यादा है';
  }

  @override
  String get attentionUsualTag => 'आम सीमा';

  @override
  String noticeReportAttention(int count, int attention) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count टेस्ट जोड़े गए',
      one: '1 टेस्ट जोड़ा गया',
    );
    String _temp1 = intl.Intl.pluralLogic(
      attention,
      locale: localeName,
      other: '$attention पर ध्यान दें',
      one: '1 पर ध्यान दें',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get noticeReportTimedOut =>
      'यह रिपोर्ट पढ़ने में बहुत समय लगा। साफ़ फ़ोटो या कम पन्ने आज़माएँ।';

  @override
  String noticeReportOtherPerson(String name) {
    return 'इस रिपोर्ट पर $name लिखा है। देखें कि यह किसके नाम में रखी है।';
  }

  @override
  String get noticeReportCancelled => 'पढ़ना रद्द किया। कुछ नहीं रखा गया।';

  @override
  String noticeMemberAdded(String name) {
    return '$name को परिवार में जोड़ा गया।';
  }

  @override
  String get reviewAction => 'जाँचें';

  @override
  String get cancelReading => 'पढ़ना रद्द करें';

  @override
  String get timedOutLine =>
      'पढ़ने में बहुत समय लगा। साफ़ फ़ोटो या कम पन्ने आज़माएँ।';

  @override
  String nameMismatchLine(String name, String member) {
    return 'इस रिपोर्ट पर नाम: $name। यह $member के नाम में रखी है।';
  }

  @override
  String get keepHere => 'यहीं रखें';

  @override
  String moveToMember(String name) {
    return '$name के पास ले जाएँ';
  }

  @override
  String get moveReport => 'इनके पास ले जाएँ…';

  @override
  String get moveReportTitle => 'यह रिपोर्ट किसकी है?';

  @override
  String noticeReportMoved(String name) {
    return '$name के पास ले जाई गई।';
  }

  @override
  String get nameMatchesBadge => 'नाम मिलता है';

  @override
  String readingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count रीडिंग',
      one: '1 रीडिंग',
    );
    return '$_temp0';
  }

  @override
  String get addMemberTitle => 'परिवार का सदस्य जोड़ें';

  @override
  String get memberNameLabel => 'पूरा नाम, जैसा लैब रिपोर्ट पर होता है';

  @override
  String get memberNameRequired => 'नाम डालें';

  @override
  String get relationLabel => 'रिश्ता';

  @override
  String get relationSelf => 'आप';

  @override
  String get relationPartner => 'पति / पत्नी';

  @override
  String get relationChild => 'बच्चा';

  @override
  String get relationParent => 'माता / पिता';

  @override
  String get relationSibling => 'भाई / बहन';

  @override
  String get relationGrandparent => 'दादा-दादी / नाना-नानी';

  @override
  String get relationOther => 'अन्य';

  @override
  String get ageLabel => 'उम्र (साल)';

  @override
  String get ageInvalid => '0 से 120 के बीच उम्र डालें';

  @override
  String get sexLabel => 'लिंग';

  @override
  String get sexFemale => 'महिला';

  @override
  String get sexMale => 'पुरुष';

  @override
  String get sexUnset => 'नहीं चुना';

  @override
  String get sexHelp =>
      'कुछ आम सीमाएँ महिला और पुरुष के लिए अलग होती हैं। अगर लिंग नहीं चुना, तो वे सीमाएँ इस्तेमाल नहीं होतीं।';

  @override
  String get saveMember => 'सदस्य जोड़ें';

  @override
  String get memberPrivacy => 'सिर्फ़ इसी फ़ोन पर सेव होता है।';

  @override
  String get onboardingSkip => 'छोड़ें';

  @override
  String get onboardingNext => 'आगे';

  @override
  String get onboardingStart => 'शुरू करें';

  @override
  String get onboardingTitle1 => 'हर लैब रिपोर्ट, एक ही जगह';

  @override
  String get onboardingBody1 =>
      'फ़ोटो लें, PDF या कोई भी फ़ाइल चुनें। हर टेस्ट खून, थायरॉइड, विटामिन जैसे समूहों में रखा जाता है।';

  @override
  String get onboardingTitle2 => 'आपके फ़ोन पर ही पढ़ी जाती है';

  @override
  String get onboardingBody2 =>
      'रिपोर्ट यहीं, इसी फ़ोन पर पढ़ी जाती हैं। जब तक आप Sync न दबाएँ, कुछ भी कहीं नहीं भेजा जाता।';

  @override
  String get onboardingTitle3 => 'पूरे परिवार का ध्यान रखें';

  @override
  String get onboardingBody3 =>
      'जिनकी आप देखभाल करते हैं, सबकी टाइमलाइन रखें और देखें कि हर नतीजा समय के साथ कैसे बदलता है।';

  @override
  String get welcomeTitle => 'Vitalog में आपका स्वागत है';

  @override
  String get continueWithoutAccount => 'बिना खाते के आगे बढ़ें';

  @override
  String get showPassword => 'पासवर्ड दिखाएँ';

  @override
  String get hidePassword => 'पासवर्ड छिपाएँ';

  @override
  String get statusPlainWithin => 'ठीक है';

  @override
  String get statusPlainHigh => 'सीमा से ज़्यादा';

  @override
  String get statusPlainLow => 'सीमा से कम';

  @override
  String get statusPlainReview => 'कृपया जाँचें';

  @override
  String onboardingPage(int page, int count) {
    return '$count में से पन्ना $page';
  }

  @override
  String get notNow => 'अभी नहीं';

  @override
  String get createPasswordHint => 'कम से कम 8 अक्षर';

  @override
  String get welcomeBack => 'फिर से स्वागत है';

  @override
  String get nameCheckNote =>
      'यह नाम हर रिपोर्ट पर छपे मरीज़ के नाम से मिलाया जाता है, ताकि गलत व्यक्ति के नाम में रखी रिपोर्ट पकड़ में आ जाए।';

  @override
  String nameMustInclude(String name) {
    return 'मिलान के लिए रिपोर्ट पर “$name” होना चाहिए।';
  }

  @override
  String nameLooksLikeNickname(String name) {
    return '“$name” घर का नाम लगता है। लैब असली नाम छापती है, इसलिए उनकी रिपोर्ट से मेल नहीं खाएगा।';
  }

  @override
  String get dateNotDetected => 'तारीख नहीं मिली';

  @override
  String get pickerFailed =>
      'Vitalog को कैमरा या आपकी फ़ोटो इस्तेमाल करने की अनुमति नहीं है। अनुमति देने के लिए सेटिंग खोलें दबाएँ और Camera और Photos चालू करें।';

  @override
  String get openSettings => 'सेटिंग खोलें';

  @override
  String get notifyAskTitle => 'रिमाइंडर की अनुमति दें?';

  @override
  String get notifyAskBody =>
      'समय पर याद दिलाने के लिए Vitalog को इस फ़ोन पर सूचनाएँ दिखानी होंगी। उनमें सिर्फ़ आपका लिखा रिमाइंडर और व्यक्ति का नाम दिखता है, टेस्ट के नतीजे कभी नहीं।';

  @override
  String get notifyAskNext => 'अब आपका फ़ोन पूछेगा। “Allow” दबाएँ।';

  @override
  String get notifyAskContinue => 'आगे बढ़ें';

  @override
  String get notifyAskNotNow => 'अभी नहीं';

  @override
  String get notifyAskLater =>
      'आप इसे कभी भी फ़ोन की Settings में बदल सकते हैं।';

  @override
  String shareMember(String name) {
    return '$name की रिपोर्ट शेयर करें';
  }

  @override
  String shareIntro(String name) {
    return 'जिन्हें आप बुलाएँगे, वे $name की रिपोर्ट देख सकेंगे और अपने फ़ोन से नई रिपोर्ट जोड़ सकेंगे। यह एंड-टू-एंड एन्क्रिप्टेड है: इसे सिर्फ़ आपका परिवार पढ़ सकता है, Vitalog भी नहीं।';
  }

  @override
  String shareUploadNote(String name) {
    return 'बुलाने से पहले $name की प्रोफ़ाइल और रिपोर्ट सील होकर आपके खाते में बैकअप हो जाती हैं।';
  }

  @override
  String get shareInvite => 'किसी को बुलाएँ';

  @override
  String get sharePeople => 'ये रिपोर्ट कौन देख सकता है';

  @override
  String shareYou(String name) {
    return '$name (आप)';
  }

  @override
  String get shareYouPlain => 'आप';

  @override
  String get shareSomeone => 'आपके परिवार का कोई सदस्य';

  @override
  String get sharePending => 'न्योता बाकी है';

  @override
  String sharePendingUntil(String date) {
    return 'लिंक $date तक काम करेगा';
  }

  @override
  String get shareCancelInvite => 'न्योता रद्द करें';

  @override
  String get shareRemove => 'हटाएँ';

  @override
  String shareRemoveTitle(String name, String person) {
    return '$name की रिपोर्ट $person के साथ शेयर करना बंद करें?';
  }

  @override
  String shareRemoveMessage(String person) {
    return '$person को नई रिपोर्ट नहीं मिलेंगी। जो रिपोर्ट पहले से उनके फ़ोन पर हैं, वे वहीं रहेंगी।';
  }

  @override
  String get shareRemoveConfirm => 'शेयर करना बंद करें';

  @override
  String shareMessage(String name, String link) {
    return 'मैंने Vitalog पर $name की सेहत की रिपोर्ट आपके साथ शेयर की हैं। उन्हें देखने के लिए यह लिंक अपने फ़ोन पर खोलें। यह 7 दिन तक, सिर्फ़ एक बार काम करेगा।\n$link';
  }

  @override
  String shareSubject(String name) {
    return '$name की सेहत की रिपोर्ट';
  }

  @override
  String get shareSignIn =>
      'शेयर करने के लिए साइन इन करें। आपके खाते के ज़रिए आपका परिवार अपने फ़ोन पर रिपोर्ट देखेगा।';

  @override
  String get shareFailed =>
      'आपके खाते तक नहीं पहुँच पाए। कनेक्शन जाँचें और फिर से कोशिश करें।';

  @override
  String get shareSample =>
      'नमूना लोगों को शेयर नहीं किया जा सकता। पहले अपने परिवार का कोई सदस्य जोड़ें।';

  @override
  String get claimTitle => 'परिवार का न्योता';

  @override
  String claimShared(String from, String name) {
    return '$from ने $name की रिपोर्ट आपके साथ शेयर की हैं';
  }

  @override
  String claimSharedNoFrom(String name) {
    return '$name की रिपोर्ट आपके साथ शेयर की गई हैं';
  }

  @override
  String claimWho(String name) {
    return '$name आपके क्या लगते हैं?';
  }

  @override
  String get claimAccept => 'मेरे परिवार में जोड़ें';

  @override
  String get claimNotNow => 'अभी नहीं';

  @override
  String get combineTitle => 'अपनी प्रोफ़ाइल के साथ मिला दें?';

  @override
  String combineMessage(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count रिपोर्ट हैं',
      one: '1 रिपोर्ट है',
      zero: 'कोई रिपोर्ट नहीं है',
    );
    return 'आपकी अपनी एक प्रोफ़ाइल $name पहले से है, जिसमें $_temp0। मिलाने पर वे इस शेयर की गई प्रोफ़ाइल में चली जाएँगी और पुरानी प्रोफ़ाइल हट जाएगी। आपका नाम, लिंग और जन्म का साल वही रहेंगे, और जो फ़ाइल दोनों में है वह एक ही बार रखी जाएगी।';
  }

  @override
  String get combineConfirm => 'मिला दें';

  @override
  String get combineKeep => 'अलग रखें';

  @override
  String claimPrivacy(String name) {
    return 'रिपोर्ट एंड-टू-एंड एन्क्रिप्टेड होकर इस फ़ोन पर आती हैं। आप भी $name के लिए रिपोर्ट जोड़ सकते हैं, और शेयर करने वाले सभी लोग उन्हें देखेंगे।';
  }

  @override
  String get claimSignIn =>
      'स्वीकार करने के लिए साइन इन करें। रिपोर्ट आपके खाते में सील होकर आती हैं, ताकि सिर्फ़ आपका परिवार उन्हें पढ़ सके।';

  @override
  String get claimAlready => 'ये रिपोर्ट आपके पास पहले से हैं।';

  @override
  String get claimOpen => 'खोलें';

  @override
  String get claimInvalid =>
      'यह Vitalog का न्योता लिंक नहीं है। देखें कि आपने पूरा लिंक कॉपी किया है।';

  @override
  String get claimGone => 'यह न्योता अब काम नहीं करता। नया लिंक माँगें।';

  @override
  String get claimUsed =>
      'इस न्योते का इस्तेमाल पहले ही हो चुका है। हर लिंक एक ही बार काम करता है, इसलिए नया माँगें।';

  @override
  String get claimExpired =>
      'इस न्योते की अवधि खत्म हो गई है। लिंक 7 दिन तक काम करते हैं, इसलिए नया माँगें।';

  @override
  String get claimLimited =>
      'बहुत ज़्यादा कोशिशें। एक घंटा रुकें, फिर लिंक दोबारा खोलें।';

  @override
  String get claimFailed =>
      'Vitalog तक नहीं पहुँच पाए। कनेक्शन जाँचें और फिर से कोशिश करें।';

  @override
  String get claimRecoveryKey =>
      'पहले अपनी रिकवरी की डालें, फिर लिंक दोबारा खोलें।';

  @override
  String get openInviteRow => 'न्योता लिंक खोलें';

  @override
  String get openInviteRowDetail =>
      'परिवार ने लिंक भेजा है? उसे यहाँ पेस्ट करें।';

  @override
  String get pasteInviteTitle => 'न्योता लिंक पेस्ट करें';

  @override
  String get pasteInviteOpen => 'खोलें';

  @override
  String noticeInviteAccepted(String name) {
    return '$name की रिपोर्ट अब आपके फ़ोन पर हैं';
  }
}
