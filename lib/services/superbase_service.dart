import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;

  static String requireUserId() {
    final user = client.auth.currentUser;
    if (user == null) {
      throw Exception('Not authenticated');
    }
    return user.id;
  }
}