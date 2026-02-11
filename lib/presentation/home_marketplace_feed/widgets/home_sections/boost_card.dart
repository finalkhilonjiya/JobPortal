import 'package:flutter/material.dart';
import '../../../../core/ui/khilonjiya_ui.dart';

class BoostCard extends StatelessWidget {
  final String boostLabel;
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback? onTap;

  const BoostCard({
    Key? key,
    this.boostLabel = "Boost 2%",
    this.title = "Personal details help recruiters know more about you",
    this.subtitle = "Add a few missing details to improve visibility.",
    this.buttonText = "Add details",
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: KhilonjiyaUI.cardDecoration(radius: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFDBEAFE)),
                  ),
                  child: Text(
                    boostLabel,
                    style: KhilonjiyaUI.caption.copyWith(
                      color: KhilonjiyaUI.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(title, style: KhilonjiyaUI.cardTitle),
                const SizedBox(height: 6),
                Text(subtitle, style: KhilonjiyaUI.sub),
                const SizedBox(height: 12),
                Row(
                  children: List.generate(
                    4,
                    (i) => Container(
                      margin: const EdgeInsets.only(right: 6),
                      width: i == 0 ? 18 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == 0
                            ? KhilonjiyaUI.primary
                            : const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: KhilonjiyaUI.text,
              side: BorderSide(color: KhilonjiyaUI.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            child: Text(
              buttonText,
              style: KhilonjiyaUI.body.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}