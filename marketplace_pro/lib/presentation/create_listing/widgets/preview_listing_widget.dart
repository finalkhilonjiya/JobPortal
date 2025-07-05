import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PreviewListingWidget extends StatelessWidget {
  final Map<String, dynamic> listingData;
  final Function(int) onEdit;

  const PreviewListingWidget({
    super.key,
    required this.listingData,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preview Listing',
            style: AppTheme.lightTheme.textTheme.headlineSmall,
          ),
          SizedBox(height: 1.h),
          Text(
            'Review your listing before publishing',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 3.h),

          // Listing preview card
          Container(
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(3.w),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.lightTheme.colorScheme.shadow,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photos section
                _buildPhotosSection(),

                Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and price
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              (listingData['title'] as String).isNotEmpty
                                  ? listingData['title'] as String
                                  : 'No title provided',
                              style: AppTheme.lightTheme.textTheme.titleLarge,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                (listingData['price'] as String).isNotEmpty
                                    ? '\$${listingData['price']}'
                                    : 'Price not set',
                                style: AppTheme.lightTheme.textTheme.titleLarge
                                    ?.copyWith(
                                  color:
                                      AppTheme.lightTheme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (listingData['isNegotiable'] as bool)
                                Text(
                                  'Negotiable',
                                  style: AppTheme.lightTheme.textTheme.bodySmall
                                      ?.copyWith(
                                    color:
                                        AppTheme.lightTheme.colorScheme.primary,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),

                      SizedBox(height: 2.h),

                      // Category and condition
                      Row(
                        children: [
                          if ((listingData['category'] as String)
                              .isNotEmpty) ...[
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 2.w, vertical: 0.5.h),
                              decoration: BoxDecoration(
                                color: AppTheme
                                    .lightTheme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(1.w),
                              ),
                              child: Text(
                                listingData['category'] as String,
                                style: AppTheme.lightTheme.textTheme.bodySmall
                                    ?.copyWith(
                                  color:
                                      AppTheme.lightTheme.colorScheme.primary,
                                ),
                              ),
                            ),
                            SizedBox(width: 2.w),
                          ],
                          if ((listingData['condition'] as String).isNotEmpty)
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 2.w, vertical: 0.5.h),
                              decoration: BoxDecoration(
                                color: AppTheme.getSuccessColor(true)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(1.w),
                              ),
                              child: Text(
                                _getConditionText(
                                    listingData['condition'] as String),
                                style: AppTheme.lightTheme.textTheme.bodySmall
                                    ?.copyWith(
                                  color: AppTheme.getSuccessColor(true),
                                ),
                              ),
                            ),
                        ],
                      ),

                      SizedBox(height: 2.h),

                      // Description
                      if ((listingData['description'] as String)
                          .isNotEmpty) ...[
                        Text(
                          'Description',
                          style: AppTheme.lightTheme.textTheme.titleSmall,
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          listingData['description'] as String,
                          style: AppTheme.lightTheme.textTheme.bodyMedium,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h),
                      ],

                      // Location
                      if ((listingData['location'] as String).isNotEmpty) ...[
                        Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'location_on',
                              color: AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                              size: 16,
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              listingData['location'] as String,
                              style: AppTheme.lightTheme.textTheme.bodySmall
                                  ?.copyWith(
                                color: AppTheme
                                    .lightTheme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 2.h),
                      ],

                      // Additional details
                      if ((listingData['additionalDetails']
                              as Map<String, dynamic>)
                          .isNotEmpty)
                        _buildAdditionalDetails(),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              icon: CustomIconWidget(
                                iconName: 'favorite_border',
                                color: AppTheme.lightTheme.colorScheme.primary,
                                size: 16,
                              ),
                              label: const Text('Save'),
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {},
                              icon: CustomIconWidget(
                                iconName: 'message',
                                color:
                                    AppTheme.lightTheme.colorScheme.onPrimary,
                                size: 16,
                              ),
                              label: const Text('Message'),
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

          SizedBox(height: 3.h),

          // Edit sections
          Text(
            'Edit Sections',
            style: AppTheme.lightTheme.textTheme.titleMedium,
          ),
          SizedBox(height: 2.h),

          ..._buildEditSections(),

          SizedBox(height: 3.h),

          // Publishing checklist
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primaryContainer
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(3.w),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'checklist',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 20,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Publishing Checklist',
                      style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                ..._buildChecklist(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosSection() {
    final photos = listingData['photos'] as List<String>;

    if (photos.isEmpty) {
      return Container(
        height: 30.h,
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(3.w)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomIconWidget(
                iconName: 'image',
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                size: 48,
              ),
              SizedBox(height: 2.h),
              Text(
                'No photos added',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 30.h,
      child: PageView.builder(
        itemCount: photos.length,
        itemBuilder: (context, index) => ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(3.w)),
          child: CustomImageWidget(
            imageUrl: photos[index],
            width: double.infinity,
            height: 30.h,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildAdditionalDetails() {
    final details = listingData['additionalDetails'] as Map<String, dynamic>;
    final filteredDetails = Map<String, dynamic>.from(details)
      ..removeWhere((key, value) => value == null || value.toString().isEmpty);

    if (filteredDetails.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Details',
          style: AppTheme.lightTheme.textTheme.titleSmall,
        ),
        SizedBox(height: 1.h),
        ...filteredDetails.entries.map((entry) => Padding(
              padding: EdgeInsets.only(bottom: 0.5.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 25.w,
                    child: Text(
                      '${entry.key.replaceAll('_', ' ').toUpperCase()}:',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value.toString(),
                      style: AppTheme.lightTheme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            )),
        SizedBox(height: 2.h),
      ],
    );
  }

  List<Widget> _buildEditSections() {
    final sections = [
      {'title': 'Photos', 'step': 0, 'icon': 'photo_camera'},
      {'title': 'Category', 'step': 1, 'icon': 'category'},
      {'title': 'Details', 'step': 2, 'icon': 'description'},
      {'title': 'Price & Condition', 'step': 3, 'icon': 'attach_money'},
      {'title': 'Location', 'step': 4, 'icon': 'location_on'},
      {'title': 'Additional Info', 'step': 5, 'icon': 'info'},
    ];

    return sections
        .map((section) => Container(
              margin: EdgeInsets.only(bottom: 1.h),
              child: ListTile(
                leading: CustomIconWidget(
                  iconName: section['icon'] as String,
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 20,
                ),
                title: Text(section['title'] as String),
                trailing: CustomIconWidget(
                  iconName: 'edit',
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 16,
                ),
                onTap: () => onEdit(section['step'] as int),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2.w),
                ),
                tileColor: AppTheme.lightTheme.colorScheme.surface,
              ),
            ))
        .toList();
  }

  List<Widget> _buildChecklist() {
    final checklistItems = [
      {
        'text': 'At least one photo added',
        'completed': (listingData['photos'] as List<String>).isNotEmpty,
      },
      {
        'text': 'Category selected',
        'completed': (listingData['category'] as String).isNotEmpty,
      },
      {
        'text': 'Title provided',
        'completed': (listingData['title'] as String).isNotEmpty,
      },
      {
        'text': 'Description added',
        'completed': (listingData['description'] as String).isNotEmpty,
      },
      {
        'text': 'Price set',
        'completed': (listingData['price'] as String).isNotEmpty,
      },
      {
        'text': 'Condition specified',
        'completed': (listingData['condition'] as String).isNotEmpty,
      },
      {
        'text': 'Location provided',
        'completed': (listingData['location'] as String).isNotEmpty,
      },
    ];

    return checklistItems
        .map((item) => Padding(
              padding: EdgeInsets.only(bottom: 0.5.h),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: item['completed'] as bool
                        ? 'check_circle'
                        : 'radio_button_unchecked',
                    color: item['completed'] as bool
                        ? AppTheme.getSuccessColor(true)
                        : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    size: 16,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      item['text'] as String,
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        decoration: item['completed'] as bool
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                  ),
                ],
              ),
            ))
        .toList();
  }

  String _getConditionText(String condition) {
    switch (condition) {
      case 'new':
        return 'New';
      case 'like_new':
        return 'Like New';
      case 'good':
        return 'Good';
      case 'fair':
        return 'Fair';
      case 'poor':
        return 'Poor';
      default:
        return condition;
    }
  }
}
