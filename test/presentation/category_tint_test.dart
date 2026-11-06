import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalog/core/theme/app_theme.dart';
import 'package:vitalog/features/family_health/domain/health_categories.dart';
import 'package:vitalog/features/family_health/presentation/health_presentation.dart';
import 'package:vitalog/features/family_health/presentation/widgets/header_wash.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (math.max(la, lb) + .05) / (math.min(la, lb) + .05);
}

void main() {
  for (final (name, c, dark) in [
    ('light', AppColors.light, false),
    ('dark', AppColors.dark, true),
  ]) {
    test('category tints keep text readable ($name)', () {
      for (final cat in healthCategories) {
        final soft = categorySoft(cat.color, c, dark: dark);
        expect(soft, isNot(c.surface), reason: '${cat.id} is tinted');
        expect(_contrast(c.textPrimary, soft), greaterThanOrEqualTo(4.5),
            reason: '${cat.id} title');
        expect(_contrast(c.textSecondary, soft), greaterThanOrEqualTo(4.5),
            reason: '${cat.id} subtitle');
        expect(_contrast(categoryInk(cat.color, c, dark: dark), c.surface),
            greaterThanOrEqualTo(3.0),
            reason: '${cat.id} icon on its chip');
      }
    });
  }

  for (final (name, c) in [
    ('light', AppColors.light),
    ('dark', AppColors.dark)
  ]) {
    test('muted text is readable on every surface ($name)', () {
      // brandSoft is the top of the header wash, where "Last tested" sits.
      for (final bg in [c.surface, c.canvas, c.brandSoft]) {
        expect(_contrast(c.textMuted, bg), greaterThanOrEqualTo(4.5),
            reason: bg.toString());
      }
    });
  }

  for (final (name, c, dark) in [
    ('light', AppColors.light, false),
    ('dark', AppColors.dark, true),
  ]) {
    test('text on the header wash stays readable ($name)', () {
      // The deepest point of the wash, corner pool included.
      final deepest = washColor(c, dark: dark, extra: washPoolAlpha);
      expect(_contrast(c.onWash, deepest), greaterThanOrEqualTo(4.5));
      expect(_contrast(c.onWash, c.canvas), greaterThanOrEqualTo(4.5));
      expect(_contrast(c.textPrimary, deepest), greaterThanOrEqualTo(4.5));
      // Visibly green: well past the old 6 % tint in light mode.
      expect(washColor(c, dark: dark), isNot(c.brandSoft));
    });
  }
}
