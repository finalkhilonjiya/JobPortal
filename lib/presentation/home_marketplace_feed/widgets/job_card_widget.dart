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
    final experience = job['experience_required'];
    final salaryMin = job['salary_min'];
    final salaryMax = job['salary_max'];
    final skills =
        (job['skills_required'] as List?)?.join(', ') ?? '';
    final vacancies = job['vacancies'];
    final createdAt = job['created_at'];

    // TEMP FLAGS (schema later)
    final bool isInternship =
        jobTitle.toLowerCase().contains('intern');
    final bool isWalkIn =
        (job['job_type'] ?? '').toString().toLowerCase().contains('walk');

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
        padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 2.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Stack(
          children: [
            /// MAIN CONTENT
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// TITLE + LOGO
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        jobTitle,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _CompanyLogo(company: company),
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

                SizedBox(height: 1.2.h),

                /// META ROW 1
                _iconText(
                  Icons.location_on,
                  location,
                  Colors.blueGrey,
                ),

                if (experience != null) ...[
                  SizedBox(height: 0.6.h),
                  _iconText(
                    Icons.work_outline,
                    experience.toString(),
                    Colors.deepPurple,
                  ),
                ],

                if (salaryMin != null || salaryMax != null) ...[
                  SizedBox(height: 0.6.h),
                  _iconText(
                    Icons.currency_rupee,
                    _salary(salaryMin, salaryMax),
                    Colors.green.shade700,
                  ),
                ],

                /// SKILLS (SMALL)
                if (skills.isNotEmpty) ...[
                  SizedBox(height: 0.8.h),
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

                SizedBox(height: 1.4.h),

                /// TAGS + FOOTER
                Row(
                  children: [
                    if (isInternship) _tag('Internship', Colors.orange),
                    if (isWalkIn) _tag('Walk-in', Colors.blue),
                    if (vacancies != null)
                      _tag('$vacancies vacancies', Colors.grey),

                    const Spacer(),

                    Text(
                      _posted(createdAt),
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.grey.shade500,
                      ),
                    ),

                    SizedBox(width: 2.w),

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
          ],
        ),
      ),
    );
  }

  /// ================= HELPERS =================

  Widget _iconText(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        SizedBox(width: 2.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11.5.sp,
              color: Colors.grey.shade800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      margin: EdgeInsets.only(right: 1.5.w),
      padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.sp,
          color: color,
          fontWeight: FontWeight.w500,
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

  String _posted(String? dateStr) {
    if (dateStr == null) return '';
    final d = DateTime.tryParse(dateStr);
    if (d == null) return '';
    final days = DateTime.now().difference(d).inDays;
    return days == 0 ? 'Today' : '${days}d ago';
  }
}

/// ================= COMPANY LOGO =================
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
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}