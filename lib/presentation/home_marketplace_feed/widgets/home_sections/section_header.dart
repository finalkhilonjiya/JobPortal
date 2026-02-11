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
      children: [
        Expanded(
          child: Text(
            title,
            style: KhilonjiyaUI.hTitle.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        InkWell(
          onTap: onTap,
          child: Text(ctaText, style: KhilonjiyaUI.link),
        ),
      ],
    );
  }
}