// File: lib/services/location_service.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LocationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ------------------------------------------------------------
  // Search locations with autocomplete (RPC)
  // RPC: search_locations(search_term, limit_count)
  // ------------------------------------------------------------
  Future<List<LocationResult>> searchLocations(String query) async {
    final q = query.trim();
    if (q.length < 2) return [];

    try {
      final response = await _supabase.rpc(
        'search_locations',
        params: {
          'search_term': q,
          'limit_count': 10,
        },
      );

      if (response == null) return [];

      final list = _asList(response);

      return list
          .map((e) => LocationResult.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      debugPrint('searchLocations error: $e');
      return [];
    }
  }

  // ------------------------------------------------------------
  // Find nearest location (RPC)
  // RPC: find_nearest_location_simple(user_lat, user_lng)
  // ------------------------------------------------------------
  Future<LocationResult?> findNearestLocation(
    double latitude,
    double longitude,
  ) async {
    try {
      final response = await _supabase.rpc(
        'find_nearest_location_simple',
        params: {
          'user_lat': latitude,
          'user_lng': longitude,
        },
      );

      if (response == null) return null;

      final list = _asList(response);
      if (list.isEmpty) return null;

      final location = Map<String, dynamic>.from(list.first);

      final distanceKm = _toDouble(location['distance_km']);

      // If nearest location is far, show "Near ..."
      if (distanceKm > 5) {
        return LocationResult(
          id: (location['id'] ?? '').toString(),
          city: (location['city'] ?? '').toString(),
          state: (location['state'] ?? '').toString(),
          latitude: latitude,
          longitude: longitude,
          displayName:
              'Near ${(location['name'] ?? '').toString()}, ${(location['city'] ?? '').toString()}',
        );
      }

      return LocationResult(
        id: (location['id'] ?? '').toString(),
        city: (location['city'] ?? '').toString(),
        state: (location['state'] ?? '').toString(),
        latitude: _toDouble(location['latitude']),
        longitude: _toDouble(location['longitude']),
        displayName: (location['display_name'] ??
                '${location['city'] ?? ''}, ${location['state'] ?? ''}')
            .toString(),
      );
    } catch (e) {
      debugPrint('findNearestLocation error: $e');
      return null;
    }
  }

  // ------------------------------------------------------------
  // Get locations by state (Table query)
  // ------------------------------------------------------------
  Future<List<LocationResult>> getLocationsByState(String state) async {
    final s = state.trim();
    if (s.isEmpty) return [];

    try {
      final response = await _supabase
          .from('locations')
          .select('*')
          .eq('state', s)
          .order('popularity', ascending: false)
          .limit(20);

      final list = _asList(response);

      return list
          .map((e) => LocationResult.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      debugPrint('getLocationsByState error: $e');
      return [];
    }
  }

  // ------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------
  List<dynamic> _asList(dynamic response) {
    if (response is List) return response;
    if (response is Map) return [response];
    return [];
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

class LocationResult {
  final String id;
  final String city;
  final String state;
  final double latitude;
  final double longitude;
  final String displayName;

  LocationResult({
    required this.id,
    required this.city,
    required this.state,
    required this.latitude,
    required this.longitude,
    required this.displayName,
  });

  factory LocationResult.fromJson(Map<String, dynamic> json) {
    return LocationResult(
      id: (json['id'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      state: (json['state'] ?? '').toString(),
      latitude: _toDoubleStatic(json['latitude']),
      longitude: _toDoubleStatic(json['longitude']),
      displayName: (json['display_name'] ??
              '${json['city'] ?? ''}, ${json['state'] ?? ''}')
          .toString(),
    );
  }

  static double _toDoubleStatic(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}