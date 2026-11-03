import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Google Places API helper for:
/// - Autocomplete suggestions
/// - Place details (lat/lng)
/// - Reverse geocoding
///
/// IMPORTANT:
/// - API key must be injected via --dart-define
///   Example:
///   flutter run --dart-define=GOOGLE_PLACES_API_KEY=xxxx
///
/// - For release builds:
///   flutter build apk --release --dart-define=GOOGLE_PLACES_API_KEY=xxxx
class GooglePlacesService {
  /// Read from build-time environment variable
  static const String _apiKey =
      String.fromEnvironment('GOOGLE_PLACES_API_KEY', defaultValue: '');

  static const String _autocompleteUrl =
      'https://maps.googleapis.com/maps/api/place/autocomplete/json';
  static const String _detailsUrl =
      'https://maps.googleapis.com/maps/api/place/details/json';
  static const String _geocodeUrl =
      'https://maps.googleapis.com/maps/api/geocode/json';

  bool get isConfigured => _apiKey.isNotEmpty;

  /// Search places by text input (autocomplete)
  ///
  /// sessionToken:
  /// You should generate one token per user search session.
  /// Example:
  /// - When user focuses input: generate token
  /// - Use same token for all autocomplete calls
  /// - Use same token for details call
  /// - When user selects: clear token
  Future<List<PlaceSuggestion>> searchPlaces(
    String input, {
    String? sessionToken,
    String countryCode = 'in',
  }) async {
    if (!isConfigured) {
      debugPrint(
        'GooglePlacesService not configured. Missing GOOGLE_PLACES_API_KEY.',
      );
      return [];
    }

    final q = input.trim();
    if (q.isEmpty || q.length < 2) return [];

    try {
      final uri = Uri.parse(_autocompleteUrl).replace(queryParameters: {
        'input': q,
        'key': _apiKey,
        'components': 'country:$countryCode',
        'types': 'geocode',
        if (sessionToken != null && sessionToken.isNotEmpty)
          'sessiontoken': sessionToken,
      });

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        debugPrint('Google Places HTTP Error: ${response.statusCode}');
        return [];
      }

      final data = json.decode(response.body);

      final status = (data['status'] ?? '').toString();
      if (status != 'OK') {
        // Common: ZERO_RESULTS, OVER_QUERY_LIMIT, REQUEST_DENIED
        debugPrint('Google Places API Error: $status');
        return [];
      }

      final predictions = (data['predictions'] as List? ?? []);
      return predictions
          .map((p) => PlaceSuggestion.fromJson(Map<String, dynamic>.from(p)))
          .toList();
    } catch (e) {
      debugPrint('Error searching places: $e');
      return [];
    }
  }

  /// Get place details (lat/lng) from place ID
  Future<PlaceDetails?> getPlaceDetails(
    String placeId, {
    String? sessionToken,
  }) async {
    if (!isConfigured) {
      debugPrint(
        'GooglePlacesService not configured. Missing GOOGLE_PLACES_API_KEY.',
      );
      return null;
    }

    final id = placeId.trim();
    if (id.isEmpty) return null;

    try {
      final uri = Uri.parse(_detailsUrl).replace(queryParameters: {
        'place_id': id,
        'key': _apiKey,
        'fields': 'geometry,name,formatted_address',
        if (sessionToken != null && sessionToken.isNotEmpty)
          'sessiontoken': sessionToken,
      });

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        debugPrint('Google Place Details HTTP Error: ${response.statusCode}');
        return null;
      }

      final data = json.decode(response.body);

      final status = (data['status'] ?? '').toString();
      if (status != 'OK') {
        debugPrint('Google Place Details API Error: $status');
        return null;
      }

      final result = data['result'];
      if (result == null) return null;

      return PlaceDetails.fromJson(Map<String, dynamic>.from(result));
    } catch (e) {
      debugPrint('Error getting place details: $e');
      return null;
    }
  }

  /// Reverse geocode (lat/lng -> formatted address)
  Future<String?> reverseGeocode(double latitude, double longitude) async {
    if (!isConfigured) {
      debugPrint(
        'GooglePlacesService not configured. Missing GOOGLE_PLACES_API_KEY.',
      );
      return null;
    }

    try {
      final uri = Uri.parse(_geocodeUrl).replace(queryParameters: {
        'latlng': '$latitude,$longitude',
        'key': _apiKey,
      });

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        debugPrint('Google Geocode HTTP Error: ${response.statusCode}');
        return null;
      }

      final data = json.decode(response.body);

      final status = (data['status'] ?? '').toString();
      if (status != 'OK') {
        debugPrint('Google Geocoding API Error: $status');
        return null;
      }

      final results = (data['results'] as List? ?? []);
      if (results.isEmpty) return null;

      return (results[0]['formatted_address'] ?? '').toString();
    } catch (e) {
      debugPrint('Error reverse geocoding: $e');
      return null;
    }
  }
}

/// Place suggestion from autocomplete
class PlaceSuggestion {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  PlaceSuggestion({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    final structured = (json['structured_formatting'] as Map?) ?? {};

    return PlaceSuggestion(
      placeId: (json['place_id'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      mainText: (structured['main_text'] ?? '').toString(),
      secondaryText: (structured['secondary_text'] ?? '').toString(),
    );
  }
}

/// Place details with coordinates
class PlaceDetails {
  final String name;
  final String formattedAddress;
  final double latitude;
  final double longitude;

  PlaceDetails({
    required this.name,
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    final geometry = (json['geometry'] as Map?) ?? {};
    final location = (geometry['location'] as Map?) ?? {};

    return PlaceDetails(
      name: (json['name'] ?? '').toString(),
      formattedAddress: (json['formatted_address'] ?? '').toString(),
      latitude: (location['lat'] as num).toDouble(),
      longitude: (location['lng'] as num).toDouble(),
    );
  }
}