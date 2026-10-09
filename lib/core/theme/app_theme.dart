import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

export 'tokens.dart';

/// Layout constants: large, one-thumb-friendly, iOS-like radii.
abstract final class AppSizes {
  /// Minimum touch target for one-thumb use while stopped.
  static const minTap = 60.0;
  static const gap = 16.0;

  /// Grouped cards, hero elements (DESIGN.md radius lg).
  static const radius = 24.0;

  /// Buttons, inputs, inner cards (radius md).
  static const radiusSm = 18.0;

  /// Settings-style icon squares (radius xs).
  static const radiusIcon = 8.0;

  /// Readable column width on tablets.
  static const maxContentWidth = 640.0;
}

/// Brand colors that ColorScheme has no slot for (docs/DESIGN.md §2).
/// Screens read these via `context.palette` — never hardcode colors in
/// features/.
///
/// Rules: [emergency] (SOS red) is ONLY for SOS. Coding badge, citations and
/// validation use [accent] (amber). Safe/OK states use [success] (green).
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.emergency,
    required this.onEmergency,
    required this.emergencyDeep,
    required this.accent,
    required this.onAccent,
    required this.cautionText,
    required this.success,
    required this.onSuccess,
    required this.muted,
    required this.textTertiary,
    required this.groupedBackground,
    required this.elevated,
    required this.sunken,
    required this.controlOutline,
    required this.primaryFill,
    required this.onPrimaryFill,
    required this.successTint,
    required this.cautionTint,
    required this.primaryTint,
    required this.glass,
    required this.highlight,
    required this.cardShadow,
    required this.raisedShadow,
  });

  /// SOS red (top of the SOS gradient). SOS surfaces only.
  final Color emergency;
  final Color onEmergency;

  /// Darker end of the SOS gradient; small text on red sits on this.
  final Color emergencyDeep;

  /// Amber fill: coding badge, law pills.
  final Color accent;
  final Color onAccent;

  /// Amber used as TEXT on surfaces (darker in light mode for contrast).
  final Color cautionText;

  /// Green: safe/OK states, call buttons, Offline-ready.
  final Color success;
  final Color onSuccess;

  /// Secondary text (textSecondary in DESIGN.md).
  final Color muted;

  /// Disabled / placeholder only — never information.
  final Color textTertiary;

  /// Canvas (`bg`).
  final Color groupedBackground;

  /// Raised fill on a card: Buddy bubble, fields, pressed rows.
  final Color elevated;

  /// Inset wells, segmented-control tracks.
  final Color sunken;

  /// Input/control boundaries (≥ 3:1 non-text contrast).
  final Color controlOutline;

  /// Blue for filled buttons and the user's chat bubble (white text ≥ 4.5:1).
  /// `colorScheme.primary` is the blue for text, links and icons.
  final Color primaryFill;
  final Color onPrimaryFill;

  /// Tinted chip backgrounds (paired with success / cautionText / primary).
  final Color successTint;
  final Color cautionTint;
  final Color primaryTint;

  /// Translucent fill for frosted glass (use with a blur).
  final Color glass;

  /// 0.5dp top highlight on cards in dark mode.
  final Color highlight;

  /// Level 1 (cards) and level 2 (raised) shadows; none in dark mode.
  final List<BoxShadow> cardShadow;
  final List<BoxShadow> raisedShadow;

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
    onAccent: Color(0xFF0B0D12),
    cautionText: Color(0xFF8A5200),
    success: Color(0xFF1F7A35),
    onSuccess: Colors.white,
    muted: Color(0xFF5A6372),
    textTertiary: Color(0xFF8A93A3),
    groupedBackground: Color(0xFFF2F3F7),
    elevated: Color(0xFFE9EBF0),
    sunken: Color(0xFFE9EBF0),
    controlOutline: Color(0xFF7C8595),
    primaryFill: Color(0xFF0064D6),
    onPrimaryFill: Colors.white,
    successTint: Color(0xFFE3F5E8),
    cautionTint: Color(0xFFFFF1D6),
    primaryTint: Color(0xFFE2EEFF),
    glass: Color(0xB8FFFFFF),
    highlight: Color(0x00FFFFFF),
    cardShadow: [
      BoxShadow(color: Color(0x0F0B0D12), blurRadius: 2, offset: Offset(0, 1)),
    ],
    raisedShadow: [
      BoxShadow(color: Color(0x140B0D12), blurRadius: 24, offset: Offset(0, 8)),
    ],
  );

  static const dark = AppPalette(
    emergency: Color(0xFFFF3B30),
    onEmergency: Colors.white,
    emergencyDeep: Color(0xFFD70015),
    accent: Color(0xFFFFB020),
    onAccent: Color(0xFF0B0D12),
    cautionText: Color(0xFFFFB020),
    success: Color(0xFF30D158),
    onSuccess: Color(0xFF0B0D12),
    muted: Color(0xFFA7AFBD),
    textTertiary: Color(0xFF6B7486),
    groupedBackground: Color(0xFF0B0D12),
    elevated: Color(0xFF202530),
    sunken: Color(0xFF0F1218),
    controlOutline: Color(0xFF6B7486),
    primaryFill: Color(0xFF1F6FE5),
    onPrimaryFill: Colors.white,
    successTint: Color(0xFF14281B),
    cautionTint: Color(0xFF2E2410),
    primaryTint: Color(0xFF14223A),
    glass: Color(0xB8161A22),
    highlight: Color(0x0FFFFFFF),
    cardShadow: [],
    raisedShadow: [],
  );

  @override
  AppPalette copyWith() => this;

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
      cautionText: c(cautionText, other.cautionText),
      success: c(success, other.success),
      onSuccess: c(onSuccess, other.onSuccess),
      muted: c(muted, other.muted),
      textTertiary: c(textTertiary, other.textTertiary),
      groupedBackground: c(groupedBackground, other.groupedBackground),
      elevated: c(elevated, other.elevated),
      sunken: c(sunken, other.sunken),
      controlOutline: c(controlOutline, other.controlOutline),
      primaryFill: c(primaryFill, other.primaryFill),
      onPrimaryFill: c(onPrimaryFill, other.onPrimaryFill),
      successTint: c(successTint, other.successTint),
      cautionTint: c(cautionTint, other.cautionTint),
      primaryTint: c(primaryTint, other.primaryTint),
      glass: c(glass, other.glass),
      highlight: c(highlight, other.highlight),
      cardShadow: BoxShadow.lerpList(cardShadow, other.cardShadow, t) ?? [],
      raisedShadow:
          BoxShadow.lerpList(raisedShadow, other.raisedShadow, t) ?? [],
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
      primary: Color(0xFF0064D6),
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFE2EEFF),
      onPrimaryContainer: Color(0xFF00387A),
      secondary: Color(0xFF0064D6),
      onSecondary: Colors.white,
      tertiary: Color(0xFFFFB020),
      onTertiary: Color(0xFF0B0D12),
      tertiaryContainer: Color(0xFFFFF1D6),
      onTertiaryContainer: Color(0xFF5C3B00),
      // Validation errors: amber, NOT red — red is reserved for SOS.
      error: Color(0xFF9A5B00),
      onError: Colors.white,
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF0B0D12),
      onSurfaceVariant: Color(0xFF5A6372),
      surfaceContainerLowest: Color(0xFFFFFFFF),
      surfaceContainerLow: Color(0xFFF2F3F7),
      surfaceContainer: Color(0xFFF7F8FA),
      surfaceContainerHigh: Color(0xFFE9EBF0),
      surfaceContainerHighest: Color(0xFFDFE2E8),
      outline: Color(0xFFC9CED8),
      outlineVariant: Color(0xFFC9CED8),
      inverseSurface: Color(0xFF161A22),
      onInverseSurface: Color(0xFFF2F4F8),
      shadow: Color(0xFF0B0D12),
    ),
  );

  static final ThemeData dark = _build(
    palette: AppPalette.dark,
    scheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF4D9BFF),
      onPrimary: Color(0xFF0B0D12),
      primaryContainer: Color(0xFF14223A),
      onPrimaryContainer: Color(0xFFD6E8FF),
      secondary: Color(0xFF4D9BFF),
      onSecondary: Color(0xFF0B0D12),
      tertiary: Color(0xFFFFB020),
      onTertiary: Color(0xFF0B0D12),
      tertiaryContainer: Color(0xFF2E2410),
      onTertiaryContainer: Color(0xFFFFE2A8),
      // Validation errors: amber, NOT red — red is reserved for SOS.
      error: Color(0xFFFFB020),
      onError: Color(0xFF0B0D12),
      surface: Color(0xFF161A22),
      onSurface: Color(0xFFF2F4F8),
      onSurfaceVariant: Color(0xFFA7AFBD),
      surfaceContainerLowest: Color(0xFF0B0D12),
      surfaceContainerLow: Color(0xFF161A22),
      surfaceContainer: Color(0xFF1B1F28),
      surfaceContainerHigh: Color(0xFF202530),
      surfaceContainerHighest: Color(0xFF2A303C),
      outline: Color(0xFF343B49),
      outlineVariant: Color(0xFF343B49),
      inverseSurface: Color(0xFFF2F3F7),
      onInverseSurface: Color(0xFF0B0D12),
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
          backgroundColor: palette.primaryFill,
          foregroundColor: palette.onPrimaryFill,
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
      displayLarge: s(44, FontWeight.w800, h: 1.09, ls: -1),
      displayMedium: s(38, FontWeight.w800, h: 1.1, ls: -0.6),
      displaySmall: s(34, FontWeight.w800, h: 1.12, ls: -0.5),
      headlineLarge: s(28, FontWeight.w800, h: 1.2, ls: -0.4),
      headlineMedium: s(26, FontWeight.w700, h: 1.2, ls: -0.3),
      headlineSmall: s(23, FontWeight.w700, h: 1.22, ls: -0.2),
      titleLarge: s(20, FontWeight.w700, ls: -0.2),
      titleMedium: s(18, FontWeight.w700),
      titleSmall: s(16, FontWeight.w600),
      bodyLarge: s(17, FontWeight.w500, h: 1.47),
      bodyMedium: s(16, FontWeight.w500, h: 1.38),
      bodySmall: s(15, FontWeight.w500, h: 1.35).copyWith(color: muted),
      labelLarge: s(19, FontWeight.w700),
      labelMedium: s(15, FontWeight.w600),
      labelSmall: s(13, FontWeight.w600).copyWith(color: muted),
    );
  }
}
