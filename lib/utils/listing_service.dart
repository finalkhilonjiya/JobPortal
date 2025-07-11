import 'package:flutter/foundation.dart';
import '../utils/supabase_service.dart';

class ListingService {
  static final ListingService _instance = ListingService._internal();
  factory ListingService() => _instance;
  ListingService._internal();

  /// Safe client access with fallback
  SupabaseClient? get _client {
    try {
      return SupabaseService().safeClient;
    } catch (e) {
      debugPrint('❌ Failed to get Supabase client: $e');
      return null;
    }
  }

  /// Get active listings with enhanced error handling
  Future<List<Map<String, dynamic>>> getActiveListings({
    int limit = 20, 
    int offset = 0
  }) async {
    try {
      final client = _client;
      if (client == null) {
        // Return mock data for offline mode
        return _getMockActiveListings();
      }

      final response = await client
          .from('listings')
          .select('''
            *,
            category:categories(name),
            seller:user_profiles(full_name, avatar_url)
          ''')
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      debugPrint('❌ Get active listings failed: $error');
      return _getMockActiveListings();
    }
  }

  /// Get listings by category with enhanced error handling
  Future<List<Map<String, dynamic>>> getListingsByCategory(
    String categoryId, {
    int limit = 20, 
    int offset = 0
  }) async {
    try {
      final client = _client;
      if (client == null) {
        // Return mock data for offline mode
        return _getMockListingsByCategory(categoryId);
      }

      final response = await client
          .from('listings')
          .select('''
            *,
            category:categories(name),
            seller:user_profiles(full_name, avatar_url)
          ''')
          .eq('status', 'active')
          .eq('category_id', categoryId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      debugPrint('❌ Get listings by category failed: $error');
      return _getMockListingsByCategory(categoryId);
    }
  }

  /// Get trending listings based on views and favorites
  Future<List<Map<String, dynamic>>> getTrendingListings({int limit = 10}) async {
    try {
      final client = _client;
      if (client == null) {
        return _getMockTrendingListings();
      }

      final response = await client
          .from('listings')
          .select('''
            *,
            category:categories(name),
            seller:user_profiles(full_name, avatar_url)
          ''')
          .eq('status', 'active')
          .order('views_count', ascending: false)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      debugPrint('❌ Get trending listings failed: $error');
      return _getMockTrendingListings();
    }
  }

  /// Get nearby listings based on location
  Future<List<Map<String, dynamic>>> getNearbyListings({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    int limit = 20,
    int offset = 0,
    String? categoryId,
  }) async {
    try {
      final client = _client;
      if (client == null) {
        return _getMockNearbyListings();
      }

      var query = client
          .from('listings')
          .select('''
            *,
            category:categories(name),
            seller:user_profiles(full_name, avatar_url)
          ''')
          .eq('status', 'active');
      if (categoryId != null && categoryId != 'all') {
        query = query.eq('category_id', categoryId);
      }
      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      debugPrint('❌ Get nearby listings failed: $error');
      return _getMockNearbyListings();
    }
  }

  /// Create a new listing
  Future<Map<String, dynamic>?> createListing({
    required String title,
    required String description,
    required double price,
    required String categoryId,
    required String condition,
    String? location,
    List<String>? imageUrls,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final client = _client;
      if (client == null) {
        throw Exception('Supabase not available');
      }

      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final listingData = {
        'title': title,
        'description': description,
        'price': price,
        'category_id': categoryId,
        'condition': condition,
        'location': location,
        'images': imageUrls ?? [],
        'metadata': metadata ?? {},
        'seller_id': userId,
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await client
          .from('listings')
          .insert(listingData)
          .select()
          .single();

      debugPrint('✅ Listing created successfully');
      return response;
    } catch (error) {
      debugPrint('❌ Create listing failed: $error');
      rethrow;
    }
  }

  /// Update an existing listing
  Future<Map<String, dynamic>?> updateListing({
    required String listingId,
    String? title,
    String? description,
    double? price,
    String? categoryId,
    String? condition,
    String? location,
    List<String>? imageUrls,
    String? status,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final client = _client;
      if (client == null) {
        throw Exception('Supabase not available');
      }

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (price != null) updateData['price'] = price;
      if (categoryId != null) updateData['category_id'] = categoryId;
      if (condition != null) updateData['condition'] = condition;
      if (location != null) updateData['location'] = location;
      if (imageUrls != null) updateData['images'] = imageUrls;
      if (status != null) updateData['status'] = status;
      if (metadata != null) updateData['metadata'] = metadata;

      final response = await client
          .from('listings')
          .update(updateData)
          .eq('id', listingId)
          .select()
          .single();

      debugPrint('✅ Listing updated successfully');
      return response;
    } catch (error) {
      debugPrint('❌ Update listing failed: $error');
      rethrow;
    }
  }

  /// Delete a listing
  Future<void> deleteListing(String listingId) async {
    try {
      final client = _client;
      if (client == null) {
        throw Exception('Supabase not available');
      }

      await client
          .from('listings')
          .delete()
          .eq('id', listingId);

      debugPrint('✅ Listing deleted successfully');
    } catch (error) {
      debugPrint('❌ Delete listing failed: $error');
      rethrow;
    }
  }

  /// Get listing by ID
  Future<Map<String, dynamic>?> getListingById(String listingId) async {
    try {
      final client = _client;
      if (client == null) {
        return _getMockListingById(listingId);
      }

      final response = await client
          .from('listings')
          .select('''
            *,
            category:categories(name),
            seller:user_profiles(full_name, avatar_url, phone_number)
          ''')
          .eq('id', listingId)
          .single();

      return response;
    } catch (error) {
      debugPrint('❌ Get listing by ID failed: $error');
      return _getMockListingById(listingId);
    }
  }

  /// Search listings with filters
  Future<List<Map<String, dynamic>>> searchListings({
    String? query,
    String? categoryId,
    double? minPrice,
    double? maxPrice,
    String? condition,
    String? location,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final client = _client;
      if (client == null) {
        return _getMockSearchResults(query);
      }

      var queryBuilder = client
          .from('listings')
          .select('''
            *,
            category:categories(name),
            seller:user_profiles(full_name, avatar_url)
          ''')
          .eq('status', 'active');

      if (query != null && query.isNotEmpty) {
        queryBuilder = queryBuilder.or('title.ilike.%$query%,description.ilike.%$query%');
      }

      if (categoryId != null) {
        queryBuilder = queryBuilder.eq('category_id', categoryId);
      }

      if (minPrice != null) {
        queryBuilder = queryBuilder.gte('price', minPrice);
      }

      if (maxPrice != null) {
        queryBuilder = queryBuilder.lte('price', maxPrice);
      }

      if (condition != null) {
        queryBuilder = queryBuilder.eq('condition', condition);
      }

      if (location != null) {
        queryBuilder = queryBuilder.ilike('location', '%$location%');
      }

      final response = await queryBuilder
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      debugPrint('❌ Search listings failed: $error');
      return _getMockSearchResults(query);
    }
  }

  // Mock data methods for offline mode
  List<Map<String, dynamic>> _getMockActiveListings() {
    return [
      {
        'id': '1',
        'title': 'iPhone 14 Pro Max - Excellent Condition',
        'description': 'Barely used iPhone 14 Pro Max in excellent condition.',
        'price': 899.0,
        'location': 'Guwahati, Assam',
        'created_at': DateTime.now().subtract(Duration(hours: 2)).toIso8601String(),
        'images': ['https://images.unsplash.com/photo-1592750475338-74b7b21085ab?w=400'],
        'category': {'name': 'Electronics'},
        'seller': {'full_name': 'John Doe', 'avatar_url': null},
        'views_count': 45,
        'condition': 'excellent',
        'status': 'active',
      },
      {
        'id': '2',
        'title': 'MacBook Air M2 - Brand New',
        'description': 'Brand new MacBook Air with M2 chip, still sealed.',
        'price': 1199.0,
        'location': 'Jorhat, Assam',
        'created_at': DateTime.now().subtract(Duration(hours: 4)).toIso8601String(),
        'images': ['https://images.unsplash.com/photo-1541807084-5c52b6b3adef?w=400'],
        'category': {'name': 'Electronics'},
        'seller': {'full_name': 'Jane Smith', 'avatar_url': null},
        'views_count': 32,
        'condition': 'new',
        'status': 'active',
      },
    ];
  }

  List<Map<String, dynamic>> _getMockListingsByCategory(String categoryId) {
    return _getMockActiveListings();
  }

  List<Map<String, dynamic>> _getMockTrendingListings() {
    return _getMockActiveListings();
  }

  List<Map<String, dynamic>> _getMockNearbyListings() {
    return _getMockActiveListings();
  }

  Map<String, dynamic>? _getMockListingById(String listingId) {
    final listings = _getMockActiveListings();
    return listings.firstWhere(
      (listing) => listing['id'] == listingId,
      orElse: () => listings.first,
    );
  }

  List<Map<String, dynamic>> _getMockSearchResults(String? query) {
    return _getMockActiveListings();
  }
}