import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' show cos, sqrt, asin;

class JobService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchJobs({
    String? categoryId,
    String? sortBy = 'Newest',
    int offset = 0,
    int limit = 20,
    double? userLatitude,
    double? userLongitude,
    String? searchQuery,
    String? location,
    int? minSalary,
    int? maxSalary,
    String? jobType,
    String? workMode,
    int? minExperience,
    int? maxExperience,
    List<String>? skills,
  }) async {
    try {
      var query = _supabase.from('job_listings').select('*').eq('status', 'active');

      if (categoryId != null && categoryId != 'All') {
        query = query.eq('job_category', categoryId);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('job_title.ilike.%$searchQuery%,company_name.ilike.%$searchQuery%');
      }

      if (location != null && location.isNotEmpty) {
        query = query.ilike('district', '%$location%');
      }

      if (minSalary != null) {
        query = query.gte('salary_min', minSalary);
      }
      if (maxSalary != null) {
        query = query.lte('salary_max', maxSalary);
      }

      if (jobType != null && jobType != 'All') {
        query = query.eq('job_type', jobType);
      }

      if (workMode != null && workMode != 'All') {
        query = query.eq('work_mode', workMode);
      }

      if (sortBy == 'Newest') {
        query = query.order('created_at', ascending: false);
      } else if (sortBy == 'Salary (High-Low)') {
        query = query.order('salary_max', ascending: false);
      } else if (sortBy == 'Salary (Low-High)') {
        query = query.order('salary_min', ascending: true);
      }

      query = query.range(offset, offset + limit - 1);

      final response = await query;
      List<Map<String, dynamic>> jobs = List<Map<String, dynamic>>.from(response);

      if (userLatitude != null && userLongitude != null && sortBy == 'Distance') {
        for (var job in jobs) {
          if (job['latitude'] != null && job['longitude'] != null) {
            final distance = _calculateDistance(
              userLatitude,
              userLongitude,
              double.parse(job['latitude'].toString()),
              double.parse(job['longitude'].toString()),
            );
            job['distance'] = distance;
          } else {
            job['distance'] = 999999.0;
          }
        }
        jobs.sort((a, b) => (a['distance'] ?? 999999.0).compareTo(b['distance'] ?? 999999.0));
      }

      return jobs;
    } catch (e) {
      print('Error fetching jobs: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchPremiumJobs({
    String? categoryId,
    int limit = 10,
    double? userLatitude,
    double? userLongitude,
  }) async {
    try {
      var query = _supabase.from('job_listings').select('*').eq('status', 'active').eq('is_premium', true);

      if (categoryId != null && categoryId != 'All') {
        query = query.eq('job_category', categoryId);
      }

      query = query.order('created_at', ascending: false).limit(limit);

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching premium jobs: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getJobCategories() async {
    try {
      final response = await _supabase.from('job_categories_master').select('*').eq('is_active', true).order('category_name', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching job categories: $e');
      return [];
    }
  }

  Future<Set<String>> getUserSavedJobs() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};

      final response = await _supabase.from('saved_jobs').select('job_id').eq('user_id', userId);

      return Set<String>.from(
        List<Map<String, dynamic>>.from(response).map((item) => item['job_id'].toString()),
      );
    } catch (e) {
      print('Error fetching saved jobs: $e');
      return {};
    }
  }

  Future<bool> toggleSaveJob(String jobId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final existingResponse = await _supabase.from('saved_jobs').select('id').eq('user_id', userId).eq('job_id', jobId).maybeSingle();

      if (existingResponse != null) {
        await _supabase.from('saved_jobs').delete().eq('user_id', userId).eq('job_id', jobId);
        return false;
      } else {
        await _supabase.from('saved_jobs').insert({
          'user_id': userId,
          'job_id': jobId,
          'saved_at': DateTime.now().toIso8601String(),
        });
        return true;
      }
    } catch (e) {
      print('Error toggling saved job: $e');
      rethrow;
    }
  }

  Future<void> trackJobView(String jobId, {int? viewDurationSeconds}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      await _supabase.from('job_views').upsert({
        'user_id': userId,
        'job_id': jobId,
        'viewed_at': DateTime.now().toIso8601String(),
        'view_duration_seconds': viewDurationSeconds,
        'device_type': 'mobile',
      }, onConflict: 'user_id,job_id');
    } catch (e) {
      print('Error tracking job view: $e');
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 - cos((lat2 - lat1) * p) / 2 + cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }
}