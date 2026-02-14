// File: lib/presentation/home_marketplace_feed/widgets/home_sections/job_card_horizontal.dart

import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/ui/khilonjiya_ui.dart';

class JobCardHorizontal extends StatelessWidget {
  final Map<String, dynamic> job;
  final bool isSaved;
  final VoidCallback onSaveToggle;
  final VoidCallback onTap;

  const JobCardHorizontal({
    Key? key,
    required this.job,
    required this.isSaved,
    required this.onSaveToggle,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final title = (job['job_title'] ?? job['title'] ?? 'Job').toString();
    final company = (job['company_name'] ?? job['company'] ?? 'Company')
        .toString();

    final location = (job['district'] ?? job['location'] ?? 'Location')
        .toString();

    final experience = (job['experience_required'] ??
            job['experience_level'] ??
            job['experience'] ??
            'Experience not specified')
        .toString();

    final salaryMin = job['salary_min'];
    final salaryMax = job['salary_max'];
    final salaryPeriodRaw = (job['salary_period'] ?? 'Monthly').toString();

    final skillsList = (job['skills_required'] as List?)?.cast<dynamic>() ?? [];
    final skillsText = skillsList.map((e) => e.toString()).join(', ');

    final vacancies = job['vacancies'];
    final postedAt = job['created_at']?.toString();

    final isInternship =
        (job['employment_type'] ?? '').toString().toLowerCase().contains('intern');
    final isWalkIn =
        (job['job_type'] ?? '').toString().toLowerCase().contains('walk');

    final salaryText = _salaryMonthly(
      salaryMin: salaryMin,
      salaryMax: salaryMax,
      salaryPeriod: salaryPeriodRaw,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: KhilonjiyaUI.r16,
      child: Container(
        width: 300, // important for horizontal list
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
            // HEADER
            // ------------------------------------------------------------
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CompanyLogo(company: company, size: 48),
                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: KhilonjiyaUI.cardTitle.copyWith(
                          fontSize: 14.2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        company,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: KhilonjiyaUI.sub.copyWith(fontSize: 12.6),
                      ),
                    ],
                  ),
                ),

                InkWell(
                  onTap: onSaveToggle,
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline,
                      size: 22,
                      color: isSaved
                          ? KhilonjiyaUI.primary
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ------------------------------------------------------------
            // TAGS
            // ------------------------------------------------------------
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (isInternship) _tagPill("Internship"),
                if (isWalkIn) _tagPill("Walk-in"),
                if (vacancies != null) _tagPill("$vacancies Vacancies"),
              ],
            ),

            if (isInternship || isWalkIn || vacancies != null)
              const SizedBox(height: 10),

            // ------------------------------------------------------------
            // META PILLS
            // ------------------------------------------------------------
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _pill(Icons.location_on_outlined, location, maxWidth: 160),
                _pill(Icons.work_outline, experience, maxWidth: 160),
                _pill(Icons.currency_rupee, salaryText, maxWidth: 200),
              ],
            ),

            // ------------------------------------------------------------
            // SKILLS
            // ------------------------------------------------------------
            if (skillsText.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                skillsText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: KhilonjiyaUI.sub.copyWith(
                  fontSize: 12.2,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],

            const Spacer(),

            // ------------------------------------------------------------
            // FOOTER
            // ------------------------------------------------------------
            Row(
              children: [
                Text(
                  _postedAgo(postedAt),
                  style: KhilonjiyaUI.sub.copyWith(
                    fontSize: 12.2,
                    color: const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward,
                  size: 18,
                  color: KhilonjiyaUI.muted,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // UI HELPERS (same as JobCardWidget)
  // ------------------------------------------------------------
  Widget _pill(
    IconData icon,
    String text, {
    double maxWidth = 160,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: KhilonjiyaUI.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF64748B)),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: KhilonjiyaUI.sub.copyWith(fontSize: 12.0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tagPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: KhilonjiyaUI.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: KhilonjiyaUI.primary.withOpacity(0.12)),
      ),
      child: Text(
        text,
        style: KhilonjiyaUI.sub.copyWith(
          fontSize: 12.0,
          fontWeight: FontWeight.w800,
          color: KhilonjiyaUI.primary,
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // SALARY (FORCE MONTHLY)
  // ------------------------------------------------------------
  String _salaryMonthly({
    required dynamic salaryMin,
    required dynamic salaryMax,
    required String salaryPeriod,
  }) {
    int? toInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is double) return v.toInt();
      return int.tryParse(v.toString());
    }

    final mn = toInt(salaryMin);
    final mx = toInt(salaryMax);

    if (mn == null && mx == null) return "Not disclosed";

    String fmt(int v) {
      return v.toString().replaceAllMapped(
            RegExp(r'\B(?=(\d{3})+(?!\d))'),
            (m) => ',',
          );
    }

    final range = (mn != null && mx != null)
        ? "₹${fmt(mn)} - ₹${fmt(mx)}"
        : (mn != null)
            ? "₹${fmt(mn)}+"
            : "Up to ₹${fmt(mx!)}";

    return "$range / month";
  }

  String _postedAgo(String? date) {
    if (date == null) return 'Recently';

    final d = DateTime.tryParse(date);
    if (d == null) return 'Recently';

    final diff = DateTime.now().difference(d);

    if (diff.inMinutes < 2) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return '1d ago';
    return '${diff.inDays}d ago';
  }
}

// ------------------------------------------------------------
// COMPANY LOGO (LEFT) - SAME STYLE AS JobCardWidget
// ------------------------------------------------------------
class _CompanyLogo extends StatelessWidget {
  final String company;
  final double size;

  const _CompanyLogo({
    required this.company,
    this.size = 52,
  });

  @override
  Widget build(BuildContext context) {
    final letter = company.isNotEmpty ? company[0].toUpperCase() : 'C';
    final color = Colors.primaries[
        Random(company.hashCode).nextInt(Colors.primaries.length)];

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KhilonjiyaUI.border),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          fontSize: size * 0.38,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}