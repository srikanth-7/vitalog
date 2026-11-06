import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalog/core/theme/app_theme.dart';
import 'package:vitalog/features/family_health/presentation/widgets/empty_art.dart';

void main() {
  testWidgets('a hidden tab plays its picture when it comes on view',
      (tester) async {
    Widget app(bool onView) => MaterialApp(
        theme: AppTheme.light(),
        home: TickerMode(
            enabled: onView, child: const EmptyArt(scene: EmptyScene.report)));
    await tester.pumpWidget(app(false));
    await tester.pump(const Duration(seconds: 2)); // time passes unseen
    await tester.pumpWidget(app(true));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.hasRunningAnimations, isTrue); // still assembling
    await tester.pump(const Duration(seconds: 3));
    expect(tester.hasRunningAnimations, isTrue); // idling, as on onboarding
    await tester.pump(const Duration(seconds: 25));
    expect(tester.hasRunningAnimations, isFalse); // rests on a still screen
  });
}
