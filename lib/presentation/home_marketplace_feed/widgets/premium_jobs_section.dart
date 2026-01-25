// File: lib/presentation/home_marketplace_feed/widgets/premium_jobs_section.dart
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

class PremiumJobsSection extends StatelessWidget {
  final List<Map<String, dynamic>> jobs;
  final Function(Map<String, dynamic>) onTap;
  final Set<String> savedJobIds;
  final Function(String) onSaveToggle;

  const PremiumJobsSection({
    Key? key,
    required this.jobs,
    required this.onTap,
    required this.savedJobIds,
    required this.onSaveToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            child: Row(
              children: [
                Icon(Icons.star, color: Color(0xFFFFD700), size: 6.w),
                SizedBox(width: 2.w),
                Text(
                  'Featured Jobs',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          // Horizontal Scrolling List
          SizedBox(
            height: 32.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                return _buildPremiumJobCard(jobs[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumJobCard(Map<String, dynamic> job) {
    final jobId = job['id'];
    final companyName = job['company_name'] ?? 'Company';
    final jobTitle = job['job_title'] ?? 'Job Title';
    final location = job['district'] ?? 'Location';
    final salaryMin = job['salary_min'];
    final salaryMax = job['salary_max'];
    final workMode = job['work_mode'] ?? '';
    final companyLogo = job['company_logo_url'];
    final isSaved = savedJobIds.contains(jobId);

    return GestureDetector(
      onTap: () => onTap(job),
      child: Container(
        width: 75.w,
        margin: EdgeInsets.only(right: 3.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2563EB),
              Color(0xFF1E40AF),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF2563EB).withOpacity(0.3),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background Pattern
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),

            // Content
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with Logo & Save Button
                  Row(
                    children: [
                      // Company Logo
                      Container(
                        width: 14.w,
                        height: 14.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: companyLogo != null && companyLogo.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  companyLogo,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildDefaultLogo(companyName),
                                ),
                              )
                            : _buildDefaultLogo(companyName),
                      ),
                      SizedBox(width: 3.w),

                      // Company Name
                      Expanded(
                        child: Text(
                          companyName,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Save Button
                      InkWell(
                        onTap: () => onSaveToggle(jobId),
                        child: Container(
                          padding: EdgeInsets.all(2.w),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isSaved ? Icons.bookmark : Icons.bookmark_border,
                            color: Colors.white,
                            size: 5.w,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 3.h),

                  // Job Title
                  Text(
                    jobTitle,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: 2.h),

                  // Location
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 4.w, color: Colors.white70),
                      SizedBox(width: 1.w),
                      Expanded(
                        child: Text(
                          location,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.white70,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 1.h),

                  // Work Mode Badge
                  if (workMode.isNotEmpty)
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.5.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        workMode,
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),

                  Spacer(),

                  // Salary
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.currency_rupee,
                            size: 4.5.w, color: Colors.white),
                        SizedBox(width: 1.w),
                        Text(
                          _formatSalary(salaryMin, salaryMax),
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Featured Badge
            Positioned(
              top: 3.w,
              right: 3.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: Color(0xFFFFD700),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 3.w, color: Colors.black87),
                    SizedBox(width: 1.w),
                    Text(
                      'FEATURED',
                      style: TextStyle(
                        fontSize: 8.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
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

  Widget _buildDefaultLogo(String companyName) {
    return Center(
      child: Text(
        companyName.isNotEmpty ? companyName[0].toUpperCase() : 'C',
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2563EB),
        ),
      ),
    );
  }

  String _formatSalary(int? min, int? max) {
    if (min == null && max == null) return 'Not Disclosed';

    String formatAmount(int amount) {
      if (amount >= 100000) {
        return '${(amount / 100000).toStringAsFixed(1)}L';
      } else if (amount >= 1000) {
        return '${(amount / 1000).toStringAsFixed(0)}K';
      }
      return amount.toString();
    }

    if (min != null && max != null) {
      return '${formatAmount(min)} - ${formatAmount(max)}';
    } else if (min != null) {
      return '${formatAmount(min)}+';
    } else {
      return '${formatAmount(max!)}';
    }
  }
}