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

// File: models/listing_model.dart
class ListingModel {
  final String? id;
  final String sellerId;
  final String categoryId;
  final String title;
  final String description;
  final double price;
  final String condition;
  final String status;
  final String location;
  final List<String> images;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ListingModel({
    this.id,
    required this.sellerId,
    required this.categoryId,
    required this.title,
    required this.description,
    required this.price,
    required this.condition,
    required this.status,
    required this.location,
    required this.images,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'seller_id': sellerId,
      'category_id': categoryId,
      'title': title,
      'description': description,
      'price': price,
      'condition': condition,
      'status': status,
      'location': location,
      'images': images,
    };
  }

  factory ListingModel.fromJson(Map<String, dynamic> json) {
    return ListingModel(
      id: json['id'],
      sellerId: json['seller_id'],
      categoryId: json['category_id'],
      title: json['title'],
      description: json['description'],
      price: json['price'].toDouble(),
      condition: json['condition'],
      status: json['status'],
      location: json['location'],
      images: List<String>.from(json['images'] ?? []),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }
}