import 'package:flutter/material.dart';

abstract final class SeaColors {
  static const ink = Color(0xFF123D50);
  static const ocean = Color(0xFF12677A);
  static const foam = Color(0xFFF2F7F8);
  static const mist = Color(0xFFDCECF0);
  static const muted = Color(0xFF526C78);
  static const danger = Color(0xFFB72F40);
}

ThemeData buildTheme() => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: SeaColors.ocean,
    primary: SeaColors.ocean,
    surface: Colors.white,
    error: SeaColors.danger,
  ),
  scaffoldBackgroundColor: SeaColors.foam,
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 34,
      fontWeight: FontWeight.w800,
      color: SeaColors.ink,
      letterSpacing: -1.1,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: SeaColors.ink,
      letterSpacing: -.7,
    ),
    titleLarge: TextStyle(
      fontSize: 21,
      fontWeight: FontWeight.w700,
      color: SeaColors.ink,
    ),
    titleMedium: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      color: SeaColors.ink,
    ),
    bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: SeaColors.ink),
    bodyMedium: TextStyle(fontSize: 14, height: 1.45, color: SeaColors.muted),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: SeaColors.foam,
    foregroundColor: SeaColors.ink,
    centerTitle: false,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: SeaColors.mist),
    ),
    contentPadding: const EdgeInsets.all(18),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(48, 54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(minimumSize: const Size(48, 52)),
  ),
  navigationBarTheme: const NavigationBarThemeData(
    backgroundColor: Colors.white,
    indicatorColor: SeaColors.mist,
  ),
);
