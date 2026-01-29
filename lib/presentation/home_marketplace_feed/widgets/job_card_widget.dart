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
        margin: EdgeInsets.only(bottom: 0.8.h),
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.6.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2563EB).withOpacity(0.035),
              Colors.white,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// TITLE ROW + LOGO
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    jobTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.6.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                _CompanyLogo(company: company),
              ],
            ),

            SizedBox(height: 0.5.h),

            /// COMPANY
            Text(
              company,
              style: TextStyle(
                fontSize: 11.6.sp,
                color: Colors.grey.shade700,
              ),
            ),

            SizedBox(height: 0.8.h),

            /// LOCATION
            _InfoRow(
              icon: Icons.location_on_outlined,
              iconColor: Colors.indigo.shade400,
              text: location,
            ),

            SizedBox(height: 0.4.h),

            /// EXPERIENCE
            _InfoRow(
              icon: Icons.work_outline,
              iconColor: Colors.teal.shade400,
              text: experience.isNotEmpty
                  ? experience
                  : 'Experience not specified',
            ),

            /// SALARY
            if (salaryMin != null || salaryMax != null) ...[
              SizedBox(height: 0.4.h),
              _InfoRow(
                icon: Icons.currency_rupee,
                iconColor: Colors.green.shade600,
                text: _formatSalary(salaryMin, salaryMax),
              ),
            ],

            /// SKILLS (PLAIN TEXT)
            if (skills.isNotEmpty) ...[
              SizedBox(height: 0.9.h),
              Text(
                skills,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.6.sp,
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
                Text(
                  'Hide',
                  style: TextStyle(
                    fontSize: 10.4.sp,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),

            SizedBox(height: 1.4.h),

            Divider(height: 1, color: Colors.grey.shade300),
          ],
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

/// ================= COMPONENTS =================

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        SizedBox(width: 1.2.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.grey.shade700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _CompanyLogo extends StatelessWidget {
  final String company;

  const _CompanyLogo({required this.company});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      width: 34,
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        company.isNotEmpty ? company[0].toUpperCase() : 'C',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: Colors.blue.shade700,
        ),
      ),
    );
  }
}