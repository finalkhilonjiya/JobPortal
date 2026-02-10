import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppStyles {
  static BorderRadius r12 = BorderRadius.circular(12);
  static BorderRadius r16 = BorderRadius.circular(16);
  static BorderRadius r20 = BorderRadius.circular(20);

  static BoxDecoration cardDecoration({
    BorderRadius? radius,
    bool shadow = true,
  }) {
    return BoxDecoration(
      color: AppTheme.card,
      borderRadius: radius ?? r16,
      border: Border.all(color: AppTheme.border),
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

  static TextStyle hTitle = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppTheme.text,
    height: 1.2,
  );

  static TextStyle cardTitle = const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppTheme.text,
    height: 1.2,
  );

  static TextStyle sub = const TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    color: AppTheme.subText,
    height: 1.25,
  );

  static TextStyle link = const TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w700,
    color: AppTheme.blue,
  );
}