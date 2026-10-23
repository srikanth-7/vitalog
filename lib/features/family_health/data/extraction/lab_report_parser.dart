import '../../domain/entities/lab_result.dart';
import '../privacy/redactor.dart';
import 'alias_trie.dart';
import 'lab_test_catalog.dart';

class ParsedTest {
  const ParsedTest({
    required this.name,
    required this.categoryId,
    required this.value,
    required this.unit,
    required this.referenceRange,
    required this.status,
  });
  final String name;
  final String categoryId;
  final String value;
  final String unit;
  final String referenceRange;
  final ResultStatus status;
}

class ParsedReport {
  const ParsedReport({
    required this.tests,
    this.reportDate,
    this.collectionDate,
    this.lab,
    this.patientName,
  });
  final List<ParsedTest> tests;
  final DateTime? reportDate;
  final DateTime? collectionDate;
  final String? lab;

  /// As printed ("Mr. Arjun Sharma"), to check the report was filed under
  /// the right family member. Stays on the phone.
  final String? patientName;
}

/// Turns OCR'd report lines (one printed row per line) into structured tests.
/// Rule-based on purpose: it runs fully on-device. Anything it can't read
/// confidently is marked [ResultStatus.needsReview] rather than guessed.
class LabReportParser {
  LabReportParser({DateTime? now}) : _now = now ?? DateTime.now();
  final DateTime _now;

  ParsedReport parse(List<String> lines) {
    final cleaned = lines.map(_normalize).where((l) => l.isNotEmpty).toList();
    final tests = <ParsedTest>[];
    final seen = <String>{};
    String? section;
    // The test on the row just above, while it still has no range: some labs
    // print the range on the next line ("(12.0 - 15.5)").
    int? rangeless;
    for (final raw in lines) {
      final line = _normalize(raw);
      if (line.isEmpty) continue;
      final lower = line.toLowerCase();
      if (!_hasDigit.hasMatch(line) && !_qualitative.hasMatch(lower)) {
        section = _sectionOf(lower) ?? section;
        rangeless = null;
        continue;
      }
      final below = rangeless == null ? null : _rangeOnly(line);
      if (below != null) {
        tests[rangeless!] = _withRange(tests[rangeless], below);
        rangeless = null;
        continue;
      }
      rangeless = null;
      // Two tests printed side by side share one row.
      for (final part in _sideBySide(raw)) {
        final row = _normalize(part);
        final test = _parseRow(row, row.toLowerCase(), section);
        if (test != null && seen.add(test.name.toLowerCase())) {
          tests.add(test);
          rangeless = test.referenceRange.isEmpty ? tests.length - 1 : null;
        }
      }
    }
    return ParsedReport(
      tests: tests,
      reportDate: _labelledDate(cleaned, _reportLabels) ?? _latestDate(cleaned),
      collectionDate: _labelledDate(cleaned, _collectionLabels),
      lab: _labName(cleaned),
      patientName: _patientName(lines),
    );
  }

  // ---- rows ---------------------------------------------------------------

