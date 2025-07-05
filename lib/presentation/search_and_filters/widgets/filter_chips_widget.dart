import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class FilterChipsWidget extends StatelessWidget {
  final Map<String, dynamic> activeFilters;
  final Function(String) onRemoveFilter;
  final VoidCallback onClearAll;

  const FilterChipsWidget({
    Key? key,
    required this.activeFilters,
    required this.onRemoveFilter,
    required this.onClearAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (activeFilters.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Active Filters (${activeFilters.length})',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
            TextButton(
              onPressed: onClearAll,
              child: Text(
                'Clear All',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: activeFilters.entries.map((entry) {
            return _buildFilterChip(entry.key, entry.value);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String key, dynamic value) {
    String displayText = _getDisplayText(key, value);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.lightTheme.primaryColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            displayText,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 2.w),
          GestureDetector(
            onTap: () => onRemoveFilter(key),
            child: CustomIconWidget(
              iconName: 'close',
              color: AppTheme.lightTheme.primaryColor,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  String _getDisplayText(String key, dynamic value) {
    switch (key) {
      case 'category':
        return value.toString();
      case 'minPrice':
        return 'Min: \$${value.toString()}';
      case 'maxPrice':
        return 'Max: \$${value.toString()}';
      case 'condition':
        return value.toString();
      case 'location':
        return 'Location: ${value.toString()}';
      case 'radius':
        return '${value.toString()} km';
      default:
        return value.toString();
    }
  }
}
