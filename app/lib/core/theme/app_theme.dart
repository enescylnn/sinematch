import 'package:flutter/material.dart';

class SineColors {
  static const bg = Color(0xFF07080C);
  static const surface = Color(0xFF101219);
  static const surface2 = Color(0xFF171A23);
  static const border = Color(0xFF262A36);
  static const pink = Color(0xFFFF315F);
  static const coral = Color(0xFFFF6A5E);
  static const gold = Color(0xFFFFC765);
  static const green = Color(0xFF57D39B);
  static const muted = Color(0xFF9297A8);
}

ThemeData buildSineTheme() {
  const scheme = ColorScheme.dark(
    primary: SineColors.pink,
    secondary: SineColors.gold,
    surface: SineColors.surface,
    error: Color(0xFFFF5C6C),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: SineColors.bg,
    colorScheme: scheme,
    fontFamily: 'Roboto',
    textTheme: const TextTheme(
      displaySmall: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -1.2),
      headlineMedium: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.8),
      titleLarge: TextStyle(fontWeight: FontWeight.w800),
      titleMedium: TextStyle(fontWeight: FontWeight.w700),
      bodyLarge: TextStyle(height: 1.35),
      bodyMedium: TextStyle(height: 1.35),
    ),
    cardTheme: CardThemeData(
      color: SineColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: SineColors.border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: SineColors.surface2,
      hintStyle: const TextStyle(color: Colors.white38),
      labelStyle: const TextStyle(color: SineColors.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: SineColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: SineColors.pink, width: 1.4),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Color(0xFF0B0D12),
      indicatorColor: Color(0x28FF315F),
      height: 72,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: SineColors.pink,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        side: const BorderSide(color: SineColors.border),
        foregroundColor: Colors.white,
      ),
    ),
  );
}
