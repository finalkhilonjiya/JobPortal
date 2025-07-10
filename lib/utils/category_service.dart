import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';

class CategoryService {
  static final CategoryService _instance = CategoryService._internal();
  factory CategoryService() => _instance;
  CategoryService._internal();

  static const String _categoriesTable = 'categories';

  SupabaseClient? get _client {
    try {
      return SupabaseService().safeClient;
    } catch (e) {
      debugPrint('❌ Failed to get Supabase client: $e');
      return null;
    }
  }

  /// Get main categories (top-level categories) - FIXED METHOD
  Future<List<Map<String, dynamic>>> getMainCategories() async {
    try {
      final client = _client;
      if (client == null) {
        return _getKhilonjijaCategories();
      }

      // Fixed: Use eq() for null check instead of is_()
      final response = await client
          .from(_categoriesTable)
          .select('*')
          .isFilter('parent_id', 'is', null)
          .order('sort_order', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      debugPrint('❌ Get main categories failed: $error');
      return _getKhilonjijaCategories();
    }
  }

  /// Get subcategories for a parent category
  Future<List<Map<String, dynamic>>> getSubcategories(String parentId) async {
    try {
      final client = _client;
      if (client == null) return [];

      final response = await client
          .from(_categoriesTable)
          .select('*')
          .eq('parent_id', parentId)
          .order('sort_order', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      debugPrint('❌ Get subcategories failed: $error');
      return [];
    }
  }

  /// Get all categories in a hierarchical structure
  Future<List<Map<String, dynamic>>> getAllCategoriesHierarchy() async {
    try {
      final client = _client;
      if (client == null) {
        return _getKhilonjijaCategories();
      }

      final response = await client
          .from(_categoriesTable)
          .select('*')
          .order('parent_id')
          .order('sort_order', ascending: true);

      final categories = List<Map<String, dynamic>>.from(response);
      return _buildCategoryHierarchy(categories);
    } catch (error) {
      debugPrint('❌ Get categories hierarchy failed: $error');
      return _getKhilonjijaCategories();
    }
  }

  /// Get category by ID
  Future<Map<String, dynamic>?> getCategoryById(String categoryId) async {
    try {
      final client = _client;
      if (client == null) {
        return _getKhilonjijaCategories()
            .where((cat) => cat['id'] == categoryId)
            .firstOrNull;
      }

      final response = await client
          .from(_categoriesTable)
          .select('*')
          .eq('id', categoryId)
          .maybeSingle();

      return response;
    } catch (error) {
      debugPrint('❌ Get category by ID failed: $error');
      return _getKhilonjijaCategories()
          .where((cat) => cat['id'] == categoryId)
          .firstOrNull;
    }
  }

  /// Search categories by name
  Future<List<Map<String, dynamic>>> searchCategories(String query) async {
    try {
      final client = _client;
      if (client == null) {
        return _getKhilonjijaCategories()
            .where((cat) => cat['name']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      }

      final response = await client
          .from(_categoriesTable)
          .select('*')
          .ilike('name', '%$query%')
          .order('sort_order', ascending: true)
          .limit(20);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      debugPrint('❌ Search categories failed: $error');
      return _getKhilonjijaCategories()
          .where((cat) => cat['name']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    }
  }

  /// Get category by name
  Future<Map<String, dynamic>?> getCategoryByName(String name) async {
    try {
      final client = _client;
      if (client == null) {
        return _getKhilonjijaCategories()
            .where((cat) => cat['name'].toString().toLowerCase() == name.toLowerCase())
            .firstOrNull;
      }

      final response = await client
          .from(_categoriesTable)
          .select('*')
          .ilike('name', name)
          .maybeSingle();

      return response;
    } catch (error) {
      debugPrint('❌ Get category by name failed: $error');
      return _getKhilonjijaCategories()
          .where((cat) => cat['name'].toString().toLowerCase() == name.toLowerCase())
          .firstOrNull;
    }
  }

  /// Get all categories as flat list
  Future<List<Map<String, dynamic>>> getAllCategories() async {
    try {
      final client = _client;
      if (client == null) {
        return _getKhilonjijaCategories();
      }

      final response = await client
          .from(_categoriesTable)
          .select('*')
          .order('sort_order', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      debugPrint('❌ Get all categories failed: $error');
      return _getKhilonjijaCategories();
    }
  }

  /// Check if category exists
  Future<bool> categoryExists(String categoryId) async {
    try {
      final category = await getCategoryById(categoryId);
      return category != null;
    } catch (error) {
      debugPrint('❌ Check category exists failed: $error');
      return false;
    }
  }

  /// Build category hierarchy from flat list
  List<Map<String, dynamic>> _buildCategoryHierarchy(List<Map<String, dynamic>> categories) {
    final Map<String, Map<String, dynamic>> categoryMap = {};
    final List<Map<String, dynamic>> rootCategories = [];

    // Create a map for quick lookup
    for (final category in categories) {
      categoryMap[category['id']] = {
        ...category,
        'children': <Map<String, dynamic>>[],
      };
    }

    // Build hierarchy
    for (final category in categories) {
      final parentId = category['parent_id'];
      if (parentId == null) {
        rootCategories.add(categoryMap[category['id']]!);
      } else if (categoryMap.containsKey(parentId)) {
        categoryMap[parentId]!['children'].add(categoryMap[category['id']]!);
      }
    }

    return rootCategories;
  }

  /// Get khilonjiya.com specific categories - EXACTLY AS REQUESTED
  List<Map<String, dynamic>> _getKhilonjijaCategories() {
    return [
      {
        'id': '1',
        'name': 'Jobs',
        'description': 'Job listings and employment opportunities',
        'parent_id': null,
        'icon_name': 'work',
        'color_code': '#4CAF50',
        'sort_order': 1,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': '2',
        'name': 'Electronics',
        'description': 'Electronic devices, gadgets, and accessories',
        'parent_id': null,
        'icon_name': 'devices',
        'color_code': '#2196F3',
        'sort_order': 2,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': '3',
        'name': 'Furniture',
        'description': 'Home and office furniture',
        'parent_id': null,
        'icon_name': 'chair',
        'color_code': '#FF9800',
        'sort_order': 3,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': '4',
        'name': 'Properties',
        'description': 'Real estate properties for sale and rent',
        'parent_id': null,
        'icon_name': 'home',
        'color_code': '#9C27B0',
        'sort_order': 4,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': '5',
        'name': 'Room for Rent',
        'description': 'Rooms available for rent',
        'parent_id': null,
        'icon_name': 'bed',
        'color_code': '#E91E63',
        'sort_order': 5,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': '6',
        'name': 'Room for PG',
        'description': 'Paying guest accommodations',
        'parent_id': null,
        'icon_name': 'people',
        'color_code': '#607D8B',
        'sort_order': 6,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      },
    ];
  }

  /// Get fallback categories (same as main categories for consistency)
  List<Map<String, dynamic>> _getFallbackCategories() {
    return _getKhilonjijaCategories();
  }

  /// Get category icons mapping
  Map<String, String> getCategoryIcons() {
    return {
      'Jobs': 'work',
      'Electronics': 'devices',
      'Furniture': 'chair',
      'Properties': 'home',
      'Room for Rent': 'bed',
      'Room for PG': 'people',
    };
  }

  /// Get category colors mapping
  Map<String, String> getCategoryColors() {
    return {
      'Jobs': '#4CAF50',
      'Electronics': '#2196F3',
      'Furniture': '#FF9800',
      'Properties': '#9C27B0',
      'Room for Rent': '#E91E63',
      'Room for PG': '#607D8B',
    };
  }
}