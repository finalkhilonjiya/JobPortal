// File: lib/presentation/home_marketplace_feed/widgets/job_card_widget.dart
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

class JobCardWidget extends StatelessWidget {
  final Map<String, dynamic> job;
  final bool isSaved;
  final VoidCallback onSaveToggle;
  final VoidCallback onTap;
  final VoidCallback? onApply;

  const JobCardWidget({
    Key? key,
    required this.job,
    required this.isSaved,
    required this.onSaveToggle,
    required this.onTap,
    this.onApply,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final companyName = job['company_name'] ?? 'Company';
    final jobTitle = job['job_title'] ?? 'Job Title';
    final location = job['district'] ?? 'Location';
    final salaryMin = job['salary_min'];
    final salaryMax = job['salary_max'];
    final experience = job['experience_required'] ?? '';
    final jobType = job['job_type'] ?? '';
    final workMode = job['work_mode'] ?? '';
    final isUrgent = job['is_urgent'] ?? false;
    final isPremium = job['is_premium'] ?? false;
    final postedDate = job['created_at'];
    final companyLogo = job['company_logo_url'];
    final viewsCount = job['views_count'] ?? 0;
    final applicationsCount = job['applications_count'] ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isPremium
              ? Border.all(color: Color(0xFFFFD700), width: 2)
              : Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section with Company Logo & Save Button
            Padding(
              padding: EdgeInsets.all(3.w),
              child: Row(
                children: [
                  // Company Logo
                  Container(
                    width: 14.w,
                    height: 14.w,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: companyLogo != null && companyLogo.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
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

                  // Company Name & Location
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          companyName,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 0.5.h),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 3.5.w, color: Colors.grey.shade600),
                            SizedBox(width: 1.w),
                            Expanded(
                              child: Text(
                                location,
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Save Button
                  InkWell(
                    onTap: onSaveToggle,
                    child: Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: isSaved
                            ? Color(0xFF2563EB).withOpacity(0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isSaved ? Icons.bookmark : Icons.bookmark_border,
                        color: isSaved ? Color(0xFF2563EB) : Colors.grey.shade600,
                        size: 5.w,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Job Title
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 3.w),
              child: Text(
                jobTitle,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            SizedBox(height: 1.5.h),

            // Badges Row (Work Mode, Job Type, Urgent)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 3.w),
              child: Wrap(
                spacing: 2.w,
                runSpacing: 1.h,
                children: [
                  if (workMode.isNotEmpty)
                    _buildBadge(
                      workMode,
                      _getWorkModeIcon(workMode),
                      _getWorkModeColor(workMode),
                    ),
                  if (jobType.isNotEmpty)
                    _buildBadge(
                      jobType,
                      Icons.work_outline,
                      Colors.blue.shade700,
                    ),
                  if (isUrgent)
                    _buildBadge(
                      'Urgent Hiring',
                      Icons.flash_on,
                      Colors.red.shade700,
                    ),
                  if (isPremium)
                    _buildBadge(
                      'Featured',
                      Icons.star,
                      Color(0xFFFFD700),
                    ),
                ],
              ),
            ),

            SizedBox(height: 1.5.h),

            // Salary & Experience Row
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 3.w),
              child: Row(
                children: [
                  // Salary
                  Expanded(
                    child: _buildInfoChip(
                      icon: Icons.currency_rupee,
                      label: _formatSalary(salaryMin, salaryMax),
                      color: Colors.green.shade700,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  // Experience
                  Expanded(
                    child: _buildInfoChip(
                      icon: Icons.work_history_outlined,
                      label: experience.isNotEmpty ? experience : 'Any',
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 1.5.h),

            // Footer with Posted Date & Stats
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Posted Date
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 3.5.w, color: Colors.grey.shade600),
                      SizedBox(width: 1.w),
                      Text(
                        _formatPostedDate(postedDate),
                        style: TextStyle(
                          fontSize: 9.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),

                  // Stats (Views & Applications)
                  Row(
                    children: [
                      _buildStatChip(Icons.visibility_outlined, viewsCount),
                      SizedBox(width: 3.w),
                      _buildStatChip(Icons.people_outline, applicationsCount),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // HELPER WIDGETS
  // ============================================

  Widget _buildDefaultLogo(String companyName) {
    return Center(
      child: Text(
        companyName.isNotEmpty ? companyName[0].toUpperCase() : 'C',
        style: TextStyle(
          fontSize: 16.sp,
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

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 4.w, color: color),
          SizedBox(width: 1.5.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, int count) {
    return Row(
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

  // ============================================
  // HELPER METHODS
  // ============================================

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
        return '${(amount / 100000).toStringAsFixed(1)}L';
      } else if (amount >= 1000) {
        return '${(amount / 1000).toStringAsFixed(0)}K';
      }
      return amount.toString();
    }

    if (min != null && max != null) {
      return '₹${formatAmount(min)} - ${formatAmount(max)}';
    } else if (min != null) {
      return '₹${formatAmount(min)}+';
    } else {
      return '₹${formatAmount(max!)}';
    }
  }

  String _formatPostedDate(String? dateStr) {
    if (dateStr == null) return 'Recently';

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
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else if (difference.inDays < 30) {
        return '${(difference.inDays / 7).floor()}w ago';
      } else {
        return DateFormat('dd MMM').format(date);
      }
    } catch (e) {
      return 'Recently';
    }
  }
}