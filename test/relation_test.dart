import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalog/features/family_health/presentation/health_presentation.dart';
import 'package:vitalog/l10n/app_localizations.dart';

void main() {
  test('relations are saved as keys, so a language switch keeps them', () {
    final te = lookupAppLocalizations(const Locale('te'));
    final en = lookupAppLocalizations(const Locale('en'));
    for (final key in relationKeys) {
      expect(relationName(te, key), isNot(key)); // shown in Telugu
      expect(relationName(en, key), key); // keys are the English labels
    }
    expect(relationName(te, 'Daughter'), 'Daughter'); // unknown: as saved
  });

  test('an undated report is the one whose date is its upload time', () {
    final t = DateTime(2026, 11, 3, 9, 41, 12, 7);
    HealthReport r(DateTime date) => HealthReport(
        id: 'r',
        profileId: 'p',
        fileName: 'a.pdf',
        lab: '',
        reportDate: date,
        uploadDate: t,
        status: ReportStatus.needsReview,
        resultCount: 1);
    expect(r(t).undated, isTrue);
    expect(r(DateTime(2026, 11, 3)).undated, isFalse);
  });
}
