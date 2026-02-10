import 'package:flutter/material.dart';
import '../../../../core/ui/khilonjiya_ui.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String actionText;
  final VoidCallback? onAction;

  const SectionHeader({
    Key? key,
    required this.title,
    this.actionText = "View all",
    this.onAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: KhilonjiyaUI.h2.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onAction,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Text(
                actionText,
                style: KhilonjiyaUI.link,
              ),
            ),
          ),
        ],
      ),
    );
  }
}