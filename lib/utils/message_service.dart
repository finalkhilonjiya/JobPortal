import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import './supabase_service.dart';

class MessageService {
  static final MessageService _instance = MessageService._internal();
  factory MessageService() => _instance;
  MessageService._internal();

  /// Get or create conversation between buyer and seller for a listing
  Future<Map<String, dynamic>> getOrCreateConversation({
    required String listingId,
    required String sellerId,
  }) async {
    try {
      final client = SupabaseService().client;
      final userId = client.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User must be authenticated');
      }

      if (userId == sellerId) {
        throw Exception('Cannot start conversation with yourself');
      }

      // Check if conversation already exists
      final existingConversation = await client
          .from('conversations')
          .select('''
            *,
            listing:listings(*),
            buyer:user_profiles!buyer_id(*),
            seller:user_profiles!seller_id(*)
          ''')
          .eq('listing_id', listingId)
          .eq('buyer_id', userId)
          .eq('seller_id', sellerId)
          .limit(1);

      if (existingConversation.isNotEmpty) {
        debugPrint('✅ Found existing conversation');
        return existingConversation.first;
      }

      // Create new conversation
      final newConversation = await client.from('conversations').insert({
        'listing_id': listingId,
        'buyer_id': userId,
        'seller_id': sellerId,
      }).select('''
            *,
            listing:listings(*),
            buyer:user_profiles!buyer_id(*),
            seller:user_profiles!seller_id(*)
          ''').single();

      debugPrint('✅ Created new conversation: ${newConversation['id']}');
      return newConversation;
    } catch (error) {
      debugPrint('❌ Failed to get/create conversation: $error');
      throw Exception('Failed to get/create conversation: $error');
    }
  }

  /// Get user's conversations
  Future<List<Map<String, dynamic>>> getUserConversations() async {
    try {
      final client = SupabaseService().client;
      final userId = client.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User must be authenticated');
      }

      final response = await client
          .from('conversations')
          .select('''
            *,
            listing:listings(*),
            buyer:user_profiles!buyer_id(*),
            seller:user_profiles!seller_id(*)
          ''')
          .or('buyer_id.eq.$userId,seller_id.eq.$userId')
          .order('last_message_at', ascending: false);

      debugPrint('✅ Fetched ${response.length} conversations');
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      debugPrint('❌ Failed to fetch conversations: $error');
      throw Exception('Failed to fetch conversations: $error');
    }
  }

  /// Get messages for a conversation
  Future<List<Map<String, dynamic>>> getConversationMessages(
    String conversationId, {
    int? limit,
    int? offset,
  }) async {
    try {
      final client = SupabaseService().client;
      final userId = client.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User must be authenticated');
      }

      // Verify user is part of this conversation
      final conversation = await client
          .from('conversations')
          .select('buyer_id, seller_id')
          .eq('id', conversationId)
          .single();

      if (conversation['buyer_id'] != userId &&
          conversation['seller_id'] != userId) {
        throw Exception('Access denied to this conversation');
      }

      var query = client
          .from('messages')
          .select('''
            *,
            sender:user_profiles!sender_id(*)
          ''')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 50) - 1);
      }

      final response = await query;

      // Mark messages as read
      await _markMessagesAsRead(conversationId, userId);

      debugPrint(
          '✅ Fetched ${response.length} messages for conversation: $conversationId');
      return List<Map<String, dynamic>>.from(response.reversed);
    } catch (error) {
      debugPrint('❌ Failed to fetch messages: $error');
      throw Exception('Failed to fetch messages: $error');
    }
  }

  /// Send a text message
  Future<Map<String, dynamic>> sendTextMessage({
    required String conversationId,
    required String content,
  }) async {
    try {
      final client = SupabaseService().client;
      final userId = client.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User must be authenticated');
      }

      final message = await client.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': userId,
        'content': content,
        'message_type': 'text',
      }).select('''
            *,
            sender:user_profiles!sender_id(*)
          ''').single();

      // Update conversation's last message
      await client.from('conversations').update({
        'last_message': content,
        'last_message_at': DateTime.now().toIso8601String(),
        'is_read_by_buyer': false,
        'is_read_by_seller': false,
      }).eq('id', conversationId);

      debugPrint('✅ Sent text message: ${message['id']}');
      return message;
    } catch (error) {
      debugPrint('❌ Failed to send message: $error');
      throw Exception('Failed to send message: $error');
    }
  }

  /// Send an image message
  Future<Map<String, dynamic>> sendImageMessage({
    required String conversationId,
    required String imageUrl,
    String? caption,
  }) async {
    try {
      final client = SupabaseService().client;
      final userId = client.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User must be authenticated');
      }

      final message = await client.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': userId,
        'content': caption,
        'message_type': 'image',
        'image_url': imageUrl,
      }).select('''
            *,
            sender:user_profiles!sender_id(*)
          ''').single();

      // Update conversation's last message
      await client.from('conversations').update({
        'last_message': '📷 Photo',
        'last_message_at': DateTime.now().toIso8601String(),
        'is_read_by_buyer': false,
        'is_read_by_seller': false,
      }).eq('id', conversationId);

      debugPrint('✅ Sent image message: ${message['id']}');
      return message;
    } catch (error) {
      debugPrint('❌ Failed to send image message: $error');
      throw Exception('Failed to send image message: $error');
    }
  }

  /// Send a location message
  Future<Map<String, dynamic>> sendLocationMessage({
    required String conversationId,
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    try {
      final client = SupabaseService().client;
      final userId = client.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User must be authenticated');
      }

      final locationData = {
        'latitude': latitude,
        'longitude': longitude,
        if (address != null) 'address': address,
      };

      final message = await client.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': userId,
        'message_type': 'location',
        'location_data': locationData,
      }).select('''
            *,
            sender:user_profiles!sender_id(*)
          ''').single();

      // Update conversation's last message
      await client.from('conversations').update({
        'last_message': '📍 Location',
        'last_message_at': DateTime.now().toIso8601String(),
        'is_read_by_buyer': false,
        'is_read_by_seller': false,
      }).eq('id', conversationId);

      debugPrint('✅ Sent location message: ${message['id']}');
      return message;
    } catch (error) {
      debugPrint('❌ Failed to send location message: $error');
      throw Exception('Failed to send location message: $error');
    }
  }

  /// Mark messages as read
  Future<void> _markMessagesAsRead(String conversationId, String userId) async {
    try {
      final client = SupabaseService().client;

      // Mark all unread messages in this conversation as read
      await client
          .from('messages')
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .neq('sender_id', userId)
          .eq('is_read', false);

      // Update conversation read status
      final conversation = await client
          .from('conversations')
          .select('buyer_id, seller_id')
          .eq('id', conversationId)
          .single();

      final isUserBuyer = conversation['buyer_id'] == userId;
      final updateField =
          isUserBuyer ? 'is_read_by_buyer' : 'is_read_by_seller';

      await client
          .from('conversations')
          .update({updateField: true}).eq('id', conversationId);

      debugPrint('✅ Marked messages as read for conversation: $conversationId');
    } catch (error) {
      debugPrint('❌ Failed to mark messages as read: $error');
      // Don't throw error as this is a secondary operation
    }
  }

  /// Get unread messages count
  Future<int> getUnreadMessagesCount() async {
    try {
      final client = SupabaseService().client;
      final userId = client.auth.currentUser?.id;

      if (userId == null) {
        return 0;
      }

      final response = await client
          .from('conversations')
          .select('*')
          .or('buyer_id.eq.$userId,seller_id.eq.$userId')
          .or('is_read_by_buyer.eq.false,is_read_by_seller.eq.false');

      final count = response.length;
      debugPrint('✅ User has $count unread conversations');
      return count;
    } catch (error) {
      debugPrint('❌ Failed to get unread count: $error');
      return 0;
    }
  }

  /// Subscribe to real-time messages for a conversation
  RealtimeChannel subscribeToConversation(
      String conversationId, Function(Map<String, dynamic>) onNewMessage) {
    final client = SupabaseService().client;

    final channel = client
        .channel('conversation_$conversationId')
        .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'messages',
            filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'conversation_id',
                value: conversationId),
            callback: (payload) {
              debugPrint('🔄 New message received: ${payload.newRecord}');
              onNewMessage(payload.newRecord);
            })
        .subscribe();

    debugPrint('✅ Subscribed to conversation: $conversationId');
    return channel;
  }

  /// Unsubscribe from conversation updates
  void unsubscribeFromConversation(RealtimeChannel channel) {
    try {
      SupabaseService().client.removeChannel(channel);
      debugPrint('✅ Unsubscribed from conversation');
    } catch (error) {
      debugPrint('❌ Failed to unsubscribe: $error');
    }
  }
}
