import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'app_shape.dart';

/// Semantic colour tokens. Widgets read these instead of hard-coded hex
/// values, so a new theme is just another [AppColors] instance.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.canvas,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textDisabled,
    required this.brand,
    required this.brandSoft,
    required this.hero,
    required this.onHero,
    required this.onHeroMuted,
    required this.success,
    required this.successSoft,
    required this.danger,
    required this.dangerSoft,
    required this.warning,
    required this.warningSoft,
    required this.onAvatar,
    required this.chartGood,
    required this.chartReview,
    required this.chartOut,
  });

  final Color canvas;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textDisabled;
  final Color brand;
  final Color brandSoft;
  final Color hero;
  final Color onHero;
  final Color onHeroMuted;
  final Color success;
  final Color successSoft;
  final Color danger;
  final Color dangerSoft;
  final Color warning;
  final Color warningSoft;
  final Color onAvatar;

  /// Status colours for charts (within range / needs review / outside range).
  /// Brighter than the text-grade success/warning/danger so adjacent segments
  /// stay distinct, incl. for colour-blind readers (dataviz validator:
  /// CVD ΔE ≥ 10, normal ΔE ≥ 16 in both modes). Always paired with an icon +
  /// label, never colour alone.
  final Color chartGood;
  final Color chartReview;
  final Color chartOut;

  static const light = AppColors(
    canvas: Color(0xFFF5F7F5),
    surface: Colors.white,
    border: Color(0xFFE5EAE6),
    textPrimary: Color(0xFF18231F),
    textSecondary: Color(0xFF53645C),
    textMuted: Color(0xFF718078),
    textDisabled: Color(0xFFBBC5BE),
    brand: Color(0xFF247A68),
    brandSoft: Color(0xFFE6F1EC),
    hero: Color(0xFF173D35),
    onHero: Color(0xFFFFFFFF),
    onHeroMuted: Color(0xFFB8D5C9),
    success: Color(0xFF26775F),
    successSoft: Color(0xFFE6F3EC),
    danger: Color(0xFFA64E41),
    dangerSoft: Color(0xFFFFECE7),
    warning: Color(0xFF8B6B2E),
    warningSoft: Color(0xFFFFF4DB),
    onAvatar: Color(0xFF263B33),
    chartGood: Color(0xFF1F8A68),
    chartReview: Color(0xFFE8A317),
    chartOut: Color(0xFFC9423A),
  );

  static const dark = AppColors(
    canvas: Color(0xFF0F1513),
    surface: Color(0xFF18201D),
    border: Color(0xFF2A3430),
    textPrimary: Color(0xFFE8EEEA),
    textSecondary: Color(0xFFB4C2BB),
    textMuted: Color(0xFF8C9A93),
    textDisabled: Color(0xFF4D5A54),
    brand: Color(0xFF5CC2A8),
    brandSoft: Color(0xFF1C2E28),
    hero: Color(0xFF1D4A40),
    onHero: Color(0xFFFFFFFF),
    onHeroMuted: Color(0xFFA9CFC1),
    success: Color(0xFF6FCBA9),
    successSoft: Color(0xFF173029),
    danger: Color(0xFFF0927F),
    dangerSoft: Color(0xFF3A211C),
    warning: Color(0xFFE5C07A),
    warningSoft: Color(0xFF372D17),
    onAvatar: Color(0xFF263B33),
    chartGood: Color(0xFF3DAA84),
    chartReview: Color(0xFFD9A030),
    chartOut: Color(0xFFE0604F),
  );

  @override
  AppColors copyWith() => this;

  /// Simple mode: secondary text one step darker, so nothing is faint.
  AppColors legible() => AppColors(
        canvas: canvas,
        surface: surface,
        border: border,
        textPrimary: textPrimary,
        textSecondary: textPrimary,
        textMuted: textSecondary,
        textDisabled: textMuted,
        brand: brand,
        brandSoft: brandSoft,
        hero: hero,
        onHero: onHero,
        onHeroMuted: onHero,
        success: success,
        successSoft: successSoft,
        danger: danger,
        dangerSoft: dangerSoft,
        warning: warning,
        warningSoft: warningSoft,
        onAvatar: onAvatar,
        chartGood: chartGood,
        chartReview: chartReview,
        chartOut: chartOut,
      );

  AppColors withAccent((Color, Color, Color, Color) accent) {
    final (brand, brandSoft, hero, onHeroMuted) = accent;
    return AppColors(
      canvas: canvas,
      surface: surface,
      border: border,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      textMuted: textMuted,
      textDisabled: textDisabled,
      brand: brand,
      brandSoft: brandSoft,
      hero: hero,
      onHero: onHero,
      onHeroMuted: onHeroMuted,
      success: success,
      successSoft: successSoft,
      danger: danger,
      dangerSoft: dangerSoft,
      warning: warning,
      warningSoft: warningSoft,
      onAvatar: onAvatar,
      chartGood: chartGood,
      chartReview: chartReview,
      chartOut: chartOut,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      canvas: l(canvas, other.canvas),
      surface: l(surface, other.surface),
      border: l(border, other.border),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textMuted: l(textMuted, other.textMuted),
      textDisabled: l(textDisabled, other.textDisabled),
      brand: l(brand, other.brand),
      brandSoft: l(brandSoft, other.brandSoft),
      hero: l(hero, other.hero),
      onHero: l(onHero, other.onHero),
      onHeroMuted: l(onHeroMuted, other.onHeroMuted),
      success: l(success, other.success),
      successSoft: l(successSoft, other.successSoft),
      danger: l(danger, other.danger),
      dangerSoft: l(dangerSoft, other.dangerSoft),
      warning: l(warning, other.warning),
      warningSoft: l(warningSoft, other.warningSoft),
      onAvatar: l(onAvatar, other.onAvatar),
      chartGood: l(chartGood, other.chartGood),
      chartReview: l(chartReview, other.chartReview),
      chartOut: l(chartOut, other.chartOut),
    );
  }
}

