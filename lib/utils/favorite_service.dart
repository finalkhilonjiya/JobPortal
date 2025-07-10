import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';

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

  /// Get all favorites for the current user
  Future<List<Map<String, dynamic>>> getUserFavorites() async {
    try {
      final client = _client;
      if (client == null) return [];
      final userId = client.auth.currentUser?.id;
      if (userId == null) return [];
      final response = await client
          .from(_favoritesTable)
          .select('*')
          .eq('user_id', userId);
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      debugPrint('❌ Get user favorites failed: $error');
      return [];
    }
  }

  /// Add a favorite listing for the current user
  Future<void> addFavorite(String listingId) async {
    try {
      final client = _client;
      if (client == null) return;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;
      await client.from(_favoritesTable).insert({
        'user_id': userId,
        'listing_id': listingId,
      });
    } catch (error) {
      debugPrint('❌ Add favorite failed: $error');
    }
  }

  /// Remove a favorite listing for the current user
  Future<void> removeFavorite(String listingId) async {
    try {
      final client = _client;
      if (client == null) return;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;
      await client
          .from(_favoritesTable)
          .delete()
          .eq('user_id', userId)
          .eq('listing_id', listingId);
    } catch (error) {
      debugPrint('❌ Remove favorite failed: $error');
    }
  }
}