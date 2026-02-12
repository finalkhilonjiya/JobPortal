// File: lib/presentation/home_marketplace_feed/widgets/home_sections/company_card.dart

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
    final name = (company['name'] ?? 'Company').toString().trim();

    final logoUrl = (company['logo_url'] ?? '').toString().trim();

    final industry = (company['industry'] ?? '').toString().trim();
    final size = (company['company_size'] ?? '').toString().trim();

    final rating = _toDouble(company['rating']);
    final totalReviews = _toInt(company['total_reviews']);
    final totalJobs = _toInt(company['total_jobs']);

    final isVerified = company['is_verified'] == true;

    final subtitle = _subtitleText(industry: industry, size: size);

    return InkWell(
      onTap: onTap,
      borderRadius: KhilonjiyaUI.r16,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: KhilonjiyaUI.r16,
          border: Border.all(color: KhilonjiyaUI.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ------------------------------------------------------------
            // TOP ROW: LOGO + NAME + VERIFIED
            // ------------------------------------------------------------
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CompanyLogo(
                  logoUrl: logoUrl,
                  name: name,
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: KhilonjiyaUI.cardTitle.copyWith(
                                fontSize: 14.2,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          if (isVerified) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(999),
                                border:
                                    Border.all(color: const Color(0xFFDBEAFE)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.verified_rounded,
                                    size: 14,
                                    color: KhilonjiyaUI.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Verified",
                                    style: KhilonjiyaUI.caption.copyWith(
                                      fontSize: 11.2,
                                      color: KhilonjiyaUI.primary,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 6),

                      Text(
                        subtitle.isEmpty ? "Company" : subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: KhilonjiyaUI.sub.copyWith(
                          fontSize: 12.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ------------------------------------------------------------
            // RATING ROW
            // ------------------------------------------------------------
            Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  size: 18,
                  color: Color(0xFFF59E0B),
                ),
                const SizedBox(width: 4),
                Text(
                  rating <= 0 ? "New" : rating.toStringAsFixed(1),
                  style: KhilonjiyaUI.body.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  totalReviews <= 0 ? "(0 reviews)" : "($totalReviews reviews)",
                  style: KhilonjiyaUI.sub.copyWith(
                    fontSize: 12.0,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),

            const Spacer(),

            // ------------------------------------------------------------
            // FOOTER: JOBS COUNT + CTA
            // ------------------------------------------------------------
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: KhilonjiyaUI.border),
                  ),
                  child: Text(
                    totalJobs <= 0 ? "0 jobs" : "$totalJobs jobs",
                    style: KhilonjiyaUI.caption.copyWith(
                      fontSize: 11.8,
                      color: const Color(0xFF334155),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Text(
                      "View jobs",
                      style: KhilonjiyaUI.link.copyWith(
                        fontSize: 12.6,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: KhilonjiyaUI.primary,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // HELPERS
  // ------------------------------------------------------------

  String _subtitleText({
    required String industry,
    required String size,
  }) {
    final parts = <String>[];

    if (industry.trim().isNotEmpty) parts.add(industry.trim());
    if (size.trim().isNotEmpty) parts.add(size.trim());

    return parts.join(" • ");
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}

class _CompanyLogo extends StatelessWidget {
  final String logoUrl;
  final String name;

  const _CompanyLogo({
    required this.logoUrl,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    final letter = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : "C";

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KhilonjiyaUI.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: logoUrl.isEmpty
          ? Center(
              child: Text(
                letter,
                style: KhilonjiyaUI.h1.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF334155),
                ),
              ),
            )
          : Image.network(
              logoUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Center(
                  child: Text(
                    letter,
                    style: KhilonjiyaUI.h1.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF334155),
                    ),
                  ),
                );
              },
            ),
    );
  }
}