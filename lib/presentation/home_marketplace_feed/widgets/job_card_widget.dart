import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class JobCardWidget extends StatelessWidget {
  final Map<String, dynamic> job;
  final bool isSaved;
  final VoidCallback onSaveToggle;
  final VoidCallback onTap;

  const JobCardWidget({
    Key? key,
    required this.job,
    required this.isSaved,
    required this.onSaveToggle,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final jobTitle = job['job_title'] ?? '';
    final company = job['company_name'] ?? '';
    final location = job['district'] ?? '';
    final experience = job['experience_required'] ?? '';
    final salaryMin = job['salary_min'];
    final salaryMax = job['salary_max'];
    final skills = (job['skills_required'] as List?)?.join(', ') ?? '';
    final createdAt = job['created_at'];

    // Optional / conditional
    final vacancies = job['vacancies']; // int?
    final jobType = job['job_type']; // internship / fulltime / etc
    final walkIn = job['walk_in'] == true;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ───────── HEADER ─────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        jobTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 0.6.h),
                      Text(
                        company,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),

                /// LOGO
                _CompanyLogo(company: company),
              ],
            ),

            SizedBox(height: 1.4.h),

            /// ───────── META INFO ─────────
            _iconRow(
              Icons.location_on_outlined,
              location,
              Colors.blueGrey,
            ),
            SizedBox(height: 0.6.h),
            _iconRow(
              Icons.work_outline,
              experience.isNotEmpty ? experience : 'Experience not specified',
              Colors.indigo,
            ),
            if (salaryMin != null || salaryMax != null) ...[
              SizedBox(height: 0.6.h),
              _iconRow(
                Icons.currency_rupee,
                _formatSalary(salaryMin, salaryMax),
                Colors.green.shade700,
              ),
            ],

            /// ───────── SKILLS ─────────
            if (skills.isNotEmpty) ...[
              SizedBox(height: 1.h),
              Text(
                skills,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.8.sp,
                  color: Colors.grey.shade600,
                ),
              ),
            ],

            SizedBox(height: 1.4.h),

            /// ───────── TAGS ─────────
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (jobType == 'internship')
                  _tag(
                    'Internship',
                    bg: Colors.orange.shade50,
                    fg: Colors.orange.shade700,
                  ),
                if (vacancies != null)
                  _tag(
                    '$vacancies vacancies',
                    bg: Colors.blue.shade50,
                    fg: Colors.blue.shade700,
                  ),
                if (walkIn)
                  _tag(
                    'Walk-in',
                    bg: Colors.green.shade50,
                    fg: Colors.green.shade700,
                  ),
              ],
            ),

            SizedBox(height: 1.4.h),

            /// ───────── FOOTER ─────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(createdAt),
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.grey.shade500,
                  ),
                ),
                InkWell(
                  onTap: onSaveToggle,
                  child: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    size: 20,
                    color:
                        isSaved ? Colors.blue : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// ───────── HELPERS ─────────

  Widget _iconRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        SizedBox(width: 2.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11.5.sp,
              color: Colors.grey.shade800,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _tag(String text, {required Color bg, required Color fg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.sp,
          color: fg,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatSalary(int? min, int? max) {
    String f(int v) =>
        v >= 100000 ? '${(v / 100000).toStringAsFixed(1)} Lacs PA' : '₹$v';
    if (min != null && max != null) return '${f(min)} - ${f(max)}';
    if (min != null) return f(min);
    if (max != null) return f(max);
    return 'Not disclosed';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Recently';
    final d = DateTime.tryParse(dateStr);
    if (d == null) return 'Recently';
    final diff = DateTime.now().difference(d).inDays;
    return diff == 0 ? 'Today' : '${diff}d ago';
  }
}

/// ───────── LOGO PLACEHOLDER ─────────
class _CompanyLogo extends StatelessWidget {
  final String company;
  const _CompanyLogo({required this.company});

  @override
  Widget build(BuildContext context) {
    final letter =
        company.isNotEmpty ? company[0].toUpperCase() : 'C';

    final color = Colors.primaries[
        Random(company.hashCode).nextInt(Colors.primaries.length)];

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}