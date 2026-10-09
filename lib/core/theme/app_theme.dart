import 'package:flutter/material.dart';

/// Layout constants: large, one-thumb-friendly.
abstract final class AppSizes {
  /// Minimum touch target for one-thumb use while stopped.
  static const minTap = 64.0;
  static const gap = 16.0;

  /// Cards, big buttons.
  static const radius = 20.0;

  /// Inputs, chips, small cards.
  static const radiusSm = 16.0;
}

/// Brand colors that ColorScheme has no slot for. Screens read these via
/// `context.palette` — never hardcode colors in features/.
///
/// Rules: [emergency] (red) is ONLY for emergency actions. Warnings like the
/// coding badge use [accent] (amber). Safe/OK states use [success] (green).
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
    required this.cardShadow,
  });

  final Color emergency;
  final Color onEmergency;

  /// Darker end of the emergency gradient.
  final Color emergencyDeep;
  final Color accent;
  final Color onAccent;
  final Color success;
  final Color onSuccess;

  /// Secondary text.
  final Color muted;
  final List<BoxShadow> cardShadow;

  LinearGradient get emergencyGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [emergency, emergencyDeep],
  );

  static const light = AppPalette(
    emergency: Color(0xFFE5383B),
    onEmergency: Colors.white,
    emergencyDeep: Color(0xFFB4232A),
    accent: Color(0xFFF5A524),
    onAccent: Color(0xFF0F172A),
    success: Color(0xFF1F9D6B),
    onSuccess: Colors.white,
    muted: Color(0xFF5B6B82),
    cardShadow: [
      BoxShadow(color: Color(0x140F2A4A), blurRadius: 24, offset: Offset(0, 8)),
      BoxShadow(color: Color(0x0A0F2A4A), blurRadius: 4, offset: Offset(0, 1)),
    ],
  );

  static const dark = AppPalette(
    emergency: Color(0xFFFF5A5F),
    onEmergency: Colors.white,
    emergencyDeep: Color(0xFFC81E2B),
    accent: Color(0xFFFFB833),
    onAccent: Color(0xFF0B1220),
    success: Color(0xFF3DDC97),
    onSuccess: Color(0xFF0B1220),
    muted: Color(0xFF93A3BA),
    cardShadow: [
      BoxShadow(color: Color(0x66000000), blurRadius: 20, offset: Offset(0, 8)),
    ],
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
    cardShadow: cardShadow ?? this.cardShadow,
  );

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      emergency: Color.lerp(emergency, other.emergency, t)!,
      onEmergency: Color.lerp(onEmergency, other.onEmergency, t)!,
      emergencyDeep: Color.lerp(emergencyDeep, other.emergencyDeep, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      cardShadow: BoxShadow.lerpList(cardShadow, other.cardShadow, t)!,
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

  static final ThemeData light = _build(
    palette: AppPalette.light,
    scheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF0F2A4A),
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFDCE7F5),
      onPrimaryContainer: Color(0xFF0F2A4A),
      secondary: Color(0xFF0F2A4A),
      onSecondary: Colors.white,
      tertiary: Color(0xFFF5A524),
      onTertiary: Color(0xFF0F172A),
      tertiaryContainer: Color(0xFFFDEBC8),
      onTertiaryContainer: Color(0xFF5A3A00),
      error: Color(0xFFE5383B),
      onError: Colors.white,
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF0F172A),
      onSurfaceVariant: Color(0xFF5B6B82),
      surfaceContainerLowest: Color(0xFFFFFFFF),
      surfaceContainerLow: Color(0xFFF5F7FB),
      surfaceContainer: Color(0xFFEDF1F7),
      surfaceContainerHigh: Color(0xFFE6EBF3),
      surfaceContainerHighest: Color(0xFFDFE5EF),
      outline: Color(0xFFDCE3EE),
      outlineVariant: Color(0xFFDCE3EE),
      inverseSurface: Color(0xFF0F172A),
      onInverseSurface: Color(0xFFF5F7FB),
      shadow: Color(0xFF0F2A4A),
    ),
    background: const Color(0xFFF5F7FB),
  );

  static final ThemeData dark = _build(
    palette: AppPalette.dark,
    scheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF7FB2FF),
      onPrimary: Color(0xFF0B1220),
      primaryContainer: Color(0xFF1D3A66),
      onPrimaryContainer: Color(0xFFDCE9FF),
      secondary: Color(0xFF7FB2FF),
      onSecondary: Color(0xFF0B1220),
      tertiary: Color(0xFFFFB833),
      onTertiary: Color(0xFF0B1220),
      tertiaryContainer: Color(0xFF4A3510),
      onTertiaryContainer: Color(0xFFFFE2B0),
      error: Color(0xFFFF5A5F),
      onError: Color(0xFF0B1220),
      surface: Color(0xFF141D2F),
      onSurface: Color(0xFFE7EDF7),
      onSurfaceVariant: Color(0xFF93A3BA),
      surfaceContainerLowest: Color(0xFF0B1220),
      surfaceContainerLow: Color(0xFF141D2F),
      surfaceContainer: Color(0xFF1C2840),
      surfaceContainerHigh: Color(0xFF22304B),
      surfaceContainerHighest: Color(0xFF293856),
      outline: Color(0xFF26344F),
      outlineVariant: Color(0xFF26344F),
      inverseSurface: Color(0xFFE7EDF7),
      onInverseSurface: Color(0xFF0B1220),
      shadow: Colors.black,
    ),
    background: const Color(0xFF0B1220),
  );

  static ThemeData _build({
    required ColorScheme scheme,
    required AppPalette palette,
    required Color background,
  }) {
    final text = _textTheme(scheme.onSurface, palette.muted);
    final rounded = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    );
    const bigButton = Size.fromHeight(AppSizes.minTap);

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      fontFamily: fontFamily,
      textTheme: text,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      extensions: [palette],
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.headlineSmall,
      ),
      iconTheme: IconThemeData(size: 28, color: scheme.onSurface),
      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius),
          side: BorderSide(color: scheme.outline),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: bigButton,
          textStyle: text.labelLarge,
          shape: rounded,
          elevation: 0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: bigButton,
          textStyle: text.labelLarge,
          shape: rounded,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: bigButton,
          textStyle: text.labelLarge,
          shape: rounded,
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outline, width: 1.5),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          textStyle: text.titleMedium,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(56, 56)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        labelStyle: text.bodyLarge?.copyWith(color: palette.muted),
        floatingLabelStyle: text.titleMedium?.copyWith(color: scheme.primary),
        hintStyle: text.bodyLarge?.copyWith(color: palette.muted),
        errorStyle: text.bodyMedium?.copyWith(color: scheme.error),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surface,
        side: BorderSide(color: scheme.outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
        labelStyle: text.titleMedium,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          textStyle: text.titleMedium,
          backgroundColor: scheme.surface,
          foregroundColor: scheme.onSurface,
          selectedBackgroundColor: scheme.primary,
          selectedForegroundColor: scheme.onPrimary,
          side: BorderSide(color: scheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        side: BorderSide(color: palette.muted, width: 2),
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? palette.success : null,
        ),
        checkColor: WidgetStatePropertyAll(palette.onSuccess),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainer,
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
      dividerTheme: DividerThemeData(color: scheme.outline, thickness: 1),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(textStyle: text.titleLarge),
    );
  }

  /// Big bold headings, readable body.
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
      displayLarge: s(44, FontWeight.w800, h: 1.1, ls: -0.5),
      displayMedium: s(36, FontWeight.w800, h: 1.12, ls: -0.4),
      displaySmall: s(32, FontWeight.w800, h: 1.15, ls: -0.3),
      headlineLarge: s(30, FontWeight.w800, h: 1.18, ls: -0.3),
      headlineMedium: s(26, FontWeight.w800, h: 1.2, ls: -0.2),
      headlineSmall: s(23, FontWeight.w700, h: 1.22),
      titleLarge: s(21, FontWeight.w700),
      titleMedium: s(18, FontWeight.w700),
      titleSmall: s(16, FontWeight.w700),
      bodyLarge: s(19, FontWeight.w500, h: 1.4),
      bodyMedium: s(17, FontWeight.w500, h: 1.4),
      bodySmall: s(15, FontWeight.w500, h: 1.35).copyWith(color: muted),
      labelLarge: s(20, FontWeight.w800, ls: 0.2),
      labelMedium: s(16, FontWeight.w700),
      labelSmall: s(14, FontWeight.w700),
    );
  }
}
