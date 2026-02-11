import 'package:flutter/material.dart';
import '../../../../core/ui/khilonjiya_ui.dart';

class CompanyCard extends StatelessWidget {
  final Map<String, dynamic> company;
  final VoidCallback? onTap;

  const CompanyCard({
    Key? key,
    required this.company,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final name = (company["name"] ?? "").toString();
    final rating = (company["rating"] ?? 0).toString();
    final reviews = (company["reviews"] ?? "").toString();
    final tag = (company["tag"] ?? "").toString();

    return InkWell(
      onTap: onTap,
      borderRadius: KhilonjiyaUI.r16,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: KhilonjiyaUI.cardDecoration(radius: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo placeholder
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: KhilonjiyaUI.border),
              ),
              child: const Icon(Icons.business_outlined),
            ),
            const SizedBox(height: 10),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: KhilonjiyaUI.cardTitle,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star_rounded,
                    size: 16, color: Color(0xFFF59E0B)),
                const SizedBox(width: 4),
                Text(
                  rating,
                  style: KhilonjiyaUI.body.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  "($reviews)",
                  style: KhilonjiyaUI.sub,
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: KhilonjiyaUI.border),
              ),
              child: Text(
                tag,
                style: KhilonjiyaUI.caption.copyWith(
                  color: const Color(0xFF334155),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "View jobs",
              style: KhilonjiyaUI.link,
            ),
          ],
        ),
      ),
    );
  }
}