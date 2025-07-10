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
      if (client == null) return _getMockFavorites();

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
      return _getMockFavorites();
    }
  }

  /// Add listing to favorites
  Future<bool> addFavorite(String listingId) async {
    try {
      final client = _client;
      if (client == null) return true; // Simulate success in offline mode

      final authService = AuthService();
      final user = authService.getCurrentUser();
      if (user == null) return false;

      // Check if already favorited to avoid duplicates
      final existing = await client
          .from(_favoritesTable)
          .select('id')
          .eq('user_id', user.id)
          .eq('listing_id', listingId)
          .maybeSingle();

      if (existing != null) {
        debugPrint('⚠️ Listing already in favorites: $listingId');
        return true;
      }

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
      if (client == null) return true; // Simulate success in offline mode

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

  /// Get favorite count for a listing - FIXED METHOD
  Future<int> getFavoriteCount(String listingId) async {
    try {
      final client = _client;
      if (client == null) return 0;

      // Fixed: Use proper count query without FetchOptions
      final response = await client
          .from(_favoritesTable)
          .select('id')
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
      if (client == null) return true; // Simulate success in offline mode

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

  /// Toggle favorite status
  Future<bool> toggleFavorite(String listingId) async {
    try {
      final isFav = await isFavorite(listingId);
      if (isFav) {
        return await removeFavorite(listingId);
      } else {
        return await addFavorite(listingId);
      }
    } catch (error) {
      debugPrint('❌ Toggle favorite failed: $error');
      return false;
    }
  }

  /// Get popular listings based on favorite count
  Future<List<Map<String, dynamic>>> getPopularListings({int limit = 10}) async {
    try {
      final client = _client;
      if (client == null) return _getMockPopularListings();

      // Get listing IDs with most favorites
      final favoriteCountsResponse = await client
          .from(_favoritesTable)
          .select('listing_id')
          .order('created_at', ascending: false);

      // Group by listing_id and count
      final listingCounts = <String, int>{};
      for (final fav in favoriteCountsResponse) {
        final listingId = fav['listing_id'].toString();
        listingCounts[listingId] = (listingCounts[listingId] ?? 0) + 1;
      }

      // Sort by count and get top listings
      final sortedListings = listingCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final topListingIds = sortedListings
          .take(limit)
          .map((e) => e.key)
          .toList();

      if (topListingIds.isEmpty) return [];

      // Get full listing details
      final listingsResponse = await client
          .from('listings')
          .select('''
            *,
            category:categories(name),
            seller:user_profiles(full_name, avatar_url)
          ''')
          .in_('id', topListingIds)
          .eq('status', 'active');

      return List<Map<String, dynamic>>.from(listingsResponse);
    } catch (error) {
      debugPrint('❌ Get popular listings failed: $error');
      return _getMockPopularListings();
    }
  }

  // Mock data for offline mode
  List<Map<String, dynamic>> _getMockFavorites() {
    return [
      {
        'id': 'fav1',
        'listing_id': '1',
        'user_id': 'user1',
        'created_at': DateTime.now().toIso8601String(),
        'listing': {
          'id': '1',
          'title': 'Traditional Assamese Mekhela Chador',
          'description': 'Beautiful handwoven silk mekhela chador',
          'price': 2500.0,
          'location': 'Guwahati, Assam',
          'images': ['https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=400'],
          'category': {'name': 'Fashion'},
          'seller': {'full_name': 'Priya Sharma', 'avatar_url': null},
          'condition': 'new',
          'status': 'active',
        }
      },
      {
        'id': 'fav2',
        'listing_id': '2',
        'user_id': 'user1',
        'created_at': DateTime.now().subtract(Duration(hours: 1)).toIso8601String(),
        'listing': {
          'id': '2',
          'title': 'Assamese Traditional Bell Metal Utensils',
          'description': 'Authentic bell metal dinner set from Sarthebari',
          'price': 1800.0,
          'location': 'Barpeta, Assam',
          'images': ['https://images.unsplash.com/photo-1449824913935-59a10b8d2000?w=400'],
          'category': {'name': 'Home & Kitchen'},
          'seller': {'full_name': 'Ranjan Das', 'avatar_url': null},
          'condition': 'excellent',
          'status': 'active',
        }
      },
    ];
  }

  List<Map<String, dynamic>> _getMockPopularListings() {
    return _getMockFavorites().map((fav) => fav['listing'] as Map<String, dynamic>).toList();
  }
}