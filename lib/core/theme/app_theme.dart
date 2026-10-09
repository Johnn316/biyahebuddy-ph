import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Layout constants: large, one-thumb-friendly, iOS-like radii.
abstract final class AppSizes {
  /// Minimum touch target for one-thumb use while stopped.
  static const minTap = 60.0;
  static const gap = 16.0;

  /// Grouped cards, hero elements.
  static const radius = 26.0;

  /// Buttons, inputs, inner cards.
  static const radiusSm = 22.0;

  /// Settings-style icon squares.
  static const radiusIcon = 10.0;

  /// Readable column width on tablets.
  static const maxContentWidth = 640.0;
}

/// Brand colors that ColorScheme has no slot for. Screens read these via
/// `context.palette` — never hardcode colors in features/.
///
/// Rules: [emergency] (SOS red) is ONLY for emergency. Coding badge and
/// citations use [accent] (amber). Safe/OK states use [success] (green).
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.emergency,
    required this.onEmergency,
    required this.emergencyDeep,
    required this.accent,
    required this.onAccent,
    required this.success,
    required this.onSuccess,
    required this.muted,
    required this.groupedBackground,
    required this.elevated,
    required this.cardShadow,
  });

  final Color emergency;
  final Color onEmergency;

  /// Darker end of the SOS gradient.
  final Color emergencyDeep;
  final Color accent;
  final Color onAccent;
  final Color success;
  final Color onSuccess;

  /// Secondary label (iOS secondaryLabel, 60%).
  final Color muted;

  /// iOS grouped background (behind inset cards).
  final Color groupedBackground;

  /// Raised fill on top of cards (iOS secondarySystemGroupedBackground /
  /// tertiary): Buddy bubbles, search fields, pills.
  final Color elevated;

  /// Very soft (light) or none (dark).
  final List<BoxShadow> cardShadow;

  LinearGradient get emergencyGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [emergency, emergencyDeep],
  );

  static const light = AppPalette(
    emergency: Color(0xFFFF3B30),
    onEmergency: Colors.white,
    emergencyDeep: Color(0xFFD70015),
    accent: Color(0xFFFFB020),
    onAccent: Color(0xFF000000),
    success: Color(0xFF34C759),
    onSuccess: Color(0xFF000000),
    muted: Color(0x993C3C43),
    groupedBackground: Color(0xFFF2F2F7),
    elevated: Color(0xFFE9E9EB),
    cardShadow: [
      BoxShadow(color: Color(0x0D000000), blurRadius: 18, offset: Offset(0, 4)),
    ],
  );

  static const dark = AppPalette(
    emergency: Color(0xFFFF3B30),
    onEmergency: Colors.white,
    emergencyDeep: Color(0xFFC4141C),
    accent: Color(0xFFFFB020),
    onAccent: Color(0xFF000000),
    success: Color(0xFF34C759),
    onSuccess: Color(0xFF000000),
    muted: Color(0x99EBEBF5),
    groupedBackground: Color(0xFF000000),
    elevated: Color(0xFF2C2C2E),
    cardShadow: [],
  );

  @override
  AppPalette copyWith({
    Color? emergency,
    Color? onEmergency,
    Color? emergencyDeep,
    Color? accent,
    Color? onAccent,
    Color? success,
    Color? onSuccess,
    Color? muted,
    Color? groupedBackground,
    Color? elevated,
    List<BoxShadow>? cardShadow,
  }) => AppPalette(
    emergency: emergency ?? this.emergency,
    onEmergency: onEmergency ?? this.onEmergency,
    emergencyDeep: emergencyDeep ?? this.emergencyDeep,
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
    success: success ?? this.success,
    onSuccess: onSuccess ?? this.onSuccess,
    muted: muted ?? this.muted,
    groupedBackground: groupedBackground ?? this.groupedBackground,
    elevated: elevated ?? this.elevated,
    cardShadow: cardShadow ?? this.cardShadow,
  );

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      emergency: c(emergency, other.emergency),
      onEmergency: c(onEmergency, other.onEmergency),
      emergencyDeep: c(emergencyDeep, other.emergencyDeep),
      accent: c(accent, other.accent),
      onAccent: c(onAccent, other.onAccent),
      success: c(success, other.success),
      onSuccess: c(onSuccess, other.onSuccess),
      muted: c(muted, other.muted),
      groupedBackground: c(groupedBackground, other.groupedBackground),
      elevated: c(elevated, other.elevated),
      cardShadow: BoxShadow.lerpList(cardShadow, other.cardShadow, t) ?? [],
    );
  }
}

extension AppThemeContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
}

abstract final class AppTheme {
  static const fontFamily = 'PlusJakartaSans';
  static const _link = Color(0xFF0A84FF);

