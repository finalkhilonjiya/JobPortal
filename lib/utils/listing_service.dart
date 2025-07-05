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
        searchQuery = searchQuery.eq('category_id', categoryId);
      }

      if (minPrice != null) {
        searchQuery = searchQuery.gte('price', minPrice);
      }

      if (maxPrice != null) {
        searchQuery = searchQuery.lte('price', maxPrice);
      }

      if (condition != null) {
        searchQuery = searchQuery.eq('condition', condition);
      }

      if (location != null) {
        searchQuery = searchQuery.ilike('location', '%$location%');
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
  Future<Map<String, dynamic>?> getListingById(String listingId, {bool incrementViews = true}) async {
    try {
      final client = SupabaseService().client;
      
      // Use PostgreSQL function to atomically fetch and increment views
      // This prevents race conditions and improves performance
      if (incrementViews) {
        final response = await client.rpc('get_listing_and_increment_views', params: {
          'listing_id': listingId,
        });
        
        if (response != null && response.isNotEmpty) {
          debugPrint('✅ Fetched listing with view increment: $listingId');
          return Map<String, dynamic>.from(response[0]);
        }
      }
      
      // Fallback: fetch without incrementing views (for cases where RPC is not available)
      final response = await client.from('listings').select('''
            *,
            seller:user_profiles!seller_id(*),
            category:categories(*)
          ''').eq('id', listingId).single();

      if (incrementViews) {
        // Use atomic increment to prevent race conditions
        try {
          await client.rpc('increment_listing_views', params: {
            'listing_id': listingId,
          });
        } catch (incrementError) {
          debugPrint('⚠️ Failed to increment views (non-critical): $incrementError');
          // Continue without throwing - view count is not critical
        }
      }

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
        query = query.eq('status', status);
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
      
      // Use more efficient query with better ordering for relevant results
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
          // Order by a combination of popularity and recency for better recommendations
          .order('views_count', ascending: false)
          .order('created_at', ascending: false);

      debugPrint('✅ Fetched ${response.length} related listings');
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      debugPrint('❌ Failed to fetch related listings: $error');
      // Return empty list instead of throwing to prevent cascade failures
      debugPrint('🔄 Returning empty related listings due to error');
      return [];
    }
  }

  /// Batch get multiple listings by IDs (performance optimization)
  Future<List<Map<String, dynamic>>> getListingsByIds(List<String> listingIds) async {
    if (listingIds.isEmpty) return [];
    
    try {
      final client = SupabaseService().client;
      final response = await client
          .from('listings')
          .select('''
            *,
            seller:user_profiles!seller_id(*),
            category:categories(*)
          ''')
          .inFilter('id', listingIds)
          .eq('status', 'active');

      debugPrint('✅ Batch fetched ${response.length} listings');
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      debugPrint('❌ Failed to batch fetch listings: $error');
      throw Exception('Failed to batch fetch listings: $error');
    }
  }
}