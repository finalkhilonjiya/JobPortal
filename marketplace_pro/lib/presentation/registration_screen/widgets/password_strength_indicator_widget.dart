import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PasswordStrengthIndicatorWidget extends StatelessWidget {
  final String password;
  final int strength;

  const PasswordStrengthIndicatorWidget({
    Key? key,
    required this.password,
    required this.strength,
  }) : super(key: key);

  String get _strengthText {
    switch (strength) {
      case 0:
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      case 5:
        return 'Very Strong';
      default:
        return 'Weak';
    }
  }

  Color get _strengthColor {
    switch (strength) {
      case 0:
      case 1:
        return AppTheme.lightTheme.colorScheme.error;
      case 2:
        return AppTheme.lightTheme.colorScheme.error.withValues(alpha: 0.7);
      case 3:
        return Colors.orange;
      case 4:
        return Colors.green;
      case 5:
        return Colors.green.shade700;
      default:
        return AppTheme.lightTheme.colorScheme.error;
    }
  }

  List<String> get _requirements {
    return [
      'At least 8 characters',
      'Contains uppercase letter',
      'Contains lowercase letter',
      'Contains number',
      'Contains special character',
    ];
  }

  List<bool> get _requirementsMet {
    return [
      password.length >= 8,
      password.contains(RegExp(r'[A-Z]')),
      password.contains(RegExp(r'[a-z]')),
      password.contains(RegExp(r'[0-9]')),
      password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Password Strength: ',
                style: AppTheme.lightTheme.textTheme.bodySmall,
              ),
              Text(
                _strengthText,
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: _strengthColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),

          // Strength indicator bars
          Row(
            children: List.generate(5, (index) {
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: index < 4 ? 1.w : 0),
                  decoration: BoxDecoration(
                    color: index < strength
                        ? _strengthColor
                        : AppTheme.lightTheme.colorScheme.outline
                            .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),

          SizedBox(height: 1.5.h),

          // Requirements list
          Column(
            children: List.generate(_requirements.length, (index) {
              final isMet = _requirementsMet[index];
              return Padding(
                padding: EdgeInsets.only(bottom: 0.5.h),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName:
                          isMet ? 'check_circle' : 'radio_button_unchecked',
                      color: isMet
                          ? Colors.green
                          : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      size: 16,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        _requirements[index],
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: isMet
                              ? AppTheme.lightTheme.colorScheme.onSurface
                              : AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                          decoration: isMet ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
