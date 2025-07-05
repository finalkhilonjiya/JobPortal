import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class AccountSettingsSectionWidget extends StatelessWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onLogout;

  const AccountSettingsSectionWidget({
    Key? key,
    required this.userData,
    required this.onLogout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              CustomIconWidget(
                iconName: 'settings',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Text(
                'Account Settings',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          SizedBox(height: 3.h),

          // Settings Options
          Container(
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.lightTheme.colorScheme.shadow,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildSettingItem(
                  icon: 'edit',
                  title: 'Edit Profile',
                  subtitle: 'Update your personal information',
                  onTap: () {
                    // Navigate to edit profile
                  },
                ),
                _buildDivider(),
                _buildSettingItem(
                  icon: 'notifications',
                  title: 'Notifications',
                  subtitle: 'Manage notification preferences',
                  onTap: () {
                    // Navigate to notification settings
                  },
                ),
                _buildDivider(),
                _buildSettingItem(
                  icon: 'privacy_tip',
                  title: 'Privacy & Security',
                  subtitle: 'Control your privacy settings',
                  onTap: () {
                    // Navigate to privacy settings
                  },
                ),
                _buildDivider(),
                _buildSettingItem(
                  icon: 'payment',
                  title: 'Payment Methods',
                  subtitle: 'Manage your payment options',
                  onTap: () {
                    // Navigate to payment methods
                  },
                ),
                _buildDivider(),
                _buildSettingItem(
                  icon: 'business',
                  title: 'Business Account',
                  subtitle: userData["isBusinessAccount"] == true
                      ? 'Manage business features'
                      : 'Upgrade to business account',
                  onTap: () {
                    // Navigate to business account
                  },
                  showBadge: userData["isBusinessAccount"] != true,
                ),
                _buildDivider(),
                _buildSettingItem(
                  icon: 'help',
                  title: 'Help & Support',
                  subtitle: 'Get help and contact support',
                  onTap: () {
                    // Navigate to help & support
                  },
                ),
                _buildDivider(),
                _buildSettingItem(
                  icon: 'info',
                  title: 'About',
                  subtitle: 'App version and legal information',
                  onTap: () {
                    // Navigate to about page
                  },
                ),
              ],
            ),
          ),

          SizedBox(height: 4.h),

          // Logout Button
          Container(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onLogout,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: EdgeInsets.symmetric(vertical: 2.h),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomIconWidget(
                    iconName: 'logout',
                    color: Colors.red,
                    size: 20,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Logout',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool showBadge = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(4.w),
        child: Row(
          children: [
            Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomIconWidget(
                iconName: icon,
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 20,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: AppTheme.lightTheme.textTheme.titleSmall
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (showBadge)
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 2.w, vertical: 0.5.h),
                          decoration: BoxDecoration(
                            color: AppTheme.getWarningColor(true),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'NEW',
                            style: AppTheme.lightTheme.textTheme.labelSmall
                                ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    subtitle,
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            CustomIconWidget(
              iconName: 'arrow_forward_ios',
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
    );
  }
}