  ParsedTest? _parseRow(String line, String lower, String? section) {
    final match = _matchCatalog(lower, section);
    final String name;
    final String categoryId;
    final String rest;
    if (match != null) {
      name = match.definition.name;
      categoryId = match.definition.categoryId;
      rest = line.substring(match.end);
    } else {
      // Unknown test: it must look like a result row. Under a known heading
      // it joins that category; elsewhere it goes to "Other tests" for the
      // user to file, and must carry both a unit and a range (see below) so
      // addresses, phone numbers and footers aren't mistaken for results.
      final value = _value.firstMatch(line);
      if (value == null) return null;
      final label = Redactor.text(line.substring(0, value.start).trim());
      if (!_plausibleName.hasMatch(label)) return null;
      name = label;
      categoryId = section ?? otherCategoryId;
      rest = line.substring(value.start);
    }

    // Counts are printed as a span ("Pus cells  2-3  /hpf  0 - 5"): a span
    // right after the name is the value when a range or a per-field unit
    // follows it.
    final count = match == null ? null : _count.firstMatch(rest);
    if (count != null) {
      final after = rest.substring(count.end);
      if (_parseRange(after) != null || _perField.hasMatch(after)) {
        return _countRow(name, categoryId, count.group(1)!, after);
      }
    }

    // Separate ranges per sex ("M: 13.0-17.0  F: 12.0-15.5"): keep them all;
    // which one applies isn't known here, so it needs review.
    final bands = _sexBand.firstMatch(rest);
    if (bands != null && _sexBand.allMatches(rest).length > 1) {
      final before = rest.substring(0, bands.start);
      final unit = _unit.firstMatch(before)?.group(1) ?? '';
      final value = _value.firstMatch(before)?.group(1);
      if (value == null) return null;
      final flag = _flag.firstMatch(before)?.group(1);
      return ParsedTest(
          name: name,
          categoryId: categoryId,
          value: value.replaceAll(',', ''),
          unit: unit,
          referenceRange: rest.substring(bands.start).trim(),
          status: flag == null
              ? ResultStatus.needsReview
              : _status(value, null, flag));
    }

    final range = _parseRange(rest);
    final withoutRange =
        range == null ? rest : rest.replaceRange(range.start, range.end, ' ');
    final unitMatch = _unit.firstMatch(withoutRange);
    var unit = unitMatch?.group(1) ?? '';
    if (unit.isEmpty && match != null && _garbled.hasMatch(withoutRange)) {
      unit = typicalUnits[name] ?? '';
    }
    final valueMatch = _value.firstMatch(withoutRange);
    // Look for H/L outside the unit, so the "L" of "10^3/µL" isn't a flag.
    final flag = _flag
        .firstMatch(unitMatch == null
            ? withoutRange
            : withoutRange.replaceRange(unitMatch.start, unitMatch.end, ' '))
        ?.group(1);

    if (valueMatch == null) {
      final word = _qualitative.firstMatch(rest.toLowerCase())?.group(0);
      if (word == null || match == null) return null;
      return ParsedTest(
        name: name,
        categoryId: categoryId,
        value: word[0].toUpperCase() + word.substring(1),
        unit: '',
        referenceRange: range?.text ?? '',
        status: _normalWords.contains(word)
            ? ResultStatus.withinRange
            : ResultStatus.needsReview,
      );
    }

    // A bare number with neither unit nor range is more likely prose ("HbA1c
    // above 6.5 indicates…") than a result row.
    if (unit.isEmpty && range == null && flag == null) return null;
    final unfiled = categoryId == otherCategoryId;
    if (unfiled && (unit.isEmpty || range == null)) return null;

    final raw = valueMatch.group(1)!;
    final value = raw.replaceAll(',', '');
    return ParsedTest(
      name: name,
      categoryId: categoryId,
      value: value,
      unit: unit,
      referenceRange: range == null
          ? ''
          : (unit.isEmpty ? range.text : '${range.text} $unit'),
      // Unfiled tests wait for the user to pick a category.
      status: unfiled ? ResultStatus.needsReview : _status(value, range, flag),
    );
  }

  AliasHit? _matchCatalog(String lower, String? section) {
    final best = _aliases.longestMatch(lower);
    if (best == null) return null;
    // Ambiguous names ("Albumin", "Glucose", "Protein") follow the section:
    // under a urine heading prefer the urine test whose alias mentions it.
    if (section == 'urine' && best.definition.categoryId != 'urine') {
      final alias = best.alias;
      for (final d in labTestCatalog) {
        if (d.categoryId == 'urine' &&
            d.aliases.any((a) => a.contains(alias))) {
          return AliasHit(d, alias, best.start, best.end);
        }
      }
    }
    return best;
  }

