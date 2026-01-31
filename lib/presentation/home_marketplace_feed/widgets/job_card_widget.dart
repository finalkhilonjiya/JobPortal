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
    final experience = job['experience_required'] ?? '0 Yrs';
    final salaryMin = job['salary_min'];
    final salaryMax = job['salary_max'];
    final skills = (job['skills_required'] as List?)?.join(', ') ?? '';

    final vacancies = job['vacancies'];
    final isWalkIn = job['is_walk_in'] == true;
    final rating = job['company_rating'];
    final reviews = job['company_reviews'];
    final createdAt = job['created_at'];

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.8.h),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// TOP ROW
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// TITLE + COMPANY
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 0.4.h),
                      Text(
                        company,
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          color: Colors.grey.shade700,
                        ),
                      ),

                      /// RATING
                      if (rating != null) ...[
                        SizedBox(height: 0.5.h),
                        Row(
                          children: [
                            const Icon(Icons.star,
                                size: 14, color: Colors.orange),
                            SizedBox(width: 1.w),
                            Text(
                              '$rating',
                              style: TextStyle(
                                fontSize: 10.5.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (reviews != null)
                              Text(
                                ' ($reviews Reviews)',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                /// LOGO (BIGGER)
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    company.isNotEmpty ? company[0].toUpperCase() : 'C',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 1.2.h),

            /// META INFO
            _row(Icons.location_on_outlined, location),
            _row(Icons.work_outline, experience),
            _row(Icons.currency_rupee, _salary(salaryMin, salaryMax)),

            if (skills.isNotEmpty) ...[
              SizedBox(height: 0.6.h),
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

            /// TAGS ROW
            Row(
              children: [
                if (vacancies != null)
                  _tag('$vacancies vacancies'),
                if (isWalkIn) _tag('Walk in'),
                const Spacer(),
                Text(
                  _posted(createdAt),
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.grey.shade500,
                  ),
                ),
                SizedBox(width: 3.w),
                InkWell(
                  onTap: onSaveToggle,
                  child: Icon(
                    isSaved
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    size: 18,
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

  Widget _row(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 0.4.h),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 11.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String text) {
    return Container(
      margin: EdgeInsets.only(right: 2.w),
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.4.h),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.sp,
          color: Colors.blue.shade700,
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
    if (dateStr == null) return 'Recently';
    final d = DateTime.tryParse(dateStr);
    if (d == null) return 'Recently';
    final days = DateTime.now().difference(d).inDays;
    return days == 0 ? 'Today' : '${days}d ago';
  }
}