import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class MessageInputWidget extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isTyping;
  final Function(String) onSendMessage;
  final Function(bool) onTypingChanged;
  final Function(String) onSendVoiceMessage;
  final Function(List<String>) onSendPhoto;
  final Function(Map<String, dynamic>) onSendLocation;

  const MessageInputWidget({
    Key? key,
    required this.controller,
    required this.focusNode,
    required this.isTyping,
    required this.onSendMessage,
    required this.onTypingChanged,
    required this.onSendVoiceMessage,
    required this.onSendPhoto,
    required this.onSendLocation,
  }) : super(key: key);

  @override
  State<MessageInputWidget> createState() => _MessageInputWidgetState();
}

class _MessageInputWidgetState extends State<MessageInputWidget>
    with TickerProviderStateMixin {
  bool _isRecording = false;
  bool _showAttachmentOptions = false;
  late AnimationController _recordingAnimationController;
  late Animation<double> _recordingAnimation;

  @override
  void initState() {
    super.initState();
    _recordingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _recordingAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _recordingAnimationController,
      curve: Curves.easeInOut,
    ));

    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _recordingAnimationController.dispose();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final isTyping = widget.controller.text.trim().isNotEmpty;
    if (isTyping != widget.isTyping) {
      widget.onTypingChanged(isTyping);
    }
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
    });
    _recordingAnimationController.repeat(reverse: true);
    HapticFeedback.mediumImpact();

    // Simulate recording for 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (_isRecording) {
        _stopRecording();
      }
    });
  }

  void _stopRecording() {
    setState(() {
      _isRecording = false;
    });
    _recordingAnimationController.stop();
    _recordingAnimationController.reset();

    // Send voice message with duration
    widget.onSendVoiceMessage('0:03');
  }

  void _toggleAttachmentOptions() {
    setState(() {
      _showAttachmentOptions = !_showAttachmentOptions;
    });
  }

  void _sendPhoto() {
    setState(() {
      _showAttachmentOptions = false;
    });

    // Simulate photo selection
    final photoUrls = [
      'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=400&h=300&fit=crop',
      'https://images.unsplash.com/photo-1565849904461-04a58ad377e0?w=400&h=300&fit=crop',
    ];
    widget.onSendPhoto(photoUrls);
  }

  void _sendLocation() {
    setState(() {
      _showAttachmentOptions = false;
    });

    // Simulate location selection
    final locationData = {
      'locationName': 'Central Park Mall',
      'locationAddress': '123 Main Street, Downtown',
      'latitude': 40.7829,
      'longitude': -73.9654,
    };
    widget.onSendLocation(locationData);
  }

  void _sendQuickReply(String message) {
    widget.onSendMessage(message);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            if (_showAttachmentOptions) _buildAttachmentOptions(),
            _buildQuickReplies(),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOptions() {
    return Container(
      padding: EdgeInsets.all(4.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildAttachmentOption(
            icon: 'camera_alt',
            label: 'Camera',
            onTap: _sendPhoto,
          ),
          _buildAttachmentOption(
            icon: 'photo_library',
            label: 'Gallery',
            onTap: _sendPhoto,
          ),
          _buildAttachmentOption(
            icon: 'location_on',
            label: 'Location',
            onTap: _sendLocation,
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentOption({
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: CustomIconWidget(
              iconName: icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickReplies() {
    final quickReplies = [
      'Is this still available?',
      'What\'s the lowest price?',
      'Can we meet today?',
      'Thanks!',
    ];

    return Container(
      height: 6.h,
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: quickReplies.length,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(right: 2.w),
            child: ActionChip(
              label: Text(
                quickReplies[index],
                style: Theme.of(context).textTheme.bodySmall,
              ),
              onPressed: () => _sendQuickReply(quickReplies[index]),
              backgroundColor: Theme.of(context).colorScheme.surface,
              side: BorderSide(
                color: Theme.of(context).colorScheme.outline,
                width: 0.5,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.all(4.w),
      child: Row(
        children: [
          IconButton(
            onPressed: _toggleAttachmentOptions,
            icon: CustomIconWidget(
              iconName: _showAttachmentOptions ? 'close' : 'attach_file',
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 24,
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: widget.focusNode,
                      maxLines: 4,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 2.h,
                        ),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          widget.onSendMessage(value.trim());
                        }
                      },
                    ),
                  ),
                  if (!widget.isTyping)
                    GestureDetector(
                      onLongPressStart: (_) => _startRecording(),
                      onLongPressEnd: (_) => _stopRecording(),
                      child: Container(
                        margin: EdgeInsets.only(right: 2.w),
                        child: AnimatedBuilder(
                          animation: _recordingAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _isRecording
                                  ? _recordingAnimation.value
                                  : 1.0,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _isRecording
                                      ? AppTheme.lightTheme.colorScheme.error
                                      : AppTheme.lightTheme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: CustomIconWidget(
                                  iconName: _isRecording ? 'stop' : 'mic',
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(width: 2.w),
          if (widget.isTyping)
            GestureDetector(
              onTap: () {
                if (widget.controller.text.trim().isNotEmpty) {
                  widget.onSendMessage(widget.controller.text.trim());
                }
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: CustomIconWidget(
                  iconName: 'send',
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
