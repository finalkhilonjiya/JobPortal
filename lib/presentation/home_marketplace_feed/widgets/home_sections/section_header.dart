import 'package:flutter/material.dart';
import '../../../../core/ui/khilonjiya_ui.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String ctaText;
  final VoidCallback? onTap;

  const SectionHeader({
    Key? key,
    required this.title,
    required this.ctaText,
    this.onTap,
  }) : super(key: key);

  @override
Widget build(BuildContext context) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        title,
        style: KhilonjiyaUI.hTitle.copyWith(
          fontWeight: FontWeight.w600, // lighter
          color: const Color(0xFF334155), // softer color
        ),
      ),
      if (ctaText.isNotEmpty)
        InkWell(
          onTap: onTap,
          child: Text(
            ctaText,
            style: KhilonjiyaUI.sub.copyWith(
              fontWeight: FontWeight.w500,
              color: KhilonjiyaUI.primary,
            ),
          ),
        ),
    ],
  );
}
}