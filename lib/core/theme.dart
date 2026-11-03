import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFF26B0F);
  static const Color primaryLight = Color(0xFFFF9A3D);
  static const Color primaryDark = Color(0xFFD9540A);
  static const Color soft = Color(0xFFFFF0E5);
  static const Color softer = Color(0xFFFFF7F0);
  static const Color bg = Color(0xFFFFFAF6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF1F1A17);
  static const Color text2 = Color(0xFF5E564F);
  static const Color text3 = Color(0xFF9A918A);
  static const Color line = Color(0xFFEFE6DF);
  static const Color success = Color(0xFF1FA463);
  static const Color successSoft = Color(0xFFE5F6EC);
  static const Color danger = Color(0xFFE5484D);
  static const Color dangerSoft = Color(0xFFFDEBEC);
  static const Color info = Color(0xFF2F7DE1);
  static const Color infoSoft = Color(0xFFE8F1FD);
  static const Color gold = Color(0xFFF5A623);
  static const Color shadow = Color(0x14291404);
  static const Color scrim = Color(0x99000000);

  static const LinearGradient brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primary],
  );
}

class AppText {
  static const String heading = 'Poppins';
  static const String body = 'Inter';

  static const TextStyle h1 = TextStyle(
      fontFamily: heading, fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.ink, height: 1.2);
  static const TextStyle h2 = TextStyle(
      fontFamily: heading, fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.ink, height: 1.25);
  static const TextStyle h3 = TextStyle(
      fontFamily: heading, fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.ink, height: 1.3);
  static const TextStyle title = TextStyle(
      fontFamily: body, fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink, height: 1.35);
  static const TextStyle bodyM = TextStyle(
      fontFamily: body, fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.text2, height: 1.5);
  static const TextStyle bodyS = TextStyle(
      fontFamily: body, fontSize: 12.5, fontWeight: FontWeight.w400, color: AppColors.text3, height: 1.4);
  static const TextStyle label = TextStyle(
      fontFamily: body, fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink);
  static const TextStyle price = TextStyle(
      fontFamily: heading, fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.primary);
}

class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      secondary: AppColors.primaryLight,
      surface: AppColors.surface,
      error: AppColors.danger,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: AppText.body,
      scaffoldBackgroundColor: AppColors.bg,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: AppColors.ink,
        titleTextStyle: AppText.h3,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontFamily: AppText.body, fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.primary, width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontFamily: AppText.body, fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontFamily: AppText.body, fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: const TextStyle(fontFamily: AppText.body, color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerColor: AppColors.line,
    );
  }
}

/// Reusable text-field decoration (avoids ThemeData.inputDecorationTheme API churn).
InputDecoration inputDeco(String hint, {IconData? icon, Widget? suffix, String? label, String? prefixText}) {
  OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c, width: w),
      );
  return InputDecoration(
    hintText: hint,
    labelText: label,
    prefixText: prefixText,
    hintStyle: const TextStyle(color: AppColors.text3, fontSize: 14),
    prefixIcon: icon == null ? null : Icon(icon, size: 20, color: AppColors.text3),
    suffixIcon: suffix,
    filled: true,
    fillColor: AppColors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    border: b(AppColors.line),
    enabledBorder: b(AppColors.line),
    focusedBorder: b(AppColors.primary, 1.6),
    errorBorder: b(AppColors.danger),
    focusedErrorBorder: b(AppColors.danger, 1.6),
  );
}

List<BoxShadow> softShadow([double blur = 22]) => [
      BoxShadow(color: AppColors.shadow, blurRadius: blur, offset: const Offset(0, 8)),
    ];
