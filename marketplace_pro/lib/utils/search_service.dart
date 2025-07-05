import 'package:flutter/foundation.dart';
import './supabase_service.dart';

class SearchService {
  static final SearchService _instance = SearchService._internal();
  factory SearchService() => _instance;
  SearchService._internal();

  /// Perform ranked search on listings
  Future<List<Map<String, dynamic>>> searchListings({
    required String query,
    String? categoryId,
    String? location,
    double? minPrice,
    double? maxPrice,
    int limit = 20,
  }) async {
    try {
      final client = SupabaseService().client;

      final response = await client.rpc('search_listings_ranked', params: {
        'search_query': query,
        'category_filter': categoryId,
        'location_filter': location,
        'min_price': minPrice,
        'max_price': maxPrice,
        'limit_count': limit,
      });

      debugPrint('✅ Search found ${response.length} results for: $query');
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      debugPrint('❌ Search failed: $error');
      throw Exception('Search failed: $error');
    }
  }

  /// Get popular/trending listings
  Future<List<Map<String, dynamic>>> getPopularListings({
    int daysBack = 7,
    int limit = 10,
  }) async {
    try {
      final client = SupabaseService().client;

      final response = await client.rpc('get_popular_listings', params: {
        'days_back': daysBack,
        'limit_count': limit,
      });

      debugPrint('✅ Fetched ${response.length} popular listings');
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      debugPrint('❌ Failed to fetch popular listings: $error');
      throw Exception('Failed to fetch popular listings: $error');
    }
  }

  /// Save search query to user's search history
  Future<void> saveSearchHistory({
    required String query,
    Map<String, dynamic>? filters,
  }) async {
    try {
      final client = SupabaseService().client;
      final userId = client.auth.currentUser?.id;

      if (userId == null) {
        // Don't save search history for non-authenticated users
        return;
      }

      await client.from('search_history').insert({
        'user_id': userId,
        'search_query': query,
        'filters': filters,
      });

      debugPrint('✅ Saved search history: $query');
    } catch (error) {
      debugPrint('❌ Failed to save search history: $error');
      // Don't throw error for search history failures
    }
  }

  /// Get user's search history
  Future<List<Map<String, dynamic>>> getSearchHistory({
    int limit = 10,
  }) async {
    try {
      final client = SupabaseService().client;
      final userId = client.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User must be authenticated');
      }

      final response = await client
          .from('search_history')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      debugPrint('✅ Fetched ${response.length} search history items');
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      debugPrint('❌ Failed to fetch search history: $error');
      throw Exception('Failed to fetch search history: $error');
    }
  }

  /// Get trending search keywords
  Future<List<String>> getTrendingKeywords({
    int limit = 10,
    int daysBack = 7,
  }) async {
    try {
      final client = SupabaseService().client;

      final response = await client
          .from('search_history')
          .select('search_query')
          .gte(
              'created_at',
              DateTime.now()
                  .subtract(Duration(days: daysBack))
                  .toIso8601String())
          .order('created_at', ascending: false);

      // Process the results to extract trending keywords
      final queryCount = <String, int>{};
      for (final item in response) {
        final query = item['search_query'] as String;
        final words = query.toLowerCase().split(' ');
        for (final word in words) {
          if (word.length > 2) {
            // Ignore very short words
            queryCount[word] = (queryCount[word] ?? 0) + 1;
          }
        }
      }

      // Sort by frequency and take top results
      final sortedKeywords = queryCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final trending =
          sortedKeywords.take(limit).map((entry) => entry.key).toList();

      debugPrint('✅ Fetched ${trending.length} trending keywords');
      return trending;
    } catch (error) {
      debugPrint('❌ Failed to fetch trending keywords: $error');
      // Return fallback trending keywords
      return [
        'iPhone',
        'MacBook',
        'furniture',
        'car',
        'laptop',
        'phone',
        'bicycle',
        'camera',
        'watch',
        'clothes',
      ];
    }
  }

  /// Clear user's search history
  Future<void> clearSearchHistory() async {
    try {
      final client = SupabaseService().client;
      final userId = client.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User must be authenticated');
      }

      await client.from('search_history').delete().eq('user_id', userId);

      debugPrint('✅ Cleared search history');
    } catch (error) {
      debugPrint('❌ Failed to clear search history: $error');
      throw Exception('Failed to clear search history: $error');
    }
  }

  /// Delete specific search history item
  Future<void> deleteSearchHistoryItem(String searchHistoryId) async {
    try {
      final client = SupabaseService().client;
      final userId = client.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User must be authenticated');
      }

      await client
          .from('search_history')
          .delete()
          .eq('id', searchHistoryId)
          .eq('user_id', userId);

      debugPrint('✅ Deleted search history item: $searchHistoryId');
    } catch (error) {
      debugPrint('❌ Failed to delete search history item: $error');
      throw Exception('Failed to delete search history item: $error');
    }
  }

  /// Get search suggestions based on partial query
  Future<List<String>> getSearchSuggestions(String partialQuery) async {
    if (partialQuery.length < 2) return [];

    try {
      final client = SupabaseService().client;

      // Get suggestions from recent searches
      final recentSearches = await client
          .from('search_history')
          .select('search_query')
          .ilike('search_query', '$partialQuery%')
          .order('created_at', ascending: false)
          .limit(5);

      // Get suggestions from listing titles
      final listingTitles = await client
          .from('listings')
          .select('title')
          .eq('status', 'active')
          .ilike('title', '$partialQuery%')
          .limit(5);

      // Get suggestions from category names
      final categories = await client
          .from('categories')
          .select('name')
          .eq('is_active', true)
          .ilike('name', '$partialQuery%')
          .limit(3);

      final suggestions = <String>{};

      // Add recent searches
      for (final item in recentSearches) {
        suggestions.add(item['search_query'] as String);
      }

      // Add listing titles
      for (final item in listingTitles) {
        suggestions.add(item['title'] as String);
      }

      // Add category names
      for (final item in categories) {
        suggestions.add(item['name'] as String);
      }

      final result = suggestions.take(8).toList();
      debugPrint('✅ Generated ${result.length} search suggestions');
      return result;
    } catch (error) {
      debugPrint('❌ Failed to get search suggestions: $error');
      return [];
    }
  }
}
