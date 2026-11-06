import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalog/core/theme/app_theme.dart';
import 'package:vitalog/features/family_health/presentation/widgets/vitalog_nav_bar.dart';

void main() {
  test('tabs fill the bar, the selected one widest', () {
    const size = Size(360, 52);
    final rects = [
      for (var i = 0; i < 4; i++) VitalogNavBar.tabRect(size, 4, 1, i)
    ];
    expect(rects.first.left, 0);
    expect(rects.last.right, closeTo(360, .001));
    for (var i = 1; i < 4; i++) {
      expect(rects[i].left, closeTo(rects[i - 1].right, .001));
    }
    expect(rects[1].width, greaterThan(rects[0].width * 2));
  });

  testWidgets('only the selected tab shows its label', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        bottomNavigationBar: VitalogNavBar(
          selectedIndex: 2,
          onSelected: (_) {},
          items: const [
            VitalogNavItem(TabGlyph.home, 'Home'),
            VitalogNavItem(TabGlyph.categories, 'Categories'),
            VitalogNavItem(TabGlyph.reports, 'Reports'),
            VitalogNavItem(TabGlyph.family, 'Family'),
          ],
        ),
      ),
    ));
    expect(find.text('Reports'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
    // Icon-only tabs still have their name for screen readers.
    expect(find.bySemanticsLabel('Home'), findsOneWidget);
  });
}
