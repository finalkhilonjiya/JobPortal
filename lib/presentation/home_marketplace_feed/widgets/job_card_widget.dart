import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'dart:math';

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
    final createdAt = job['created_at'];
    final skills = (job['skills_required'] as List?)?.join(', ') ?? '';

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.6.h),
        padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 2.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            /// CONTENT
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// JOB TITLE
                Text(
                  jobTitle,
                  style: TextStyle(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: 0.5.h),

                /// COMPANY
                Text(
                  company,
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    color: Colors.grey.shade700,
                  ),
                ),

                SizedBox(height: 1.h),

                /// LOCATION
                _iconText(
                  icon: Icons.location_on_outlined,
                  text: location,
                  iconColor: Colors.blueGrey,
                ),

                SizedBox(height: 0.5.h),

                /// EXPERIENCE
                _iconText(
                  icon: Icons.work_outline,
                  text: experience.isNotEmpty
                      ? experience
                      : 'Experience not specified',
                  iconColor: Colors.deepPurple,
                ),

                if (salaryMin != null || salaryMax != null) ...[
                  SizedBox(height: 0.5.h),
                  _iconText(
                    icon: Icons.currency_rupee,
                    text: _formatSalary(salaryMin, salaryMax),
                    iconColor: Colors.green.shade700,
                  ),
                ],

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

                SizedBox(height: 1.2.h),

                /// FOOTER
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

            /// COMPANY LOGO (SUBTLE, TOP-RIGHT)
            Positioned(
              top: 0,
              right: 0,
              child: _CompanyLogo(company: company),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconText({
    required IconData icon,
    required String text,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
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
    return diff == 0 ? 'Today' : '$diff d ago';
  }
}

/// COMPANY LOGO PLACEHOLDER
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
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}