/// Accent presets the user can pick. Each recolours the brand tokens (buttons,
/// links, hero cards) for both themes; neutrals and status colours stay, so
/// contrast and "high / low" meaning never change.
enum ThemeAccent {
  vitalog(light: (
    Color(0xFF247A68),
    Color(0xFFE6F1EC),
    Color(0xFF173D35),
    Color(0xFFB8D5C9)
  ), dark: (
    Color(0xFF5CC2A8),
    Color(0xFF1C2E28),
    Color(0xFF1D4A40),
    Color(0xFFA9CFC1)
  )),
  ocean(light: (
    Color(0xFF2563A8),
    Color(0xFFE5EEF8),
    Color(0xFF16324F),
    Color(0xFFB5CBE3)
  ), dark: (
    Color(0xFF6FA8E8),
    Color(0xFF1A2633),
    Color(0xFF1E3D5E),
    Color(0xFFA9C4E2)
  )),
  plum(light: (
    Color(0xFF7A4A8C),
    Color(0xFFF2EAF5),
    Color(0xFF3A2245),
    Color(0xFFD7C2E0)
  ), dark: (
    Color(0xFFC49AD6),
    Color(0xFF2A2030),
    Color(0xFF4A2E57),
    Color(0xFFD5BEE0)
  )),
  ember(light: (
    Color(0xFFB2562F),
    Color(0xFFFBEDE6),
    Color(0xFF4A2414),
    Color(0xFFEAC6B5)
  ), dark: (
    Color(0xFFF0A07C),
    Color(0xFF33221A),
    Color(0xFF5A2E1B),
    Color(0xFFEBC3AF)
  )),
  graphite(light: (
    Color(0xFF3F4A54),
    Color(0xFFECEFF2),
    Color(0xFF1F262C),
    Color(0xFFC2CBD3)
  ), dark: (
    Color(0xFFB7C3CE),
    Color(0xFF22282D),
    Color(0xFF2C343B),
    Color(0xFFC0CAD3)
  ));

