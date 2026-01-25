// File: lib/presentation/home_marketplace_feed/widgets/job_details_page.dart
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class JobDetailsPage extends StatelessWidget {
  final Map<String, dynamic> job;
  final bool isSaved;
  final VoidCallback onSaveToggle;

  const JobDetailsPage({
    Key? key,
    required this.job,
    required this.isSaved,
    required this.onSaveToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final companyName = job['company_name'] ?? 'Company';
    final jobTitle = job['job_title'] ?? 'Job Title';
    final location = job['district'] ?? 'Location';
    final salaryMin = job['salary_min'];
    final salaryMax = job['salary_max'];
    final experience = job['experience_required'] ?? 'Not specified';
    final education = job['education_required'] ?? 'Not specified';
    final jobType = job['job_type'] ?? '';
    final workMode = job['work_mode'] ?? '';
    final description = job['job_description'] ?? 'No description available';
    final requirements = job['requirements'] ?? '';
    final benefits = job['benefits'] ?? '';
    final companyLogo = job['company_logo_url'];
    final postedDate = job['created_at'];
    final viewsCount = job['views_count'] ?? 0;
    final applicationsCount = job['applications_count'] ?? 0;
    final skillsRequired = job['skills_required'];
    final applyUrl = job['apply_url'];
    final contactEmail = job['email'];
    final contactPhone = job['phone'];
    final isPremium = job['is_premium'] ?? false;
    final isUrgent = job['is_urgent'] ?? false;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 25.h,
            pinned: true,
            backgroundColor: Color(0xFF2563EB),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: Colors.white,
                ),
                onPressed: onSaveToggle,
              ),
              IconButton(
                icon: Icon(Icons.share, color: Colors.white),
                onPressed: () => _shareJob(),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(4.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Company Logo
                            Container(
                              width: 16.w,
                              height: 16.w,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: companyLogo != null && companyLogo.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
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
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    companyName,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 0.5.h),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on_outlined,
                                          size: 4.w, color: Colors.white70),
                                      SizedBox(width: 1.w),
                                      Text(
                                        location,
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Job Title & Badges
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    jobTitle,
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Wrap(
                    spacing: 2.w,
                    runSpacing: 1.h,
                    children: [
                      if (isPremium)
                        _buildBadge('Featured', Icons.star, Color(0xFFFFD700)),
                      if (isUrgent)
                        _buildBadge('Urgent Hiring', Icons.flash_on, Colors.red.shade700),
                      if (workMode.isNotEmpty)
                        _buildBadge(workMode, _getWorkModeIcon(workMode),
                            _getWorkModeColor(workMode)),
                      if (jobType.isNotEmpty)
                        _buildBadge(jobType, Icons.work_outline, Colors.blue.shade700),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 4.w, color: Colors.grey.shade600),
                      SizedBox(width: 1.w),
                      Text(
                        'Posted ${_formatPostedDate(postedDate)}',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Spacer(),
                      _buildStatChip(Icons.visibility_outlined, viewsCount),
                      SizedBox(width: 3.w),
                      _buildStatChip(Icons.people_outline, applicationsCount),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 1.h).toBoxAdapter(),

          // Key Details
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Job Overview',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  _buildDetailRow(
                    Icons.currency_rupee,
                    'Salary',
                    _formatSalary(salaryMin, salaryMax),
                    Colors.green.shade700,
                  ),
                  _buildDetailRow(
                    Icons.work_history_outlined,
                    'Experience',
                    experience,
                    Colors.orange.shade700,
                  ),
                  _buildDetailRow(
                    Icons.school_outlined,
                    'Education',
                    education,
                    Colors.purple.shade700,
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 1.h).toBoxAdapter(),

          // Skills Required
          if (skillsRequired != null && skillsRequired is List && skillsRequired.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Skills Required',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Wrap(
                      spacing: 2.w,
                      runSpacing: 1.h,
                      children: (skillsRequired as List).map((skill) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 3.w, vertical: 1.h),
                          decoration: BoxDecoration(
                            color: Color(0xFF2563EB).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Color(0xFF2563EB).withOpacity(0.3)),
                          ),
                          child: Text(
                            skill.toString(),
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

          if (skillsRequired != null && skillsRequired is List && skillsRequired.isNotEmpty)
            SizedBox(height: 1.h).toBoxAdapter(),

          // Job Description
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Job Description',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey.shade700,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Requirements
          if (requirements.isNotEmpty) ...[
            SizedBox(height: 1.h).toBoxAdapter(),
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Requirements',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      requirements,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey.shade700,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Benefits
          if (benefits.isNotEmpty) ...[
            SizedBox(height: 1.h).toBoxAdapter(),
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Benefits',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      benefits,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey.shade700,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          SliverPadding(padding: EdgeInsets.only(bottom: 12.h)),
        ],
      ),

      // Apply Button
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () => _applyToJob(context, applyUrl, contactEmail, contactPhone),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF2563EB),
            padding: EdgeInsets.symmetric(vertical: 2.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Apply Now',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultLogo(String companyName) {
    return Center(
      child: Text(
        companyName.isNotEmpty ? companyName[0].toUpperCase() : 'C',
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2563EB),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.6.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 3.5.w, color: color),
          SizedBox(width: 1.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 9.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 3.5.w, color: Colors.grey.shade600),
        SizedBox(width: 1.w),
        Text(
          count > 999 ? '${(count / 1000).toStringAsFixed(1)}k' : count.toString(),
          style: TextStyle(
            fontSize: 9.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 5.w, color: color),
          ),
          SizedBox(width: 3.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getWorkModeIcon(String workMode) {
    switch (workMode.toLowerCase()) {
      case 'remote':
        return Icons.home_outlined;
      case 'on-site':
        return Icons.business_outlined;
      case 'hybrid':
        return Icons.location_city_outlined;
      default:
        return Icons.work_outline;
    }
  }

  Color _getWorkModeColor(String workMode) {
    switch (workMode.toLowerCase()) {
      case 'remote':
        return Colors.purple.shade700;
      case 'on-site':
        return Colors.teal.shade700;
      case 'hybrid':
        return Colors.indigo.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  String _formatSalary(int? min, int? max) {
    if (min == null && max == null) return 'Not Disclosed';

    String formatAmount(int amount) {
      if (amount >= 100000) {
        return '₹${(amount / 100000).toStringAsFixed(1)}L';
      } else if (amount >= 1000) {
        return '₹${(amount / 1000).toStringAsFixed(0)}K';
      }
      return '₹$amount';
    }

    if (min != null && max != null) {
      return '${formatAmount(min)} - ${formatAmount(max)} /year';
    } else if (min != null) {
      return '${formatAmount(min)}+ /year';
    } else {
      return 'Up to ${formatAmount(max!)} /year';
    }
  }

 