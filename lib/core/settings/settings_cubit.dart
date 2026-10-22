import 'dart:convert';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart' show ThemeMode;
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

class AppSettings {
  const AppSettings(
      {this.simpleMode = false,
      this.hidden = const {},
      this.themeMode = ThemeMode.system,
      this.accent = ThemeAccent.vitalog});

  /// Larger text and buttons, fewer things on screen, plain-language
  /// statuses. Meant for older family members.
  final bool simpleMode;
  final Set<HomeSection> hidden;

  /// System follows the phone's light/dark setting.
  final ThemeMode themeMode;
  final ThemeAccent accent;

  bool shows(HomeSection section) => !hidden.contains(section);

  AppSettings copyWith(
          {bool? simpleMode,
          Set<HomeSection>? hidden,
          ThemeMode? themeMode,
          ThemeAccent? accent}) =>
      AppSettings(
          simpleMode: simpleMode ?? this.simpleMode,
          hidden: hidden ?? this.hidden,
          themeMode: themeMode ?? this.themeMode,
          accent: accent ?? this.accent);

  Map<String, dynamic> toJson() => {
        'simpleMode': simpleMode,
        'hidden': [for (final s in hidden) s.name],
        'themeMode': themeMode.name,
        'accent': accent.name,
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
        // 'fammo' is the accent's name before the app became Vitalog.
        accent: ThemeAccent.values
                .where((a) =>
                    a.name ==
                    (j['accent'] == 'fammo' ? 'vitalog' : j['accent']))
                .firstOrNull ??
            ThemeAccent.vitalog,
      );
}

/// Display preferences, kept on this phone in settings.json. Not health
/// data, so not encrypted.
class SettingsCubit extends Cubit<AppSettings> {
  SettingsCubit({Future<Directory> Function()? directory})
      : _directory = directory ?? getApplicationDocumentsDirectory,
        super(const AppSettings()) {
    _load();
  }

  final Future<Directory> Function() _directory;

  Future<File> get _file async =>
      File('${(await _directory()).path}/settings.json');

  Future<void> _load() async {
    try {
      final file = await _file;
      if (await file.exists()) {
        emit(AppSettings.fromJson(jsonDecode(await file.readAsString())));
      }
    } catch (_) {
      // Unreadable or unavailable (e.g. tests): keep the defaults.
    }
  }

  void setSimpleMode(bool on) => _update(state.copyWith(simpleMode: on));

  void setThemeMode(ThemeMode mode) => _update(state.copyWith(themeMode: mode));

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
