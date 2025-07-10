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

  /// Get main categories (top-level categories)
  Future<List<Map<String, dynamic>>> getMainCategories() async {
    try {
      final client = _client;
      if (client == null) {
        return _getFallbackCategories();
      }

      final response = await client
          .from(_categoriesTable)
          .select('*')
          .is_('parent_id', null)
          .order('name');

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      debugPrint('❌ Get main categories failed: $error');
      return _getFallbackCategories();
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
          .order('name');

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
        return _getFallbackCategories();
      }

      final response = await client
          .from(_categoriesTable)
          .select('*')
          .order('parent_id')
          .order('name');

      final categories = List<Map<String, dynamic>>.from(response);
      return _buildCategoryHierarchy(categories);
    } catch (error) {
      debugPrint('❌ Get categories hierarchy failed: $error');
      return _getFallbackCategories();
    }
  }

  /// Get category by ID
  Future<Map<String, dynamic>?> getCategoryById(String categoryId) async {
    try {
      final client = _client;
      if (client == null) return null;

      final response = await client
          .from(_categoriesTable)
          .select('*')
          .eq('id', categoryId)
          .single();

      return response;
    } catch (error) {
      debugPrint('❌ Get category by ID failed: $error');
      return null;
    }
  }

  /// Search categories by name
  Future<List<Map<String, dynamic>>> searchCategories(String query) async {
    try {
      final client = _client;
      if (client == null) return [];

      final response = await client
          .from(_categoriesTable)
          .select('*')
          .ilike('name', '%$query%')
          .order('name')
          .limit(20);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      debugPrint('❌ Search categories failed: $error');
      return [];
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

  /// Get fallback categories when database is unavailable
  List<Map<String, dynamic>> _getFallbackCategories() {
    return [
      {'id': '1', 'name': 'Electronics', 'parent_id': null},
      {'id': '2', 'name': 'Furniture', 'parent_id': null},
      {'id': '3', 'name': 'Fashion', 'parent_id': null},
      {'id': '4', 'name': 'Sports', 'parent_id': null},
      {'id': '5', 'name': 'Automotive', 'parent_id': null},
      {'id': '6', 'name': 'Books', 'parent_id': null},
      {'id': '7', 'name': 'Home & Garden', 'parent_id': null},
      {'id': '8', 'name': 'Jobs', 'parent_id': null},
    ];
  }
}