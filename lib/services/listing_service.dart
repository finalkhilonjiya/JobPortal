// File: services/listing_service.dart
// PART 1 OF 3 - Copy this entire file
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:postgrest/postgrest.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:math' as math;
import '../models/listing_model.dart';
import '../presentation/login_screen/mobile_auth_service.dart';

class ListingService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final MobileAuthService _authService = MobileAuthService();

  // Add a debug info property that can be displayed on screen
  String lastFetchDebugInfo = '';

  /// Verify authentication before making API calls
  Future<void> _ensureAuthenticated() async {
    debugPrint('ListingService: Checking authentication state');
    final sessionValid = await _authService.ensureValidSession();
    if (!sessionValid) {
      throw Exception('Authentication required. Please login again.');
    }
    final currentUser = _supabase.auth.currentUser;
    final currentSession = _supabase.auth.currentSession;
    if (currentUser == null || currentSession == null) {
      throw Exception('Authentication required. Please login again.');
    }
    debugPrint('ListingService: Authentication verified for user: ${currentUser.id}');
  }

  /// Get all subcategory IDs for a parent category
  Future<List<String>> getSubcategoryIds(String parentCategoryId) async {
    try {
      debugPrint('Fetching subcategories for parent: $parentCategoryId');
      final response = await _supabase
          .from('categories')
          .select('id')
          .eq('parent_category_id', parentCategoryId)
          .eq('is_active', true);
      final subcategoryIds = List<String>.from(response.map((cat) => cat['id']));
      debugPrint('Found ${subcategoryIds.length} subcategories for parent $parentCategoryId');
      return subcategoryIds;
    } catch (e) {
      debugPrint('Error fetching subcategory IDs: $e');
      return [];
    }
  }

  /// Upload images to Supabase Storage
  Future<List<String>> uploadImages(List<File> images) async {
    await _ensureAuthenticated();
    List<String> imageUrls = [];
    for (int i = 0; i < images.length; i++) {
      final file = images[i];
      final userId = _supabase.auth.currentUser!.id;
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
      final storagePath = 'listings/$fileName';
      try {
        await _supabase.storage.from('listings').upload(storagePath, file);
        final url = _supabase.storage.from('listings').getPublicUrl(storagePath);
        imageUrls.add(url);
        debugPrint('Successfully uploaded image: $fileName');
      } catch (e) {
        debugPrint('Error uploading image: $e');
        throw Exception('Failed to upload image ${i + 1}: ${e.toString()}');
      }
    }
    return imageUrls;
  }

  /// Fetch all active listings with category filtering and distance sorting
  Future<List<Map<String, dynamic>>> fetchListings({
    String? categoryId,
    String? sortBy,
    int limit = 20,
    int offset = 0,
    double? userLatitude,
    double? userLongitude,
  }) async {
    await _ensureAuthenticated();

    try {
      // BUILD DEBUG INFO STRING
      lastFetchDebugInfo = '🔍 FETCH DEBUG\n';
      lastFetchDebugInfo += 'Category: ${categoryId ?? "All"}\n';
      lastFetchDebugInfo += 'Sort: ${sortBy ?? "null"}\n';
      lastFetchDebugInfo += 'User Lat: ${userLatitude?.toStringAsFixed(4) ?? "null"}\n';
      lastFetchDebugInfo += 'User Lng: ${userLongitude?.toStringAsFixed(4) ?? "null"}\n';
      
      debugPrint('Fetching listings: categoryId=$categoryId, sortBy=$sortBy, limit=$limit, offset=$offset, userLat=$userLatitude, userLng=$userLongitude');

      // If we have user coordinates, ALWAYS try distance-based sorting first
      if (userLatitude != null && userLongitude != null) {
        try {
          lastFetchDebugInfo += '✅ Using distance-based fetch\n';
          debugPrint('User coordinates available, attempting distance-based fetch');
          
          final distanceListings = await _fetchListingsWithDistance(
            categoryId: categoryId,
            userLatitude: userLatitude,
            userLongitude: userLongitude,
            limit: limit,
            offset: offset,
          );

          lastFetchDebugInfo += '📦 Got ${distanceListings.length} listings\n';
          
          // Show first 3 listings with distance
          if (distanceListings.isNotEmpty) {
            lastFetchDebugInfo += '\nFirst 3 listings:\n';
            for (var i = 0; i < math.min(3, distanceListings.length); i++) {
              final listing = distanceListings[i];
              final title = listing['title']?.toString() ?? 'No title';
              final shortTitle = title.substring(0, math.min(20, title.length));
              lastFetchDebugInfo += '${i + 1}. $shortTitle\n';
              lastFetchDebugInfo += '   Distance: ${listing['distance']?.toStringAsFixed(2) ?? "null"} km\n';
            }
          }

          // If distance fetch succeeded and we want distance sorting (default), return as-is
          if (sortBy == null || sortBy == 'Distance' || sortBy == 'Newest') {
            lastFetchDebugInfo += '✅ Returning sorted by distance\n';
            debugPrint('Returning ${distanceListings.length} listings sorted by distance');
            return distanceListings;
          }

          // If user wants different sorting (price), apply it
          if (sortBy == 'Price (Low to High)') {
            distanceListings.sort((a, b) => (a['price'] ?? 0).compareTo(b['price'] ?? 0));
            lastFetchDebugInfo += '💰 Re-sorted by price (low to high)\n';
            debugPrint('Re-sorted ${distanceListings.length} listings by price (low to high)');
            return distanceListings;
          } else if (sortBy == 'Price (High to Low)') {
            distanceListings.sort((a, b) => (b['price'] ?? 0).compareTo(a['price'] ?? 0));
            lastFetchDebugInfo += '💰 Re-sorted by price (high to low)\n';
            debugPrint('Re-sorted ${distanceListings.length} listings by price (high to low)');
            return distanceListings;
          }

          return distanceListings;

        } catch (rpcError) {
          final errorMsg = rpcError.toString();
          final shortError = errorMsg.substring(0, math.min(50, errorMsg.length));
          lastFetchDebugInfo += '⚠️ RPC failed: $shortError\n';
          lastFetchDebugInfo += '🔄 Falling back to manual calculation\n';
          debugPrint('RPC distance fetch failed: $rpcError, falling back to regular fetch with manual distance calculation');
          // Continue to fallback logic below
        }
      } else {
        lastFetchDebugInfo += '⚠️ No user coordinates available\n';
      }

      // Fallback: Regular query without RPC
      lastFetchDebugInfo += '📋 Using regular query\n';
      debugPrint('Using regular query (no coordinates or RPC failed)');
      
      var query = _supabase
          .from('listings')
          .select('''
            *,
            category:categories!inner(
              id,
              name,
              parent_category_id
            )
          ''')
          .eq('status', 'active')
          .eq('is_premium', false);

      // Apply category filter if provided
      if (categoryId != null && categoryId != 'All') {
        final subcategoryIds = await getSubcategoryIds(categoryId);
        if (subcategoryIds.isNotEmpty) {
          query = query.inFilter('category_id', subcategoryIds);
          debugPrint('Filtering by parent category: $categoryId with ${subcategoryIds.length} subcategories');
        } else {
          query = query.eq('category_id', categoryId);
          debugPrint('Filtering by subcategory: $categoryId');
        }
      }

      // Apply sorting
      dynamic finalQuery = query;
      if (sortBy == 'Price (Low to High)') {
        finalQuery = query.order('price', ascending: true);
        lastFetchDebugInfo += '💰 Sorted by price (low to high)\n';
      } else if (sortBy == 'Price (High to Low)') {
        finalQuery = query.order('price', ascending: false);
        lastFetchDebugInfo += '💰 Sorted by price (high to low)\n';
      } else if (sortBy == 'Oldest') {
        finalQuery = query.order('created_at', ascending: true);
        lastFetchDebugInfo += '📅 Sorted by oldest\n';
      } else {
        finalQuery = query.order('created_at', ascending: false);
        lastFetchDebugInfo += '📅 Sorted by newest\n';
      }

      // Apply pagination
      final response = await finalQuery.range(offset, offset + limit - 1);
      lastFetchDebugInfo += '📦 Got ${response.length} listings from DB\n';
      debugPrint('Fetched ${response.length} regular listings');

      // Transform data
      var listings = await _transformListingData(response);

      // IMPORTANT: Always calculate distance if we have coordinates (even in fallback)
      if (userLatitude != null && userLongitude != null) {
        lastFetchDebugInfo += '📏 Calculating distances manually\n';
        
        int calculatedCount = 0;
        listings = listings.map((listing) {
          if (listing['latitude'] != null && listing['longitude'] != null) {
            final distance = _calculateDistance(
              userLatitude,
              userLongitude,
              listing['latitude'],
              listing['longitude'],
            );
            listing['distance'] = distance;
            calculatedCount++;
          }
          return listing;
        }).toList();

        lastFetchDebugInfo += '✅ Calculated distance for $calculatedCount listings\n';

        // Sort by distance if sortBy is null, 'Distance', or 'Newest'
        if (sortBy == null || sortBy == 'Distance' || sortBy == 'Newest') {
          listings.sort((a, b) {
            final distA = a['distance'] ?? double.infinity;
            final distB = b['distance'] ?? double.infinity;
            return distA.compareTo(distB);
          });
          lastFetchDebugInfo += '✅ Manually sorted by distance\n';
          debugPrint('Manually sorted ${listings.length} listings by distance');
        }

        // Show first 3 after sorting
        if (listings.isNotEmpty) {
          lastFetchDebugInfo += '\nFirst 3 after sort:\n';
          for (var i = 0; i < math.min(3, listings.length); i++) {
            final listing = listings[i];
            final title = listing['title']?.toString() ?? 'No title';
            final shortTitle = title.substring(0, math.min(20, title.length));
            lastFetchDebugInfo += '${i + 1}. $shortTitle\n';
            lastFetchDebugInfo += '   Distance: ${listing['distance']?.toStringAsFixed(2) ?? "null"} km\n';
          }
        }
      }

      lastFetchDebugInfo += '✅ Returning ${listings.length} listings\n';
      return listings;
      
    } catch (e) {
      final errorMsg = e.toString();
      final shortError = errorMsg.substring(0, math.min(100, errorMsg.length));
      lastFetchDebugInfo += '❌ ERROR: $shortError\n';
      debugPrint('Error fetching listings: $e');

      if (e.toString().contains('JWT') || 
          e.toString().contains('auth') || 
          e.toString().contains('401') ||
          e.toString().contains('403')) {
        throw Exception('Authentication expired. Please login again.');
      }
      throw Exception('Failed to fetch listings: ${e.toString()}');
    }
  }


