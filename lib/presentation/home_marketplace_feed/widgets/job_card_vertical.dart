import 'package:flutter/material.dart';
import '../../../../core/ui/khilonjiya_ui.dart';

class JobCardVertical extends StatelessWidget {
  final Map<String, dynamic> job;
  final bool isSaved;
  final VoidCallback onSaveToggle;
  final VoidCallback onTap;

  const JobCardVertical({
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

    String salaryText = "Salary not disclosed";
    if (salaryMin != null || salaryMax != null) {
      salaryText = "₹${salaryMin ?? ''} - ₹${salaryMax ?? ''}";
    }

    final posted = (job['created_at'] ?? '').toString().isEmpty
        ? "Posted recently"
        : "Posted";

    return InkWell(
      onTap: onTap,
      borderRadius: KhilonjiyaUI.r16,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: KhilonjiyaUI.border),
              ),
              child: const Icon(
                Icons.business_outlined,
                color: Color(0xFF334155),
              ),
            ),

            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: KhilonjiyaUI.cardTitle.copyWith(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: onSaveToggle,
                        borderRadius: BorderRadius.circular(999),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            isSaved
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_outline,
                            size: 22,
                            color: isSaved
                                ? KhilonjiyaUI.primary
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Text(
                    company,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KhilonjiyaUI.sub.copyWith(fontSize: 12.8),
                  ),

                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    children: [
                      _pill(
                        icon: Icons.location_on_outlined,
                        text: location,
                      ),
                      _pill(
                        icon: Icons.work_outline,
                        text: exp,
                      ),
                      _pill(
                        icon: Icons.currency_rupee,
                        text: salaryText,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Text(
                        posted,
                        style: KhilonjiyaUI.sub.copyWith(
                          fontSize: 11.5,
                          color: const Color(0xFF94A3B8),
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
          ],
        ),
      ),
    );
  }

  Widget _pill({
    required IconData icon,
    required String text,
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
            constraints: const BoxConstraints(maxWidth: 170),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: KhilonjiyaUI.sub.copyWith(fontSize: 12.2),
            ),
          ),
        ],
      ),
    );
  }
}