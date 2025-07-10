import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './auth_service.dart';

class FavoriteService {
  static final FavoriteService _instance = FavoriteService._internal();
  factory FavoriteService() => _instance;
  FavoriteService._internal();

  static const String _favoritesTable = 'favorites';

  SupabaseClient? get _client {
    try {
      return SupabaseService().safeClient;
    } catch (e) {
      debugPrint('❌ Failed to get Supabase client: $e');
      return null;
    }
  }

  /// Get user's favorite listings
  Future<List<Map<String, dynamic>>> getUserFavorites() async {
    try {
      final client = _client;
      if (client == null) return [];

      final authService = AuthService();
      final user = authService.getCurrentUser();
      if (user == null) return [];

      final response = await client
          .from(_favoritesTable)
          .select('''
            *,
            listing:listings(
              *,
              category:categories(name),
              seller:user_profiles(full_name, avatar_url)
            )
          ''')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      debugPrint('❌ Get user favorites failed: $error');
      return [];
    }
  }

  /// Add listing to favorites
  Future<bool> addFavorite(String listingId) async {
    try {
      final client = _client;
      if (client == null) return false;

      final authService = AuthService();
      final user = authService.getCurrentUser();
      if (user == null) return false;

      await client.from(_favoritesTable).insert({
        'user_id': user.id,
        'listing_id': listingId,
        'created_at': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ Added to favorites: $listingId');
      return true;
    } catch (error) {
      debugPrint('❌ Add favorite failed: $error');
      return false;
    }
  }

  /// Remove listing from favorites
  Future<bool> removeFavorite(String listingId) async {
    try {
      final client = _client;
      if (client == null) return false;

      final authService = AuthService();
      final user = authService.getCurrentUser();
      if (user == null) return false;

      await client
          .from(_favoritesTable)
          .delete()
          .eq('user_id', user.id)
          .eq('listing_id', listingId);

      debugPrint('✅ Removed from favorites: $listingId');
      return true;
    } catch (error) {
      debugPrint('❌ Remove favorite failed: $error');
      return false;
    }
  }

  /// Check if listing is favorited by user
  Future<bool> isFavorite(String listingId) async {
    try {
      final client = _client;
      if (client == null) return false;

      final authService = AuthService();
      final user = authService.getCurrentUser();
      if (user == null) return false;

      final response = await client
          .from(_favoritesTable)
          .select('id')
          .eq('user_id', user.id)
          .eq('listing_id', listingId)
          .maybeSingle();

      return response != null;
    } catch (error) {
      debugPrint('❌ Check favorite failed: $error');
      return false;
    }
  }

  /// Get favorite count for a listing
  Future<int> getFavoriteCount(String listingId) async {
    try {
      final client = _client;
      if (client == null) return 0;

      final response = await client
          .from(_favoritesTable)
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('listing_id', listingId);

      return response.length;
    } catch (error) {
      debugPrint('❌ Get favorite count failed: $error');
      return 0;
    }
  }

  /// Get user's favorite listing IDs only
  Future<Set<String>> getUserFavoriteIds() async {
    try {
      final client = _client;
      if (client == null) return {};

      final authService = AuthService();
      final user = authService.getCurrentUser();
      if (user == null) return {};

      final response = await client
          .from(_favoritesTable)
          .select('listing_id')
          .eq('user_id', user.id);

      return response
          .map<String>((fav) => fav['listing_id'].toString())
          .toSet();
    } catch (error) {
      debugPrint('❌ Get user favorite IDs failed: $error');
      return {};
    }
  }

  /// Clear all user favorites
  Future<bool> clearAllFavorites() async {
    try {
      final client = _client;
      if (client == null) return false;

      final authService = AuthService();
      final user = authService.getCurrentUser();
      if (user == null) return false;

      await client
          .from(_favoritesTable)
          .delete()
          .eq('user_id', user.id);

      debugPrint('✅ Cleared all favorites');
      return true;
    } catch (error) {
      debugPrint('❌ Clear favorites failed: $error');
      return false;
    }
  }
}