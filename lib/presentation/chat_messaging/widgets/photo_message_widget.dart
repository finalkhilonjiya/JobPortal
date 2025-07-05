import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PhotoMessageWidget extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isSelected;

  const PhotoMessageWidget({
    Key? key,
    required this.message,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isMe = message['isMe'] ?? false;
    final bool isRead = message['isRead'] ?? false;
    final bool isDelivered = message['isDelivered'] ?? false;
    final bool isSent = message['isSent'] ?? false;
    final List<String> photoUrls =
        (message['photoUrls'] as List?)?.cast<String>() ?? [];

    return Container(
      margin: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.outline,
              child: CustomImageWidget(
                imageUrl: message['senderAvatar'] ?? '',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: 2.w),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: 75.w),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(1.w),
                    decoration: BoxDecoration(
                      color: isMe
                          ? AppTheme.lightTheme.colorScheme.primary
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMe ? 16 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 16),
                      ),
                      border: !isMe
                          ? Border.all(
                              color: Theme.of(context).colorScheme.outline,
                              width: 0.5,
                            )
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.shadow,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _buildPhotoGrid(photoUrls),
                  ),
                  SizedBox(height: 0.5.h),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTimestamp(message['timestamp']),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontSize: 10.sp,
                            ),
                      ),
                      if (isMe) ...[
                        SizedBox(width: 1.w),
                        _buildMessageStatus(
                            context, isSent, isDelivered, isRead),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            SizedBox(width: 2.w),
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.outline,
              child: CustomImageWidget(
                imageUrl: message['senderAvatar'] ?? '',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotoGrid(List<String> photoUrls) {
    if (photoUrls.isEmpty) return const SizedBox.shrink();

    if (photoUrls.length == 1) {
      return _buildSinglePhoto(photoUrls.first);
    } else if (photoUrls.length == 2) {
      return _buildTwoPhotos(photoUrls);
    } else {
      return _buildMultiplePhotos(photoUrls);
    }
  }

  Widget _buildSinglePhoto(String photoUrl) {
    return GestureDetector(
      onTap: () => _showPhotoViewer([photoUrl], 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CustomImageWidget(
          imageUrl: photoUrl,
          width: 60.w,
          height: 40.h,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildTwoPhotos(List<String> photoUrls) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _showPhotoViewer(photoUrls, 0),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: CustomImageWidget(
                imageUrl: photoUrls[0],
                width: double.infinity,
                height: 30.h,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        SizedBox(width: 0.5.w),
        Expanded(
          child: GestureDetector(
            onTap: () => _showPhotoViewer(photoUrls, 1),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: CustomImageWidget(
                imageUrl: photoUrls[1],
                width: double.infinity,
                height: 30.h,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMultiplePhotos(List<String> photoUrls) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _showPhotoViewer(photoUrls, 0),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: CustomImageWidget(
              imageUrl: photoUrls[0],
              width: 60.w,
              height: 25.h,
              fit: BoxFit.cover,
            ),
          ),
        ),
        SizedBox(height: 0.5.h),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _showPhotoViewer(photoUrls, 1),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                  ),
                  child: CustomImageWidget(
                    imageUrl: photoUrls[1],
                    width: double.infinity,
                    height: 15.h,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            SizedBox(width: 0.5.w),
            Expanded(
              child: GestureDetector(
                onTap: () => _showPhotoViewer(photoUrls, 2),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(12),
                      ),
                      child: CustomImageWidget(
                        imageUrl:
                            photoUrls.length > 2 ? photoUrls[2] : photoUrls[1],
                        width: double.infinity,
                        height: 15.h,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (photoUrls.length > 3)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: const BorderRadius.only(
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '+${photoUrls.length - 3}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showPhotoViewer(List<String> photoUrls, int initialIndex) {
    // This would typically navigate to a full-screen photo viewer
    // For now, we'll just show a simple dialog
    showDialog(
      context: NavigationService.navigatorKey.currentContext!,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Container(
          width: double.infinity,
          height: 80.h,
          child: PageView.builder(
            controller: PageController(initialPage: initialIndex),
            itemCount: photoUrls.length,
            itemBuilder: (context, index) {
              return InteractiveViewer(
                child: CustomImageWidget(
                  imageUrl: photoUrls[index],
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.contain,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMessageStatus(
      BuildContext context, bool isSent, bool isDelivered, bool isRead) {
    if (isRead) {
      return CustomIconWidget(
        iconName: 'done_all',
        color: AppTheme.lightTheme.colorScheme.primary,
        size: 12,
      );
    } else if (isDelivered) {
      return CustomIconWidget(
        iconName: 'done_all',
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        size: 12,
      );
    } else if (isSent) {
      return CustomIconWidget(
        iconName: 'done',
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        size: 12,
      );
    } else {
      return CustomIconWidget(
        iconName: 'schedule',
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        size: 12,
      );
    }
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${timestamp.day}/${timestamp.month}';
    } else {
      final hour = timestamp.hour;
      final minute = timestamp.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    }
  }
}

// Navigation service for accessing context globally
class NavigationService {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}
