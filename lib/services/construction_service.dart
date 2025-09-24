import 'package:supabase_flutter/supabase_flutter.dart';

class ConstructionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> submitConstructionRequest(Map<String, dynamic> formData) async {
    try {
      // Add user_id if authenticated
      final user = _supabase.auth.currentUser;
      if (user != null) {
        formData['user_id'] = user.id;
      }

      // Add timestamp
      formData['created_at'] = DateTime.now().toIso8601String();
      
      await _supabase
          .from('construction_service_requests')
          .insert(formData);
    } catch (e) {
      throw Exception('Failed to submit request: $e');
    }
  }
}