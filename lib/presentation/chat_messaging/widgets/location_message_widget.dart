import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class LocationMessageWidget extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isSelected;

  const LocationMessageWidget({
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
                  GestureDetector(
                    onTap: _openLocationInMaps,
                    child: Container(
                      padding: EdgeInsets.all(3.w),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Map preview
                          Container(
                            width: double.infinity,
                            height: 20.h,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: isMe
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withValues(alpha: 0.1),
                            ),
                            child: Stack(
                              children: [
                                // Mock map background
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.blue.withValues(alpha: 0.1),
                                        Colors.green.withValues(alpha: 0.1),
                                      ],
                                    ),
                                  ),
                                ),
                                // Map lines pattern
                                CustomPaint(
                                  size: Size(double.infinity, 20.h),
                                  painter: MapPatternPainter(
                                    color: isMe
                                        ? Colors.white.withValues(alpha: 0.3)
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant
                                            .withValues(alpha: 0.3),
                                  ),
                                ),
                                // Location pin
                                Center(
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color:
                                          AppTheme.lightTheme.colorScheme.error,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.2),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: CustomIconWidget(
                                      iconName: 'location_on',
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 2.h),
                          // Location details
                          Row(
                            children: [
                              CustomIconWidget(
                                iconName: 'place',
                                color: isMe
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onSurface,
                                size: 16,
                              ),
                              SizedBox(width: 2.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message['locationName'] ??
                                          'Shared Location',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: isMe
                                                ? Colors.white
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                            fontWeight: FontWeight.w600,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (message['locationAddress'] != null) ...[
                                      SizedBox(height: 0.5.h),
                                      Text(
                                        message['locationAddress'],
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: isMe
                                                  ? Colors.white
                                                      .withValues(alpha: 0.8)
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                            ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 2.h),
                          // Action buttons
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 1.h),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? Colors.white.withValues(alpha: 0.2)
                                        : AppTheme
                                            .lightTheme.colorScheme.primary
                                            .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CustomIconWidget(
                                        iconName: 'directions',
                                        color: isMe
                                            ? Colors.white
                                            : AppTheme
                                                .lightTheme.colorScheme.primary,
                                        size: 16,
                                      ),
                                      SizedBox(width: 1.w),
                                      Text(
                                        'Get Directions',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: isMe
                                                  ? Colors.white
                                                  : AppTheme.lightTheme
                                                      .colorScheme.primary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
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

  void _openLocationInMaps() {
    // This would typically open the location in the device's default maps app
    // For now, we'll just show a toast message
    // In a real app, you would use url_launcher to open maps with coordinates
    print(
        'Opening location: ${message['locationName']} at ${message['latitude']}, ${message['longitude']}');
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

class MapPatternPainter extends CustomPainter {
  final Color color;

  MapPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw grid pattern to simulate map
    const gridSize = 20.0;

    // Vertical lines
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Draw some curved lines to simulate roads
    final path = Path();
    path.moveTo(0, size.height * 0.3);
    path.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.1,
      size.width * 0.7,
      size.height * 0.4,
    );
    path.quadraticBezierTo(
      size.width * 0.9,
      size.height * 0.6,
      size.width,
      size.height * 0.8,
    );

    canvas.drawPath(path, paint..strokeWidth = 2.0);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
