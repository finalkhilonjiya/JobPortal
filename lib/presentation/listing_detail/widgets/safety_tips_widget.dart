import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SafetyTipsWidget extends StatefulWidget {
  const SafetyTipsWidget({Key? key}) : super(key: key);

  @override
  State<SafetyTipsWidget> createState() => _SafetyTipsWidgetState();
}

class _SafetyTipsWidgetState extends State<SafetyTipsWidget> {
  bool _isExpanded = false;

  final List<Map<String, dynamic>> safetyTips = [
    {
      "icon": "shield",
      "title": "Meet in Public Places",
      "description":
          "Always meet in well-lit, public areas with good foot traffic. Avoid isolated locations."
    },
    {
      "icon": "group",
      "title": "Bring a Friend",
      "description":
          "Consider bringing a trusted friend or family member when meeting buyers or sellers."
    },
    {
      "icon": "payment",
      "title": "Secure Payment Methods",
      "description":
          "Use secure payment methods. Avoid wire transfers or sending money to unknown parties."
    },
    {
      "icon": "visibility",
      "title": "Inspect Before Buying",
      "description":
          "Thoroughly inspect items before making payment. Test electronics and check for damage."
    },
    {
      "icon": "phone",
      "title": "Trust Your Instincts",
      "description":
          "If something feels wrong or too good to be true, trust your instincts and walk away."
    },
    {
      "icon": "report",
      "title": "Report Suspicious Activity",
      "description":
          "Report any suspicious behavior, scams, or fraudulent listings to keep the community safe."
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Container(
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color:
                          AppTheme.getWarningColor(true).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomIconWidget(
                      iconName: 'security',
                      color: AppTheme.getWarningColor(true),
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Safety Tips',
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          'Stay safe while buying and selling',
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CustomIconWidget(
                    iconName: _isExpanded ? 'expand_less' : 'expand_more',
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 4.w),
              child: Column(
                children: [
                  Container(
                    height: 1,
                    color: AppTheme.lightTheme.colorScheme.outline
                        .withValues(alpha: 0.2),
                    margin: EdgeInsets.only(bottom: 3.h),
                  ),
                  ...safetyTips.map((tip) => _buildSafetyTipItem(tip)).toList(),
                ],
              ),
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyTipItem(Map<String, dynamic> tip) {
    return Container(
      margin: EdgeInsets.only(bottom: 3.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primary
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: CustomIconWidget(
              iconName: tip["icon"] as String,
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 16,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip["title"] as String,
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  tip["description"] as String,
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
