import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class FavoriteItemCardWidget extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isSelected;
  final bool isMultiSelectMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onRemove;
  final VoidCallback onShare;
  final VoidCallback onPriceAlert;
  final VoidCallback onSimilarItems;

  const FavoriteItemCardWidget({
    Key? key,
    required this.item,
    required this.isSelected,
    required this.isMultiSelectMode,
    required this.onTap,
    required this.onLongPress,
    required this.onRemove,
    required this.onShare,
    required this.onPriceAlert,
    required this.onSimilarItems,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isAvailable = item["isAvailable"] ?? true;
    final double priceChange = item["priceChange"] ?? 0.0;
    final DateTime dateSaved = item["dateSaved"] ?? DateTime.now();
    final String timeAgo = _getTimeAgo(dateSaved);

    return Dismissible(
      key: Key('favorite_${item["id"]}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 4.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'delete',
              color: Colors.white,
              size: 24,
            ),
            SizedBox(height: 1.h),
            Text(
              'Remove',
              style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      onDismissed: (direction) {
        onRemove();
      },
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          margin: EdgeInsets.only(bottom: 3.h),
          decoration: BoxDecoration(
            color: isAvailable
                ? AppTheme.lightTheme.colorScheme.surface
                : AppTheme.lightTheme.colorScheme.surface
                    .withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppTheme.lightTheme.primaryColor
                  : AppTheme.lightTheme.colorScheme.outline,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.lightTheme.colorScheme.shadow,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Main Content
              Padding(
                padding: EdgeInsets.all(4.w),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Selection Checkbox
                    if (isMultiSelectMode) ...[
                      Checkbox(
                        value: isSelected,
                        onChanged: (value) => onTap(),
                      ),
                      SizedBox(width: 2.w),
                    ],

                    // Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CustomImageWidget(
                        imageUrl: item["image"] ?? "",
                        width: 20.w,
                        height: 20.w,
                        fit: BoxFit.cover,
                      ),
                    ),

                    SizedBox(width: 4.w),

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title and Featured Badge
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item["title"] ?? "",
                                  style: AppTheme
                                      .lightTheme.textTheme.titleMedium
                                      ?.copyWith(
                                    color: isAvailable
                                        ? AppTheme
                                            .lightTheme.colorScheme.onSurface
                                        : AppTheme.lightTheme.colorScheme
                                            .onSurfaceVariant,
                                    decoration: isAvailable
                                        ? null
                                        : TextDecoration.lineThrough,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (item["isFeatured"] == true) ...[
                                SizedBox(width: 2.w),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 2.w, vertical: 0.5.h),
                                  decoration: BoxDecoration(
                                    color: AppTheme.getAccentColor(true),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'FEATURED',
                                    style: AppTheme
                                        .lightTheme.textTheme.labelSmall
                                        ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),

                          SizedBox(height: 1.h),

                          // Price and Price Change
                          Row(
                            children: [
                              Text(
                                item["price"] ?? "",
                                style: AppTheme.lightTheme.textTheme.titleMedium
                                    ?.copyWith(
                                  color: AppTheme.lightTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (priceChange != 0) ...[
                                SizedBox(width: 2.w),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 2.w, vertical: 0.5.h),
                                  decoration: BoxDecoration(
                                    color: priceChange < 0
                                        ? AppTheme.getSuccessColor(true)
                                        : AppTheme.getWarningColor(true),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CustomIconWidget(
                                        iconName: priceChange < 0
                                            ? 'arrow_downward'
                                            : 'arrow_upward',
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                      SizedBox(width: 1.w),
                                      Text(
                                        '${priceChange.abs().toStringAsFixed(1)}%',
                                        style: AppTheme
                                            .lightTheme.textTheme.labelSmall
                                            ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),

                          SizedBox(height: 1.h),

                          // Location and Distance
                          Row(
                            children: [
                              CustomIconWidget(
                                iconName: 'location_on',
                                color: AppTheme
                                    .lightTheme.colorScheme.onSurfaceVariant,
                                size: 16,
                              ),
                              SizedBox(width: 1.w),
                              Expanded(
                                child: Text(
                                  '${item["location"]} • ${item["distance"]}',
                                  style:
                                      AppTheme.lightTheme.textTheme.bodySmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 1.h),

                          // Saved Date and Views
                          Row(
                            children: [
                              Text(
                                'Saved $timeAgo',
                                style: AppTheme.lightTheme.textTheme.bodySmall
                                    ?.copyWith(
                                  color: AppTheme
                                      .lightTheme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Spacer(),
                              CustomIconWidget(
                                iconName: 'visibility',
                                color: AppTheme
                                    .lightTheme.colorScheme.onSurfaceVariant,
                                size: 14,
                              ),
                              SizedBox(width: 1.w),
                              Text(
                                '${item["views"]}',
                                style: AppTheme.lightTheme.textTheme.bodySmall
                                    ?.copyWith(
                                  color: AppTheme
                                      .lightTheme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Action Buttons
              if (!isMultiSelectMode) ...[
                Divider(height: 1),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
                  child: Row(
                    children: [
                      // Remove Button
                      Expanded(
                        child: TextButton.icon(
                          onPressed: onRemove,
                          icon: CustomIconWidget(
                            iconName: 'favorite',
                            color: AppTheme.lightTheme.colorScheme.error,
                            size: 16,
                          ),
                          label: Text(
                            'Remove',
                            style: TextStyle(
                              color: AppTheme.lightTheme.colorScheme.error,
                            ),
                          ),
                        ),
                      ),

                      // Share Button
                      Expanded(
                        child: TextButton.icon(
                          onPressed: onShare,
                          icon: CustomIconWidget(
                            iconName: 'share',
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                            size: 16,
                          ),
                          label: Text('Share'),
                        ),
                      ),

                      // Price Alert or Similar Items Button
                      Expanded(
                        child: isAvailable
                            ? TextButton.icon(
                                onPressed: onPriceAlert,
                                icon: CustomIconWidget(
                                  iconName: 'notifications',
                                  color: AppTheme.lightTheme.primaryColor,
                                  size: 16,
                                ),
                                label: Text(
                                  'Alert',
                                  style: TextStyle(
                                    color: AppTheme.lightTheme.primaryColor,
                                  ),
                                ),
                              )
                            : TextButton.icon(
                                onPressed: onSimilarItems,
                                icon: CustomIconWidget(
                                  iconName: 'search',
                                  color: AppTheme.lightTheme.primaryColor,
                                  size: 16,
                                ),
                                label: Text(
                                  'Similar',
                                  style: TextStyle(
                                    color: AppTheme.lightTheme.primaryColor,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],

              // Unavailable Overlay
              if (!isAvailable) ...[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 1.h),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomIconWidget(
                        iconName: 'info',
                        color: AppTheme.lightTheme.colorScheme.onErrorContainer,
                        size: 16,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        'Item no longer available',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color:
                              AppTheme.lightTheme.colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
