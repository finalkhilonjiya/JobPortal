import 'package:flutter/foundation.dart';
import './supabase_service.dart';

class CategoryService {
  static final CategoryService _instance = CategoryService._internal();
  factory CategoryService() => _instance;
  CategoryService._internal();

  /// Get all active categories
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final client = SupabaseService().client;
      final response = await client
          .from('categories')
          .select('*')
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      debugPrint('✅ Fetched ${response.length} categories');
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      debugPrint('❌ Failed to fetch categories: $error');
      throw Exception('Failed to fetch categories: $error');
    }
  }

  /// Get main categories (no parent)
  Future<List<Map<String, dynamic>>> getMainCategories() async {
    try {
      final client = SupabaseService().client;
      final response = await client
          .from('categories')
          .select('*')
          .eq('is_active', true)
          .isFilter('parent_category_id', null)
          .order('sort_order', ascending: true);

      debugPrint('✅ Fetched ${response.length} main categories');
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      debugPrint('❌ Failed to fetch main categories: $error');
      throw Exception('Failed to fetch main categories: $error');
    }
  }

  /// Get subcategories by parent category
  Future<List<Map<String, dynamic>>> getSubcategories(
      String parentCategoryId) async {
    try {
      final client = SupabaseService().client;
      final response = await client
          .from('categories')
          .select('*')
          .eq('is_active', true)
          .eq('parent_category_id', parentCategoryId)
          .order('sort_order', ascending: true);

      debugPrint(
          '✅ Fetched ${response.length} subcategories for parent: $parentCategoryId');
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      debugPrint('❌ Failed to fetch subcategories: $error');
      throw Exception('Failed to fetch subcategories: $error');
    }
  }

  /// Get category by ID
  Future<Map<String, dynamic>?> getCategoryById(String categoryId) async {
    try {
      final client = SupabaseService().client;
      final response = await client
          .from('categories')
          .select('*')
          .eq('id', categoryId)
          .single();

      debugPrint('✅ Fetched category: $categoryId');
      return response;
    } catch (error) {
      debugPrint('❌ Failed to fetch category: $error');
      throw Exception('Failed to fetch category: $error');
    }
  }

  /// Get categories with listing counts
  Future<List<Map<String, dynamic>>> getCategoriesWithCounts() async {
    try {
      final client = SupabaseService().client;

      // Get categories with listing counts using a join
      final response = await client.rpc('get_categories_with_counts');

      debugPrint('✅ Fetched categories with listing counts');
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      // Fallback to simple category fetch if RPC doesn't exist
      debugPrint('⚠️ RPC not available, fetching categories without counts');
      return await getCategories();
    }
  }

  /// Search categories
  Future<List<Map<String, dynamic>>> searchCategories(String query) async {
    try {
      final client = SupabaseService().client;
      final response = await client
          .from('categories')
          .select('*')
          .eq('is_active', true)
          .ilike('name', '%$query%')
          .order('sort_order', ascending: true);

      debugPrint(
          '✅ Search found ${response.length} categories for query: $query');
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      debugPrint('❌ Failed to search categories: $error');
      throw Exception('Failed to search categories: $error');
    }
  }

  /// Get category hierarchy (category with its parent and children)
  Future<Map<String, dynamic>> getCategoryHierarchy(String categoryId) async {
    try {
      final client = SupabaseService().client;

      // Get the category with its parent
      final category = await client.from('categories').select('''
            *,
            parent:categories!parent_category_id(*)
          ''').eq('id', categoryId).single();

      // Get children categories
      final children = await client
          .from('categories')
          .select('*')
          .eq('parent_category_id', categoryId)
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      final result = {
        ...category,
        'children': children,
      };

      debugPrint('✅ Fetched category hierarchy for: $categoryId');
      return result;
    } catch (error) {
      debugPrint('❌ Failed to fetch category hierarchy: $error');
      throw Exception('Failed to fetch category hierarchy: $error');
    }
  }

  /// Get popular categories (based on listing count)
  Future<List<Map<String, dynamic>>> getPopularCategories(
      {int limit = 6}) async {
    try {
      final client = SupabaseService().client;

      // This would ideally use a database function, but for now we'll do a simple query
      final response = await client
          .from('categories')
          .select('*')
          .eq('is_active', true)
          .order('sort_order', ascending: true)
          .limit(limit);

      debugPrint('✅ Fetched ${response.length} popular categories');
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      debugPrint('❌ Failed to fetch popular categories: $error');
      throw Exception('Failed to fetch popular categories: $error');
    }
  }
}
