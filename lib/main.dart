import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/backend/backend.dart';
import 'core/brand/vitalog_splash.dart';
import 'core/settings/settings_cubit.dart';
import 'core/theme/app_theme.dart';
import 'features/family_health/domain/repositories/family_health_repository.dart';
import 'features/family_health/domain/usecases/load_family_health.dart';
import 'features/family_health/family_health_dependencies.dart';
import 'features/family_health/presentation/bloc/health_bloc.dart';
import 'features/family_health/presentation/bloc/health_event.dart';
import 'features/family_health/presentation/bloc/health_state.dart';
import 'features/family_health/presentation/pages/dash_board_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('te');
  await Backend.init();
  runApp(const FamilyHealthApp());
}

class FamilyHealthApp extends StatelessWidget {
  const FamilyHealthApp(
      {super.key, this.themeMode, this.repository, this.initialSettings});

  /// Forces light / dark (tests, previews). Otherwise the user's choice in
  /// Display settings applies, which defaults to following the phone.
  final ThemeMode? themeMode;

  /// Overrides the real repository (used by widget tests).
  final FamilyHealthRepository? repository;

  /// Starting display settings (tests skip onboarding with this).
  final AppSettings? initialSettings;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<FamilyHealthRepository>(
      create: (_) => repository ?? createFamilyHealthRepository(),
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => SettingsCubit(initial: initialSettings)),
          BlocProvider(create: (context) {
            final repository = context.read<FamilyHealthRepository>();
            return HealthBloc(LoadFamilyHealth(repository), repository)
              ..add(LoadHealthData());
          }),
        ],
        child: BlocBuilder<SettingsCubit, AppSettings>(
          buildWhen: (a, b) =>
              a.themeMode != b.themeMode ||
              a.accent != b.accent ||
              a.language != b.language,
          builder: (context, settings) => MaterialApp(
            onGenerateTitle: (context) => context.l10n.appTitle,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(settings.accent),
            darkTheme: AppTheme.dark(settings.accent),
            themeMode: themeMode ?? settings.themeMode,
            locale: settings.language.locale,
            // Languages come from lib/l10n/app_*.arb; the device language is
            // used when supported, English otherwise.
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) {
              Intl.defaultLocale =
                  Localizations.localeOf(context).toLanguageTag();
              // Simple mode: text at least 30% larger, on top of the
              // phone's own accessibility size.
              final simple =
                  context.select((SettingsCubit s) => s.state.simpleMode);
              if (!simple) return child!;
              // Plus bold text, bigger buttons/icons and darker greys.
              final media = MediaQuery.of(context);
              return MediaQuery(
                  data: media.copyWith(
                      boldText: true,
                      // Linear, not clamped: widgets like NavigationBar clamp
                      // the scaler again, and nested min/max clamps assert.
                      textScaler: TextScaler.linear(
                          media.textScaler.scale(1).clamp(1.3, 2.0))),
                  child: Theme(
                      data: AppTheme.simple(Theme.of(context)), child: child!));
            },
            home: Builder(builder: (context) {
              final settings = context.watch<SettingsCubit>();
              return SplashGate(
                ready: settings.state.loaded &&
                    context.select((HealthBloc bloc) =>
                        bloc.state is HealthLoaded ||
                        bloc.state is HealthLoadFailure),
                // First launch: welcome pages and the sign-in offer.
                child: OnboardingGate(
                  onboarded: settings.state.onboarded,
                  onDone: settings.completeOnboarding,
                  child: const DashBoardScreen(),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
