import 'package:flutter/material.dart';
import '../../../../core/ui/khilonjiya_ui.dart';

class BoostCard extends StatelessWidget {
  final String boostLabel; // ex: "Boost 2%"
  final String title;
  final String subtitle;
  final String buttonText;

  final int dotsCount;
  final int activeDotIndex;

  final VoidCallback? onPressed;

  const BoostCard({
    Key? key,
    required this.boostLabel,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    this.dotsCount = 5,
    this.activeDotIndex = 1,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final safeDots = dotsCount.clamp(3, 7);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Container(
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
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFDCEBFF)),
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
                  Text(
                    title,
                    style: KhilonjiyaUI.cardTitle,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: KhilonjiyaUI.sub,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: List.generate(safeDots, (i) {
                      final active = i == activeDotIndex.clamp(0, safeDots - 1);
                      return Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: active
                              ? KhilonjiyaUI.primary
                              : const Color(0xFFD6DCE6),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: KhilonjiyaUI.text,
                side: const BorderSide(color: KhilonjiyaUI.border),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: KhilonjiyaUI.body.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }
}