  const ThemeAccent({required this.light, required this.dark});

  /// brand, brandSoft, hero, onHeroMuted.
  final (Color, Color, Color, Color) light;
  final (Color, Color, Color, Color) dark;
}

class AppTheme {
  /// Simple mode on top of [t]: taller buttons, bigger icons, darker
  /// secondary text. Local `styleFrom` sizes still win where a screen sets one.
  static ThemeData simple(ThemeData t) {
    ButtonStyle big(ButtonStyle? s) => (s ?? const ButtonStyle()).copyWith(
        minimumSize: const WidgetStatePropertyAll(Size(64, 56)),
        iconSize: const WidgetStatePropertyAll(24));
    return t.copyWith(
      filledButtonTheme:
          FilledButtonThemeData(style: big(t.filledButtonTheme.style)),
      outlinedButtonTheme:
          OutlinedButtonThemeData(style: big(t.outlinedButtonTheme.style)),
      textButtonTheme: TextButtonThemeData(style: big(t.textButtonTheme.style)),
      iconTheme: t.iconTheme.copyWith(size: 28),
      extensions: [
        ...t.extensions.values.where((e) => e is! AppColors),
        t.extension<AppColors>()!.legible(),
      ],
    );
  }

  static ThemeData light([ThemeAccent accent = ThemeAccent.vitalog]) =>
      _build(AppColors.light.withAccent(accent.light), Brightness.light);
  static ThemeData dark([ThemeAccent accent = ThemeAccent.vitalog]) =>
      _build(AppColors.dark.withAccent(accent.dark), Brightness.dark);

  static ThemeData _build(AppColors c, Brightness brightness) => ThemeData(
        useMaterial3: true,
        brightness: brightness,
        scaffoldBackgroundColor: c.canvas,
        colorScheme: ColorScheme.fromSeed(
          seedColor: c.brand,
          brightness: brightness,
          primary: c.brand,
          surface: c.surface,
        ),
        extensions: [c],
        appBarTheme: AppBarTheme(
          backgroundColor: c.canvas,
          foregroundColor: c.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          // Material 3 sets titles at regular weight, which reads faint next
          // to the bold headings in the page body.
          titleTextStyle: TextStyle(
              color: c.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -.2),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: c.surface,
          indicatorColor: c.brandSoft,
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
        cardTheme: CardThemeData(
          color: c.surface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: AppShape.of(AppRadius.lg),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: c.brand,
            foregroundColor: brightness == Brightness.light
                ? Colors.white
                : const Color(0xFF0F1513),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            shape: AppShape.of(AppRadius.md),
          ),
        ),
        // Continuous corners everywhere, from one scale (app_shape.dart).
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: c.border),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            shape: AppShape.of(AppRadius.md),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(shape: AppShape.of(AppRadius.sm)),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(shape: AppShape.of(AppRadius.sm)),
        ),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: c.surface,
          showDragHandle: true,
          shape: const RoundedSuperellipseBorder(
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(AppRadius.sheet))),
        ),
        dialogTheme: DialogThemeData(
            backgroundColor: c.surface, shape: AppShape.of(AppRadius.xl)),
        snackBarTheme: SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            shape: AppShape.of(AppRadius.md)),
        popupMenuTheme: PopupMenuThemeData(shape: AppShape.of(AppRadius.md)),
        chipTheme: ChipThemeData(shape: AppShape.of(AppRadius.xs)),
        inputDecorationTheme: InputDecorationTheme(
          // Input borders can't be superellipses; same radius keeps rhythm.
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm)),
        ),
      );
}

extension AppContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
  AppLocalizations get l10n => AppLocalizations.of(this);
}
