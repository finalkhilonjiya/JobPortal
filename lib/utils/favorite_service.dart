import 'package:flutter/foundation.dart';
import './supabase_service.dart';

class FavoriteService {
  static final FavoriteService _instance = FavoriteService._internal();
  factory FavoriteService() => _instance;
  FavoriteService._internal();

  /// Add a listing to favorites
  Future<Map<String, dynamic>> addFavorite(String listingId) async {
    try {
      final client = SupabaseService().client;
      final userId = client.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User must be authenticated to add favorites');
      }

      final response = await client
          .from('favorites')
          .insert({
            'user_id': userId,
            'listing_id': listingId,
          })
          .select()
          .single();

      // Update favorites count in listings table
      await client.rpc('increment_favorites_count', params: {
        'listing_uuid': listingId,
      });

      debugPrint('✅ Added listing to favorites: $listingId');
      return response;
    } catch (error) {
      debugPrint('❌ Failed to add favorite: $error');
      throw Exception('Failed to add favorite: $error');
    }
  }

  /// Remove a listing from favorites
  Future<void> removeFavorite(String listingId) async {
    try {
      final client = SupabaseService().client;
      final userId = client.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User must be authenticated');
      }

      await client
          .from('favorites')
          .delete()
          .eq('user_id', userId)
          .eq('listing_id', listingId);

      // Update favorites count in listings table
      await client.rpc('decrement_favorites_count', params: {
        'listing_uuid': listingId,
      });

      debugPrint('✅ Removed listing from favorites: $listingId');
    } catch (error) {
      debugPrint('❌ Failed to remove favorite: $error');
      throw Exception('Failed to remove favorite: $error');
    }
  }

  /// Get user's favorite listings
  Future<List<Map<String, dynamic>>> getUserFavorites({
    int? limit,
    int? offset,
  }) async {
    try {
      final client = SupabaseService().client;
      final userId = client.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User must be authenticated');
      }

      var query = client.from('favorites').select('''
            *,
            listing:listings!listing_id(
              *,
              seller:user_profiles!seller_id(*),
              category:categories(*)
            )
          ''').eq('user_id', userId).order('created_at', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 50) - 1);
      }

      final response = await query;
      debugPrint('✅ Fetched ${response.length} user favorites');
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      debugPrint('❌ Failed to fetch user favorites: $error');
      throw Exception('Failed to fetch user favorites: $error');
    }
  }

  /// Check if a listing is favorited by current user
  Future<bool> isListingFavorited(String listingId) async {
    try {
      final client = SupabaseService().client;
      final userId = client.auth.currentUser?.id;

      if (userId == null) {
        return false;
      }

      final response = await client
          .from('favorites')
          .select('id')
          .eq('user_id', userId)
          .eq('listing_id', listingId)
          .maybeSingle();

      return response != null;
    } catch (error) {
      debugPrint('❌ Failed to check favorite status: $error');
      return false;
    }
  }

  /// Get favorite counts for multiple listings
  Future<Map<String, int>> getFavoriteCounts(List<String> listingIds) async {
    try {
      final client = SupabaseService().client;

      // Get favorite counts for each listing
      final counts = <String, int>{};

      for (String listingId in listingIds) {
        final response = await client
            .from('favorites')
            .select('id')
            .eq('listing_id', listingId);

        counts[listingId] = response.length;
      }

      debugPrint('✅ Fetched favorite counts for ${listingIds.length} listings');
      return counts;
    } catch (error) {
      debugPrint('❌ Failed to fetch favorite counts: $error');
      throw Exception('Failed to fetch favorite counts: $error');
    }
  }

  /// Get users who favorited a specific listing
  Future<List<Map<String, dynamic>>> getListingFavoriters(
    String listingId, {
    int? limit,
  }) async {
    try {
      final client = SupabaseService().client;

      var query = client
          .from('favorites')
          .select('''
            *,
            user:user_profiles!user_id(*)
          ''')
          .eq('listing_id', listingId)
          .order('created_at', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;
      debugPrint(
          '✅ Fetched ${response.length} favoriters for listing: $listingId');
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      debugPrint('❌ Failed to fetch listing favoriters: $error');
      throw Exception('Failed to fetch listing favoriters: $error');
    }
  }

  /// Get trending/popular listings based on favorites
  Future<List<Map<String, dynamic>>> getTrendingListings({
    int limit = 10,
    int? categoryId,
  }) async {
    try {
      final client = SupabaseService().client;

      // This would ideally use a database function for better performance
      var query = client
          .from('listings')
          .select('''
            *,
            seller:user_profiles!seller_id(*),
            category:categories(*)
          ''')
          .eq('status', 'active')
          .order('favorites_count', ascending: false);

      if (categoryId != null) {
        query = query.eq('category_id', categoryId);
      }

      query = query.limit(limit);

      final response = await query;
      debugPrint('✅ Fetched ${response.length} trending listings');
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      debugPrint('❌ Failed to fetch trending listings: $error');
      throw Exception('Failed to fetch trending listings: $error');
    }
  }

  /// Get user's favorite statistics
  Future<Map<String, dynamic>> getUserFavoriteStats() async {
    try {
      final client = SupabaseService().client;
      final userId = client.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User must be authenticated');
      }

      final results = await Future.wait([
        // Total favorites count
        client.from('favorites').select('*').eq('user_id', userId),

        // Favorites by category
        client.rpc('get_user_favorites_by_category', params: {
          'user_uuid': userId,
        }),
      ]);

      final totalCount = results[0].count ?? 0;
      final byCategory = results[1] as List<dynamic>;

      debugPrint('✅ Fetched user favorite statistics');
      return {
        'total_favorites': totalCount,
        'favorites_by_category': byCategory,
      };
    } catch (error) {
      debugPrint('❌ Failed to fetch user favorite stats: $error');
      throw Exception('Failed to fetch user favorite stats: $error');
    }
  }
}