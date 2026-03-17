import 'package:flutter/material.dart';

/// Farm app palette: white background, green + black text/accents.
abstract final class FarmColors {
  static const Color background = Color(0xFFFFFFFF);
  static const Color green = Color(0xFF1B5E20);
  static const Color greenLight = Color(0xFF2E7D32);
  static const Color black = Color(0xFF0A0A0A);
  static const Color blackMuted = Color(0xFF424242);
  static const Color outline = Color(0xFF1B5E20);
}

ThemeData buildFarmTheme() {
  const green = FarmColors.green;
  const black = FarmColors.black;

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: FarmColors.background,
    colorScheme: const ColorScheme.light(
      surface: FarmColors.background,
      onSurface: black,
      primary: green,
      onPrimary: FarmColors.background,
      secondary: FarmColors.greenLight,
      onSecondary: FarmColors.background,
      outline: FarmColors.outline,
      error: Color(0xFFB71C1C),
      onError: FarmColors.background,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: FarmColors.background,
      foregroundColor: black,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: FarmColors.background,
      labelStyle: const TextStyle(color: FarmColors.blackMuted),
      floatingLabelStyle: const TextStyle(color: green),
      hintStyle: TextStyle(color: black.withValues(alpha: 0.5)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: FarmColors.outline, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: black.withValues(alpha: 0.2), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: green, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFB71C1C)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: green,
        foregroundColor: FarmColors.background,
        // Avoid double.infinity width: breaks layout inside Row (e.g. sheet + icon).
        minimumSize: const Size(64, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textTheme: TextTheme(
      headlineLarge: const TextStyle(
        color: green,
        fontWeight: FontWeight.w700,
        fontSize: 28,
        letterSpacing: -0.5,
      ),
      headlineMedium: const TextStyle(
        color: green,
        fontWeight: FontWeight.w700,
        fontSize: 24,
      ),
      titleLarge: const TextStyle(color: black, fontWeight: FontWeight.w600),
      bodyLarge: const TextStyle(color: black, fontSize: 16, height: 1.4),
      bodyMedium: const TextStyle(
        color: FarmColors.blackMuted,
        fontSize: 14,
        height: 1.4,
      ),
      bodySmall: const TextStyle(
        color: FarmColors.blackMuted,
        fontSize: 12,
        height: 1.35,
      ),
    ),
  );
}