  static final ThemeData light = _build(
    palette: AppPalette.light,
    scheme: const ColorScheme(
      brightness: Brightness.light,
      primary: _link,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFDDEBFF),
      onPrimaryContainer: Color(0xFF003A80),
      secondary: _link,
      onSecondary: Colors.white,
      tertiary: Color(0xFFFFB020),
      onTertiary: Colors.black,
      tertiaryContainer: Color(0xFFFFF1D6),
      onTertiaryContainer: Color(0xFF5C3B00),
      // Validation errors: amber, NOT red — red is reserved for SOS.
      error: Color(0xFFB25E00),
      onError: Colors.white,
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF000000),
      onSurfaceVariant: Color(0x993C3C43),
      surfaceContainerLowest: Color(0xFFFFFFFF),
      surfaceContainerLow: Color(0xFFF2F2F7),
      surfaceContainer: Color(0xFFEFEFF4),
      surfaceContainerHigh: Color(0xFFE9E9EB),
      surfaceContainerHighest: Color(0xFFE5E5EA),
      outline: Color(0xFFC6C6C8),
      outlineVariant: Color(0xFFC6C6C8),
      inverseSurface: Color(0xFF1C1C1E),
      onInverseSurface: Colors.white,
      shadow: Colors.black,
    ),
  );

  static final ThemeData dark = _build(
    palette: AppPalette.dark,
    scheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: _link,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFF0B3B73),
      onPrimaryContainer: Color(0xFFD6E8FF),
      secondary: _link,
      onSecondary: Colors.white,
      tertiary: Color(0xFFFFB020),
      onTertiary: Colors.black,
      tertiaryContainer: Color(0xFF3D2C0B),
      onTertiaryContainer: Color(0xFFFFE2A8),
      // Validation errors: amber, NOT red — red is reserved for SOS.
      error: Color(0xFFFFB020),
      onError: Colors.black,
      surface: Color(0xFF1C1C1E),
      onSurface: Color(0xFFFFFFFF),
      onSurfaceVariant: Color(0x99EBEBF5),
      surfaceContainerLowest: Color(0xFF000000),
      surfaceContainerLow: Color(0xFF1C1C1E),
      surfaceContainer: Color(0xFF242426),
      surfaceContainerHigh: Color(0xFF2C2C2E),
      surfaceContainerHighest: Color(0xFF3A3A3C),
      outline: Color(0xFF38383A),
      outlineVariant: Color(0xFF38383A),
      inverseSurface: Color(0xFFF2F2F7),
      onInverseSurface: Colors.black,
      shadow: Colors.black,
    ),
  );

  static ThemeData _build({
    required ColorScheme scheme,
    required AppPalette palette,
  }) {
    final text = _textTheme(scheme.onSurface, palette.muted);
    final pill = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
    );
    const bigButton = Size.fromHeight(AppSizes.minTap);

    return ThemeData(
      useMaterial3: true,
      // iOS behaviours on every device: back chevrons, bouncing scroll,
      // Cupertino transitions, adaptive switches/dialogs.
      platform: TargetPlatform.iOS,
      brightness: scheme.brightness,
      colorScheme: scheme,
      fontFamily: fontFamily,
      textTheme: text,
      scaffoldBackgroundColor: palette.groupedBackground,
      canvasColor: palette.groupedBackground,
      extensions: [palette],
      splashFactory: NoSplash.splashFactory,
      highlightColor: scheme.onSurface.withValues(alpha: 0.06),
      cupertinoOverrideTheme: NoDefaultCupertinoThemeData(
        brightness: scheme.brightness,
        primaryColor: scheme.primary,
        scaffoldBackgroundColor: palette.groupedBackground,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.groupedBackground,
        foregroundColor: scheme.primary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: text.titleLarge,
        iconTheme: IconThemeData(color: scheme.primary, size: 28),
      ),
      iconTheme: IconThemeData(size: 26, color: scheme.onSurface),
      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: bigButton,
          textStyle: text.labelLarge,
          shape: pill,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: bigButton,
          textStyle: text.labelLarge,
          shape: pill,
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.outline),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: scheme.primary,
          textStyle: text.titleMedium,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(52, 52)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        labelStyle: text.bodyLarge?.copyWith(color: palette.muted),
        floatingLabelStyle: text.titleSmall?.copyWith(color: scheme.primary),
        hintStyle: text.bodyLarge?.copyWith(color: palette.muted),
        errorStyle: text.bodyMedium?.copyWith(color: scheme.error),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surface,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        labelStyle: text.titleSmall,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: palette.elevated,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyLarge?.copyWith(
          color: scheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outline,
        thickness: 0.5,
        space: 0.5,
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? palette.success : null,
        ),
      ),
    );
  }

  /// iOS-like hierarchy, sized up for drivers.
  static TextTheme _textTheme(Color on, Color muted) {
    TextStyle s(double size, FontWeight w, {double h = 1.25, double ls = 0}) =>
        TextStyle(
          fontFamily: fontFamily,
          fontSize: size,
          fontWeight: w,
          height: h,
          letterSpacing: ls,
          color: on,
        );
    return TextTheme(
      // Large Title and friends.
      displayLarge: s(48, FontWeight.w800, h: 1.05, ls: -1),
      displayMedium: s(38, FontWeight.w800, h: 1.1, ls: -0.6),
      displaySmall: s(34, FontWeight.w800, h: 1.12, ls: -0.5),
      headlineLarge: s(30, FontWeight.w800, h: 1.15, ls: -0.4),
      headlineMedium: s(26, FontWeight.w700, h: 1.2, ls: -0.3),
      headlineSmall: s(23, FontWeight.w700, h: 1.22, ls: -0.2),
      titleLarge: s(20, FontWeight.w700, ls: -0.2),
      titleMedium: s(18, FontWeight.w600),
      titleSmall: s(16, FontWeight.w600),
      bodyLarge: s(19, FontWeight.w500, h: 1.4),
      bodyMedium: s(17, FontWeight.w500, h: 1.4),
      bodySmall: s(15, FontWeight.w500, h: 1.35).copyWith(color: muted),
      labelLarge: s(19, FontWeight.w700),
      labelMedium: s(15, FontWeight.w600),
      labelSmall: s(13, FontWeight.w600).copyWith(color: muted),
    );
  }
}
