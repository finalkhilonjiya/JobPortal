class ListingService {
  // Simulated fetch of active listings
  Future<List<Map<String, dynamic>>> getActiveListings({int limit = 20, int offset = 0}) async {
    await Future.delayed(Duration(milliseconds: 300));
    return []; // Replace with Firestore query later
  }

  // Simulated fetch of listings by category
  Future<List<Map<String, dynamic>>> getListingsByCategory(String categoryId, {int limit = 20, int offset = 0}) async {
    await Future.delayed(Duration(milliseconds: 300));
    return []; // Replace with Firestore query later
  }
  // ADD THESE METHODS TO YOUR EXISTING ListingService CLASS

  /// Get trending listings based on views and favorites
  Future<List<Map<String, dynamic>>> getTrendingListings({int limit = 10}) async {
    try {
      final client = _client;
      if (client == null) return [];

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
      return [];
    }
  }

  /// Get nearby listings based on location
  Future<List<Map<String, dynamic>>> getNearbyListings({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final client = _client;
      if (client == null) return [];

      // For now, return all active listings since geo-filtering requires PostGIS
      // In production, you would use ST_DWithin or similar PostGIS functions
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
      debugPrint('❌ Get nearby listings failed: $error');
      return [];
    }
  }
}