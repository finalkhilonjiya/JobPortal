import 'package:flutter/material.dart';
import '../../../core/ui/khilonjiya_ui.dart';

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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: KhilonjiyaUI.cardDecoration(radius: KhilonjiyaUI.r16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Container(
                  width: 46,
                  height: 46,
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
                const SizedBox(width: 12),

                // Title + company
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: KhilonjiyaUI.cardTitle.copyWith(fontSize: 14.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        company,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: KhilonjiyaUI.sub.copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                InkWell(
                  onTap: onSaveToggle,
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_border,
                      size: 22,
                      color: isSaved ? KhilonjiyaUI.primary : KhilonjiyaUI.muted,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Rating + category pills (static for now)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _smallPill(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 14, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 4),
                      Text(
                        "4.2 (1.2k)",
                        style: KhilonjiyaUI.sub.copyWith(
                          fontSize: 12,
                          color: KhilonjiyaUI.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                _smallPill(
                  child: Text(
                    "Corporate",
                    style: KhilonjiyaUI.sub.copyWith(
                      fontSize: 12,
                      color: KhilonjiyaUI.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Details
            _detailRow(Icons.location_on_outlined, location),
            const SizedBox(height: 6),
            _detailRow(Icons.work_outline, experience),
            const SizedBox(height: 6),
            _detailRow(Icons.currency_rupee, salary),

            const SizedBox(height: 14),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  posted,
                  style: KhilonjiyaUI.sub.copyWith(fontSize: 12),
                ),
                Text(
                  "View",
                  style: KhilonjiyaUI.link.copyWith(fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: KhilonjiyaUI.muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: KhilonjiyaUI.sub.copyWith(fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _smallPill({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: KhilonjiyaUI.border),
      ),
      child: child,
    );
  }
}