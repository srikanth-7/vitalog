import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import 'core/layout/readable_width.dart';
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
import 'features/family_health/presentation/pages/claim_invite_screen.dart';
import 'features/family_health/presentation/pages/dash_board_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/reminders/reminder_scheduler.dart';
import 'features/reminders/reminders_cubit.dart';
import 'features/reminders/reminders_screen.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('te');
  await initializeDateFormatting('hi');
  await Backend.init();
  runApp(FamilyHealthApp(inviteLinks: AppLinks().uriLinkStream));
}

class FamilyHealthApp extends StatelessWidget {
  const FamilyHealthApp(
      {super.key,
      this.themeMode,
      this.repository,
      this.initialSettings,
      this.inviteLinks});

  /// Forces light / dark (tests, previews). Otherwise the user's choice in
  /// Display settings applies, which defaults to following the phone.
  final ThemeMode? themeMode;

  /// Overrides the real repository (used by widget tests).
  final FamilyHealthRepository? repository;

  /// Starting display settings (tests skip onboarding with this).
  final AppSettings? initialSettings;

  /// Links that open the app (family invites); none in tests.
  final Stream<Uri>? inviteLinks;

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
          BlocProvider(create: (context) {
            final repository = context.read<FamilyHealthRepository>();
            return RemindersCubit(
                load: repository.loadReminders,
                save: repository.saveReminders,
                scheduler: LocalReminderScheduler())
              ..start();
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
              final media = evenSideInsets(MediaQuery.of(context));
              if (!simple) return MediaQuery(data: media, child: child!);
              // Plus bold text, bigger buttons/icons and darker greys.
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
              return InviteLinkListener(
                  links: inviteLinks ?? const Stream.empty(),
                  child: SplashGate(
                    ready: settings.state.loaded &&
                        context.select((HealthBloc bloc) =>
                            bloc.state is HealthLoaded ||
                            bloc.state is HealthLoadFailure),
                    // First launch: welcome pages and the sign-in offer.
                    child: OnboardingGate(
                      onboarded: settings.state.onboarded,
                      onDone: settings.completeOnboarding,
                      // Reminders follow the family: a removed member's go, and
                      // names on the notifications stay current.
                      child: const ReminderSync(child: DashBoardScreen()),
                    ),
                  ));
            }),
          ),
        ),
      ),
    );
  }
}
