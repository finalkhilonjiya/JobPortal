// File: services/listing_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:postgrest/postgrest.dart';
import 'dart:io';
import '../models/listing_model.dart';

class ListingService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Upload images to Supabase Storage
  Future<List<String>> uploadImages(List<File> images) async {
    List<String> imageUrls = [];
    
    for (int i = 0; i < images.length; i++) {
      final file = images[i];
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
      final storagePath = 'listings/$fileName';
      
      try {
        // Upload to Supabase Storage
        await _supabase.storage
            .from('listings')
            .upload(storagePath, file);
        
        // Get public URL
        final url = _supabase.storage
            .from('listings')
            .getPublicUrl(storagePath);
        
        imageUrls.add(url);
      } catch (e) {
        print('Error uploading image: $e');
        throw Exception('Failed to upload image ${i + 1}');
      }
    }
    
    return imageUrls;
  }
  

   // Add these methods to your existing listing_service.dart file

// In your ListingService class, add:

  // Fetch all active listings with infinite scroll support
  Future<List<Map<String, dynamic>>> fetchListings({
    String? categoryId,
    String? sortBy,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var query = _supabase
          .from('listings')
          .select('''
            *,
            category:categories!inner(
              id,
              name,
              parent_category_id
            )
          ''')
          .eq('status', 'active');

      // Apply category filter if provided
      if (categoryId != null && categoryId != 'All') {
        query = query.eq('category_id', categoryId);
      }

      // Apply sorting and pagination in a single chain
      var finalQuery = query;
      if (sortBy == 'Price (Low to High)') {
        finalQuery = finalQuery.order('price', ascending: true);
      } else if (sortBy == 'Price (High to Low)') {
        finalQuery = finalQuery.order('price', ascending: false);
      } else {
        // Default to newest first
        finalQuery = finalQuery.order('created_at', ascending: false);
      }

      // Apply pagination
      final response = await finalQuery.range(offset, offset + limit - 1);
      
      // Transform the data to match your existing format
      return List<Map<String, dynamic>>.from(response.map((item) {
        // Get first image from the images array
        List<dynamic> images = item['images'] ?? [];
        String mainImage = images.isNotEmpty ? images[0] : 'https://via.placeholder.com/300';
        
        return {
          'id': item['id'],
          'title': item['title'] ?? 'Untitled',
          'price': item['price'] ?? 0,
          'image': mainImage,
          'images': images,
          'location': item['location'] ?? 'Location not specified',
          'category': item['category']['name'] ?? 'Uncategorized',
          'subcategory': item['category']['name'] ?? 'Uncategorized', // Using category name as subcategory
          'description': item['description'] ?? '',
          'condition': item['condition'] ?? 'used',
          'phone': item['seller_phone'] ?? '',
          'seller_name': item['seller_name'] ?? 'Seller',
          'views': item['views_count'] ?? 0,
          'created_at': item['created_at'],
          'is_featured': item['is_featured'] ?? false,
          // Additional fields
          'brand': item['brand'],
          'model': item['model'],
          'year': item['year_of_purchase'],
          'fuel_type': item['fuel_type'],
          'transmission': item['transmission_type'],
          'km_driven': item['kilometres_driven'],
          'bedrooms': item['bedrooms'],
          'bathrooms': item['bathrooms'],
          'furnishing': item['furnishing_status'],
        };
      }));
    } catch (e) {
      print('Error fetching listings: $e');
      return []; // Return empty array on error
    }
  }

  // Fetch premium/featured listings
  Future<List<Map<String, dynamic>>> fetchPremiumListings() async {
    try {
      final response = await _supabase
          .from('listings')
          .select('''
            *,
            category:categories!inner(
              id,
              name
            ),
            seller:user_profiles!inner(
              id,
              full_name,
              phone_number
            )
          ''')
          .eq('status', 'active')
          .eq('is_featured', true)
          .order('created_at', ascending: false)
          .limit(10);
      
      // Transform the data
      return List<Map<String, dynamic>>.from(response.map((item) {
        List<dynamic> images = item['images'] ?? [];
        String mainImage = images.isNotEmpty ? images[0] : '';
        
        return {
          'id': item['id'],
          'title': item['title'],
          'price': item['price'],
          'image': mainImage,
          'images': images,
          'location': item['location'] ?? '',
          'category': item['category']['name'],
          'subcategory': item['category']['name'],
          'description': item['description'],
          'condition': item['condition'],
          'phone': item['seller_phone'] ?? item['seller']['phone_number'] ?? '',
          'seller_name': item['seller_name'] ?? item['seller']['full_name'] ?? 'Unknown',
          'is_featured': true,
        };
      }));
    } catch (e) {
      print('Error fetching premium listings: $e');
      return []; // Return empty list on error
    }
  }

  // Get user's favorites
  Future<Set<String>> getUserFavorites() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return {};

      final response = await _supabase
          .from('favorites')
          .select('listing_id')
          .eq('user_id', user.id);

      return Set<String>.from(
        response.map((item) => item['listing_id'] as String)
      );
    } catch (e) {
      print('Error fetching favorites: $e');
      return {};
    }
  }

  // Toggle favorite
  Future<bool> toggleFavorite(String listingId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check if already favorited
      final existing = await _supabase
          .from('favorites')
          .select('id')
          .eq('user_id', user.id)
          .eq('listing_id', listingId)
          .maybeSingle();

      if (existing != null) {
        // Remove favorite
        await _supabase
            .from('favorites')
            .delete()
            .eq('user_id', user.id)
            .eq('listing_id', listingId);
        return false; // Not favorited anymore
      } else {
        // Add favorite
        await _supabase
            .from('favorites')
            .insert({
              'user_id': user.id,
              'listing_id': listingId,
            });
        return true; // Now favorited
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      throw Exception('Failed to toggle favorite');
    }
  }
  // Create a new listing
  Future<Map<String, dynamic>> createListing({
    required String title,
    required String categoryId,
    required String description,
    required double price,
    required String condition,
    required String location,
    required List<String> imageUrls,
    required String priceType,
    required String sellerName,
    required String sellerPhone,
    required String userType,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Get current user
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
       
      print('User ID: ${user.id}');
      print('Category ID: $categoryId');
      // Prepare listing data
      final Map<String, dynamic> listingData = {
        'seller_id': user.id,
        'category_id': categoryId,
        'title': title,
        'description': description,
        'price': price,
        'price_type': priceType.toLowerCase(),
        'condition': condition,
        'status': 'active',
        'location': location,
        'images': imageUrls,
        'seller_name': sellerName,
        'seller_phone': sellerPhone,
        'user_type': userType.toLowerCase(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Add any additional data (like brand, model, etc.)
      if (additionalData != null) {
        // Convert field names to snake_case for database
        final Map<String, dynamic> dbAdditionalData = {};
        
        if (additionalData['brand'] != null) {
          dbAdditionalData['brand'] = additionalData['brand'];
        }
        if (additionalData['model'] != null) {
          dbAdditionalData['model'] = additionalData['model'];
        }
        if (additionalData['yearOfPurchase'] != null) {
          dbAdditionalData['year_of_purchase'] = int.tryParse(additionalData['yearOfPurchase'].toString());
        }
        if (additionalData['warrantyStatus'] != null) {
          dbAdditionalData['warranty_status'] = additionalData['warrantyStatus'].toLowerCase();
        }
        if (additionalData['availability'] != null) {
          dbAdditionalData['availability'] = additionalData['availability'];
        }
        if (additionalData['kilometresDriven'] != null) {
          dbAdditionalData['kilometres_driven'] = int.tryParse(additionalData['kilometresDriven'].toString());
        }
        if (additionalData['fuelType'] != null) {
          dbAdditionalData['fuel_type'] = additionalData['fuelType'].toLowerCase();
        }
        if (additionalData['transmissionType'] != null) {
          dbAdditionalData['transmission_type'] = additionalData['transmissionType'].toLowerCase();
        }
        if (additionalData['bedrooms'] != null) {
          dbAdditionalData['bedrooms'] = int.tryParse(additionalData['bedrooms'].toString());
        }
        if (additionalData['bathrooms'] != null) {
          dbAdditionalData['bathrooms'] = int.tryParse(additionalData['bathrooms'].toString());
        }
        if (additionalData['furnishingStatus'] != null) {
          dbAdditionalData['furnishing_status'] = additionalData['furnishingStatus'].toLowerCase();
        }
        
        listingData.addAll(dbAdditionalData);
      }
      

    print('=== LISTING DATA TO INSERT ===');
    print(listingData);
    print('=============================');
      // Insert into database
      final response = await _supabase
          .from('listings')
          .insert(listingData)
          .select()
          .single();

      return response;
    } catch (e) {
      print('Error creating listing: $e');
      throw Exception('Failed to create listing: $e');
    }
  }

  // Get categories for dropdown
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await _supabase
          .from('categories')
          .select('*')
          .eq('is_active', true)
          .order('sort_order', ascending: true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching categories: $e');
      throw Exception('Failed to fetch categories');
    }
  }

  // Get subcategories for a parent category
  Future<List<Map<String, dynamic>>> getSubcategories(String parentCategoryId) async {
    try {
      final response = await _supabase
          .from('categories')
          .select('*')
          .eq('parent_category_id', parentCategoryId)
          .eq('is_active', true)
          .order('sort_order', ascending: true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching subcategories: $e');
      throw Exception('Failed to fetch subcategories');
    }
  }
}

