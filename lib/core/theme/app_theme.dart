import 'package:flutter/material.dart';

/// High-contrast, large-text, one-thumb-friendly theme for drivers.
abstract final class AppColors {
  static const emergency = Color(0xFFD50000);
  static const onEmergency = Colors.white;
  static const primary = Color(0xFF0D47A1);
  static const accent = Color(0xFFFFC400);
  static const background = Color(0xFF0B0B0F);
  static const surface = Color(0xFF1C1C22);
  static const onSurface = Colors.white;
  static const ok = Color(0xFF00C853);
  static const warning = Color(0xFFFFAB00);
}

abstract final class AppSizes {
  /// Minimum touch target for one-thumb use while stopped.
  static const minTap = 64.0;
  static const gap = 16.0;
  static const radius = 20.0;
}

abstract final class AppTheme {
  static ThemeData get dark {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ).copyWith(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          error: AppColors.emergency,
          onError: AppColors.onEmergency,
          surface: AppColors.surface,
          onSurface: AppColors.onSurface,
        );

    const text = TextTheme(
      displayLarge: TextStyle(fontSize: 44, fontWeight: FontWeight.w900),
      headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
      bodyLarge: TextStyle(fontSize: 20),
      bodyMedium: TextStyle(fontSize: 18),
      labelLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
    );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSizes.radius),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: text.apply(
        bodyColor: AppColors.onSurface,
        displayColor: AppColors.onSurface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onSurface,
        centerTitle: false,
        titleTextStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
      ),
      iconTheme: const IconThemeData(size: 32),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.minTap),
          textStyle: text.labelLarge,
          shape: shape,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.minTap),
          textStyle: text.labelLarge,
          shape: shape,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(AppSizes.minTap, AppSizes.minTap),
        ),
      ),
    );
  }
}
