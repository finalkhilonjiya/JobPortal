// File: lib/services/construction_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class ConstructionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Submit construction service request
  Future<void> submitConstructionRequest(Map<String, dynamic> requestData) async {
    try {
      // Get current user
      final user = _supabase.auth.currentUser;
      if (user != null) {
        requestData['user_id'] = user.id;
      }

      // Add timestamp
      requestData['created_at'] = DateTime.now().toIso8601String();

      // Insert into database
      await _supabase
          .from('construction_service_requests')
          .insert(requestData);

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

  /// Get construction requests for admin
  Future<List<Map<String, dynamic>>> getConstructionRequests({
    String? serviceType,
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _supabase
          .from('construction_service_requests')
          .select()
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      if (serviceType != null) {
        query = query.eq('service_type', serviceType);
      }

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);

    } catch (e) {
      throw Exception('Failed to fetch construction requests: $e');
    }
  }

  /// Update construction request status
  Future<void> updateRequestStatus(String requestId, String status, {String? notes}) async {
    try {
      Map<String, dynamic> updateData = {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (notes != null) {
        updateData['admin_notes'] = notes;
      }

      await _supabase
          .from('construction_service_requests')
          .update(updateData)
          .eq('id', requestId);

    } catch (e) {
      throw Exception('Failed to update request status: $e');
    }
  }

  /// Get user's construction requests
  Future<List<Map<String, dynamic>>> getUserConstructionRequests() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

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

  /// Get construction service statistics
  Future<Map<String, dynamic>> getConstructionStats() async {
    try {
      // Get total requests
      final totalRequestsResponse = await _supabase
          .from('construction_service_requests')
          .select('*', const FetchOptions(count: CountOption.exact));

      // Get pending requests
      final pendingRequestsResponse = await _supabase
          .from('construction_service_requests')
          .select('*', const FetchOptions(count: CountOption.exact))
          .eq('status', 'pending');

      // Get completed requests
      final completedRequestsResponse = await _supabase
          .from('construction_service_requests')
          .select('*', const FetchOptions(count: CountOption.exact))
          .eq('status', 'completed');

      // Get requests by service type
      final serviceTypeStats = await _supabase
          .from('construction_service_requests')
          .select('service_type')
          .order('service_type');

      // Count by service type
      Map<String, int> serviceTypeCounts = {};
      for (var request in serviceTypeStats) {
        String serviceType = request['service_type'];
        serviceTypeCounts[serviceType] = (serviceTypeCounts[serviceType] ?? 0) + 1;
      }

      return {
        'total_requests': totalRequestsResponse.count,
        'pending_requests': pendingRequestsResponse.count,
        'completed_requests': completedRequestsResponse.count,
        'service_type_counts': serviceTypeCounts,
      };

    } catch (e) {
      throw Exception('Failed to fetch construction stats: $e');
    }
  }
}