// PART 2 OF 3 - CONTINUE FROM PART 1

  /// Fetch listings with distance calculation using PostGIS
  Future<List<Map<String, dynamic>>> _fetchListingsWithDistance({
    String? categoryId,
    required double userLatitude,
    required double userLongitude,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      debugPrint('Fetching listings with distance calculation');

      // Get subcategory IDs if filtering by parent category
      List<String>? categoryIds;
      if (categoryId != null && categoryId != 'All') {
        final subcategoryIds = await getSubcategoryIds(categoryId);
        if (subcategoryIds.isNotEmpty) {
          categoryIds = subcategoryIds;
        } else {
          categoryIds = [categoryId];
        }
      }

      // Call RPC function for distance-based search
      final response = await _supabase.rpc(
        'search_listings_by_distance',
        params: {
          'user_lat': userLatitude,
          'user_lng': userLongitude,
          'search_radius': 500.0,
          'category_ids': categoryIds,
          'limit_count': limit,
          'offset_count': offset,
        },
      );

      debugPrint('Distance search returned ${response.length} results');
      return await _transformListingData(response);
    } catch (e) {
      debugPrint('Error in distance search: $e');
      throw e; // Throw to trigger fallback
    }
  }

  /// Transform listing data to common format
  Future<List<Map<String, dynamic>>> _transformListingData(List<dynamic> response) async {
    // Get all unique parent category IDs
    Set<String> parentCategoryIds = {};
    for (var item in response) {
      if (item['category'] != null && item['category']['parent_category_id'] != null) {
        parentCategoryIds.add(item['category']['parent_category_id']);
      }
    }

    // Fetch parent categories if needed
    Map<String, String> parentCategoryNames = {};
    if (parentCategoryIds.isNotEmpty) {
      final parentCategories = await _supabase
          .from('categories')
          .select('id, name')
          .inFilter('id', parentCategoryIds.toList());

      for (var parent in parentCategories) {
        parentCategoryNames[parent['id']] = parent['name'];
      }
    }

    // Transform the data
    return List<Map<String, dynamic>>.from(response.map((item) {
      List<dynamic> images = item['images'] ?? [];
      String mainImage = images.isNotEmpty ? images[0] : 'https://via.placeholder.com/300';

      // Determine category and subcategory
      String categoryName;
      String subcategoryName;

      if (item['category'] != null) {
        if (item['category']['parent_category_id'] != null) {
          categoryName = parentCategoryNames[item['category']['parent_category_id']] ?? 'Uncategorized';
          subcategoryName = item['category']['name'] ?? 'Uncategorized';
        } else {
          categoryName = item['category']['name'] ?? 'Uncategorized';
          subcategoryName = item['category']['name'] ?? 'Uncategorized';
        }
      } else {
        categoryName = 'Uncategorized';
        subcategoryName = 'Uncategorized';
      }

      return {
        'id': item['id'],
        'title': item['title'] ?? 'Untitled',
        'price': item['price'] ?? 0,
        'image': mainImage,
        'images': images,
        'location': item['location'] ?? 'Location not specified',
        'category': categoryName,
        'subcategory': subcategoryName,
        'description': item['description'] ?? '',
        'condition': item['condition'] ?? 'used',
        'phone': item['seller_phone'] ?? '',
        'seller_name': item['seller_name'] ?? 'Seller',
        'views': item['views_count'] ?? 0,
        'created_at': item['created_at'],
        'is_featured': item['is_featured'] ?? false,
        'is_premium': item['is_premium'] ?? false,
        'distance': item['distance'],
        'latitude': item['latitude'],
        'longitude': item['longitude'],
        'brand': item['brand'],
        'model': item['model'],
        'year': item['year_of_purchase'],
        'fuel_type': item['fuel_type'],
        'transmission': item['transmission_type'],
        'km_driven': item['kilometres_driven'],
        'bedrooms': item['bedrooms'],
        'bathrooms': item['bathrooms'],
        'furnishing': item['furnishing_status'],
      };
    }));
  }

  /// Search listings by keywords and/or location
  Future<List<Map<String, dynamic>>> searchListings({
    String? keywords,
    String? location,
    double? latitude,
    double? longitude,
    String? sortBy,
    double searchRadius = 50.0,
    int limit = 20,
    int offset = 0,
  }) async {
    await _ensureAuthenticated();

    try {
      debugPrint('Searching listings: keywords=$keywords, location=$location');

      if (latitude != null && longitude != null) {
        final response = await _supabase.rpc(
          'search_listings_by_distance',
          params: {
            'user_lat': latitude,
            'user_lng': longitude,
            'search_radius': searchRadius,
            'search_keywords': keywords ?? '',
            'search_location': location?.contains('Current Location') == true ? null : location,
            'limit_count': limit,
            'offset_count': offset,
          },
        );

        debugPrint('Distance search returned ${response.length} results');
        return await _transformListingData(response);
      } else {
        var query = _supabase
            .from('listings')
            .select('''
              *,
              category:categories!inner(
                id,
                name,
                parent_category_id
              )
            ''')
            .eq('status', 'active');

        if (keywords != null && keywords.isNotEmpty) {
          query = query.or(
            'title.ilike.%$keywords%,'
            'description.ilike.%$keywords%,'
            'brand.ilike.%$keywords%,'
            'model.ilike.%$keywords%'
          );
        }

        if (location != null && location.isNotEmpty && !location.contains('Current Location')) {
          query = query.ilike('location', '%$location%');
        }

        final List<Map<String, dynamic>> response;

        if (sortBy == 'Price (Low to High)') {
          response = await query
              .order('price', ascending: true)
              .range(offset, offset + limit - 1);
        } else if (sortBy == 'Price (High to Low)') {
          response = await query
              .order('price', ascending: false)
              .range(offset, offset + limit - 1);
        } else {
          response = await query
              .order('created_at', ascending: false)
              .range(offset, offset + limit - 1);
        }

        debugPrint('Text search returned ${response.length} results');
        return await _transformListingData(response);
      }
    } catch (e) {
      debugPrint('Error searching listings: $e');

      if (e.toString().contains('JWT') || 
          e.toString().contains('auth') || 
          e.toString().contains('401') ||
          e.toString().contains('403')) {
        throw Exception('Authentication expired. Please login again.');
      }

      throw Exception('Failed to search listings: ${e.toString()}');
    }
  }

  /// Fetch premium/featured listings ONLY with distance sorting
  Future<List<Map<String, dynamic>>> fetchPremiumListings({
    String? categoryId,
    int limit = 10,
    double? userLatitude,
    double? userLongitude,
  }) async {
    await _ensureAuthenticated();

    try {
      debugPrint('Fetching premium listings: categoryId=$categoryId, limit=$limit');

      var query = _supabase
          .from('listings')
          .select('''
            *,
            category:categories!inner(
              id,
              name,
              parent_category_id
            )
          ''')
          .eq('status', 'active')
          .eq('is_premium', true);

      if (categoryId != null && categoryId != 'All') {
        final subcategoryIds = await getSubcategoryIds(categoryId);

        if (subcategoryIds.isNotEmpty) {
          query = query.inFilter('category_id', subcategoryIds);
          debugPrint('Filtering premium by parent category: $categoryId with ${subcategoryIds.length} subcategories');
        } else {
          query = query.eq('category_id', categoryId);
          debugPrint('Filtering premium by subcategory: $categoryId');
        }
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      debugPrint('Fetched ${response.length} premium listings');

      var listings = await _transformListingData(response);

      if (userLatitude != null && userLongitude != null) {
        listings = listings.map((listing) {
          if (listing['latitude'] != null && listing['longitude'] != null) {
            final distance = _calculateDistance(
              userLatitude,
              userLongitude,
              listing['latitude'],
              listing['longitude'],
            );
            listing['distance'] = distance;
          }
          return listing;
        }).toList();

        listings.sort((a, b) {
          final distA = a['distance'] ?? double.infinity;
          final distB = b['distance'] ?? double.infinity;
          return distA.compareTo(distB);
        });
      }

      return listings;
    } catch (e) {
      debugPrint('Error fetching premium listings: $e');

      if (e.toString().contains('JWT') || 
          e.toString().contains('auth') || 
          e.toString().contains('401') ||
          e.toString().contains('403')) {
        throw Exception('Authentication expired. Please login again.');
      }

      throw Exception('Failed to fetch premium listings: ${e.toString()}');
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371;
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a = 
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
      math.sin(dLon / 2) * math.sin(dLon / 2);

    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * math.pi / 180;
  }

  Future<Set<String>> getUserFavorites() async {
    await _ensureAuthenticated();

    try {
      final user = _supabase.auth.currentUser!;
      debugPrint('Fetching favorites for user: ${user.id}');

      final response = await _supabase
          .from('favorites')
          .select('listing_id')
          .eq('user_id', user.id);

      final favorites = Set<String>.from(
        response.map((item) => item['listing_id'] as String)
      );

      debugPrint('User has ${favorites.length} favorites');
      return favorites;
    } catch (e) {
      debugPrint('Error fetching favorites: $e');

      if (e.toString().contains('JWT') || 
          e.toString().contains('auth') || 
          e.toString().contains('401') ||
          e.toString().contains('403')) {
        throw Exception('Authentication expired. Please login again.');
      }

      throw Exception('Failed to fetch favorites: ${e.toString()}');
    }
  }

  Future<bool> toggleFavorite(String listingId) async {
    await _ensureAuthenticated();

    try {
      final user = _supabase.auth.currentUser!;
      debugPrint('Toggling favorite for listing: $listingId, user: ${user.id}');

      final existing = await _supabase
          .from('favorites')
          .select('id')
          .eq('user_id', user.id)
          .eq('listing_id', listingId)
          .maybeSingle();

      if (existing != null) {
        await _supabase
            .from('favorites')
            .delete()
            .eq('user_id', user.id)
            .eq('listing_id', listingId);
        debugPrint('Removed favorite for listing: $listingId');
        return false;
      } else {
        await _supabase
            .from('favorites')
            .insert({
              'user_id': user.id,
              'listing_id': listingId,
              'created_at': DateTime.now().toIso8601String(),
            });
        debugPrint('Added favorite for listing: $listingId');
        return true;
      }
    } catch (e) {
      debugPrint('Error toggling favorite: $e');

      if (e.toString().contains('JWT') || 
          e.toString().contains('auth') || 
          e.toString().contains('401') ||
          e.toString().contains('403')) {
        throw Exception('Authentication expired. Please login again.');
      }

      throw Exception('Failed to toggle favorite: ${e.toString()}');
    }
  }

// PART 3 OF 3 - CONTINUE FROM PART 2 - THIS IS THE FINAL PART

  Future<Map<String, dynamic>> createListing({
    required String title,
    required String categoryId,
    required String description,
    required double price,
    required String condition,
    required String location,
    double? latitude,
    double? longitude,
    required List<String> imageUrls,
    required String priceType,
    required String sellerName,
    required String sellerPhone,
    required String userType,
    Map<String, dynamic>? additionalData,
  }) async {
    await _ensureAuthenticated();

    try {
      final user = _supabase.auth.currentUser!;

      debugPrint('Creating listing for user: ${user.id}');
      debugPrint('Category ID: $categoryId');
      debugPrint('Location: $location, Lat: $latitude, Lng: $longitude');

      final Map<String, dynamic> listingData = {
        'seller_id': user.id,
        'category_id': categoryId,
        'title': title,
        'description': description,
        'price': price,
        'price_type': priceType.toLowerCase(),
        'condition': condition,
        'status': 'active',
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
        'images': imageUrls,
        'seller_name': sellerName,
        'seller_phone': sellerPhone,
        'user_type': userType.toLowerCase(),
        'is_premium': false,
        'is_featured': false,
        'views_count': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (additionalData != null && additionalData['conditions'] != null) {
        listingData['search_tags'] = additionalData['conditions'];
        debugPrint('Storing conditions as search_tags: ${additionalData['conditions']}');
      }

      // Add other additional data fields
      if (additionalData != null) {
        final Map<String, dynamic> dbAdditionalData = {};

        if (additionalData['brand'] != null) dbAdditionalData['brand'] = additionalData['brand'];
        if (additionalData['model'] != null) dbAdditionalData['model'] = additionalData['model'];
        if (additionalData['yearOfPurchase'] != null) dbAdditionalData['year_of_purchase'] = int.tryParse(additionalData['yearOfPurchase'].toString());
        if (additionalData['warrantyStatus'] != null) dbAdditionalData['warranty_status'] = additionalData['warrantyStatus'].toLowerCase();
        if (additionalData['availability'] != null) dbAdditionalData['availability'] = additionalData['availability'];
        if (additionalData['kilometresDriven'] != null) dbAdditionalData['kilometres_driven'] = int.tryParse(additionalData['kilometresDriven'].toString());
        if (additionalData['fuelType'] != null) dbAdditionalData['fuel_type'] = additionalData['fuelType'].toLowerCase();
        if (additionalData['transmissionType'] != null) dbAdditionalData['transmission_type'] = additionalData['transmissionType'].toLowerCase();
        if (additionalData['bedrooms'] != null) dbAdditionalData['bedrooms'] = int.tryParse(additionalData['bedrooms'].toString());
        if (additionalData['bathrooms'] != null) dbAdditionalData['bathrooms'] = int.tryParse(additionalData['bathrooms'].toString());
        if (additionalData['furnishingStatus'] != null) dbAdditionalData['furnishing_status'] = additionalData['furnishingStatus'].toLowerCase();

        listingData.addAll(dbAdditionalData);
      }

      debugPrint('=== LISTING DATA TO INSERT ===');
      debugPrint('Latitude: ${listingData['latitude']}');
      debugPrint('Longitude: ${listingData['longitude']}');
      debugPrint('===============================');

      final response = await _supabase
          .from('listings')
          .insert(listingData)
          .select()
          .single();

      debugPrint('Successfully created listing: ${response['id']}');
      return response;
    } catch (e) {
      debugPrint('Error creating listing: $e');

      if (e.toString().contains('JWT') || 
          e.toString().contains('auth') || 
          e.toString().contains('401') ||
          e.toString().contains('403')) {
        throw Exception('Authentication expired. Please login again.');
      }

      throw Exception('Failed to create listing: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      debugPrint('Fetching categories (public data)');

      final response = await _supabase
          .from('categories')
          .select('*')
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      debugPrint('Fetched ${response.length} categories');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      throw Exception('Failed to fetch categories: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getSubcategories(String parentCategoryId) async {
    try {
      debugPrint('Fetching subcategories for parent: $parentCategoryId');

      final response = await _supabase
          .from('categories')
          .select('*')
          .eq('parent_category_id', parentCategoryId)
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      debugPrint('Fetched ${response.length} subcategories');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching subcategories: $e');
      throw Exception('Failed to fetch subcategories: ${e.toString()}');
    }
  }
}

// END OF FILE - This is the complete listing_service.dart