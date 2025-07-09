import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class EnhancedCategoryChipWidget extends StatelessWidget {
  final Map<String, dynamic> category;
  final bool isSelected;
  final VoidCallback onTap;

  const EnhancedCategoryChipWidget({
    Key? key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorValue = category['color'] as String?;
    final categoryColor = colorValue != null 
        ? Color(int.parse(colorValue))
        : AppTheme.lightTheme.colorScheme.primary;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 20.w, // Fixed width for prominent look
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: isSelected 
              ? categoryColor
              : categoryColor.withAlpha(26),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? categoryColor
                : categoryColor.withAlpha(51),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: categoryColor.withAlpha(51),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Category Icon
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: isSelected 
                    ? Colors.white.withAlpha(51)
                    : categoryColor.withAlpha(77),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getIconData(category['icon'] ?? 'apps'),
                color: isSelected ? Colors.white : categoryColor,
                size: 24,
              ),
            ),
            
            SizedBox(height: 1.h),
            
            // Category Name
            Text(
              category['name'] ?? 'Unknown',
              style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                color: isSelected ? Colors.white : categoryColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            
            // Count Badge (if available)
            if (category['count'] != null && category['count'] > 0) ...[
              SizedBox(height: 0.5.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.2.h),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Colors.white.withAlpha(77)
                      : categoryColor.withAlpha(51),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${category['count']}',
                  style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                    color: isSelected ? Colors.white : categoryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'apps':
        return Icons.apps;
      case 'devices':
        return Icons.devices;
      case 'checkroom':
        return Icons.checkroom;
      case 'work':
        return Icons.work;
      case 'directions_car':
        return Icons.directions_car;
      case 'chair':
        return Icons.chair;
      case 'menu_book':
        return Icons.menu_book;
      case 'sports_soccer':
        return Icons.sports_soccer;
      case 'restaurant':
        return Icons.restaurant;
      case 'handyman':
        return Icons.handyman;
      default:
        return Icons.category;
    }
  }
}