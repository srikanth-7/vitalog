import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalog/core/theme/app_theme.dart';
import 'package:vitalog/features/family_health/domain/health_categories.dart';
import 'package:vitalog/features/family_health/presentation/widgets/health_widgets.dart';
import 'package:vitalog/l10n/app_localizations.dart';

void main() {
  testWidgets(
      'CategoryCard reads the group name before its outside-range count',
      (tester) async {
    final handle = tester.ensureSemantics();
    final kidney = healthCategories.firstWhere((c) => c.id == 'kidney');
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SizedBox(
          width: 180,
          height: 120,
          child: CategoryCard(
              category: kidney,
              testCount: 5,
              lastDate: null,
              flaggedCount: 2,
              onTap: () {}),
        ),
      ),
    ));
    final label = tester.getSemantics(find.byType(CategoryCard)).label;
    expect(
        label.indexOf('2 outside range'), greaterThan(label.indexOf('Kidney')),
        reason: label);
    handle.dispose();
  });
}
