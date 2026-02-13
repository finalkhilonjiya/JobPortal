// File: lib/services/construction_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class ConstructionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Submit construction service request
  Future<void> submitConstructionRequest(Map<String, dynamic> requestData) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        requestData['user_id'] = user.id;
      }

      // DB already sets created_at = now()
      await _supabase.from('construction_service_requests').insert(requestData);
    } catch (e) {
      throw Exception('Failed to submit construction request: $e');
    }
  }

  /// Submit RCC Works request
  Future<void> submitRCCWorksRequest(Map<String, dynamic> formData) async {
    formData['service_type'] = 'RCC Works';
    await submitConstructionRequest(formData);
  }

  /// Submit Assam Type house request
  Future<void> submitAssamTypeRequest(Map<String, dynamic> formData) async {
    formData['service_type'] = 'Assam Type';
    await submitConstructionRequest(formData);
  }

  /// Submit Electrical Works request
  Future<void> submitElectricalWorksRequest(Map<String, dynamic> formData) async {
    formData['service_type'] = 'Electrical Works';
    await submitConstructionRequest(formData);
  }

  /// Submit False Ceiling request
  Future<void> submitFalseCeilingRequest(Map<String, dynamic> formData) async {
    formData['service_type'] = 'False Ceiling';
    await submitConstructionRequest(formData);
  }

  /// Submit Plumbing request
  Future<void> submitPlumbingRequest(Map<String, dynamic> formData) async {
    formData['service_type'] = 'Plumbing';
    await submitConstructionRequest(formData);
  }

  /// Submit Interior Design request
  Future<void> submitInteriorDesignRequest(Map<String, dynamic> formData) async {
    formData['service_type'] = 'Interior Design';
    await submitConstructionRequest(formData);
  }

  /// Get construction requests (admin / management)
  Future<List<Map<String, dynamic>>> getConstructionRequests({
    String? serviceType,
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _supabase.from('construction_service_requests').select();

      if (serviceType != null && serviceType.trim().isNotEmpty) {
        query = query.eq('service_type', serviceType.trim());
      }

      if (status != null && status.trim().isNotEmpty) {
        query = query.eq('status', status.trim());
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch construction requests: $e');
    }
  }

  /// Update construction request status (admin)
  Future<void> updateRequestStatus(
    String requestId,
    String status, {
    String? notes,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (notes != null && notes.trim().isNotEmpty) {
        updateData['admin_notes'] = notes.trim();
      }

      await _supabase
          .from('construction_service_requests')
          .update(updateData)
          .eq('id', requestId);
    } catch (e) {
      throw Exception('Failed to update request status: $e');
    }
  }

  /// Get current user's construction requests
  Future<List<Map<String, dynamic>>> getUserConstructionRequests() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('construction_service_requests')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch user requests: $e');
    }
  }

  /// Construction service stats (admin)
  /// NOTE: This is heavy because it fetches rows and counts locally.
  /// We'll later replace with a Postgres view/RPC for performance.
  Future<Map<String, dynamic>> getConstructionStats() async {
    try {
      final total = await _supabase.from('construction_service_requests').select('id');
      final pending = await _supabase
          .from('construction_service_requests')
          .select('id')
          .eq('status', 'pending');

      final completed = await _supabase
          .from('construction_service_requests')
          .select('id')
          .eq('status', 'completed');

      final types = await _supabase
          .from('construction_service_requests')
          .select('service_type')
          .order('service_type');

      final Map<String, int> typeCounts = {};
      for (final row in types) {
        final t = (row['service_type'] ?? '').toString();
        if (t.isEmpty) continue;
        typeCounts[t] = (typeCounts[t] ?? 0) + 1;
      }

      return {
        'total_requests': total.length,
        'pending_requests': pending.length,
        'completed_requests': completed.length,
        'service_type_counts': typeCounts,
      };
    } catch (e) {
      throw Exception('Failed to fetch construction stats: $e');
    }
  }
}