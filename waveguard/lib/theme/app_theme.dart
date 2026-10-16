import 'package:flutter/material.dart';

abstract final class SeaColors {
  static const ink = Color(0xFF06264C);
  static const ocean = Color(0xFF0087ED);
  static const foam = Color(0xFFF7FBFF);
  static const mist = Color(0xFFE1EDF6);
  static const muted = Color(0xFF49627C);
  static const danger = Color(0xFFB72F40);
}

ThemeData buildTheme() => ThemeData(
  fontFamily: 'Roboto',
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
      fontSize: 28,
      fontWeight: FontWeight.w800,
      color: SeaColors.ink,
      letterSpacing: -1.1,
    ),
    headlineMedium: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: SeaColors.ink,
      letterSpacing: -.7,
    ),
    titleLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: SeaColors.ink,
    ),
    titleMedium: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: SeaColors.ink,
    ),
    bodyLarge: TextStyle(fontSize: 14, height: 1.4, color: SeaColors.ink),
    bodyMedium: TextStyle(fontSize: 13, height: 1.4, color: SeaColors.muted),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: SeaColors.foam,
    foregroundColor: SeaColors.ink,
    centerTitle: false,
    toolbarHeight: 52,
    titleTextStyle: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: SeaColors.ink,
    ),
  ),
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: SeaColors.mist),
    ),
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
      textStyle: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(minimumSize: const Size(48, 52)),
  ),
  navigationBarTheme: NavigationBarThemeData(
    height: 68,
    labelTextStyle: WidgetStateProperty.all(
      const TextStyle(color: Colors.white, fontSize: 11),
    ),
    backgroundColor: Colors.white,
    indicatorColor: SeaColors.mist,
  ),
);
