// File: lib/services/construction_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class ConstructionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Core submit method
  Future<void> submitConstructionRequest(
    Map<String, dynamic> requestData,
  ) async {
    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        throw Exception("User not authenticated");
      }

      // Attach user_id
      requestData['user_id'] = user.id;

      // ======================================
      // Attach district geo coordinates
      // ======================================
      if (requestData['project_address'] != null) {
        final districtData = await _supabase
            .from('assam_districts_master')
            .select('latitude, longitude')
            .eq(
              'district_name',
              requestData['project_address'],
            )
            .maybeSingle();

        if (districtData != null) {
          requestData['latitude'] =
              districtData['latitude'];

          requestData['longitude'] =
              districtData['longitude'];
        }
      }

      requestData['status'] ??= 'pending';

      // ======================================
      // Insert Request
      // ======================================
      await _supabase
          .from('construction_service_requests')
          .insert(requestData);

    } catch (e) {
      throw Exception(
        'Failed to submit construction request: $e',
      );
    }
  }

  /// ============================
  /// Service Specific Wrappers
  /// ============================

  Future<void> submitRCCWorksRequest(
    Map<String, dynamic> formData,
  ) async {
    formData['service_type'] = 'rcc';
    formData['service_type_detail'] =
        'RCC Works';

    await submitConstructionRequest(formData);
  }

  Future<void> submitAssamTypeRequest(
    Map<String, dynamic> formData,
  ) async {
    formData['service_type'] = 'assam_type';
    formData['service_type_detail'] =
        'Assam Type';

    await submitConstructionRequest(formData);
  }

  Future<void> submitElectricalWorksRequest(
    Map<String, dynamic> formData,
  ) async {
    formData['service_type'] = 'electrical';
    formData['service_type_detail'] =
        'Electrical Works';

    await submitConstructionRequest(formData);
  }

  Future<void> submitFalseCeilingRequest(
    Map<String, dynamic> formData,
  ) async {
    formData['service_type'] = 'false_ceiling';
    formData['service_type_detail'] =
        'False Ceiling';

    await submitConstructionRequest(formData);
  }

  Future<void> submitPlumbingRequest(
    Map<String, dynamic> formData,
  ) async {
    formData['service_type'] = 'plumbing';
    formData['service_type_detail'] =
        'Plumbing';

    await submitConstructionRequest(formData);
  }

  Future<void> submitInteriorDesignRequest(
    Map<String, dynamic> formData,
  ) async {
    formData['service_type'] = 'interior';
    formData['service_type_detail'] =
        'Interior Design';

    await submitConstructionRequest(formData);
  }

  /// ============================
  /// Admin / Management
  /// ============================

  Future<List<Map<String, dynamic>>>
      getConstructionRequests({
    String? serviceType,
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _supabase
          .from('construction_service_requests')
          .select();

      if (serviceType != null &&
          serviceType.trim().isNotEmpty) {
        query = query.eq(
          'service_type',
          serviceType.trim(),
        );
      }

      if (status != null &&
          status.trim().isNotEmpty) {
        query = query.eq(
          'status',
          status.trim(),
        );
      }

      final response = await query
          .order(
            'created_at',
            ascending: false,
          )
          .range(
            offset,
            offset + limit - 1,
          );

      return List<Map<String, dynamic>>.from(
        response,
      );

    } catch (e) {
      throw Exception(
        'Failed to fetch construction requests: $e',
      );
    }
  }

  Future<void> updateRequestStatus(
    String requestId,
    String status, {
    String? notes,
    num? quoteAmount,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status,
        'updated_at':
            DateTime.now().toIso8601String(),
      };

      if (notes != null &&
          notes.trim().isNotEmpty) {
        updateData['admin_notes'] =
            notes.trim();
      }

      if (quoteAmount != null) {
        updateData['quote_amount'] =
            quoteAmount;
      }

      await _supabase
          .from('construction_service_requests')
          .update(updateData)
          .eq('id', requestId);

    } catch (e) {
      throw Exception(
        'Failed to update request status: $e',
      );
    }
  }

  /// ============================
  /// User Requests
  /// ============================

  Future<List<Map<String, dynamic>>>
      getUserConstructionRequests() async {
    try {
      final user =
          _supabase.auth.currentUser;

      if (user == null) {
        throw Exception(
          'User not authenticated',
        );
      }

      final response = await _supabase
          .from('construction_service_requests')
          .select()
          .eq('user_id', user.id)
          .order(
            'created_at',
            ascending: false,
          );

      return List<Map<String, dynamic>>.from(
        response,
      );

    } catch (e) {
      throw Exception(
        'Failed to fetch user requests: $e',
      );
    }
  }

  /// ============================
  /// Stats
  /// ============================

  Future<Map<String, dynamic>>
      getConstructionStats() async {
    try {
      final total = await _supabase
          .from('construction_service_requests')
          .select('id');

      final pending = await _supabase
          .from('construction_service_requests')
          .select('id')
          .eq('status', 'pending');

      final completed = await _supabase
          .from('construction_service_requests')
          .select('id')
          .eq('status', 'completed');

      return {
        'total_requests': total.length,
        'pending_requests': pending.length,
        'completed_requests':
            completed.length,
      };

    } catch (e) {
      throw Exception(
        'Failed to fetch construction stats: $e',
      );
    }
  }
}