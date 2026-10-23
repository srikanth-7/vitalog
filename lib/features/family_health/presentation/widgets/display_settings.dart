import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/settings/settings_cubit.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_shape.dart';

String sectionLabel(AppLocalizations l10n, HomeSection s) => switch (s) {
      HomeSection.latestReport => l10n.sectionLatestReport,
      HomeSection.overview => l10n.sectionOverview,
      HomeSection.trends => l10n.sectionTrends,
      HomeSection.categories => l10n.sectionCategories,
      HomeSection.recentResults => l10n.sectionRecentResults,
      HomeSection.rangeNote => l10n.sectionRangeNote,
    };

String languageLabel(AppLocalizations l10n, AppLanguage language) =>
    switch (language) {
      AppLanguage.system => l10n.languageSystem,
      AppLanguage.english => l10n.languageEnglish,
      AppLanguage.telugu => l10n.languageTelugu,
    };

/// Let the user choose the language used throughout the app.
Future<void> showLanguageSheet(BuildContext context) {
  final cubit = context.read<SettingsCubit>();
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: BlocBuilder<SettingsCubit, AppSettings>(
        builder: (context, settings) {
          final l10n = context.l10n;
          final languages = AppLanguage.values;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      l10n.languageTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.colors.textPrimary,
                      ),
                    ),
                  ),
                  for (final language in languages)
                    RadioListTile<AppLanguage>(
                      key: ValueKey('language-${language.name}'),
                      value: language,
                      groupValue: settings.language,
                      title: Text(languageLabel(l10n, language)),
                      onChanged: (value) {
                        if (value == null) return;
                        HapticFeedback.selectionClick();
                        cubit.setLanguage(value);
                        Navigator.of(context).pop();
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}

/// Show / hide switches for each Home section.
Future<void> showCustomizeHomeSheet(BuildContext context) {
  final cubit = context.read<SettingsCubit>();
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: BlocBuilder<SettingsCubit, AppSettings>(
        builder: (context, settings) {
          final l10n = context.l10n;
          final c = context.colors;
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.customizeHome,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: c.textPrimary)),
                            const SizedBox(height: 4),
                            Text(l10n.customizeHomeHint,
                                style: TextStyle(color: c.textMuted)),
                          ]),
                    ),
                    for (final section in HomeSection.values)
                      SwitchListTile(
                        key: ValueKey('section-${section.name}'),
                        title: Text(sectionLabel(l10n, section)),
                        subtitle: section == HomeSection.categories &&
                                settings.simpleMode
                            ? Text(l10n.hiddenInSimpleMode)
                            : null,
                        value: settings.shows(section),
                        onChanged: (on) {
                          HapticFeedback.selectionClick();
                          context.read<SettingsCubit>().setVisible(section, on);
                        },
                      ),
                  ]),
            ),
          );
        },
      ),
    ),
  );
}

/// "Display" card on the Family tab: Simple mode + Customize Home.
class DisplaySettingsCard extends StatelessWidget {
  const DisplaySettingsCard({super.key});
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final simple = context.select((SettingsCubit s) => s.state.simpleMode);
    final language = context.select((SettingsCubit s) => s.state.language);
    return Container(
      clipBehavior: Clip.antiAlias, // keep list-tile ink inside the corners
      decoration: AppShape.decoration(
          radius: AppRadius.lg,
          color: c.surface,
          side: BorderSide(color: c.border)),
      child: Material(
        type: MaterialType.transparency,
        child: Column(children: [
        SwitchListTile(
          key: const ValueKey('simple-mode'),
          secondary: Icon(Icons.text_increase, color: c.brand),
          title: Text(l10n.simpleMode,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(l10n.simpleModeHint),
          value: simple,
          onChanged: (on) {
            HapticFeedback.mediumImpact();
            context.read<SettingsCubit>().setSimpleMode(on);
          },
        ),
        Divider(height: 1, color: c.border),
        ListTile(
          key: const ValueKey('theme-settings'),
          leading: Icon(Icons.palette_outlined, color: c.brand),
          title: Text(l10n.themeTitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showThemeSheet(context),
        ),
        Divider(height: 1, color: c.border),
        ListTile(
          key: const ValueKey('language-settings'),
          leading: Icon(Icons.language_outlined, color: c.brand),
          title: Text(l10n.languageTitle),
          subtitle: Text(languageLabel(l10n, language)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showLanguageSheet(context),
        ),
        Divider(height: 1, color: c.border),
        ListTile(
          key: const ValueKey('customize-home'),
          leading: Icon(Icons.dashboard_customize_outlined, color: c.brand),
          title: Text(l10n.customizeHome),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showCustomizeHomeSheet(context),
        ),
        ]),
      ),
    );
  }
}

String accentLabel(AppLocalizations l10n, ThemeAccent a) => switch (a) {
      ThemeAccent.vitalog => l10n.accentVitalog,
      ThemeAccent.ocean => l10n.accentOcean,
      ThemeAccent.plum => l10n.accentPlum,
      ThemeAccent.ember => l10n.accentEmber,
      ThemeAccent.graphite => l10n.accentGraphite,
    };

/// Light / dark / follow the phone, plus an accent colour. Changes apply
/// live behind the sheet.
Future<void> showThemeSheet(BuildContext context) {
  final cubit = context.read<SettingsCubit>();
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child:
          BlocBuilder<SettingsCubit, AppSettings>(builder: (context, settings) {
        final l10n = context.l10n;
        final c = context.colors;
        final dark = Theme.of(context).brightness == Brightness.dark;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.themeTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700, color: c.textPrimary)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemeMode>(
                      key: const ValueKey('theme-mode'),
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                            value: ThemeMode.system,
                            icon: const Icon(Icons.brightness_auto_outlined),
                            label: Text(l10n.themeSystem)),
                        ButtonSegment(
                            value: ThemeMode.light,
                            icon: const Icon(Icons.light_mode_outlined),
                            label: Text(l10n.themeLight)),
                        ButtonSegment(
                            value: ThemeMode.dark,
                            icon: const Icon(Icons.dark_mode_outlined),
                            label: Text(l10n.themeDark)),
                      ],
                      selected: {settings.themeMode},
                      onSelectionChanged: (s) {
                        HapticFeedback.selectionClick();
                        context.read<SettingsCubit>().setThemeMode(s.first);
                      },
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(l10n.accentTitle,
                      style: TextStyle(
                          color: c.textSecondary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Wrap(spacing: 14, runSpacing: 12, children: [
                    for (final accent in ThemeAccent.values)
                      _AccentSwatch(
                        accent: accent,
                        dark: dark,
                        selected: accent == settings.accent,
                        label: accentLabel(l10n, accent),
                      ),
                  ]),
                ]),
          ),
        );
      }),
    ),
  );
}

class _AccentSwatch extends StatelessWidget {
  const _AccentSwatch(
      {required this.accent,
      required this.dark,
      required this.selected,
      required this.label});
  final ThemeAccent accent;
  final bool dark;
  final bool selected;
  final String label;

  @override
  Widget build(BuildContext context) {
    final (brand, _, hero, _) = dark ? accent.dark : accent.light;
    final c = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('accent-${accent.name}'),
        onTap: () {
          HapticFeedback.selectionClick();
          context.read<SettingsCubit>().setAccent(accent);
        },
        child: Column(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: selected ? c.textPrimary : Colors.transparent,
                    width: 2)),
            child: DecoratedBox(
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [brand, hero])),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : null,
            ),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: selected ? c.textPrimary : c.textMuted,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
        ]),
      ),
    );
  }
}
