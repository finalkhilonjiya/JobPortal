import 'package:flutter/foundation.dart';
import './supabase_service.dart';

class ListingService {
  static final ListingService _instance = ListingService._internal();
  factory ListingService() => _instance;
  ListingService._internal();

  /// Get all active listings
  Future<List<Map<String, dynamic>>> getActiveListings({
    int? limit,
    int? offset,
  }) async {
    try {
      final client = SupabaseService().client;
      var query = client.from('listings').select('''
            *,
            seller:user_profiles!seller_id(*),
            category:categories(*)
          ''').eq('status', 'active').order('created_at', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 50) - 1);
      }

      final response = await query;
      debugPrint('✅ Fetched ${response.length} active listings');
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      debugPrint('❌ Failed to fetch listings: $error');
      throw Exception('Failed to fetch listings: $error');
    }
  }

  /// Get listings by category
  Future<List<Map<String, dynamic>>> getListingsByCategory(
    String categoryId, {
    int? limit,
  }) async {
    try {
      final client = SupabaseService().client;
      var query = client
          .from('listings')
          .select('''
            *,
            seller:user_profiles!seller_id(*),
            category:categories(*)
          ''')
          .eq('category_id', categoryId)
          .eq('status', 'active')
          .order('created_at', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;
      debugPrint(
          '✅ Fetched ${response.length} listings for category: $categoryId');
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      debugPrint('❌ Failed to fetch listings by category: $error');
      throw Exception('Failed to fetch listings by category: $error');
    }
  }

  /// Search listings
  Future<List<Map<String, dynamic>>> searchListings(
    String query, {
    String? categoryId,
    double? minPrice,
    double? maxPrice,
    String? condition,
    String? location,
    int? limit,
  }) async {
    try {
      final client = SupabaseService().client;
      var searchQuery = client
          .from('listings')
          .select('''
            *,
            seller:user_profiles!seller_id(*),
            category:categories(*)
          ''')
          .eq('status', 'active')
          .ilike('title', '%$query%')
          .order('created_at', ascending: false);

      if (categoryId != null) {
        searchQuery = searchQuery.filter('category_id', 'eq', categoryId);
      }

      if (minPrice != null) {
        searchQuery = searchQuery.filter('price', 'gte', minPrice);
      }

      if (maxPrice != null) {
        searchQuery = searchQuery.filter('price', 'lte', maxPrice);
      }

      if (condition != null) {
        searchQuery = searchQuery.filter('condition', 'eq', condition);
      }

      if (location != null) {
        searchQuery = searchQuery.filter('location', 'ilike', '%$location%');
      }

      if (limit != null) {
        searchQuery = searchQuery.limit(limit);
      }

      final response = await searchQuery;
      debugPrint(
          '✅ Search found ${response.length} listings for query: $query');
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      debugPrint('❌ Failed to search listings: $error');
      throw Exception('Failed to search listings: $error');
    }
  }

  /// Get listing by ID
  Future<Map<String, dynamic>?> getListingById(String listingId) async {
    try {
      final client = SupabaseService().client;
      final response = await client.from('listings').select('''
            *,
            seller:user_profiles!seller_id(*),
            category:categories(*)
          ''').eq('id', listingId).single();

      // Increment view count
      await client
          .from('listings')
          .update({'views_count': (response['views_count'] ?? 0) + 1}).eq(
              'id', listingId);

      debugPrint('✅ Fetched listing: $listingId');
      return response;
    } catch (error) {
      debugPrint('❌ Failed to fetch listing: $error');
      throw Exception('Failed to fetch listing: $error');
    }
  }

  /// Create a new listing
  Future<Map<String, dynamic>> createListing({
    required String title,
    required String description,
    required double price,
    required String categoryId,
    required String condition,
    String? location,
    double? latitude,
    double? longitude,
    List<String>? imageUrls,
  }) async {
    try {
      final client = SupabaseService().client;
      final userId = client.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User must be authenticated to create listing');
      }

      final listingData = {
        'seller_id': userId,
        'category_id': categoryId,
        'title': title,
        'description': description,
        'price': price,
        'condition': condition,
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
        'images': imageUrls ?? [],
        'status': 'active',
      };

      final response =
          await client.from('listings').insert(listingData).select('''
            *,
            seller:user_profiles!seller_id(*),
            category:categories(*)
          ''').single();

      debugPrint('✅ Created listing: ${response['id']}');
      return response;
    } catch (error) {
      debugPrint('❌ Failed to create listing: $error');
      throw Exception('Failed to create listing: $error');
    }
  }

  /// Update listing
  Future<Map<String, dynamic>> updateListing(
    String listingId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final client = SupabaseService().client;
      final userId = client.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User must be authenticated');
      }

      // Add updated_at timestamp
      updates['updated_at'] = DateTime.now().toIso8601String();

      final response = await client
          .from('listings')
          .update(updates)
          .eq('id', listingId)
          .eq('seller_id', userId) // Ensure user owns the listing
          .select('''
            *,
            seller:user_profiles!seller_id(*),
            category:categories(*)
          ''').single();

      debugPrint('✅ Updated listing: $listingId');
      return response;
    } catch (error) {
      debugPrint('❌ Failed to update listing: $error');
      throw Exception('Failed to update listing: $error');
    }
  }

  /// Delete listing
  Future<void> deleteListing(String listingId) async {
    try {
      final client = SupabaseService().client;
      final userId = client.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User must be authenticated');
      }

      await client
          .from('listings')
          .delete()
          .eq('id', listingId)
          .eq('seller_id', userId); // Ensure user owns the listing

      debugPrint('✅ Deleted listing: $listingId');
    } catch (error) {
      debugPrint('❌ Failed to delete listing: $error');
      throw Exception('Failed to delete listing: $error');
    }
  }

  /// Get user's listings
  Future<List<Map<String, dynamic>>> getUserListings({
    String? status,
    int? limit,
  }) async {
    try {
      final client = SupabaseService().client;
      final userId = client.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User must be authenticated');
      }

      var query = client.from('listings').select('''
            *,
            category:categories(*)
          ''').eq('seller_id', userId).order('created_at', ascending: false);

      if (status != null) {
        query = query.filter('status', 'eq', status);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;
      debugPrint('✅ Fetched ${response.length} user listings');
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      debugPrint('❌ Failed to fetch user listings: $error');
      throw Exception('Failed to fetch user listings: $error');
    }
  }

  /// Get related listings (same category, excluding current listing)
  Future<List<Map<String, dynamic>>> getRelatedListings(
    String currentListingId,
    String categoryId, {
    int limit = 5,
  }) async {
    try {
      final client = SupabaseService().client;
      final response = await client
          .from('listings')
          .select('''
            *,
            seller:user_profiles!seller_id(*),
            category:categories(*)
          ''')
          .eq('category_id', categoryId)
          .eq('status', 'active')
          .neq('id', currentListingId)
          .limit(limit)
          .order('created_at', ascending: false);

      debugPrint('✅ Fetched ${response.length} related listings');
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      debugPrint('❌ Failed to fetch related listings: $error');
      throw Exception('Failed to fetch related listings: $error');
    }
  }
}