import 'package:flutter/material.dart';
import '../../../../core/ui/khilonjiya_ui.dart';

class CompanyCard extends StatelessWidget {
  final String name;
  final String tag;
  final double rating;
  final int reviews;
  final String? logoUrl;
  final VoidCallback? onViewJobs;

  const CompanyCard({
    Key? key,
    required this.name,
    required this.tag,
    required this.rating,
    required this.reviews,
    this.logoUrl,
    this.onViewJobs,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: KhilonjiyaUI.cardDecoration(radius: 16),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// logo
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: KhilonjiyaUI.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: (logoUrl == null || logoUrl!.trim().isEmpty)
                  ? const Icon(
                      Icons.business_outlined,
                      color: Color(0xFF6B7280),
                    )
                  : Image.network(
                      logoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.business_outlined,
                        color: Color(0xFF6B7280),
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 10),

          Text(
            name,
            style: KhilonjiyaUI.cardTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 8),

          /// rating row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: KhilonjiyaUI.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 14, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
                      style: KhilonjiyaUI.sub.copyWith(
                        fontWeight: FontWeight.w800,
                        color: KhilonjiyaUI.text,
                      ),
                    ),
                    Text(
                      " ($reviews)",
                      style: KhilonjiyaUI.sub,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          /// tag pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFDBEAFE)),
            ),
            child: Text(
              tag,
              style: KhilonjiyaUI.sub.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1D4ED8),
              ),
            ),
          ),

          const Spacer(),

          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onViewJobs,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text("View jobs", style: KhilonjiyaUI.link),
            ),
          ),
        ],
      ),
    );
  }
}