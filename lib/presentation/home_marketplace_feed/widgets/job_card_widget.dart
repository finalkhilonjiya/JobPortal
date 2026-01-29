import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

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
    final rating = job['rating'];
    final reviews = job['total_reviews'];

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.6.h),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Job title
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

            SizedBox(height: 0.4.h),

            /// Company name
            Text(
              company,
              style: TextStyle(
                fontSize: 11.5.sp,
                color: Colors.grey.shade700,
              ),
            ),

            SizedBox(height: 0.6.h),

            /// Rating (optional)
            if (rating != null && reviews != null)
              Row(
                children: [
                  Icon(Icons.star, size: 14, color: Colors.orange),
                  SizedBox(width: 1.w),
                  Text(
                    '$rating ($reviews Reviews)',
                    style: TextStyle(fontSize: 10.5.sp, color: Colors.grey.shade600),
                  ),
                ],
              ),

            if (rating != null) SizedBox(height: 0.6.h),

            /// Location
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 15, color: Colors.grey),
                SizedBox(width: 1.w),
                Expanded(
                  child: Text(
                    location,
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            SizedBox(height: 0.5.h),

            /// Experience
            Row(
              children: [
                Icon(Icons.work_outline, size: 15, color: Colors.grey),
                SizedBox(width: 1.w),
                Text(
                  experience.isNotEmpty ? experience : 'Experience not specified',
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade700),
                ),
              ],
            ),

            /// Salary (optional, same line style as Naukri)
            if (salaryMin != null || salaryMax != null) ...[
              SizedBox(height: 0.5.h),
              Row(
                children: [
                  Icon(Icons.currency_rupee, size: 15, color: Colors.grey),
                  SizedBox(width: 1.w),
                  Text(
                    _formatSalary(salaryMin, salaryMax),
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ],

            /// Skills (plain text, NOT tags)
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

            SizedBox(height: 1.h),

            /// Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(createdAt),
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade500),
                ),
                Text(
                  'Hide',
                  style: TextStyle(fontSize: 10.5.sp, color: Colors.grey.shade500),
                ),
              ],
            ),

            SizedBox(height: 1.6.h),

            /// Divider (Naukri-style)
            Divider(height: 1, color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }

  String _formatSalary(int? min, int? max) {
    String f(int v) => v >= 100000 ? '${(v / 100000).toStringAsFixed(1)} Lacs PA' : '₹$v';
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
