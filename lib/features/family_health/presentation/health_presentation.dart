import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

import '../domain/entities/family_member.dart';
import '../domain/entities/health_category.dart';
import '../domain/entities/health_report.dart';
import '../domain/entities/lab_result.dart';

export '../domain/entities/family_member.dart';
export '../domain/entities/health_category.dart';
export '../domain/entities/health_report.dart';
export '../domain/entities/lab_result.dart';

extension FamilyMemberPresentation on FamilyMember {
  Color get color => Color(colorValue);
}

/// Relations are saved as these fixed English keys, never as the label in
/// the current language, so switching language can't lose them.
const relationKeys = [
  'You',
  'Partner',
  'Child',
  'Parent',
  'Sibling',
  'Grandparent',
  'Other'
];

/// A saved relation in the current language; anything else (older saves,
/// sample "Daughter") is shown as saved.
String relationName(AppLocalizations l10n, String relation) =>
    switch (relation) {
      'You' => l10n.relationSelf,
      'Partner' => l10n.relationPartner,
      'Child' => l10n.relationChild,
      'Parent' => l10n.relationParent,
      'Sibling' => l10n.relationSibling,
      'Grandparent' => l10n.relationGrandparent,
      'Other' => l10n.relationOther,
      _ => relation,
    };

extension HealthCategoryPresentation on HealthCategory {
  Color get color => Color(colorValue);

  /// Translated name; falls back to the stored name for custom categories.
  String label(AppLocalizations l10n) {
    final translated = l10n.categoryName(id);
    return translated == l10n.categoryName('_') ? name : translated;
  }

  IconData get icon => _categoryIcons[iconKey] ?? Icons.category_outlined;
}

const _categoryIcons = <String, IconData>{
  'bloodtype_outlined': Icons.bloodtype_outlined,
  'water_drop_outlined': Icons.water_drop_outlined,
  'filter_alt_outlined': Icons.filter_alt_outlined,
  'spa_outlined': Icons.spa_outlined,
  'monitor_heart_outlined': Icons.monitor_heart_outlined,
  'bubble_chart_outlined': Icons.bubble_chart_outlined,
  'wb_sunny_outlined': Icons.wb_sunny_outlined,
  'grain': Icons.grain,
  'opacity_outlined': Icons.opacity_outlined,
  'favorite_border': Icons.favorite_border,
  'science_outlined': Icons.science_outlined,
  'shield_outlined': Icons.shield_outlined,
  'biotech_outlined': Icons.biotech_outlined,
  'balance': Icons.balance,
  'coronavirus_outlined': Icons.coronavirus_outlined,
  'healing_outlined': Icons.healing_outlined,
};

/// Medium date in the active locale (e.g. "Sep 18, 2026" / "18 Sept 2026").
/// `Intl.defaultLocale` is kept in sync with the app locale in main.dart.
String formatDate(DateTime date) => DateFormat.yMMMd().format(date);

/// "Good morning / afternoon / evening" by the phone's clock.
String timeGreeting(AppLocalizations l10n, [DateTime? now]) {
  final hour = (now ?? DateTime.now()).hour;
  if (hour < 12) return l10n.greetingMorning;
  return hour < 17 ? l10n.greetingAfternoon : l10n.greetingEvening;
}

/// A category's soft card background: its colour washed over the surface.
/// Decoration only (status colours keep meaning status), so text on it
/// stays at full contrast.
Color categorySoft(Color category, AppColors c, {required bool dark}) =>
    Color.alphaBlend(category.withValues(alpha: dark ? .2 : .14), c.surface);

/// A category's colour for icons on a surface chip: nudged toward the text
/// colour so it reads in both themes.
Color categoryInk(Color category, AppColors c, {required bool dark}) =>
    Color.lerp(category, c.textPrimary, dark ? .4 : .2)!;

/// The first name to greet the signed-in person by, or null when the
/// account has no real name (an email isn't one).
String? greetingName(String? displayName) {
  final name = displayName?.trim() ?? '';
  if (name.isEmpty || name.contains('@')) return null;
  return name.split(RegExp(r'\s+')).first;
}

/// [usual]: judged against the app's built-in usual range because the
/// report printed none — never claim "per report" for those.
/// [plain]: Simple mode's everyday words ("Higher than range"); the test's
/// page still says which range judged it.
String statusLabel(AppLocalizations l10n, ResultStatus status,
        {bool usual = false, bool plain = false}) =>
    switch (status) {
      ResultStatus.withinRange when plain => l10n.statusPlainWithin,
      ResultStatus.high when plain => l10n.statusPlainHigh,
      ResultStatus.low when plain => l10n.statusPlainLow,
      ResultStatus.needsReview when plain => l10n.statusPlainReview,
      ResultStatus.withinRange =>
        usual ? l10n.statusWithinUsual : l10n.statusWithinRange,
      ResultStatus.high =>
        usual ? l10n.statusHighUsual : l10n.statusHighPerReport,
      ResultStatus.low => usual ? l10n.statusLowUsual : l10n.statusLowPerReport,
      ResultStatus.needsReview => l10n.statusNeedsReview,
    };

String reportStatusLabel(AppLocalizations l10n, ReportStatus status) =>
    switch (status) {
      ReportStatus.processing => l10n.reportStatusProcessing,
      ReportStatus.ready => l10n.reportStatusReady,
      ReportStatus.needsReview => l10n.reportStatusNeedsReview,
      ReportStatus.failed => l10n.reportStatusFailed,
    };

/// Foreground / background colours for a status, from the active theme.
(Color, Color) statusColors(AppColors c, ResultStatus status) =>
    switch (status) {
      ResultStatus.withinRange => (c.success, c.successSoft),
      ResultStatus.high || ResultStatus.low => (c.danger, c.dangerSoft),
      ResultStatus.needsReview => (c.warning, c.warningSoft),
    };
