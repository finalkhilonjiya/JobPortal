import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF0E7C66);
  static const Color primaryDark = Color(0xFF0A5C4C);
  static const Color primarySoft = Color(0xFFE6F4F0);
  static const Color accent = Color(0xFFFF7A59);
  static const Color accentSoft = Color(0xFFFFEFEA);

  static const Color ink = Color(0xFF101828);
  static const Color text2 = Color(0xFF475467);
  static const Color muted = Color(0xFF98A2B3);
  static const Color border = Color(0xFFE4E7EC);
  static const Color bg = Color(0xFFF7F8FA);
  static const Color surface = Color(0xFFFFFFFF);

  static const Color danger = Color(0xFFD92D20);
  static const Color success = Color(0xFF12B76A);

  // Pre-computed translucent colours (avoid deprecated withOpacity calls).
  static const Color shadow = Color(0x14101828); // ink @ 8%
  static const Color scrim = Color(0x66000000); // black @ 40%
  static const Color glass = Color(0xCCFFFFFF); // white @ 80%
}

class AppText {
  static const TextStyle display = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 28,
    height: 1.2,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );
  static const TextStyle h1 = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 22,
    height: 1.25,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );
  static const TextStyle h2 = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 18,
    height: 1.3,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
  );
  static const TextStyle h3 = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    height: 1.3,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
  );
  static const TextStyle price = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 18,
    height: 1.2,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );
  static const TextStyle body = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    height: 1.45,
    color: AppColors.text2,
  );
  static const TextStyle bodyStrong = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    height: 1.45,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
  );
  static const TextStyle small = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    height: 1.4,
    color: AppColors.muted,
  );
  static const TextStyle label = TextStyle(
    fontFamily: 'Inter',
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
  );
}

class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      surface: AppColors.surface,
      error: AppColors.danger,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bg,
      fontFamily: 'Inter',
      splashFactory: InkRipple.splashFactory,
    );
  }
}

/// Shared input decoration (kept out of ThemeData so it never breaks when
/// Flutter renames component-theme classes).
InputDecoration inputDeco(String label, {String? hint, String? prefixText}) {
  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c, width: w),
      );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixText: prefixText,
    filled: true,
    fillColor: AppColors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    labelStyle: AppText.body,
    hintStyle: AppText.small.copyWith(fontSize: 14),
    enabledBorder: border(AppColors.border),
    focusedBorder: border(AppColors.primary, 1.6),
    errorBorder: border(AppColors.danger),
    focusedErrorBorder: border(AppColors.danger, 1.6),
  );
}
