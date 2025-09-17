// File: services/listing_service.dart
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

  /// Verify authentication before making API calls
  Future<void> _ensureAuthenticated() async {
    final currentUser = _supabase.auth.currentUser;
    final currentSession = _supabase.auth.currentSession;
    
    if (currentUser == null || currentSession == null) {
      debugPrint('ListingService: No valid Supabase session, attempting refresh');
      
      final refreshed = await _authService.refreshSession();
      if (!refreshed) {
        throw Exception('Authentication required. Please login again.');
      }
      
      // Verify refresh worked
      final newUser = _supabase.auth.currentUser;
      if (newUser == null) {
        throw Exception('Authentication failed. Please login again.');
      }
    }
    
    debugPrint('ListingService: Authentication verified for user: ${_supabase.auth.currentUser?.id}');
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
        // Upload to Supabase Storage
        await _supabase.storage
            .from('listings')
            .upload(storagePath, file);

        // Get public URL
        final url = _supabase.storage
            .from('listings')
            .getPublicUrl(storagePath);

        imageUrls.add(url);
        debugPrint('Successfully uploaded image: $fileName');
      } catch (e) {
        debugPrint('Error uploading image: $e');
        throw Exception('Failed to upload image ${i + 1}: ${e.toString()}');
      }
    }

    return imageUrls;
  }

  /// Fetch all active listings with infinite scroll support (REGULAR LISTINGS ONLY)
  Future<List<Map<String, dynamic>>> fetchListings({
    String? categoryId,
    String? sortBy,
    int limit = 20,
    int offset = 0,
  }) async {
    await _ensureAuthenticated();
    
    try {
      debugPrint('Fetching regular listings: categoryId=$categoryId, limit=$limit, offset=$offset');
      
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
          .eq('is_premium', false); // FIXED: Only fetch regular listings, not premium

      // Apply category filter if provided
      if (categoryId != null && categoryId != 'All') {
        query = query.eq('category_id', categoryId);
      }

      // Apply sorting and pagination in a single chain
      dynamic finalQuery = query;
      if (sortBy == 'Price (Low to High)') {
        finalQuery = query.order('price', ascending: true);
      } else if (sortBy == 'Price (High to Low)') {
        finalQuery = query.order('price', ascending: false);
      } else {
        // Default to newest first
        finalQuery = query.order('created_at', ascending: false);
      }

      // Apply pagination
      final response = await finalQuery.range(offset, offset + limit - 1);

      debugPrint('Fetched ${response.length} regular listings');

      // First, get all unique parent category IDs
      Set<String> parentCategoryIds = {};
      for (var item in response) {
        if (item['category']['parent_category_id'] != null) {
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

      // Transform the data to match your existing format
      return List<Map<String, dynamic>>.from(response.map((item) {
        // Get first image from the images array
        List<dynamic> images = item['images'] ?? [];
        String mainImage = images.isNotEmpty ? images[0] : 'https://via.placeholder.com/300';

        // Determine category and subcategory
        String categoryName;
        String subcategoryName;

        if (item['category']['parent_category_id'] != null) {
          // This is a subcategory
          categoryName = parentCategoryNames[item['category']['parent_category_id']] ?? 'Uncategorized';
          subcategoryName = item['category']['name'] ?? 'Uncategorized';
        } else {
          // This is a parent category
          categoryName = item['category']['name'] ?? 'Uncategorized';
          subcategoryName = item['category']['name'] ?? 'Uncategorized';
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
          'is_premium': false, // These are explicitly regular listings
          // Additional fields
          'brand': item['brand'],
          'model': item['model'],
          'year': item['year_of_purchase'],
          'fuel_type': item['fuel_type'],
          'transmission': item['transmission_type'],
          'km_driven': item['kilometres_driven'],
          'bedrooms': item['bedrooms'],
          'bathrooms': item['bathrooms'],
          'furnishing': item['furnishing_status'],
          'latitude': item['latitude'],
          'longitude': item['longitude'],
        };
      }));
    } catch (e) {
      debugPrint('Error fetching listings: $e');
      
      // Check if error is auth-related
      if (e.toString().contains('JWT') || 
          e.toString().contains('auth') || 
          e.toString().contains('401') ||
          e.toString().contains('403')) {
        throw Exception('Authentication expired. Please login again.');
      }
      
      throw Exception('Failed to fetch listings: ${e.toString()}');
    }
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
      
      // If we have coordinates (either from current location or selected location)
      if (latitude != null && longitude != null) {
        // Use distance-based search
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

        // Get parent categories for the results
        Set<String> categoryIds = {};
        for (var item in response) {
          if (item['category_id'] != null) {
            categoryIds.add(item['category_id']);
          }
        }

        // Fetch categories with their parents
        Map<String, Map<String, dynamic>> categoryInfo = {};
        if (categoryIds.isNotEmpty) {
          final categories = await _supabase
              .from('categories')
              .select('id, name, parent_category_id')
              .inFilter('id', categoryIds.toList());

          // Get parent category IDs
          Set<String> parentIds = {};
          for (var cat in categories) {
            if (cat['parent_category_id'] != null) {
              parentIds.add(cat['parent_category_id']);
            }
            categoryInfo[cat['id']] = cat;
          }

          // Fetch parent categories
          if (parentIds.isNotEmpty) {
            final parents = await _supabase
                .from('categories')
                .select('id, name')
                .inFilter('id', parentIds.toList());

            for (var parent in parents) {
              categoryInfo[parent['id']] = parent;
            }
          }
        }

        // Transform the response
        return List<Map<String, dynamic>>.from(response.map((item) {
          List<dynamic> images = item['images'] ?? [];
          String mainImage = images.isNotEmpty ? images[0] : 'https://via.placeholder.com/300';

          // Determine category names
          String categoryName = 'Uncategorized';
          String subcategoryName = 'Uncategorized';

          if (item['category_id'] != null && categoryInfo.containsKey(item['category_id'])) {
            var catData = categoryInfo[item['category_id']]!;
            if (catData['parent_category_id'] != null && 
                categoryInfo.containsKey(catData['parent_category_id'])) {
              categoryName = categoryInfo[catData['parent_category_id']]!['name'];
              subcategoryName = catData['name'];
            } else {
              categoryName = catData['name'];
              subcategoryName = catData['name'];
            }
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
            'distance': item['distance'], // Distance in kilometers
            'latitude': item['latitude'],
            'longitude': item['longitude'],
          };
        }));
      } else {
        // Fall back to regular search without distance
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

        // Apply keyword search
        if (keywords != null && keywords.isNotEmpty) {
          query = query.or(
            'title.ilike.%$keywords%,'
            'description.ilike.%$keywords%,'
            'brand.ilike.%$keywords%,'
            'model.ilike.%$keywords%'
          );
        }

        // Apply location filter
        if (location != null && location.isNotEmpty && !location.contains('Current Location')) {
          query = query.ilike('location', '%$location%');
        }

        // Build the final query with sorting and pagination
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

        // Get parent categories
        Set<String> parentCategoryIds = {};
        for (var item in response) {
          if (item['category']['parent_category_id'] != null) {
            parentCategoryIds.add(item['category']['parent_category_id']);
          }
        }

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

          if (item['category']['parent_category_id'] != null) {
            categoryName = parentCategoryNames[item['category']['parent_category_id']] ?? 'Uncategorized';
            subcategoryName = item['category']['name'] ?? 'Uncategorized';
          } else {
            categoryName = item['category']['name'] ?? 'Uncategorized';
            subcategoryName = item['category']['name'] ?? 'Uncategorized';
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
            'latitude': item['latitude'],
            'longitude': item['longitude'],
          };
        }));
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

  // Helper method to calculate distance between two points
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
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

  /// Fetch premium/featured listings ONLY
  Future<List<Map<String, dynamic>>> fetchPremiumListings({
    String? categoryId,
    int limit = 10,
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
          .eq('is_premium', true); // Only fetch premium listings

      // Apply category filter if provided
      if (categoryId != null && categoryId != 'All') {
        query = query.eq('category_id', categoryId);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      debugPrint('Fetched ${response.length} premium listings');

      // Get parent categories
      Set<String> parentCategoryIds = {};
      for (var item in response) {
        if (item['category']['parent_category_id'] != null) {
          parentCategoryIds.add(item['category']['parent_category_id']);
        }
      }

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

        if (item['category']['parent_category_id'] != null) {
          categoryName = parentCategoryNames[item['category']['parent_category_id']] ?? 'Uncategorized';
          subcategoryName = item['category']['name'] ?? 'Uncategorized';
        } else {
          categoryName = item['category']['name'] ?? 'Uncategorized';
          subcategoryName = item['category']['name'] ?? 'Uncategorized';
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
          'is_featured': item['is_featured'] ?? false,
          'is_premium': true, // These are explicitly premium listings
          'views': item['views_count'] ?? 0,
          'created_at': item['created_at'],
          // Additional fields
          'brand': item['brand'],
          'model': item['model'],
          'year': item['year_of_purchase'],
          'fuel_type': item['fuel_type'],
          'transmission': item['transmission_type'],
          'km_driven': item['kilometres_driven'],
          'bedrooms': item['bedrooms'],
          'bathrooms': item['bathrooms'],
          'furnishing': item['furnishing_status'],
          'latitude': item['latitude'],
          'longitude': item['longitude'],
        };
      }));
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

  /// Get user's favorites
  Future<Set<String>> getUserFavorites() async {
    await _ensureAuthenticated();
    
    try {
      final user = _supabase.auth.currentUser!; // Safe to use ! after _ensureAuthenticated()
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

  /// Toggle favorite
  Future<bool> toggleFavorite(String listingId) async {
    await _ensureAuthenticated();
    
    try {
      final user = _supabase.auth.currentUser!;
      debugPrint('Toggling favorite for listing: $listingId, user: ${user.id}');

      // Check if already favorited
      final existing = await _supabase
          .from('favorites')
          .select('id')
          .eq('user_id', user.id)
          .eq('listing_id', listingId)
          .maybeSingle();

      if (existing != null) {
        // Remove favorite
        await _supabase
            .from('favorites')
            .delete()
            .eq('user_id', user.id)
            .eq('listing_id', listingId);
        debugPrint('Removed favorite for listing: $listingId');
        return false; // Not favorited anymore
      } else {
        // Add favorite
        await _supabase
            .from('favorites')
            .insert({
              'user_id': user.id,
              'listing_id': listingId,
              'created_at': DateTime.now().toIso8601String(),
            });
        debugPrint('Added favorite for listing: $listingId');
        return true; // Now favorited
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

  /// Create a new listing
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

      // Prepare listing data
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
        'is_premium': false, // Default to regular listing
        'is_featured': false,
        'views_count': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Add any additional data (like brand, model, etc.)
      if (additionalData != null) {
        // Convert field names to snake_case for database
        final Map<String, dynamic> dbAdditionalData = {};

        if (additionalData['brand'] != null) {
          dbAdditionalData['brand'] = additionalData['brand'];
        }
        if (additionalData['model'] != null) {
          dbAdditionalData['model'] = additionalData['model'];
        }
        if (additionalData['yearOfPurchase'] != null) {
          dbAdditionalData['year_of_purchase'] = int.tryParse(additionalData['yearOfPurchase'].toString());
        }
        if (additionalData['warrantyStatus'] != null) {
          dbAdditionalData['warranty_status'] = additionalData['warrantyStatus'].toLowerCase();
        }
        if (additionalData['availability'] != null) {
          dbAdditionalData['availability'] = additionalData['availability'];
        }
        if (additionalData['kilometresDriven'] != null) {
          dbAdditionalData['kilometres_driven'] = int.tryParse(additionalData['kilometresDriven'].toString());
        }
        if (additionalData['fuelType'] != null) {
          dbAdditionalData['fuel_type'] = additionalData['fuelType'].toLowerCase();
        }
        if (additionalData['transmissionType'] != null) {
          dbAdditionalData['transmission_type'] = additionalData['transmissionType'].toLowerCase();
        }
        if (additionalData['bedrooms'] != null) {
          dbAdditionalData['bedrooms'] = int.tryParse(additionalData['bedrooms'].toString());
        }
        if (additionalData['bathrooms'] != null) {
          dbAdditionalData['bathrooms'] = int.tryParse(additionalData['bathrooms'].toString());
        }
        if (additionalData['furnishingStatus'] != null) {
          dbAdditionalData['furnishing_status'] = additionalData['furnishingStatus'].toLowerCase();
        }

        listingData.addAll(dbAdditionalData);
      }

      debugPrint('=== LISTING DATA TO INSERT ===');
      debugPrint(listingData);
      debugPrint('===============================');

      // Insert into database
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

  /// Get categories for dropdown (does not require auth - public data)
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

  /// Get subcategories for a parent category (does not require auth - public data)
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