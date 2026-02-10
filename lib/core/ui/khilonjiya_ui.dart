// lib/core/ui/khilonjiya_ui.dart
import 'package:flutter/material.dart';

class KhilonjiyaUI {
  // ------------------------------------------------------------
  // COLORS (Naukri-style / Figma)
  // ------------------------------------------------------------
  static const Color bg = Color(0xFFF6F7FB);
  static const Color surface = Colors.white;

  static const Color text = Color(0xFF0F172A);
  static const Color muted = Color(0xFF64748B);
  static const Color faint = Color(0xFF94A3B8);

  static const Color line = Color(0xFFE6EAF2);

  // Primary (clean Naukri-like blue)
  static const Color primary = Color(0xFF2563EB);

  // Pills
  static const Color pillBg = Color(0xFFF1F5FF);

  // ------------------------------------------------------------
  // RADII
  // ------------------------------------------------------------
  static const double radiusCard = 18;
  static const double radiusPill = 999;

  // ------------------------------------------------------------
  // SHADOWS
  // ------------------------------------------------------------
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
  ];

  // ------------------------------------------------------------
  // CARD DECORATION
  // ------------------------------------------------------------
  static BoxDecoration cardDecoration() {
    return BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(radiusCard),
      border: Border.all(color: line),
      boxShadow: softShadow,
    );
  }

  // ------------------------------------------------------------
  // TEXT STYLES
  // ------------------------------------------------------------
  static const String font = "Inter";

  static const TextStyle h1 = TextStyle(
    fontFamily: font,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: text,
    letterSpacing: -0.2,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: font,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: text,
    letterSpacing: -0.1,
  );

  static const TextStyle body = TextStyle(
    fontFamily: font,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: text,
  );

  static const TextStyle small = TextStyle(
    fontFamily: font,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: muted,
  );

  static const TextStyle link = TextStyle(
    fontFamily: font,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: primary,
  );

  // ------------------------------------------------------------
  // THEME
  // ------------------------------------------------------------
  static ThemeData theme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: font,
      scaffoldBackgroundColor: bg,

      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: bg,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: text),
        titleTextStyle: TextStyle(
          fontFamily: font,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: text,
        ),
      ),

      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF0F172A),
        contentTextStyle: TextStyle(
          fontFamily: font,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: line,
        thickness: 1,
        space: 1,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(
          fontFamily: font,
          fontWeight: FontWeight.w600,
          color: muted,
        ),
        hintStyle: const TextStyle(
          fontFamily: font,
          fontWeight: FontWeight.w500,
          color: faint,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFFCA5A5)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: const TextStyle(
            fontFamily: font,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          side: const BorderSide(color: line),
          textStyle: const TextStyle(
            fontFamily: font,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}