  /// Built once: every catalog alias in one prefix tree.
  static final _aliases = AliasTrie(labTestCatalog);

  // Section headings are few and only checked on heading lines.
  static final _wordCache = <String, RegExp>{};
  static RegExp _wordPattern(String word) => _wordCache.putIfAbsent(
      word, () => RegExp('(?<![a-z0-9])${RegExp.escape(word)}(?![a-z0-9])'));

  /// Status for a value the user typed in, judged against the printed range
  /// the same way a parsed row is.
  ResultStatus statusFor(String value, String referenceRange) {
    final word = value.trim().toLowerCase();
    if (_normalWords.contains(word)) return ResultStatus.withinRange;
    if (_sexBand.allMatches(referenceRange).length > 1) {
      return ResultStatus.needsReview;
    }
    return _status(value.trim(), _parseRange(referenceRange), null);
  }

  ResultStatus _status(String value, _Range? range, String? flag) {
    if (flag != null) {
      return flag.toUpperCase().startsWith('H')
          ? ResultStatus.high
          : ResultStatus.low;
    }
    // A count span ("2-3") is judged by its ends.
    final span = _count.firstMatch(value);
    final low = span != null
        ? double.parse(span.group(2)!)
        : double.tryParse(value.replaceAll(RegExp('[<>,]'), ''));
    final high = span != null ? double.parse(span.group(3)!) : low;
    if (range == null || low == null || high == null) {
      return ResultStatus.needsReview;
    }
    if (range.high != null && high > range.high!) return ResultStatus.high;
    if (range.low != null && low < range.low!) return ResultStatus.low;
    return ResultStatus.withinRange;
  }

  _Range? _parseRange(String text) {
    final between = _between.firstMatch(text);
    if (between != null) {
      return _Range(between.start, between.end, between.group(0)!.trim(),
          _number(between.group(1)!), _number(between.group(2)!));
    }
    final below = _below.firstMatch(text);
    if (below != null) {
      return _Range(below.start, below.end, below.group(0)!.trim(), null,
          _number(below.group(1)!));
    }
    final above = _above.firstMatch(text);
    if (above != null) {
      return _Range(above.start, above.end, above.group(0)!.trim(),
          _number(above.group(1)!), null);
    }
    return null;
  }

  ParsedTest _countRow(
      String name, String categoryId, String value, String after) {
    final range = _parseRange(after);
    final rest =
        range == null ? after : after.replaceRange(range.start, range.end, ' ');
    final unitMatch = _unit.firstMatch(rest);
    final unit = unitMatch?.group(1) ?? '';
    final flag = _flag
        .firstMatch(unitMatch == null
            ? rest
            : rest.replaceRange(unitMatch.start, unitMatch.end, ' '))
        ?.group(1);
    final span = value.replaceAll(' ', '');
    return ParsedTest(
        name: name,
        categoryId: categoryId,
        value: span,
        unit: unit,
        referenceRange: range == null
            ? ''
            : (unit.isEmpty ? range.text : '${range.text} $unit'),
        status: _status(span, range, flag));
  }

  /// A line that is only a reference range, e.g. "(12.0 - 15.5)" or
  /// "Ref. range: 0.4 - 4.0 mIU/L".
  _Range? _rangeOnly(String line) {
    final text = line.replaceFirst(_rangeLabel, '');
    final range = _parseRange(text);
    if (range == null || text.substring(0, range.start).trim().isNotEmpty) {
      return null;
    }
    final tail = text.substring(range.end).replaceAll(_unit, '');
    return RegExp(r'^[\s)\]]*$').hasMatch(tail) ? range : null;
  }

  ParsedTest _withRange(ParsedTest t, _Range range) => ParsedTest(
      name: t.name,
      categoryId: t.categoryId,
      value: t.value,
      unit: t.unit,
      referenceRange: t.unit.isEmpty ? range.text : '${range.text} ${t.unit}',
      // A printed H/L flag already decided it; otherwise judge it now.
      status: t.status == ResultStatus.needsReview &&
              t.categoryId != otherCategoryId
          ? _status(t.value, range, null)
          : t.status);

