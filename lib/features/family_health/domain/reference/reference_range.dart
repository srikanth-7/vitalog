import '../entities/lab_result.dart';

enum Sex { male, female }

/// Where a range comes from, so the UI can say "usual range (WHO)".
enum RangeBasis { who, india, ada, atp3, kdigo, reference }

/// A built-in "usual" range for one test, for adults unless stated.
/// Immutable and compiled into the app (see data/reference/reference_table.dart),
/// so it can only change through a signed app update.
class ReferenceRange {
  const ReferenceRange({
    required this.test,
    required this.unit,
    this.low,
    this.high,
    this.lowFemale,
    this.highFemale,
    this.highAge60,
    this.childLow,
    this.adultOnly = true,
    required this.basis,
    required this.source,
    this.note,
  });

  /// Canonical test name, as in `labTestCatalog`.
  final String test;
  final String unit;
  final double? low;
  final double? high;

  /// Female limits where they differ (otherwise [low]/[high] apply to all).
  final double? lowFemale;
  final double? highFemale;

  /// Upper limit from age 60 (e.g. TSH rises with age in Indian adults).
  final double? highAge60;

  /// Lower limit for children 5–11 (WHO anaemia cut-off).
  final double? childLow;

  /// Adult intervals aren't applied to children (under 18).
  final bool adultOnly;
  final RangeBasis basis;
  final String source;
  final String? note;

  bool get sexSpecific => lowFemale != null || highFemale != null;

  /// Limits for a person, or null when the range can't be applied: a
  /// sex-specific range with the sex unknown (a combined range would call a
  /// man's low haemoglobin "normal"), or an adult-only range for a child.
  (double?, double?)? limitsFor({Sex? sex, int? age}) {
    if (sexSpecific && sex == null) return null;
    final child = age != null && age < 18;
    if (child) {
      if (childLow != null && age >= 5 && age <= 11) return (childLow, null);
      if (adultOnly) return null;
    }
    double? lo = low, hi = high;
    if (sex == Sex.female) {
      lo = lowFemale ?? low;
      hi = highFemale ?? high;
    }
    if (highAge60 != null && age != null && age >= 60) hi = highAge60;
    return (lo, hi);
  }

  String describe({Sex? sex, int? age}) {
    final limits = limitsFor(sex: sex, age: age);
    if (limits == null) return '';
    final (lo, hi) = limits;
    final body = switch ((lo, hi)) {
      (null, null) => '',
      (final l?, null) => '≥ ${_fmt(l)}',
      (null, final h?) => '< ${_fmt(h)}',
      (final l?, final h?) => '${_fmt(l)}–${_fmt(h)}',
    };
    return body.isEmpty ? '' : '$body $unit';
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}

/// Multipliers that convert a reported unit into a range's unit, per test
/// family. Keys are lower-cased, with µ normalised to u.
class UnitConversion {
  const UnitConversion(this.from, this.to, this.factor, {this.tests});
  final String from;
  final String to;
  final double factor;

  /// Limits the conversion to these tests (molar factors differ per analyte).
  final Set<String>? tests;
}

String normUnit(String u) => u
    .toLowerCase()
    .replaceAll('µ', 'u')
    .replaceAll('μ', 'u')
    .replaceAll(' ', '')
    .replaceAll('mcg', 'ug');

/// Converts [value] in [from] to [to] for [test], or null if unknown.
double? convertUnit(double value, String from, String to, String test,
    List<UnitConversion> table) {
  final f = normUnit(from), t = normUnit(to);
  if (f.isEmpty) return null; // unit not printed: don't guess
  if (f == t) return value;
  for (final c in table) {
    if (c.tests != null && !c.tests!.contains(test)) continue;
    if (normUnit(c.from) == f && normUnit(c.to) == t) return value * c.factor;
    if (normUnit(c.from) == t && normUnit(c.to) == f) return value / c.factor;
  }
  return null;
}

/// How a value compares with the built-in usual range.
class UsualRangeCheck {
  const UsualRangeCheck(this.range, this.status, this.text);
  final ReferenceRange range;
  final ResultStatus status;

  /// e.g. "30–100 ng/mL" for this person.
  final String text;
}

/// Judges [result] against the built-in table. Returns null when there's no
/// usual range for this test / person, or the value or unit can't be compared.
UsualRangeCheck? checkUsualRange(
  LabResult result, {
  required Map<String, ReferenceRange> table,
  required List<UnitConversion> conversions,
  Sex? sex,
  int? age,
}) {
  final range = table[result.name];
  if (range == null) return null;
  final limits = range.limitsFor(sex: sex, age: age);
  if (limits == null) return null;
  final raw = double.tryParse(result.value.replaceAll(',', ''));
  if (raw == null) return null;
  final value =
      convertUnit(raw, result.unit, range.unit, range.test, conversions);
  if (value == null) return null;
  final (lo, hi) = limits;
  final status = lo != null && value < lo
      ? ResultStatus.low
      : (hi != null && value > hi
          ? ResultStatus.high
          : ResultStatus.withinRange);
  return UsualRangeCheck(range, status, range.describe(sex: sex, age: age));
}
