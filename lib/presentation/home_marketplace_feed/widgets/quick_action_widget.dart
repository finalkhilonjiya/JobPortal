import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class QuickActionWidget extends StatelessWidget {
  // For main quick actions (used in home feed)
  final VoidCallback? onSearchTap;
  final VoidCallback? onFilterTap;
  final VoidCallback? onLocationTap;
  final bool hasActiveFilters;

  // For listing quick actions (used in bottom sheet)
  final Map<String, dynamic>? listing;
  final VoidCallback? onShare;
  final VoidCallback? onReport;
  final VoidCallback? onHide;

  const QuickActionWidget({
    Key? key,
    // Main quick actions
    this.onSearchTap,
    this.onFilterTap,
    this.onLocationTap,
    this.hasActiveFilters = false,
    // Listing quick actions
    this.listing,
    this.onShare,
    this.onReport,
    this.onHide,
  }) : super(key: key);

  // Constructor for main quick actions
  const QuickActionWidget.main({
    Key? key,
    required VoidCallback this.onSearchTap,
    required VoidCallback this.onFilterTap,
    required VoidCallback this.onLocationTap,
    this.hasActiveFilters = false,
  }) : listing = null,
       onShare = null,
       onReport = null,
       onHide = null,
       super(key: key);

  // Constructor for listing quick actions
  const QuickActionWidget.listing({
    Key? key,
    required this.listing,
    required VoidCallback this.onShare,
    required VoidCallback this.onReport,
    required VoidCallback this.onHide,
  }) : onSearchTap = null,
       onFilterTap = null,
       onLocationTap = null,
       hasActiveFilters = false,
       super(key: key);

  @override
  Widget build(BuildContext context) {
    // If listing is provided, show listing quick actions bottom sheet
    if (listing != null) {
      return _buildListingQuickActions(context);
    }
    
    // Otherwise show main quick actions
    return _buildMainQuickActions(context);
  }

  Widget _buildMainQuickActions(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 26),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Quick Actions Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.flash_on,
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 20,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Find what you need faster',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 3.h),

          // Action Buttons Row
          Row(
            children: [
              // Advanced Search
              Expanded(
                child: _buildActionButton(
                  context: context,
                  icon: Icons.search,
                  label: 'Search',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  onTap: onSearchTap,
                ),
              ),

              SizedBox(width: 3.w),

              // Filters
              Expanded(
                child: _buildActionButton(
                  context: context,
                  icon: Icons.tune,
                  label: 'Filters',
                  color: AppTheme.getAccentColor(true),
                  onTap: onFilterTap,
                  badge: hasActiveFilters,
                ),
              ),

              SizedBox(width: 3.w),

              // Location
              Expanded(
                child: _buildActionButton(
                  context: context,
                  icon: Icons.my_location,
                  label: 'Near Me',
                  color: AppTheme.getSuccessColor(true),
                  onTap: onLocationTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
    bool badge = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 3.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 26),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 51),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Icon with optional badge
            Stack(
              children: [
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                if (badge)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                    ),
                  ),
              ],
            ),

            SizedBox(height: 1.h),

            // Label
            Text(
              label,
              style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListingQuickActions(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.only(top: 3.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header with listing info
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              children: [
                // Listing image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    listing!['imageUrl'] ?? '',
                    width: 15.w,
                    height: 15.w,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 15.w,
                      height: 15.w,
                      color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.image_not_supported,
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                
                SizedBox(width: 3.w),
                
                // Listing details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing!['title'] ?? 'No Title',
                        style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        listing!['price'] ?? 'Price not set',
                        style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1),

          // Quick Action Options
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              children: [
                _buildQuickActionTile(
                  context: context,
                  icon: Icons.share,
                  title: 'Share Listing',
                  subtitle: 'Share with friends and family',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  onTap: () {
                    Navigator.of(context).pop();
                    onShare?.call();
                  },
                ),

                SizedBox(height: 2.w),

                _buildQuickActionTile(
                  context: context,
                  icon: Icons.visibility_off,
                  title: 'Hide Similar',
                  subtitle: 'Don\'t show similar listings',
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  onTap: () {
                    Navigator.of(context).pop();
                    onHide?.call();
                  },
                ),

                SizedBox(height: 2.w),

                _buildQuickActionTile(
                  context: context,
                  icon: Icons.flag,
                  title: 'Report Listing',
                  subtitle: 'Report inappropriate content',
                  color: AppTheme.lightTheme.colorScheme.error,
                  onTap: () {
                    Navigator.of(context).pop();
                    onReport?.call();
                  },
                ),

                SizedBox(height: 4.w),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 13),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 26),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.5.w),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),

            SizedBox(width: 3.w),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 0.3.h),
                  Text(
                    subtitle,
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