  /// Splits a row holding two tests side by side ("Hemoglobin  12.8  g/dL
  /// 12-15.5  Creatinine  0.9  mg/dL  0.6-1.1") at the column where the
  /// second test's name starts. Columns are 2+ spaces apart in the raw row.
  List<String> _sideBySide(String raw) {
    final cols = raw.trim().split(RegExp(r'\s{2,}|\t'));
    for (var i = 2; i < cols.length - 1; i++) {
      final hit = _aliases.longestMatch(cols[i].toLowerCase(), maxPrefix: 0);
      if (hit == null || !_hasDigit.hasMatch(cols.sublist(1, i).join(' '))) {
        continue;
      }
      if (!_hasDigit.hasMatch(cols.sublist(i).join(' '))) continue;
      return [
        cols.sublist(0, i).join('  '),
        ..._sideBySide(cols.sublist(i).join('  '))
      ];
    }
    return [raw];
  }

  String? _sectionOf(String lower) {
    for (final entry in labSectionKeywords.entries) {
      for (final keyword in entry.value) {
        if (_wordPattern(keyword).hasMatch(lower)) return entry.key;
      }
    }
    return null;
  }

  // ---- header fields --------------------------------------------------------

  DateTime? _labelledDate(List<String> lines, List<String> labels) {
    for (final line in lines) {
      final lower = line.toLowerCase();
      for (final label in labels) {
        final at = lower.indexOf(label);
        if (at < 0) continue;
        final date = _firstDate(line.substring(at + label.length));
        if (date != null) return date;
      }
    }
    return null;
  }

  DateTime? _latestDate(List<String> lines) {
    DateTime? latest;
    for (final line in lines) {
      if (_birthLine.hasMatch(line.toLowerCase())) continue;
      final date = _firstDate(line);
      if (date != null && (latest == null || date.isAfter(latest))) {
        latest = date;
      }
    }
    return latest;
  }

