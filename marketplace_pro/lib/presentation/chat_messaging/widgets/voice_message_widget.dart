import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class VoiceMessageWidget extends StatefulWidget {
  final Map<String, dynamic> message;
  final bool isSelected;

  const VoiceMessageWidget({
    Key? key,
    required this.message,
    this.isSelected = false,
  }) : super(key: key);

  @override
  State<VoiceMessageWidget> createState() => _VoiceMessageWidgetState();
}

class _VoiceMessageWidgetState extends State<VoiceMessageWidget>
    with TickerProviderStateMixin {
  bool _isPlaying = false;
  double _playbackProgress = 0.0;
  late AnimationController _waveAnimationController;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _waveAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _waveAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _waveAnimationController.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    setState(() {
      _isPlaying = !_isPlaying;
    });

    if (_isPlaying) {
      _waveAnimationController.repeat(reverse: true);
      _simulatePlayback();
    } else {
      _waveAnimationController.stop();
      _waveAnimationController.reset();
    }
  }

  void _simulatePlayback() {
    // Simulate voice message playback
    const totalDuration = 23; // 23 seconds
    const updateInterval = 100; // Update every 100ms
    const totalUpdates = (totalDuration * 1000) ~/ updateInterval;

    int currentUpdate = 0;

    void updateProgress() {
      if (_isPlaying && currentUpdate < totalUpdates) {
        setState(() {
          _playbackProgress = currentUpdate / totalUpdates;
        });
        currentUpdate++;
        Future.delayed(
            const Duration(milliseconds: updateInterval), updateProgress);
      } else if (_isPlaying) {
        // Playback finished
        setState(() {
          _isPlaying = false;
          _playbackProgress = 0.0;
        });
        _waveAnimationController.stop();
        _waveAnimationController.reset();
      }
    }

    updateProgress();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMe = widget.message['isMe'] ?? false;
    final bool isRead = widget.message['isRead'] ?? false;
    final bool isDelivered = widget.message['isDelivered'] ?? false;
    final bool isSent = widget.message['isSent'] ?? false;

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
                imageUrl: widget.message['senderAvatar'] ?? '',
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: _togglePlayback,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isMe
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : AppTheme.lightTheme.colorScheme.primary
                                      .withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: CustomIconWidget(
                              iconName: _isPlaying ? 'pause' : 'play_arrow',
                              color: isMe
                                  ? Colors.white
                                  : AppTheme.lightTheme.colorScheme.primary,
                              size: 20,
                            ),
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildWaveform(isMe),
                              SizedBox(height: 1.h),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _isPlaying
                                        ? _formatDuration(
                                            _playbackProgress * 23)
                                        : widget.message['voiceDuration'] ??
                                            '0:00',
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
                                          fontSize: 10.sp,
                                        ),
                                  ),
                                  if (_isPlaying)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: isMe
                                            ? Colors.white
                                            : AppTheme
                                                .lightTheme.colorScheme.primary,
                                        shape: BoxShape.circle,
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
                  SizedBox(height: 0.5.h),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTimestamp(widget.message['timestamp']),
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
                imageUrl: widget.message['senderAvatar'] ?? '',
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

  Widget _buildWaveform(bool isMe) {
    return AnimatedBuilder(
      animation: _waveAnimation,
      builder: (context, child) {
        return Row(
          children: List.generate(20, (index) {
            final baseHeight = 3.0 + (index % 4) * 2.0;
            final animatedHeight = _isPlaying
                ? baseHeight * (0.5 + 0.5 * _waveAnimation.value)
                : baseHeight;

            final isActive = _playbackProgress > (index / 20);

            return Container(
              width: 2,
              height: animatedHeight,
              margin: const EdgeInsets.only(right: 2),
              decoration: BoxDecoration(
                color: isActive
                    ? (isMe
                        ? Colors.white
                        : AppTheme.lightTheme.colorScheme.primary)
                    : (isMe
                        ? Colors.white.withValues(alpha: 0.4)
                        : Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: 0.4)),
                borderRadius: BorderRadius.circular(1),
              ),
            );
          }),
        );
      },
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

  String _formatDuration(double seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = (seconds % 60).floor();
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
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
