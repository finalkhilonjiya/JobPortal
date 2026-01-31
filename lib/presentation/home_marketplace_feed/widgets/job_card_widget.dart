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
    final title = job['job_title'] ?? '';
    final company = job['company_name'] ?? '';
    final location = job['district'] ?? '';
    final experience = job['experience_required'] ?? '';
    final salaryMin = job['salary_min'];
    final salaryMax = job['salary_max'];
    final skills = (job['skills_required'] as List?)?.join(', ') ?? '';
    final vacancies = job['vacancies'];
    final postedAt = job['created_at'];

    /// TEMP LOGIC (schema-safe)
    final isInternship =
        (job['employment_type'] ?? '').toString().toLowerCase().contains('intern');
    final isWalkIn =
        (job['job_type'] ?? '').toString().toLowerCase().contains('walk');

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER ROW
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                _CompanyLogo(company: company, size: 42),
              ],
            ),

            SizedBox(height: 0.4.h),

            /// COMPANY
            Text(
              company,
              style: TextStyle(
                fontSize: 11.5.sp,
                color: Colors.grey.shade700,
              ),
            ),

            SizedBox(height: 0.8.h),

            /// TAGS
            Wrap(
              spacing: 2.w,
              runSpacing: 0.6.h,
              children: [
                if (isInternship) _tag('Internship', Colors.orange),
                if (isWalkIn) _tag('Walk-in', Colors.green),
                if (vacancies != null)
                  _tag('$vacancies Vacancies', Colors.blueGrey),
              ],
            ),

            SizedBox(height: 1.h),

            /// META ROW
            _metaRow(
              icon: Icons.location_on,
              color: Colors.blue,
              text: location,
            ),
            SizedBox(height: 0.4.h),
            _metaRow(
              icon: Icons.work_outline,
              color: Colors.deepPurple,
              text: experience.isNotEmpty
                  ? experience
                  : 'Experience not specified',
            ),
            if (salaryMin != null || salaryMax != null) ...[
              SizedBox(height: 0.4.h),
              _metaRow(
                icon: Icons.currency_rupee,
                color: Colors.green,
                text: _salary(salaryMin, salaryMax),
              ),
            ],

            /// SKILLS
            if (skills.isNotEmpty) ...[
              SizedBox(height: 1.h),
              Text(
                skills,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5.sp,
                  color: Colors.grey.shade600,
                ),
              ),
            ],

            SizedBox(height: 1.2.h),

            /// FOOTER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _postedAgo(postedAt),
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.grey.shade500,
                  ),
                ),
                InkWell(
                  onTap: onSaveToggle,
                  child: Icon(
                    isSaved
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    size: 18,
                    color: isSaved
                        ? Colors.blue
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// ---------------- HELPERS ----------------

  Widget _metaRow({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        SizedBox(width: 2.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.grey.shade800,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5.sp,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  String _salary(int? min, int? max) {
    String f(int v) =>
        '${(v / 100000).toStringAsFixed(1)} Lacs PA';
    if (min != null && max != null) return '${f(min)} - ${f(max)}';
    if (min != null) return f(min);
    return 'Not disclosed';
  }

  String _postedAgo(String? dateStr) {
    if (dateStr == null) return 'Recently';
    final d = DateTime.tryParse(dateStr);
    if (d == null) return 'Recently';
    final days = DateTime.now().difference(d).inDays;
    return days == 0 ? 'Today' : '$days d ago';
  }
}

/// COMPANY LOGO PLACEHOLDER
class _CompanyLogo extends StatelessWidget {
  final String company;
  final double size;

  const _CompanyLogo({
    required this.company,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final letter =
        company.isNotEmpty ? company[0].toUpperCase() : 'C';

    final color = Colors.primaries[
        Random(company.hashCode).nextInt(Colors.primaries.length)];

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          fontSize: size / 2.1,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}