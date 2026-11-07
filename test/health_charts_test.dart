import 'package:flutter_test/flutter_test.dart';
import 'package:vitalog/features/family_health/domain/entities/lab_result.dart';
import 'package:vitalog/features/family_health/presentation/widgets/health_charts.dart';

LabResult r(String name, String value, ResultStatus status, DateTime date,
        {String unit = 'mg/dL', String range = '70 - 99'}) =>
    LabResult(
        id: '$name$date',
        profileId: 'p',
        name: name,
        categoryIds: const ['glucose'],
        value: value,
        unit: unit,
        referenceRange: range,
        status: status,
        reportDate: date,
        lab: 'Lab');

void main() {
  final jan = DateTime(2026, 1, 1),
      mar = DateTime(2026, 3, 1),
      sep = DateTime(2026, 9, 1);

  test('tally counts each test once, using its latest value', () {
    // Newest first, as FamilyHealthSnapshot.resultsFor returns them.
    final results = [
      r('Glucose', '104', ResultStatus.high, sep),
      r('TSH', '2.1', ResultStatus.withinRange, sep),
      r('Vitamin D', 'Nil', ResultStatus.needsReview, sep),
      r('Glucose', '96', ResultStatus.withinRange, mar),
    ];
    final tally = StatusTally.of(latestPerTest(results));
    expect(
        (tally.good, tally.review, tally.outside, tally.total), (1, 1, 1, 3));
  });

  test('trends need two numeric results in the same unit, oldest first', () {
    final trends = trendsFor([
      r('Glucose', '104', ResultStatus.high, sep),
      r('Glucose', '96', ResultStatus.withinRange, mar),
      r('Glucose', '91', ResultStatus.withinRange, jan),
      r('TSH', '2.1', ResultStatus.withinRange, sep), // only one point
      r('LDL', '120', ResultStatus.high, sep, unit: 'mg/dL'),
      r('LDL', '3.1', ResultStatus.high, mar, unit: 'mmol/L'), // other unit
    ]);
    expect(trends, hasLength(1));
    final glucose = trends.single;
    expect(glucose.points.map((p) => p.$2), [91, 96, 104]);
    expect(glucose.change, 8);
    expect(glucose.previousDate, mar);
    expect((glucose.low, glucose.high), (70, 99));
  });

  test('outside-range trends come first', () {
    final trends = trendsFor([
      r('A', '5', ResultStatus.withinRange, sep),
      r('A', '4', ResultStatus.withinRange, mar),
      r('B', '9', ResultStatus.high, sep),
      r('B', '8', ResultStatus.withinRange, mar),
    ]);
    expect(trends.map((t) => t.latest.name), ['B', 'A']);
  });

  test('printed ranges parse in all common forms', () {
    expect(parseRange('12.0–15.5 g/dL'), (12.0, 15.5));
    expect(parseRange('< 100'), (null, 100.0));
    expect(parseRange('> 40 mg/dL'), (40.0, null));
    expect(parseRange(''), (null, null));
  });

  test('rangePosition places the value inside the printed range', () {
    final d = DateTime(2026, 1, 1);
    expect(
        rangePosition(r('LDL', '150', ResultStatus.high, d, range: '100-200')),
        .5);
    expect(
        rangePosition(r('LDL', '250', ResultStatus.high, d, range: '100-200')),
        1.0); // clamped
    expect(rangePosition(r('LDL', '50', ResultStatus.low, d, range: '100-200')),
        0.0);
  });

  test('rangePosition hides without two bounds or a number', () {
    final d = DateTime(2026, 1, 1);
    expect(rangePosition(r('TG', '210', ResultStatus.high, d, range: '< 150')),
        isNull);
    expect(
        rangePosition(r('TG', '210', ResultStatus.high, d, range: '')), isNull);
    expect(rangePosition(r('HIV', 'Negative', ResultStatus.withinRange, d)),
        isNull);
  });

  test('withinPeriod counts back from the latest reading', () {
    final oldestFirst = [
      r('LDL', '160', ResultStatus.high, DateTime(2024, 6, 1)),
      r('LDL', '140', ResultStatus.high, DateTime(2025, 11, 1)),
      r('LDL', '120', ResultStatus.withinRange, DateTime(2026, 3, 1)),
      r('LDL', '110', ResultStatus.withinRange, DateTime(2026, 9, 1)),
    ];
    List<String> values(HistoryPeriod p) =>
        withinPeriod(oldestFirst, p).map((x) => x.value).toList();
    expect(values(HistoryPeriod.all), ['160', '140', '120', '110']);
    expect(values(HistoryPeriod.year), ['140', '120', '110']);
    expect(values(HistoryPeriod.sixMonths), ['120', '110']);
    expect(withinPeriod(const [], HistoryPeriod.year), isEmpty);
  });

  test('trend streak counts same-way moves ending at the latest value', () {
    expect(trendStreak([1, 2, 3, 4]), 3); // up, up, up → "Up 3 times"
    expect(trendStreak([9, 5, 4, 3, 2]), -4);
    expect(trendStreak([1, 2, 1, 2]), 1); // up/down/up: no run
    expect(trendStreak([1, 2, 3, 3]), 0); // last move flat
    expect(trendStreak([1, 2, 3]), 2); // fewer than 3 moves: no note
    expect(trendStreak([5]), 0);
  });

  test('trends keep units apart, so a streak never mixes them', () {
    LabResult r(String id, int month, String value, String unit) => LabResult(
        id: id,
        profileId: 'p',
        name: 'Glucose',
        categoryIds: const ['glucose'],
        value: value,
        unit: unit,
        referenceRange: '70-100',
        status: ResultStatus.withinRange,
        reportDate: DateTime(2026, month),
        lab: 'Lab');
    final trends = trendsFor([
      r('a', 1, '80', 'mg/dL'),
      r('b', 2, '90', 'mg/dL'),
      r('c', 3, '5.5', 'mmol/L'),
      r('d', 4, '5.6', 'mmol/L'),
    ]);
    expect(trends.map((t) => t.streak), everyElement(1));
  });
}
