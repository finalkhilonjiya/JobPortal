import 'package:flutter/material.dart';

class KhilonjiyaUI {
  // Colors (Figma)
  static const Color bg = Color(0xFFF7F8FA);
  static const Color card = Colors.white;
  static const Color border = Color(0xFFE6E8EC);
  static const Color text = Color(0xFF111827);
  static const Color muted = Color(0xFF6B7280);
  static const Color primary = Color(0xFF2563EB);

  // Radius
  static BorderRadius r12 = BorderRadius.circular(12);
  static BorderRadius r16 = BorderRadius.circular(16);
  static BorderRadius r20 = BorderRadius.circular(20);

  // Text Styles
  static const TextStyle h1 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: text,
    height: 1.2,
  );

  static const TextStyle hTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: text,
    height: 1.2,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: text,
    height: 1.2,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: text,
    height: 1.35,
  );

  static const TextStyle sub = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    color: muted,
    height: 1.25,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    color: muted,
    height: 1.2,
  );

  static const TextStyle link = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w700,
    color: primary,
    height: 1.2,
  );

  // Card decoration
  static BoxDecoration cardDecoration({
    double? radius,
    bool shadow = true,
  }) {
    return BoxDecoration(
      color: card,
      borderRadius: BorderRadius.circular(radius ?? 16),
      border: Border.all(color: border),
      boxShadow: shadow
          ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ]
          : [],
    );
  }

  // Theme (Material 3)
  static ThemeData theme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: "Inter",
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(seedColor: primary).copyWith(
        primary: primary,
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