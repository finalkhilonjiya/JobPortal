import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ProfilePhotoUploadWidget extends StatelessWidget {
  final Function(String?) onPhotoSelected;
  final String? currentPhotoPath;

  const ProfilePhotoUploadWidget({
    Key? key,
    required this.onPhotoSelected,
    this.currentPhotoPath,
  }) : super(key: key);

  void _showPhotoPickerBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(top: 2.h),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  children: [
                    Text(
                      'Select Profile Photo',
                      style: AppTheme.lightTheme.textTheme.titleLarge,
                    ),
                    SizedBox(height: 3.h),
                    Row(
                      children: [
                        Expanded(
                          child: _buildPhotoOption(
                            context,
                            icon: 'camera_alt',
                            label: 'Camera',
                            onTap: () {
                              Navigator.pop(context);
                              _handleCameraSelection();
                            },
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: _buildPhotoOption(
                            context,
                            icon: 'photo_library',
                            label: 'Gallery',
                            onTap: () {
                              Navigator.pop(context);
                              _handleGallerySelection();
                            },
                          ),
                        ),
                      ],
                    ),
                    if (currentPhotoPath != null) ...[
                      SizedBox(height: 2.h),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            onPhotoSelected(null);
                          },
                          child: const Text('Remove Photo'),
                        ),
                      ),
                    ],
                    SizedBox(height: 2.h),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoOption(
    BuildContext context, {
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 4.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            CustomIconWidget(
              iconName: icon,
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 32,
            ),
            SizedBox(height: 1.h),
            Text(
              label,
              style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleCameraSelection() {
    // Simulate camera selection
    onPhotoSelected('camera_photo_path');
  }

  void _handleGallerySelection() {
    // Simulate gallery selection
    onPhotoSelected('gallery_photo_path');
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _showPhotoPickerBottomSheet(context),
            child: Container(
              width: 25.w,
              height: 25.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.lightTheme.colorScheme.surface,
                border: Border.all(
                  color: AppTheme.lightTheme.colorScheme.outline,
                  width: 2,
                ),
              ),
              child: currentPhotoPath != null
                  ? ClipOval(
                      child: Container(
                        color: AppTheme.lightTheme.colorScheme.primary
                            .withValues(alpha: 0.1),
                        child: CustomIconWidget(
                          iconName: 'person',
                          color: AppTheme.lightTheme.colorScheme.primary,
                          size: 40,
                        ),
                      ),
                    )
                  : CustomIconWidget(
                      iconName: 'add_a_photo',
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      size: 32,
                    ),
            ),
          ),
          SizedBox(height: 1.h),
          GestureDetector(
            onTap: () => _showPhotoPickerBottomSheet(context),
            child: Text(
              currentPhotoPath != null ? 'Change Photo' : 'Add Profile Photo',
              style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Optional - helps build trust with other users',
            style: AppTheme.lightTheme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
