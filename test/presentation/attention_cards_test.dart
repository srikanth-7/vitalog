import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalog/core/theme/app_theme.dart';
import 'package:vitalog/features/family_health/domain/entities/lab_result.dart';
import 'package:vitalog/features/family_health/presentation/widgets/health_charts.dart';
import 'package:vitalog/l10n/app_localizations.dart';

LabResult _result(String value, ResultStatus status, String range) => LabResult(
    id: 'r1',
    profileId: 'p',
    name: 'Hemoglobin',
    categoryIds: const ['blood'],
    value: value,
    unit: 'g/dL',
    referenceRange: range,
    status: status,
    reportDate: DateTime(2026, 9, 1),
    lab: 'Lab');

Widget _app(Widget child, {double textScale = 1}) => MaterialApp(
    theme: AppTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
        builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: Scaffold(body: ListView(children: [child])))));

void main() {
  testWidgets('a screen reader can open an attention card', (tester) async {
    final handle = tester.ensureSemantics();
    var opened = false;
    await tester.pumpWidget(_app(AttentionCards(
        results: [_result('10.2', ResultStatus.low, '12-15.5')],
        onTap: (_) => opened = true)));
    await tester.pumpAndSettle();
    final node =
        tester.getSemantics(find.bySemanticsLabel(RegExp('Hemoglobin')));
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    tester.semantics.tap(find.semantics.byLabel(RegExp('Hemoglobin')));
    expect(opened, isTrue);
    handle.dispose();
  });

  testWidgets('attention cards fit larger system text', (tester) async {
    await tester.pumpWidget(_app(
        AttentionCards(
            results: [_result('10.2', ResultStatus.low, '12-15.5')],
            onTap: (_) {}),
        textScale: 1.5));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('no gauge when the printed flag disagrees with the range',
      (tester) async {
    // Flagged High by the lab, yet inside the parsed range (e.g. a
    // sex-specific range read as one): the marker would contradict the pill.
    await tester.pumpWidget(_app(AttentionCards(
        results: [_result('14', ResultStatus.high, '12-15.5')],
        onTap: (_) {})));
    await tester.pumpAndSettle();
    expect(find.byType(RangeGauge), findsNothing);
  });
}
