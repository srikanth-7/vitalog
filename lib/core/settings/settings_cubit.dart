import 'dart:convert';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart' show Locale, ThemeMode;
import 'package:path_provider/path_provider.dart';

import '../theme/app_theme.dart';

/// Sections of the Home screen the user can show or hide. A hidden section
/// isn't built at all, so whatever it would load or compute is skipped too.
/// Home sections the user can hide. Order = order on screen. Saved by name,
/// so new values can be added anywhere; never rename existing ones.
enum HomeSection {
  latestReport,
  overview,
  trends,
  categories,
  recentResults,
  rangeNote
}

/// App language preference. [system] follows the device when supported.
enum AppLanguage { system, english, telugu }

extension AppLanguageLocale on AppLanguage {
  Locale? get locale => switch (this) {
        AppLanguage.system => null,
        AppLanguage.english => const Locale('en'),
        AppLanguage.telugu => const Locale('te'),
      };
}

class AppSettings {
  const AppSettings(
      {this.simpleMode = false,
      this.hidden = const {},
      this.themeMode = ThemeMode.system,
      this.language = AppLanguage.system,
      this.accent = ThemeAccent.vitalog,
      this.onboarded = false,
      this.loaded = false});

  /// Larger text and buttons, fewer things on screen, plain-language
  /// statuses. Meant for older family members.
  final bool simpleMode;
  final Set<HomeSection> hidden;

  /// System follows the phone's light/dark setting.
  final ThemeMode themeMode;
  final AppLanguage language;
  final ThemeAccent accent;

  /// The welcome screens (and first sign-in offer) have been seen.
  final bool onboarded;

  /// settings.json has been read (or found missing). Not saved.
  final bool loaded;

  bool shows(HomeSection section) => !hidden.contains(section);

  AppSettings copyWith(
          {bool? simpleMode,
          Set<HomeSection>? hidden,
          ThemeMode? themeMode,
          AppLanguage? language,
          ThemeAccent? accent,
          bool? onboarded,
          bool? loaded}) =>
      AppSettings(
          simpleMode: simpleMode ?? this.simpleMode,
          hidden: hidden ?? this.hidden,
          themeMode: themeMode ?? this.themeMode,
          language: language ?? this.language,
          accent: accent ?? this.accent,
          onboarded: onboarded ?? this.onboarded,
          loaded: loaded ?? this.loaded);

  Map<String, dynamic> toJson() => {
        'simpleMode': simpleMode,
        'hidden': [for (final s in hidden) s.name],
        'themeMode': themeMode.name,
        'language': language.name,
        'accent': accent.name,
        'onboarded': onboarded,
      };

  static AppSettings fromJson(Map<String, dynamic> j) => AppSettings(
        simpleMode: j['simpleMode'] == true,
        hidden: {
          for (final name in (j['hidden'] as List? ?? const []))
            ...HomeSection.values.where((s) => s.name == name)
        },
        themeMode: ThemeMode.values
                .where((m) => m.name == j['themeMode'])
                .firstOrNull ??
            ThemeMode.system,
        language: AppLanguage.values
                .where((language) => language.name == j['language'])
                .firstOrNull ??
            AppLanguage.system,
        // 'fammo' is the accent's name before the app became Vitalog.
        accent: ThemeAccent.values
                .where((a) =>
                    a.name ==
                    (j['accent'] == 'fammo' ? 'vitalog' : j['accent']))
                .firstOrNull ??
            ThemeAccent.vitalog,
        onboarded: j['onboarded'] == true,
      );
}

/// Display preferences, kept on this phone in settings.json. Not health
/// data, so not encrypted.
class SettingsCubit extends Cubit<AppSettings> {
  SettingsCubit({Future<Directory> Function()? directory, AppSettings? initial})
      : _directory = directory ?? getApplicationDocumentsDirectory,
        super(initial ?? const AppSettings()) {
    _load();
  }

  final Future<Directory> Function() _directory;

  Future<File> get _file async =>
      File('${(await _directory()).path}/settings.json');

  Future<void> _load() async {
    try {
      final file = await _file;
      if (await file.exists()) {
        emit(AppSettings.fromJson(jsonDecode(await file.readAsString()))
            .copyWith(loaded: true));
      }
    } catch (_) {
      // Unreadable or unavailable (e.g. tests): keep the defaults.
    }
    if (!state.loaded) emit(state.copyWith(loaded: true));
  }

  void completeOnboarding() => _update(state.copyWith(onboarded: true));

  void setSimpleMode(bool on) => _update(state.copyWith(simpleMode: on));

  void setThemeMode(ThemeMode mode) => _update(state.copyWith(themeMode: mode));

  void setLanguage(AppLanguage language) =>
      _update(state.copyWith(language: language));

  void setAccent(ThemeAccent accent) => _update(state.copyWith(accent: accent));

  void setVisible(HomeSection section, bool visible) => _update(state.copyWith(
      hidden: visible
          ? (state.hidden.toSet()..remove(section))
          : {...state.hidden, section}));

  Future<void> _update(AppSettings next) async {
    emit(next);
    try {
      await (await _file).writeAsString(jsonEncode(next.toJson()));
    } catch (_) {
      // Preference still applies for this session.
    }
  }
}