  DateTime? _firstDate(String text) {
    final candidates = <({int at, DateTime date})>[];
    for (final m in _numericDate.allMatches(text)) {
      var a = int.parse(m.group(1)!), b = int.parse(m.group(2)!);
      var y = int.parse(m.group(3)!);
      if (y < 100) y += 2000;
      // Day-first (as printed in India/UK) unless that's impossible.
      final (day, month) = (a > 12 || b <= 12) ? (a, b) : (b, a);
      final d = _valid(y, month, day);
      if (d != null) candidates.add((at: m.start, date: d));
    }
    for (final m in _isoDate.allMatches(text)) {
      final d = _valid(int.parse(m.group(1)!), int.parse(m.group(2)!),
          int.parse(m.group(3)!));
      if (d != null) candidates.add((at: m.start, date: d));
    }
    for (final m in _dayMonthName.allMatches(text)) {
      final month = _months[m.group(2)!.toLowerCase().substring(0, 3)];
      final d = month == null
          ? null
          : _valid(_year(m.group(3)!), month, int.parse(m.group(1)!));
      if (d != null) candidates.add((at: m.start, date: d));
    }
    for (final m in _monthNameDay.allMatches(text)) {
      final month = _months[m.group(1)!.toLowerCase().substring(0, 3)];
      final d = month == null
          ? null
          : _valid(_year(m.group(3)!), month, int.parse(m.group(2)!));
      if (d != null) candidates.add((at: m.start, date: d));
    }
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => a.at.compareTo(b.at));
    return candidates.first.date;
  }

  int _year(String y) => y.length == 2 ? 2000 + int.parse(y) : int.parse(y);

  DateTime? _valid(int y, int m, int d) {
    if (m < 1 || m > 12 || d < 1 || d > 31) return null;
    if (y < 1990 || y > _now.year + 1) return null;
    final date = DateTime(y, m, d);
    return date.month == m ? date : null;
  }

  String? _labName(List<String> lines) {
    for (final line in lines.take(8)) {
      final lower = line.toLowerCase();
      if (_labWords.hasMatch(lower) && !_notLab.hasMatch(lower)) {
        // Name only: the same printed line often carries the address and
        // phone number, which the app has no reason to keep.
        final name = Redactor.labName(line.replaceAll(RegExp(r'\s{2,}'), ' '));
        return name.isEmpty ? null : name;
      }
    }
    return null;
  }

  /// "Patient Name : Mr. ARJUN SHARMA  Age/Sex : 36 Y/M" → "Mr. ARJUN SHARMA".
  /// Uses the raw rows: two spaces still separate the printed columns there.
  String? _patientName(List<String> lines) {
    for (final line in lines.take(30)) {
      final m = _nameLabel.firstMatch(line.trim());
      if (m == null) continue;
      final name = line
          .trim()
          .substring(m.end)
          .split(RegExp(r'\s{2,}|\t|\|'))
          .first
          .split(_afterName)
          .first
          .replaceAll(RegExp(r'[^\p{L}. ]', unicode: true), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      if (RegExp(r'\p{L}{2}', unicode: true).hasMatch(name)) return name;
    }
    return null;
  }

  static String _normalize(String line) => line
      .replaceAll(RegExp('[–—−]'), '-')
      .replaceAll('μ', 'µ')
      // OCR commonly reads the micro sign in µIU/mL as "H" or "p".
      .replaceAll(
          RegExp(r'(?<![A-Za-z])[HhpP]IU/', caseSensitive: true), 'µIU/')
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .trim();
}

class _Range {
  _Range(this.start, this.end, this.text, this.low, this.high);
  final int start;
  final int end;
  final String text;
  final double? low;
  final double? high;
}

// Indian/Western digit grouping ("1,50,000") first, so a range isn't read
// from the middle of a grouped number.
const _num = r'(?<![\d,.])(?:\d{1,3}(?:,\d{2,3})+(?:\.\d+)?|\d+(?:\.\d+)?)';
double _number(String text) => double.parse(text.replaceAll(',', ''));
final _hasDigit = RegExp(r'\d');
// Letters outside Latin script: OCR misread a unit cell.
final _garbled = RegExp(r'[\u0370-\u03FF\u0400-\u04FF]');
// A standalone result value: not glued to letters or a hyphen ("25-OH", "T3").
final _value = RegExp(
    r'(?:^|(?<=[\s:(]))([<>]?\d{1,3}(?:,\d{2,3})+(?:\.\d+)?|[<>]?\d+(?:\.\d+)?)(?=\s|$|\))');
final _between = RegExp('($_num)\\s*(?:-|to)\\s*($_num)');
final _below =
    RegExp('(?:<=?|≤|less than|up to|upto)\\s*($_num)', caseSensitive: false);
final _above =
    RegExp('(?:>=?|≥|more than|greater than)\\s*($_num)', caseSensitive: false);
final _flag = RegExp(r'(?<![\w/])(HIGH|LOW|High|Low|H|L)(?![\w/])');
// A count span value, e.g. "2-3" or "8 - 10" cells per field.
final _count = RegExp(r'^\s*((\d+)\s*-\s*(\d+))(?=\s|$)');
final _perField = RegExp(r'^\s*/[hl]pf\b', caseSensitive: false);
// "M: 13-17", "Female 12.0-15.5", "Men - 0.7-1.3".
final _sexBand = RegExp(
    r'(?<![a-z])(?:m|f|male|female|men|women)\s*[:\-]?\s*(?=[<>≤≥]?\s*\d)',
    caseSensitive: false);
