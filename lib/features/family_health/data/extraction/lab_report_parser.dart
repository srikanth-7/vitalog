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
  });
  final List<ParsedTest> tests;
  final DateTime? reportDate;
  final DateTime? collectionDate;
  final String? lab;
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
    for (final line in cleaned) {
      final lower = line.toLowerCase();
      if (!_hasDigit.hasMatch(line) && !_qualitative.hasMatch(lower)) {
        section = _sectionOf(lower) ?? section;
        continue;
      }
      final test = _parseRow(line, lower, section);
      if (test != null && seen.add(test.name.toLowerCase())) tests.add(test);
    }
    return ParsedReport(
      tests: tests,
      reportDate: _labelledDate(cleaned, _reportLabels) ?? _latestDate(cleaned),
      collectionDate: _labelledDate(cleaned, _collectionLabels),
      lab: _labName(cleaned),
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

    final range = _parseRange(rest);
    final withoutRange =
        range == null ? rest : rest.replaceRange(range.start, range.end, ' ');
    var unit = _unit.firstMatch(withoutRange)?.group(1) ?? '';
    if (unit.isEmpty && match != null && _garbled.hasMatch(withoutRange)) {
      unit = typicalUnits[name] ?? '';
    }
    final valueMatch = _value.firstMatch(withoutRange);
    final flag = _flag.firstMatch(withoutRange)?.group(1);

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
    return _status(value.trim(), _parseRange(referenceRange), null);
  }

  ResultStatus _status(String value, _Range? range, String? flag) {
    if (flag != null) {
      return flag.toUpperCase().startsWith('H')
          ? ResultStatus.high
          : ResultStatus.low;
    }
    final number = double.tryParse(value.replaceAll(RegExp('[<>]'), ''));
    if (range == null || number == null) return ResultStatus.needsReview;
    if (range.low != null && number < range.low!) return ResultStatus.low;
    if (range.high != null && number > range.high!) return ResultStatus.high;
    return ResultStatus.withinRange;
  }

  _Range? _parseRange(String text) {
    final between = _between.firstMatch(text);
    if (between != null) {
      return _Range(between.start, between.end, between.group(0)!.trim(),
          double.parse(between.group(1)!), double.parse(between.group(2)!));
    }
    final below = _below.firstMatch(text);
    if (below != null) {
      return _Range(below.start, below.end, below.group(0)!.trim(), null,
          double.parse(below.group(1)!));
    }
    final above = _above.firstMatch(text);
    if (above != null) {
      return _Range(above.start, above.end, above.group(0)!.trim(),
          double.parse(above.group(1)!), null);
    }
    return null;
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

const _num = r'\d+(?:\.\d+)?';
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
final _unit = RegExp(
    r'(?<![\w/])(x?10\^?[36]\s*/\s*[uµ]l|10\^?[36]/cumm|lakhs?/cumm|million/cumm|mill/cumm|cells/cumm|thou/mm3|/cumm|/hpf|/[uµ]l|mm/1st hr|mm/hr|ml/min/1\.73\s?m2|mmol/mol|[uµ]iu/ml|miu/l|miu/ml|iu/ml|iu/l|u/ml|u/l|ng/ml|ng/dl|pg/ml|[uµ]g/dl|mcg/dl|mg/dl|mg/l|g/dl|g/l|mmol/l|[uµ]mol/l|nmol/l|pmol/l|meq/l|fl|pg|%)(?![\w/])',
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
