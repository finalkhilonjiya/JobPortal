// File: services/location_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class LocationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Search locations with autocomplete
  Future<List<LocationResult>> searchLocations(String query) async {
    if (query.isEmpty || query.length < 2) {
      return [];
    }

    try {
      final response = await _supabase
          .rpc('search_locations', params: {
            'search_term': query,
            'limit_count': 10
          });

      if (response == null) return [];

      return (response as List)
          .map((location) => LocationResult.fromJson(location))
          .toList();
    } catch (e) {
      print('Error searching locations: $e');
      return [];
    }
  }

  // Get all locations for a specific state
  Future<List<LocationResult>> getLocationsByState(String state) async {
    try {
      final response = await _supabase
          .from('locations')
          .select('*')
          .eq('state', state)
          .order('popularity', ascending: false)
          .limit(20);

      return (response as List)
          .map((location) => LocationResult.fromJson(location))
          .toList();
    } catch (e) {
      print('Error fetching locations by state: $e');
      return [];
    }
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
      id: json['id'],
      city: json['city'],
      state: json['state'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      displayName: json['display_name'] ?? '${json['city']}, ${json['state']}',
    );
  }
}