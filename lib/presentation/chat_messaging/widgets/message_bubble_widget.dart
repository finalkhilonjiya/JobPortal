import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class MessageBubbleWidget extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isSelected;

  const MessageBubbleWidget({
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
                    padding:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
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
                    child: Text(
                      message['message'] ?? '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isMe
                                ? Colors.white
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
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

  Widget _buildMessageStatus(
      BuildContext context, bool isSent, bool isDelivered, bool isRead) {
    if (isRead) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(
            iconName: 'done_all',
            color: AppTheme.lightTheme.colorScheme.primary,
            size: 12,
          ),
        ],
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
