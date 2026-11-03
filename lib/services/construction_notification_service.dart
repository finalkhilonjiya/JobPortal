// lib/services/construction_notification_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class ConstructionNotificationService {
  final SupabaseClient _db = Supabase.instance.client;

  Future<int> getUnreadCount() async {
    final user = _db.auth.currentUser;
    if (user == null) return 0;

    try {
      final res = await _db
          .from('notifications')
          .select('id')
          .eq('user_id', user.id)
          .eq('user_role', 'construction')
          .eq('is_read', false);

      return (res as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> fetchNotifications({
    int limit = 50,
  }) async {
    final user = _db.auth.currentUser;
    if (user == null) return [];

    try {
      final res = await _db
          .from('notifications')
          .select('id,type,title,body,data,is_read,created_at')
          .eq('user_id', user.id)
          .eq('user_role', 'construction')
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }

  Future<void> markAllRead() async {
    final user = _db.auth.currentUser;
    if (user == null) return;

    try {
      await _db
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', user.id)
          .eq('user_role', 'construction')
          .eq('is_read', false);
    } catch (_) {}
  }

  Future<void> markRead(String id) async {
    final user = _db.auth.currentUser;
    if (user == null) return;

    try {
      await _db
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id)
          .eq('user_id', user.id);
    } catch (_) {}
  }
}