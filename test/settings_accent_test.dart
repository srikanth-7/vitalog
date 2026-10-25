import 'package:flutter_test/flutter_test.dart';
import 'package:vitalog/core/settings/settings_cubit.dart';
import 'package:vitalog/core/theme/app_theme.dart';

void main() {
  test('completed onboarding remains complete after settings reload', () {
    final saved = const AppSettings(onboarded: true).toJson();

    expect(AppSettings.fromJson(saved).onboarded, isTrue);
    expect(AppSettings.fromJson({'onboarded': false}).onboarded, isFalse);
  });

  test('accent saved before the rename (fammo) still loads', () {
    expect(
        AppSettings.fromJson({'accent': 'fammo'}).accent, ThemeAccent.vitalog);
    expect(AppSettings.fromJson({'accent': 'vitalog'}).accent,
        ThemeAccent.vitalog);
  });
}
