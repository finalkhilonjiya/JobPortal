import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';
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
        margin: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
        padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 2.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Colors.blue.withOpacity(0.03),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            /// MAIN CONTENT
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

                SizedBox(height: 0.6.h),

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
                  color: Colors.blueGrey,
                ),

                SizedBox(height: 0.6.h),

                /// EXPERIENCE
                _iconText(
                  icon: Icons.work_outline,
                  text: experience.isNotEmpty
                      ? experience
                      : 'Experience not specified',
                  color: Colors.deepPurple,
                ),

                if (salaryMin != null || salaryMax != null) ...[
                  SizedBox(height: 0.6.h),
                  _iconText(
                    icon: Icons.currency_rupee,
                    text: _formatSalary(salaryMin, salaryMax),
                    color: Colors.green.shade700,
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

                SizedBox(height: 1.4.h),

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

            /// COMPANY LOGO (TOP RIGHT – SUBTLE)
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

  /// ---------------- HELPERS ----------------

  Widget _iconText({
    required IconData icon,
    required String text,
    required Color color,
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

/// ---------------- LOGO ----------------

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
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}