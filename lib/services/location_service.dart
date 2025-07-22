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
  Future<LocationResult?> findNearestLocation(double latitude, double longitude) async {
    try {
      final response = await _supabase.rpc(
        'find_nearest_location_simple', // Use the simple version
        params: {
          'user_lat': latitude,
          'user_lng': longitude,
        },
      );

      if (response == null || (response as List).isEmpty) {
        return null;
      }

      final location = response[0];
      
      // If the nearest location is more than 5km away, 
      // return a generic "Near [location]" response
      final distanceKm = location['distance_km'] ?? 0;
      
      if (distanceKm > 5) {
        return LocationResult(
          id: location['id'],
          city: location['city'],
          state: location['state'],
          latitude: latitude, // Use user's actual coordinates
          longitude: longitude,
          displayName: 'Near ${location['name']}, ${location['city']}',
        );
      } else {
        // If within 5km, use the actual location
        return LocationResult(
          id: location['id'],
          city: location['city'],
          state: location['state'],
          latitude: location['latitude'],
          longitude: location['longitude'],
          displayName: location['display_name'],
        );
      }
    } catch (e) {
      print('Error finding nearest location: $e');
      return null;
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