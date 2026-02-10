import 'package:flutter/material.dart';
import '../../../core/ui/khilonjiya_ui.dart';

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

  String _s(dynamic v) => (v ?? '').toString();

  @override
  Widget build(BuildContext context) {
    final title = _s(job['title']).isEmpty ? 'Job Title' : _s(job['title']);
    final company =
        _s(job['company_name']).isEmpty ? 'Company' : _s(job['company_name']);
    final location =
        _s(job['location']).isEmpty ? 'Location' : _s(job['location']);
    final experience =
        _s(job['experience']).isEmpty ? '0-2 yrs' : _s(job['experience']);
    final salary = _s(job['salary']).isEmpty ? 'Not disclosed' : _s(job['salary']);
    final posted = _s(job['posted_time']).isEmpty ? '1d ago' : _s(job['posted_time']);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(14),
        decoration: KhilonjiyaUI.cardDecoration(radius: KhilonjiyaUI.r16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: KhilonjiyaUI.border),
                  ),
                  child: const Icon(
                    Icons.business_outlined,
                    color: Color(0xFF64748B),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),

                // Title + company
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: KhilonjiyaUI.cardTitle.copyWith(fontSize: 13.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        company,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: KhilonjiyaUI.sub,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Save
                InkWell(
                  onTap: onSaveToggle,
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_border,
                      size: 20,
                      color: isSaved ? KhilonjiyaUI.primary : KhilonjiyaUI.muted,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Pills row
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _pill(
                  icon: Icons.location_on_outlined,
                  text: location,
                ),
                _pill(
                  icon: Icons.work_outline,
                  text: experience,
                ),
                _pill(
                  icon: Icons.currency_rupee,
                  text: salary,
                ),
              ],
            ),

            const Spacer(),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  posted,
                  style: KhilonjiyaUI.sub.copyWith(fontSize: 11.5),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Text(
                    "Apply",
                    style: KhilonjiyaUI.link.copyWith(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill({required IconData icon, required String text}) {
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
          Icon(icon, size: 14, color: KhilonjiyaUI.muted),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: KhilonjiyaUI.sub.copyWith(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}