// File: services/listing_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
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

      // Prepare listing data
      final listingData = {
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
        final dbAdditionalData = {
          if (additionalData['brand'] != null) 'brand': additionalData['brand'],
          if (additionalData['model'] != null) 'model': additionalData['model'],
          if (additionalData['yearOfPurchase'] != null) 'year_of_purchase': int.tryParse(additionalData['yearOfPurchase'].toString()),
          if (additionalData['warrantyStatus'] != null) 'warranty_status': additionalData['warrantyStatus'].toLowerCase(),
          if (additionalData['availability'] != null) 'availability': additionalData['availability'],
          if (additionalData['kilometresDriven'] != null) 'kilometres_driven': int.tryParse(additionalData['kilometresDriven'].toString()),
          if (additionalData['fuelType'] != null) 'fuel_type': additionalData['fuelType'].toLowerCase(),
          if (additionalData['transmissionType'] != null) 'transmission_type': additionalData['transmissionType'].toLowerCase(),
          if (additionalData['bedrooms'] != null) 'bedrooms': int.tryParse(additionalData['bedrooms'].toString()),
          if (additionalData['bathrooms'] != null) 'bathrooms': int.tryParse(additionalData['bathrooms'].toString()),
          if (additionalData['furnishingStatus'] != null) 'furnishing_status': additionalData['furnishingStatus'].toLowerCase(),
        };
        listingData.addAll(dbAdditionalData);
      }

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

