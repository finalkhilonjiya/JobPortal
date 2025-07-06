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
}