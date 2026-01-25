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
                onPressed: () {
                  // Share functionality
                  print('Share job: $jobTitle');
                },
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
                                            Center(
                                              child: Text(
                                                companyName.isNotEmpty ? companyName[0].toUpperCase() : 'C',
                                                style: TextStyle(
                                                  fontSize: 18.sp,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF2563EB),
                                                ),
                                              ),
                                            ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        companyName.isNotEmpty ? companyName[0].toUpperCase() : 'C',
                                        style: TextStyle(
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2563EB),
                                        ),
                                      ),
                                    ),
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

          // Job Title & Info
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
                  Text(
                    'Posted ${_formatPostedDate(postedDate)}',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.grey.shade600,
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
                        _buildBadge(workMode, Icons.work_outline, Colors.blue.shade700),
                      if (jobType.isNotEmpty)
                        _buildBadge(jobType, Icons.work_outline, Colors.green.shade700),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: 1.h)),

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
            SliverToBoxAdapter(child: SizedBox(height: 1.h)),
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
            SliverToBoxAdapter(child: SizedBox(height: 1.h)),
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
          onPressed: () {
            if (applyUrl != null && applyUrl.isNotEmpty) {
              _launchURL(applyUrl);
            } else if (contactEmail != null && contactEmail.isNotEmpty) {
              _launchEmail(contactEmail);
            } else if (contactPhone != null && contactPhone.isNotEmpty) {
              _launchPhone(contactPhone);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('No application method available')),
              );
            }
          },
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

  String _formatPostedDate(String? dateStr) {
    if (dateStr == null) return 'recently';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          return '${difference.inMinutes}m ago';
        }
        return '${difference.inHours}h ago';
      } else if (difference.inDays == 1) {
        return 'yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return DateFormat('dd MMM yyyy').format(date);
      }
    } catch (e) {
      return 'recently';
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchPhone(String phone) async {
    final Uri uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}