final _rangeLabel = RegExp(
    r'^[(\[]?\s*(?:bio\.?\s*)?(?:ref(?:erence)?\.?\s*)?(?:range|interval|normal(?: range)?)?\s*[:\-]?\s*',
    caseSensitive: false);
final _unit = RegExp(
    r'(?<![\w/])(x?10\^?[36]\s*/\s*[uµ]l|10\^?[36]/cumm|lakhs?/cumm|million/cumm|mill/cumm|cells/cumm|thou/mm3|/cumm|/hpf|/lpf|/[uµ]l|mm/1st hr|mm/hr|ml/min/1\.73\s?m2|mmol/mol|[uµ]iu/ml|miu/l|miu/ml|iu/ml|iu/l|u/ml|u/l|ng/ml|ng/dl|pg/ml|[uµ]g/dl|mcg/dl|mg/dl|mg/l|g/dl|g/l|mmol/l|[uµ]mol/l|nmol/l|pmol/l|meq/l|fl|pg|%)(?![\w/])',
    caseSensitive: false);
final _qualitative = RegExp(
    r'\b(non[ -]reactive|reactive|not detected|negative|nil|absent|normal|clear|pale yellow|yellow|positive|present|trace|turbid)\b');
const _normalWords = {
  'non reactive',
  'non-reactive',
  'not detected',
  'negative',
  'nil',
  'absent',
  'normal',
  'clear',
  'pale yellow',
  'yellow',
};
final _plausibleName = RegExp(r'^[A-Za-z][A-Za-z0-9 ,()./%-]{2,40}$');

const _reportLabels = [
  'reported on',
  'report date',
  'reporting date',
  'date of report',
  'result date',
  'reported',
];
const _collectionLabels = [
  'collected on',
  'collection date',
  'date of collection',
  'sample collected',
  'sample date',
  'collected',
  'drawn on',
  'registered on',
  'registered',
];
final _birthLine = RegExp(r'\b(dob|d\.o\.b|birth)\b');
final _numericDate =
    RegExp(r'(?<!\d)(\d{1,2})[/.-](\d{1,2})[/.-](\d{4}|\d{2})(?!\d)');
final _isoDate = RegExp(r'(?<!\d)(\d{4})-(\d{1,2})-(\d{1,2})(?!\d)');
final _dayMonthName = RegExp(
    r'(?<!\d)(\d{1,2})(?:st|nd|rd|th)?[\s/-]([A-Za-z]{3,9})[\s/,-]+(\d{4}|\d{2})(?!\d)');
final _monthNameDay =
    RegExp(r'\b([A-Za-z]{3,9})\s+(\d{1,2})(?:st|nd|rd|th)?,?\s+(\d{4})(?!\d)');
const _months = {
  'jan': 1,
  'feb': 2,
  'mar': 3,
  'apr': 4,
  'may': 5,
  'jun': 6,
  'jul': 7,
  'aug': 8,
  'sep': 9,
  'oct': 10,
  'nov': 11,
  'dec': 12,
};
final _labWords = RegExp(
    r'\b(lab|labs|laboratory|laboratories|diagnostic|diagnostics|pathology|healthcare|hospital|clinic|medical|imaging)\b');
final _notLab = RegExp(r'\b(patient|name|ref\.?|referred|doctor|dr\.)\b');
// "Name:" only at the start of a row, so "Lab Name" / "Doctor Name" don't count.
final _nameLabel = RegExp(
    r"^(?:patient'?s?\s*name|name\s*of\s*(?:the\s*)?patient|pt\.?\s*name|patient|name)\s*(?:[:\-]\s*|\s{2,})",
    caseSensitive: false);
// Labels that often follow the name on the same printed row.
final _afterName = RegExp(
    r'\s(?:age|sex|gender|dob|d\.o\.b|uhid|mrn|id|ref|referred|sample|lab\s*no|reg|bill|visit|date)\b',
    caseSensitive: false);
