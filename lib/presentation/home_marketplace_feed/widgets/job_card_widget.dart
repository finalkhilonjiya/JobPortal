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
    final createdAt = job['created_at'];
    final skills = (job['skills_required'] as List?)?.join(', ') ?? '';

    return InkWell(
      onTap: onTap,
      child: Container(
        color: Colors.white,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// subtle professional anchor (NOT a border)
            Container(
              width: 2,
              height: double.infinity,
              color: Colors.blue.shade100,
            ),

            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(4.w, 1.6.h, 4.w, 1.6.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Job title
                    Text(
                      jobTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade900,
                        height: 1.25,
                      ),
                    ),

                    SizedBox(height: 0.4.h),

                    /// Company
                    Text(
                      company,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey.shade700,
                      ),
                    ),

                    SizedBox(height: 0.9.h),

                    /// Meta block (grouped, not scattered)
                    _metaRow(Icons.location_on_outlined, location),
                    _metaRow(Icons.work_outline, experience),
                    if (salaryMin != null || salaryMax != null)
                      _metaRow(
                        Icons.currency_rupee,
                        _formatSalary(salaryMin, salaryMax),
                      ),

                    if (skills.isNotEmpty) ...[
                      SizedBox(height: 0.8.h),
                      Text(
                        skills,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],

                    SizedBox(height: 1.2.h),

                    /// Footer (visually grounded)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDate(createdAt),
                          style: TextStyle(
                            fontSize: 10.5.sp,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        Text(
                          'Hide',
                          style: TextStyle(
                            fontSize: 10.5.sp,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaRow(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 0.4.h),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade500),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11.5.sp,
                color: Colors.grey.shade700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatSalary(int? min, int? max) {
    String f(int v) => '${(v / 100000).toStringAsFixed(1)} Lacs PA';
    if (min != null && max != null) return '${f(min)} – ${f(max)}';
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