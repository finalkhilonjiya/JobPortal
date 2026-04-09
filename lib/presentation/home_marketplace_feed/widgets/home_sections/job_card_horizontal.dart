import 'package:flutter/material.dart';
import '../../../../core/ui/khilonjiya_ui.dart';

class JobCardHorizontal extends StatelessWidget {
  final Map<String, dynamic> job;
  final VoidCallback onTap;

  const JobCardHorizontal({
    Key? key,
    required this.job,
    required this.onTap,
  }) : super(key: key);

  static const double cardWidth = 320;
  static const double cardHeight = 160;

  static const double _logoSize = 46;
  static const double _rightColumnWidth = 64;

  @override
  Widget build(BuildContext context) {
    final title =
        (job['job_title'] ?? job['title'] ?? 'Job').toString().trim();

    final companyMap = job['companies'];
    final companyName = (companyMap is Map<String, dynamic>)
        ? (companyMap['name'] ?? '').toString().trim()
        : '';

    final company = companyName.isNotEmpty
        ? companyName
        : (job['company_name'] ?? job['company'] ?? 'Company')
            .toString()
            .trim();

    final location = (job['district'] ??
            job['location'] ??
            job['job_address'] ??
            'Location')
        .toString()
        .trim();

    final salaryMin = job['salary_min'];
    final salaryMax = job['salary_max'];

    final salaryText = _salaryText(
      salaryMin: salaryMin,
      salaryMax: salaryMax,
    );

    final postedAt = job['created_at']?.toString();

    String businessType = "Business";

    if (companyMap is Map<String, dynamic>) {
      final bt = companyMap['business_types_master'];

      if (bt is Map<String, dynamic>) {
        final name = (bt['type_name'] ?? '').toString().trim();
        if (name.isNotEmpty) businessType = name;
      }

      if (businessType.trim().isEmpty) {
        final fallback =
            (companyMap['industry'] ?? companyMap['business_type'] ?? '')
                .toString()
                .trim();
        if (fallback.isNotEmpty) businessType = fallback;
      }
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: cardWidth,
        height: cardHeight,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LEFT CONTENT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.isEmpty ? "Job" : title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),

                  Text(
                    company.isEmpty ? "Company" : company,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF475569),
                    ),
                  ),

                  const SizedBox(height: 10),

                  _plainRow(
                    icon: Icons.location_on_outlined,
                    iconColor: const Color(0xFF2563EB),
                    text: location,
                  ),

                  const SizedBox(height: 6),

                  _plainRow(
                    icon: Icons.currency_rupee_rounded,
                    iconColor: const Color(0xFF16A34A),
                    text: salaryText,
                  ),

                  const SizedBox(height: 6),

                  _plainRow(
                    icon: Icons.work_outline,
                    iconColor: const Color(0xFF7C3AED),
                    text: (job['experience_required'] ?? '').toString().trim().isEmpty
                        ? "Experience not specified"
                        : job['experience_required'].toString().trim(),
                  ),

                  const Spacer(),

                  Text(
                    _postedAgo(postedAt),
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // ✅ REMOVED BUSINESS LOGO → KEEP SPACE CLEAN
            SizedBox(
              width: _rightColumnWidth,
            ),
          ],
        ),
      ),
    );
  }

  Widget _plainRow({
    required IconData icon,
    required Color iconColor,
    required String text,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text.trim().isEmpty ? "—" : text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF334155),
            ),
          ),
        ),
      ],
    );
  }

  String _salaryText({
    required dynamic salaryMin,
    required dynamic salaryMax,
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
    if (mn != null && mx != null) return "$mn-$mx per month";
    if (mn != null) return "$mn+ per month";
    return "Up to ${mx!} per month";
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