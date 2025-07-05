import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/location_message_widget.dart';
import './widgets/message_bubble_widget.dart';
import './widgets/message_input_widget.dart';
import './widgets/photo_message_widget.dart';
import './widgets/typing_indicator_widget.dart';
import './widgets/voice_message_widget.dart';

class ChatMessaging extends StatefulWidget {
  const ChatMessaging({Key? key}) : super(key: key);

  @override
  State<ChatMessaging> createState() => _ChatMessagingState();
}

class _ChatMessagingState extends State<ChatMessaging>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();

  bool _isTyping = false;
  bool _isOtherUserTyping = false;
  bool _isLoading = false;
  String _selectedMessageId = '';

  // Mock data for chat messages
  final List<Map<String, dynamic>> _messages = [
    {
      "id": "msg_001",
      "senderId": "user_123",
      "senderName": "John Smith",
      "senderAvatar":
          "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face",
      "message": "Hi! Is this iPhone still available?",
      "timestamp": DateTime.now().subtract(const Duration(hours: 2)),
      "messageType": "text",
      "isRead": true,
      "isDelivered": true,
      "isSent": true,
      "isMe": false,
    },
    {
      "id": "msg_002",
      "senderId": "current_user",
      "senderName": "Me",
      "senderAvatar":
          "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face",
      "message": "Yes, it's still available! Are you interested?",
      "timestamp":
          DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
      "messageType": "text",
      "isRead": true,
      "isDelivered": true,
      "isSent": true,
      "isMe": true,
    },
    {
      "id": "msg_003",
      "senderId": "user_123",
      "senderName": "John Smith",
      "senderAvatar":
          "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face",
      "message": "Great! Can you send me more photos?",
      "timestamp":
          DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
      "messageType": "text",
      "isRead": true,
      "isDelivered": true,
      "isSent": true,
      "isMe": false,
    },
    {
      "id": "msg_004",
      "senderId": "current_user",
      "senderName": "Me",
      "senderAvatar":
          "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face",
      "message": "",
      "timestamp":
          DateTime.now().subtract(const Duration(hours: 1, minutes: 15)),
      "messageType": "photo",
      "photoUrls": [
        "https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=400&h=300&fit=crop",
        "https://images.unsplash.com/photo-1565849904461-04a58ad377e0?w=400&h=300&fit=crop"
      ],
      "isRead": true,
      "isDelivered": true,
      "isSent": true,
      "isMe": true,
    },
    {
      "id": "msg_005",
      "senderId": "user_123",
      "senderName": "John Smith",
      "senderAvatar":
          "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face",
      "message": "",
      "timestamp": DateTime.now().subtract(const Duration(minutes: 45)),
      "messageType": "voice",
      "voiceDuration": "0:23",
      "voiceUrl": "voice_message_url",
      "isRead": true,
      "isDelivered": true,
      "isSent": true,
      "isMe": false,
    },
    {
      "id": "msg_006",
      "senderId": "current_user",
      "senderName": "Me",
      "senderAvatar":
          "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face",
      "message": "",
      "timestamp": DateTime.now().subtract(const Duration(minutes: 30)),
      "messageType": "location",
      "locationName": "Central Park Mall",
      "locationAddress": "123 Main Street, Downtown",
      "latitude": 40.7829,
      "longitude": -73.9654,
      "isRead": true,
      "isDelivered": true,
      "isSent": true,
      "isMe": true,
    },
    {
      "id": "msg_007",
      "senderId": "user_123",
      "senderName": "John Smith",
      "senderAvatar":
          "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face",
      "message": "Perfect! I can meet you there at 3 PM today. Is that okay?",
      "timestamp": DateTime.now().subtract(const Duration(minutes: 15)),
      "messageType": "text",
      "isRead": true,
      "isDelivered": true,
      "isSent": true,
      "isMe": false,
    },
    {
      "id": "msg_008",
      "senderId": "current_user",
      "senderName": "Me",
      "senderAvatar":
          "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face",
      "message": "Sounds good! See you at 3 PM 👍",
      "timestamp": DateTime.now().subtract(const Duration(minutes: 5)),
      "messageType": "text",
      "isRead": false,
      "isDelivered": true,
      "isSent": true,
      "isMe": true,
    },
  ];

  // Mock listing data for context
  final Map<String, dynamic> _listingContext = {
    "id": "listing_001",
    "title": "iPhone 14 Pro Max - 256GB",
    "price": "\$899",
    "thumbnail":
        "https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=100&h=100&fit=crop",
    "condition": "Like New",
  };

  // Mock contact data
  final Map<String, dynamic> _contactInfo = {
    "id": "user_123",
    "name": "John Smith",
    "avatar":
        "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face",
    "isOnline": true,
    "lastSeen": DateTime.now().subtract(const Duration(minutes: 2)),
    "isVerified": true,
    "rating": 4.8,
    "totalReviews": 127,
  };

  @override
  void initState() {
    super.initState();
    _scrollToBottom();
    _simulateTypingIndicator();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _simulateTypingIndicator() {
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _isOtherUserTyping = true;
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _isOtherUserTyping = false;
            });
          }
        });
      }
    });
  }

  void _sendMessage(String message, String messageType,
      {Map<String, dynamic>? extraData}) {
    if (message.trim().isEmpty && messageType == 'text') return;

    final newMessage = {
      "id": "msg_${DateTime.now().millisecondsSinceEpoch}",
      "senderId": "current_user",
      "senderName": "Me",
      "senderAvatar":
          "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face",
      "message": message,
      "timestamp": DateTime.now(),
      "messageType": messageType,
      "isRead": false,
      "isDelivered": false,
      "isSent": false,
      "isMe": true,
      ...?extraData,
    };

    setState(() {
      _messages.add(newMessage);
      _messageController.clear();
      _isTyping = false;
    });

    _scrollToBottom();

    // Simulate message sending states
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          final index =
              _messages.indexWhere((msg) => msg['id'] == newMessage['id']);
          if (index != -1) {
            _messages[index]['isSent'] = true;
          }
        });
      }
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          final index =
              _messages.indexWhere((msg) => msg['id'] == newMessage['id']);
          if (index != -1) {
            _messages[index]['isDelivered'] = true;
          }
        });
      }
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          final index =
              _messages.indexWhere((msg) => msg['id'] == newMessage['id']);
          if (index != -1) {
            _messages[index]['isRead'] = true;
          }
        });
      }
    });
  }

  void _onMessageLongPress(String messageId) {
    setState(() {
      _selectedMessageId = messageId;
    });

    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildMessageContextMenu(messageId),
    );
  }

  Widget _buildMessageContextMenu(String messageId) {
    final message = _messages.firstWhere((msg) => msg['id'] == messageId);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4,
              margin: EdgeInsets.symmetric(vertical: 2.h),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (message['messageType'] == 'text') ...[
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'content_copy',
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 24,
                ),
                title: Text(
                  'Copy Message',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: message['message']));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Message copied to clipboard')),
                  );
                },
              ),
            ],
            if (message['isMe']) ...[
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'delete',
                  color: AppTheme.lightTheme.colorScheme.error,
                  size: 24,
                ),
                title: Text(
                  'Delete Message',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.error,
                      ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(messageId);
                },
              ),
            ] else ...[
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'report',
                  color: AppTheme.lightTheme.colorScheme.error,
                  size: 24,
                ),
                title: Text(
                  'Report Message',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.error,
                      ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _reportMessage(messageId);
                },
              ),
            ],
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  void _deleteMessage(String messageId) {
    setState(() {
      _messages.removeWhere((msg) => msg['id'] == messageId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message deleted')),
    );
  }

  void _reportMessage(String messageId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Message'),
        content: const Text(
            'Are you sure you want to report this message? Our team will review it.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Message reported successfully')),
              );
            },
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshMessages() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate loading older messages
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isLoading = false;
    });
  }

  void _blockUser() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: Text(
            'Are you sure you want to block ${_contactInfo['name']}? You won\'t receive messages from them anymore.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('${_contactInfo['name']} has been blocked')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightTheme.colorScheme.error,
            ),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildListingContext(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshMessages,
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                itemCount: _messages.length + (_isOtherUserTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isOtherUserTyping) {
                    return TypingIndicatorWidget(
                      senderName: _contactInfo['name'],
                      senderAvatar: _contactInfo['avatar'],
                    );
                  }

                  final message = _messages[index];
                  return _buildMessageItem(message);
                },
              ),
            ),
          ),
          MessageInputWidget(
            controller: _messageController,
            focusNode: _messageFocusNode,
            isTyping: _isTyping,
            onSendMessage: (message) => _sendMessage(message, 'text'),
            onTypingChanged: (isTyping) {
              setState(() {
                _isTyping = isTyping;
              });
            },
            onSendVoiceMessage: (duration) =>
                _sendMessage('', 'voice', extraData: {
              'voiceDuration': duration,
              'voiceUrl': 'voice_message_url',
            }),
            onSendPhoto: (photoUrls) => _sendMessage('', 'photo', extraData: {
              'photoUrls': photoUrls,
            }),
            onSendLocation: (locationData) =>
                _sendMessage('', 'location', extraData: locationData),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 1,
      shadowColor: Theme.of(context).colorScheme.shadow,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: CustomIconWidget(
          iconName: 'arrow_back',
          color: Theme.of(context).colorScheme.onSurface,
          size: 24,
        ),
      ),
      title: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Theme.of(context).colorScheme.outline,
                child: CustomImageWidget(
                  imageUrl: _contactInfo['avatar'],
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              ),
              if (_contactInfo['isOnline'])
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppTheme.getSuccessColor(
                          Theme.of(context).brightness == Brightness.light),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.surface,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _contactInfo['name'],
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_contactInfo['isVerified']) ...[
                      SizedBox(width: 1.w),
                      CustomIconWidget(
                        iconName: 'verified',
                        color: AppTheme.lightTheme.colorScheme.primary,
                        size: 16,
                      ),
                    ],
                  ],
                ),
                Text(
                  _contactInfo['isOnline']
                      ? 'Online'
                      : 'Last seen ${_formatLastSeen(_contactInfo['lastSeen'])}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _contactInfo['isOnline']
                            ? AppTheme.getSuccessColor(
                                Theme.of(context).brightness ==
                                    Brightness.light)
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            // Navigate to user profile
            Navigator.pushNamed(context, '/user-profile');
          },
          icon: CustomIconWidget(
            iconName: 'person',
            color: Theme.of(context).colorScheme.onSurface,
            size: 24,
          ),
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'block':
                _blockUser();
                break;
              case 'report':
                _reportMessage('');
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'block',
              child: Row(
                children: [
                  Icon(Icons.block, size: 20),
                  SizedBox(width: 8),
                  Text('Block User'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'report',
              child: Row(
                children: [
                  Icon(Icons.report, size: 20),
                  SizedBox(width: 8),
                  Text('Report User'),
                ],
              ),
            ),
          ],
          icon: CustomIconWidget(
            iconName: 'more_vert',
            color: Theme.of(context).colorScheme.onSurface,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildListingContext() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CustomImageWidget(
              imageUrl: _listingContext['thumbnail'],
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _listingContext['title'],
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 0.5.h),
                Row(
                  children: [
                    Text(
                      _listingContext['price'],
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    SizedBox(width: 2.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 2.w, vertical: 0.5.h),
                      decoration: BoxDecoration(
                        color: AppTheme.getSuccessColor(
                                Theme.of(context).brightness ==
                                    Brightness.light)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _listingContext['condition'],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.getSuccessColor(
                                  Theme.of(context).brightness ==
                                      Brightness.light),
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/listing-detail');
            },
            icon: CustomIconWidget(
              iconName: 'arrow_forward_ios',
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(Map<String, dynamic> message) {
    return GestureDetector(
      onLongPress: () => _onMessageLongPress(message['id']),
      child: Container(
        margin: EdgeInsets.only(bottom: 2.h),
        child: _buildMessageByType(message),
      ),
    );
  }

  Widget _buildMessageByType(Map<String, dynamic> message) {
    switch (message['messageType']) {
      case 'text':
        return MessageBubbleWidget(
          message: message,
          isSelected: _selectedMessageId == message['id'],
        );
      case 'voice':
        return VoiceMessageWidget(
          message: message,
          isSelected: _selectedMessageId == message['id'],
        );
      case 'photo':
        return PhotoMessageWidget(
          message: message,
          isSelected: _selectedMessageId == message['id'],
        );
      case 'location':
        return LocationMessageWidget(
          message: message,
          isSelected: _selectedMessageId == message['id'],
        );
      default:
        return MessageBubbleWidget(
          message: message,
          isSelected: _selectedMessageId == message['id'],
        );
    }
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${lastSeen.day}/${lastSeen.month}/${lastSeen.year}';
    }
  }
}
