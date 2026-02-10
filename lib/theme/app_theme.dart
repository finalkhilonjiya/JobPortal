import 'package:flutter/material.dart';

class AppTheme {
  static const Color bg = Color(0xFFF7F8FA);
  static const Color card = Colors.white;
  static const Color border = Color(0xFFE6E8EC);
  static const Color text = Color(0xFF111827);
  static const Color subText = Color(0xFF6B7280);
  static const Color blue = Color(0xFF2563EB);

  static ThemeData light({required String fontFamily}) {
    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(seedColor: blue).copyWith(
        primary: blue,
        surface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}