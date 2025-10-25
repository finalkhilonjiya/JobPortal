// File: services/listing_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:math' as math;
import '../models/listing_model.dart';
import '../presentation/login_screen/mobile_auth_service.dart';

class ListingService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final MobileAuthService _authService = MobileAuthService();

  Future<void> _ensureAuthenticated() async {
    final sessionValid = await _authService.ensureValidSession();
    if (!sessionValid) {
      throw Exception('Authentication required. Please login again.');
    }
    final currentUser = _supabase.auth.currentUser;
    final currentSession = _supabase.auth.currentSession;
    if (currentUser == null || currentSession == null) {
      throw Exception('Authentication required. Please login again.');
    }
  }

  Future<List<String>> getSubcategoryIds(String parentCategoryId) async {
    try {
      final response = await _supabase
          .from('categories')
          .select('id')
          .eq('parent_category_id', parentCategoryId)
          .eq('is_active', true);
      return List<String>.from(response.map((cat) => cat['id']));
    } catch (e) {
      debugPrint('Error fetching subcategory IDs: $e');
      return [];
    }
  }

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
      } catch (e) {
        throw Exception('Failed to upload image ${i + 1}: ${e.toString()}');
      }
    }
    return imageUrls;
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

/// Fetch regular listings with PostGIS distance (with fallback)
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
      // TRY POSTGIS FIRST if coordinates available
      if (userLatitude != null && userLongitude != null) {
        try {
          debugPrint('🚀 Using PostGIS function for regular listings');

          // Get category IDs for filter
          List<String>? categoryIds;
          if (categoryId != null && categoryId != 'All') {
            final subcategoryIds = await getSubcategoryIds(categoryId);
            if (subcategoryIds.isNotEmpty) {
              categoryIds = subcategoryIds;
            } else {
              categoryIds = [categoryId];
            }
          }

          // Call PostGIS function
          final response = await _supabase.rpc(
            'search_regular_listings_by_distance',
            params: {
              'user_lat': userLatitude,
              'user_lng': userLongitude,
              'search_radius': 500.0,
              'category_ids': categoryIds,
              'limit_count': limit,
              'offset_count': offset,
            },
          );

          debugPrint('✅ PostGIS returned ${response.length} regular listings');

          var listings = await _transformListingData(response);

          // Apply price sorting if requested
          if (sortBy == 'Price (Low to High)') {
            listings.sort((a, b) => (a['price'] ?? 0).compareTo(b['price'] ?? 0));
          } else if (sortBy == 'Price (High to Low)') {
            listings.sort((a, b) => (b['price'] ?? 0).compareTo(a['price'] ?? 0));
          }
          // Distance sorting already done by PostGIS

          return listings;

        } catch (postgisError) {
          debugPrint('⚠️ PostGIS failed: $postgisError');
          debugPrint('📋 Falling back to manual calculation');
          // Continue to fallback below
        }
      }

      // FALLBACK: Manual calculation
      debugPrint('📋 Using manual distance calculation');

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

      if (categoryId != null && categoryId != 'All') {
        final subcategoryIds = await getSubcategoryIds(categoryId);
        if (subcategoryIds.isNotEmpty) {
          query = query.inFilter('category_id', subcategoryIds);
        } else {
          query = query.eq('category_id', categoryId);
        }
      }

      dynamic finalQuery = query;
      if (sortBy == 'Price (Low to High)') {
        finalQuery = query.order('price', ascending: true);
      } else if (sortBy == 'Price (High to Low)') {
        finalQuery = query.order('price', ascending: false);
      } else if (sortBy == 'Oldest') {
        finalQuery = query.order('created_at', ascending: true);
      } else {
        finalQuery = query.order('created_at', ascending: false);
      }

      final response = await finalQuery.range(offset, offset + limit - 1);
      var listings = await _transformListingData(response);

      if (userLatitude != null && userLongitude != null) {
        listings = listings.map((listing) {
          if (listing['latitude'] != null && listing['longitude'] != null) {
            listing['distance'] = _calculateDistance(
              userLatitude,
              userLongitude,
              listing['latitude'],
              listing['longitude'],
            );
          }
          return listing;
        }).toList();

        if (sortBy == null || sortBy == 'Distance' || sortBy == 'Newest') {
          listings.sort((a, b) {
            final distA = a['distance'] ?? double.infinity;
            final distB = b['distance'] ?? double.infinity;
            return distA.compareTo(distB);
          });
        }
      }

      return listings;
    } catch (e) {
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

/// Fetch premium listings with PostGIS distance (with fallback)
  Future<List<Map<String, dynamic>>> fetchPremiumListings({
    String? categoryId,
    int limit = 10,
    double? userLatitude,
    double? userLongitude,
  }) async {
    await _ensureAuthenticated();

    try {
      // TRY POSTGIS FIRST if coordinates available
      if (userLatitude != null && userLongitude != null) {
        try {
          debugPrint('🚀 Using PostGIS function for premium listings');

          // Get category IDs for filter
          List<String>? categoryIds;
          if (categoryId != null && categoryId != 'All') {
            final subcategoryIds = await getSubcategoryIds(categoryId);
            if (subcategoryIds.isNotEmpty) {
              categoryIds = subcategoryIds;
            } else {
              categoryIds = [categoryId];
            }
          }

          // Call PostGIS function
          final response = await _supabase.rpc(
            'search_premium_listings_by_distance',
            params: {
              'user_lat': userLatitude,
              'user_lng': userLongitude,
              'search_radius': 500.0,
              'category_ids': categoryIds,
              'limit_count': limit,
            },
          );

          debugPrint('✅ PostGIS returned ${response.length} premium listings');
          return await _transformListingData(response);

        } catch (postgisError) {
          debugPrint('⚠️ PostGIS failed: $postgisError');
          debugPrint('📋 Falling back to manual calculation');
          // Continue to fallback below
        }
      }

      // FALLBACK: Manual calculation
      debugPrint('📋 Using manual distance calculation for premium');

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
        } else {
          query = query.eq('category_id', categoryId);
        }
      }

      final response = await query.order('created_at', ascending: false).limit(limit);
      var listings = await _transformListingData(response);

      if (userLatitude != null && userLongitude != null) {
        listings = listings.map((listing) {
          if (listing['latitude'] != null && listing['longitude'] != null) {
            listing['distance'] = _calculateDistance(
              userLatitude,
              userLongitude,
              listing['latitude'],
              listing['longitude'],
            );
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


Future<List<Map<String, dynamic>>> _transformListingData(List<dynamic> response) async {
    Set<String> parentCategoryIds = {};
    for (var item in response) {
      if (item['category'] != null && item['category']['parent_category_id'] != null) {
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

    return List<Map<String, dynamic>>.from(response.map((item) {
      List<dynamic> images = item['images'] ?? [];
      String mainImage = images.isNotEmpty ? images[0] : 'https://via.placeholder.com/300';

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
        'status': item['status'],
      };
    }));
  }


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
        response = await query.order('price', ascending: true).range(offset, offset + limit - 1);
      } else if (sortBy == 'Price (High to Low)') {
        response = await query.order('price', ascending: false).range(offset, offset + limit - 1);
      } else {
        response = await query.order('created_at', ascending: false).range(offset, offset + limit - 1);
      }

      var listings = await _transformListingData(response);

      if (latitude != null && longitude != null) {
        listings = listings.map((listing) {
          if (listing['latitude'] != null && listing['longitude'] != null) {
            listing['distance'] = _calculateDistance(
              latitude,
              longitude,
              listing['latitude'],
              listing['longitude'],
            );
          }
          return listing;
        }).toList();

        if (sortBy == null || sortBy == 'Distance' || sortBy == 'Newest') {
          listings.sort((a, b) {
            final distA = a['distance'] ?? double.infinity;
            final distB = b['distance'] ?? double.infinity;
            return distA.compareTo(distB);
          });
        }
      }

      return listings;
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


Future<Set<String>> getUserFavorites() async {
    await _ensureAuthenticated();
    try {
      final user = _supabase.auth.currentUser!;
      final response = await _supabase
          .from('favorites')
          .select('listing_id')
          .eq('user_id', user.id);
      return Set<String>.from(response.map((item) => item['listing_id'] as String));
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
        return false;
      } else {
        await _supabase
            .from('favorites')
            .insert({
              'user_id': user.id,
              'listing_id': listingId,
              'created_at': DateTime.now().toIso8601String(),
            });
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
      }

      if (additionalData != null) {
        if (additionalData['brand'] != null) listingData['brand'] = additionalData['brand'];
        if (additionalData['model'] != null) listingData['model'] = additionalData['model'];
        if (additionalData['yearOfPurchase'] != null) listingData['year_of_purchase'] = int.tryParse(additionalData['yearOfPurchase'].toString());
        if (additionalData['warrantyStatus'] != null) listingData['warranty_status'] = additionalData['warrantyStatus'].toLowerCase();
        if (additionalData['availability'] != null) listingData['availability'] = additionalData['availability'];
        if (additionalData['kilometresDriven'] != null) listingData['kilometres_driven'] = int.tryParse(additionalData['kilometresDriven'].toString());
        if (additionalData['fuelType'] != null) listingData['fuel_type'] = additionalData['fuelType'].toLowerCase();
        if (additionalData['transmissionType'] != null) listingData['transmission_type'] = additionalData['transmissionType'].toLowerCase();
        if (additionalData['bedrooms'] != null) listingData['bedrooms'] = int.tryParse(additionalData['bedrooms'].toString());
        if (additionalData['bathrooms'] != null) listingData['bathrooms'] = int.tryParse(additionalData['bathrooms'].toString());
        if (additionalData['furnishingStatus'] != null) listingData['furnishing_status'] = additionalData['furnishingStatus'].toLowerCase();
      }

      final response = await _supabase
          .from('listings')
          .insert(listingData)
          .select()
          .single();

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
      final response = await _supabase
          .from('categories')
          .select('*')
          .eq('is_active', true)
          .order('sort_order', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      throw Exception('Failed to fetch categories: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getSubcategories(String parentCategoryId) async {
    try {
      final response = await _supabase
          .from('categories')
          .select('*')
          .eq('parent_category_id', parentCategoryId)
          .eq('is_active', true)
          .order('sort_order', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching subcategories: $e');
      throw Exception('Failed to fetch subcategories: ${e.toString()}');
    }
  }

  /// NEW METHOD: Get user profile data
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    await _ensureAuthenticated();
    
    try {
      final response = await _supabase
          .from('user_profiles')
          .select('*')
          .eq('id', userId)
          .single();
      
      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      if (e.toString().contains('JWT') || 
          e.toString().contains('auth') || 
          e.toString().contains('401') ||
          e.toString().contains('403')) {
        throw Exception('Authentication expired. Please login again.');
      }
      throw Exception('Failed to fetch user profile: ${e.toString()}');
    }
  }

  /// NEW METHOD: Get user's own listings
  Future<List<Map<String, dynamic>>> getUserListings() async {
    await _ensureAuthenticated();
    
    try {
      final user = _supabase.auth.currentUser!;
      
      final response = await _supabase
          .from('listings')
          .select('''
            *,
            category:categories!inner(
              id,
              name,
              parent_category_id
            )
          ''')
          .eq('seller_id', user.id)
          .order('created_at', ascending: false);
      
      return await _transformListingData(response);
    } catch (e) {
      debugPrint('Error fetching user listings: $e');
      if (e.toString().contains('JWT') || 
          e.toString().contains('auth') || 
          e.toString().contains('401') ||
          e.toString().contains('403')) {
        throw Exception('Authentication expired. Please login again.');
      }
      throw Exception('Failed to fetch user listings: ${e.toString()}');
    }
  }

  /// NEW METHOD: Delete a listing
  Future<void> deleteListing(String listingId) async {
    await _ensureAuthenticated();
    
    try {
      final user = _supabase.auth.currentUser!;
      
      // Verify ownership before deleting
      final listing = await _supabase
          .from('listings')
          .select('seller_id')
          .eq('id', listingId)
          .single();
      
      if (listing['seller_id'] != user.id) {
        throw Exception('You can only delete your own listings');
      }
      
      await _supabase
          .from('listings')
          .delete()
          .eq('id', listingId);
      
      debugPrint('Listing deleted successfully: $listingId');
    } catch (e) {
      debugPrint('Error deleting listing: $e');
      if (e.toString().contains('JWT') || 
          e.toString().contains('auth') || 
          e.toString().contains('401') ||
          e.toString().contains('403')) {
        throw Exception('Authentication expired. Please login again.');
      }
      throw Exception('Failed to delete listing: ${e.toString()}');
    }
  }

  /// NEW METHOD: Update listing status (e.g., mark as sold)
  Future<void> updateListingStatus(String listingId, String newStatus) async {
    await _ensureAuthenticated();
    
    try {
      final user = _supabase.auth.currentUser!;
      
      // Verify ownership before updating
      final listing = await _supabase
          .from('listings')
          .select('seller_id')
          .eq('id', listingId)
          .single();
      
      if (listing['seller_id'] != user.id) {
        throw Exception('You can only update your own listings');
      }
      
      await _supabase
          .from('listings')
          .update({
            'status': newStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', listingId);
      
      debugPrint('Listing status updated to $newStatus: $listingId');
    } catch (e) {
      debugPrint('Error updating listing status: $e');
      if (e.toString().contains('JWT') || 
          e.toString().contains('auth') || 
          e.toString().contains('401') ||
          e.toString().contains('403')) {
        throw Exception('Authentication expired. Please login again.');
      }
      throw Exception('Failed to update listing status: ${e.toString()}');
    }
  }
}

// END OF FILE