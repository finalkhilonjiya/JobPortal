import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class VerificationCenterWidget extends StatelessWidget {
  final String kycStatus;
  final bool phoneVerified;
  final bool emailVerified;

  const VerificationCenterWidget({
    Key? key,
    required this.kycStatus,
    required this.phoneVerified,
    required this.emailVerified,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(4.w),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'security',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  'Verification Center',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 3.h),

          // KYC Status
          _buildVerificationItem(
            title: 'Identity Verification',
            subtitle: kycStatus == 'verified'
                ? 'Your identity has been verified'
                : 'Complete KYC verification',
            isVerified: kycStatus == 'verified',
            onTap: () {
              if (kycStatus != 'verified') {
                // Navigate to KYC verification
              }
            },
          ),

          SizedBox(height: 2.h),

          // Phone Verification
          _buildVerificationItem(
            title: 'Phone Number',
            subtitle: phoneVerified
                ? 'Phone number verified'
                : 'Verify your phone number',
            isVerified: phoneVerified,
            onTap: () {
              if (!phoneVerified) {
                // Navigate to phone verification
              }
            },
          ),

          SizedBox(height: 2.h),

          // Email Verification
          _buildVerificationItem(
            title: 'Email Address',
            subtitle: emailVerified
                ? 'Email address verified'
                : 'Verify your email address',
            isVerified: emailVerified,
            onTap: () {
              if (!emailVerified) {
                // Navigate to email verification
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationItem({
    required String title,
    required String subtitle,
    required bool isVerified,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: isVerified
              ? AppTheme.getSuccessColor(true).withValues(alpha: 0.1)
              : AppTheme.getWarningColor(true).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isVerified
                ? AppTheme.getSuccessColor(true)
                : AppTheme.getWarningColor(true),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 10.w,
              height: 10.w,
              decoration: BoxDecoration(
                color: isVerified
                    ? AppTheme.getSuccessColor(true)
                    : AppTheme.getWarningColor(true),
                shape: BoxShape.circle,
              ),
              child: CustomIconWidget(
                iconName: isVerified ? 'check' : 'warning',
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
                    style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
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
            if (!isVerified)
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
}
