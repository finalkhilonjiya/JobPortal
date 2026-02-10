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
        width: 270,
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
            // Logo + Save
            Row(
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
                  ),
                ),
                const Spacer(),
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

            const SizedBox(height: 10),

            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: KhilonjiyaUI.cardTitle.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),

            Text(
              company,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: KhilonjiyaUI.sub.copyWith(fontSize: 12.5),
            ),

            const SizedBox(height: 10),

            _metaRow(Icons.location_on_outlined, location),
            const SizedBox(height: 6),
            _metaRow(Icons.work_outline, exp),
            const SizedBox(height: 6),
            _metaRow(Icons.currency_rupee, salaryText),

            const Spacer(),

            const SizedBox(height: 10),

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
    );
  }

  Widget _metaRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: KhilonjiyaUI.sub.copyWith(fontSize: 12.2),
          ),
        ),
      ],
    );
  }
}