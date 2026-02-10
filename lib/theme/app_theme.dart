import 'package:flutter/material.dart';

class AppTheme {
  static const Color bg = Color(0xFFF7F8FA);
  static const Color card = Colors.white;
  static const Color border = Color(0xFFE6E8EC);
  static const Color text = Color(0xFF111827);
  static const Color subText = Color(0xFF6B7280);
  static const Color blue = Color(0xFF2563EB);

  /// Old screens in your project are calling AppTheme.lightTheme
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: "Inter",
    scaffoldBackgroundColor: bg,
    cardColor: card,
    colorScheme: ColorScheme.fromSeed(seedColor: blue).copyWith(
      primary: blue,
      surface: Colors.white,
      outline: border,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
  );

  /// ✅ FIXED: ThemeData.copyWith() doesn't support fontFamily
  /// So we rebuild the theme and only override the fontFamily.
  static ThemeData light({required String fontFamily}) {
    return ThemeData(
      useMaterial3: lightTheme.useMaterial3,
      brightness: lightTheme.brightness,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: lightTheme.scaffoldBackgroundColor,
      cardColor: lightTheme.cardColor,
      colorScheme: lightTheme.colorScheme,
      appBarTheme: lightTheme.appBarTheme,
      dividerTheme: lightTheme.dividerTheme,
      inputDecorationTheme: lightTheme.inputDecorationTheme,
      elevatedButtonTheme: lightTheme.elevatedButtonTheme,
      outlinedButtonTheme: lightTheme.outlinedButtonTheme,
      textTheme: lightTheme.textTheme,
    );
  }

  // These are referenced in some of your old screens.
  // Keep them so build does not fail.
  static Color getSuccessColor(bool _) => const Color(0xFF16A34A);
  static Color getWarningColor(bool _) => const Color(0xFFF59E0B);
  static Color getAccentColor(bool _) => const Color(0xFF2563EB);
}