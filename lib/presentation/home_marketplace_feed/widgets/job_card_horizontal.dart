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

    final exp = (job['experience_level'] ?? job['experience'] ?? 'Experience')
        .toString();

    final salaryMin = job['salary_min'];
    final salaryMax = job['salary_max'];

    String salaryText = "Salary";
    if (salaryMin != null || salaryMax != null) {
      salaryText = "₹${salaryMin ?? ''}-${salaryMax ?? ''}";
    }

    return InkWell(
      onTap: onTap,
      borderRadius: KhilonjiyaUI.r16,
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 12),
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
            // Header row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: KhilonjiyaUI.border),
                  ),
                  child: const Icon(
                    Icons.business_outlined,
                    color: Color(0xFF334155),
                    size: 22,
                  ),
                ),
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
                          fontSize: 13.8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        company,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: KhilonjiyaUI.sub.copyWith(fontSize: 12.4),
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

            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _pill(Icons.location_on_outlined, location),
                _pill(Icons.work_outline, exp),
                _pill(Icons.currency_rupee, salaryText),
              ],
            ),

            const Spacer(),

            Row(
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
                    "Early access",
                    style: KhilonjiyaUI.sub.copyWith(
                      fontSize: 11.5,
                      color: KhilonjiyaUI.primary,
                      fontWeight: FontWeight.w800,
                    ),
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

  Widget _pill(IconData icon, String text) {
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
            constraints: const BoxConstraints(maxWidth: 150),
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
}