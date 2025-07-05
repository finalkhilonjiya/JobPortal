import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PhotoUploadWidget extends StatefulWidget {
  final List<String> photos;
  final Function(List<String>) onPhotosChanged;

  const PhotoUploadWidget({
    super.key,
    required this.photos,
    required this.onPhotosChanged,
  });

  @override
  State<PhotoUploadWidget> createState() => _PhotoUploadWidgetState();
}

class _PhotoUploadWidgetState extends State<PhotoUploadWidget> {
  final List<String> _mockPhotos = [
    'https://images.pexels.com/photos/90946/pexels-photo-90946.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
    'https://images.pexels.com/photos/276517/pexels-photo-276517.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
    'https://images.pexels.com/photos/1667088/pexels-photo-1667088.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
  ];

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4.w)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'Add Photos',
              style: AppTheme.lightTheme.textTheme.titleLarge,
            ),
            SizedBox(height: 2.h),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'camera_alt',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 24,
              ),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _addPhoto();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'photo_library',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 24,
              ),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _addPhoto();
              },
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  void _addPhoto() {
    if (widget.photos.length < 10) {
      final newPhotos = List<String>.from(widget.photos);
      newPhotos.add(_mockPhotos[newPhotos.length % _mockPhotos.length]);
      widget.onPhotosChanged(newPhotos);
    }
  }

  void _removePhoto(int index) {
    final newPhotos = List<String>.from(widget.photos);
    newPhotos.removeAt(index);
    widget.onPhotosChanged(newPhotos);
  }

  void _reorderPhotos(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final newPhotos = List<String>.from(widget.photos);
    final item = newPhotos.removeAt(oldIndex);
    newPhotos.insert(newIndex, item);
    widget.onPhotosChanged(newPhotos);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Photos',
            style: AppTheme.lightTheme.textTheme.headlineSmall,
          ),
          SizedBox(height: 1.h),
          Text(
            'Add up to 10 photos. The first photo will be your cover image.',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 3.h),

          // Photo grid
          widget.photos.isEmpty
              ? _buildEmptyState()
              : ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.photos.length +
                      (widget.photos.length < 10 ? 1 : 0),
                  onReorder: _reorderPhotos,
                  itemBuilder: (context, index) {
                    if (index == widget.photos.length) {
                      return _buildAddPhotoCard(key: ValueKey('add_$index'));
                    }
                    return _buildPhotoCard(
                      index,
                      widget.photos[index],
                      key: ValueKey('photo_$index'),
                    );
                  },
                ),

          if (widget.photos.isNotEmpty) ...[
            SizedBox(height: 3.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(2.w),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'info',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 20,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'Drag and drop to reorder photos. First photo will be the main image.',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      height: 40.h,
      decoration: BoxDecoration(
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(3.w),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'add_a_photo',
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 48,
          ),
          SizedBox(height: 2.h),
          Text(
            'Add Your First Photo',
            style: AppTheme.lightTheme.textTheme.titleMedium,
          ),
          SizedBox(height: 1.h),
          Text(
            'Tap to add photos from camera or gallery',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 3.h),
          ElevatedButton.icon(
            onPressed: _showImageSourceDialog,
            icon: CustomIconWidget(
              iconName: 'add',
              color: AppTheme.lightTheme.colorScheme.onPrimary,
              size: 20,
            ),
            label: const Text('Add Photos'),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard(int index, String photoUrl, {required Key key}) {
    return Container(
      key: key,
      margin: EdgeInsets.only(bottom: 2.h),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: 25.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3.w),
              border: index == 0
                  ? Border.all(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      width: 2,
                    )
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3.w),
              child: CustomImageWidget(
                imageUrl: photoUrl,
                width: double.infinity,
                height: 25.h,
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Main photo badge
          if (index == 0)
            Positioned(
              top: 2.w,
              left: 2.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(1.w),
                ),
                child: Text(
                  'MAIN',
                  style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          // Remove button
          Positioned(
            top: 2.w,
            right: 2.w,
            child: GestureDetector(
              onTap: () => _removePhoto(index),
              child: Container(
                padding: EdgeInsets.all(1.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.error,
                  shape: BoxShape.circle,
                ),
                child: CustomIconWidget(
                  iconName: 'close',
                  color: AppTheme.lightTheme.colorScheme.onError,
                  size: 16,
                ),
              ),
            ),
          ),

          // Drag handle
          Positioned(
            bottom: 2.w,
            right: 2.w,
            child: Container(
              padding: EdgeInsets.all(1.w),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(1.w),
              ),
              child: CustomIconWidget(
                iconName: 'drag_handle',
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPhotoCard({required Key key}) {
    return Container(
      key: key,
      margin: EdgeInsets.only(bottom: 2.h),
      child: GestureDetector(
        onTap: _showImageSourceDialog,
        child: Container(
          width: double.infinity,
          height: 15.h,
          decoration: BoxDecoration(
            border: Border.all(
              color: AppTheme.lightTheme.colorScheme.outline,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(3.w),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomIconWidget(
                iconName: 'add',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 32,
              ),
              SizedBox(height: 1.h),
              Text(
                'Add Photo',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
