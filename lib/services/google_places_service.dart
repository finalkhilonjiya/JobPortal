// File: lib/services/google_places_service.dart
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GooglePlacesService {
  // TODO: Replace with your actual Google Places API key
  static const String _apiKey = 'YOUR_GOOGLE_PLACES_API_KEY_HERE';
  
  static const String _autocompleteUrl = 
      'https://maps.googleapis.com/maps/api/place/autocomplete/json';
  static const String _detailsUrl = 
      'https://maps.googleapis.com/maps/api/place/details/json';
  static const String _geocodeUrl = 
      'https://maps.googleapis.com/maps/api/geocode/json';

  /// Search places by text input (autocomplete)
  Future<List<PlaceSuggestion>> searchPlaces(String input) async {
    if (input.isEmpty || input.length < 2) {
      return [];
    }

    try {
      final url = Uri.parse(
        '$_autocompleteUrl?input=$input&key=$_apiKey&components=country:in&types=geocode'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List;
          return predictions
              .map((prediction) => PlaceSuggestion.fromJson(prediction))
              .toList();
        } else {
          debugPrint('Google Places API Error: ${data['status']}');
          return [];
        }
      } else {
        debugPrint('HTTP Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error searching places: $e');
      return [];
    }
  }

  /// Get place details (lat/lng) from place ID
  Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    try {
      final url = Uri.parse(
        '$_detailsUrl?place_id=$placeId&key=$_apiKey&fields=geometry,name,formatted_address'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          return PlaceDetails.fromJson(data['result']);
        } else {
          debugPrint('Google Places Details API Error: ${data['status']}');
          return null;
        }
      } else {
        debugPrint('HTTP Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error getting place details: $e');
      return null;
    }
  }

  /// Reverse geocode (lat/lng to address)
  Future<String?> reverseGeocode(double latitude, double longitude) async {
    try {
      final url = Uri.parse(
        '$_geocodeUrl?latlng=$latitude,$longitude&key=$_apiKey'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          // Get the first result's formatted address
          return data['results'][0]['formatted_address'] as String;
        } else {
          debugPrint('Google Geocoding API Error: ${data['status']}');
          return null;
        }
      } else {
        debugPrint('HTTP Error: ${response.statusCode}');
        return null;
      }
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
    final structuredFormatting = json['structured_formatting'] ?? {};
    
    return PlaceSuggestion(
      placeId: json['place_id'] ?? '',
      description: json['description'] ?? '',
      mainText: structuredFormatting['main_text'] ?? '',
      secondaryText: structuredFormatting['secondary_text'] ?? '',
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
    final geometry = json['geometry'];
    final location = geometry['location'];

    return PlaceDetails(
      name: json['name'] ?? '',
      formattedAddress: json['formatted_address'] ?? '',
      latitude: (location['lat'] as num).toDouble(),
      longitude: (location['lng'] as num).toDouble(),
    );
  }
}