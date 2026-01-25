// File: lib/services/job_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' show cos, sqrt, asin;

class JobService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================
  // FETCH JOB LISTINGS
  // ============================================
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
      var query = _supabase
          .from('job_listings')
          .select('*')
          .eq('status', 'active');

      // Category Filter
      if (categoryId != null && categoryId != 'All') {
        query = query.eq('job_category', categoryId);
      }

      // Search Query Filter
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('job_title.ilike.%$searchQuery%,company_name.ilike.%$searchQuery%,job_description.ilike.%$searchQuery%');
      }

      // Location Filter
      if (location != null && location.isNotEmpty) {
        query = query.ilike('district', '%$location%');
      }

      // Salary Filter
      if (minSalary != null) {
        query = query.gte('salary_min', minSalary);
      }
      if (maxSalary != null) {
        query = query.lte('salary_max', maxSalary);
      }

      // Job Type Filter
      if (jobType != null && jobType != 'All') {
        query = query.eq('job_type', jobType);
      }

      // Work Mode Filter
      if (workMode != null && workMode != 'All') {
        query = query.eq('work_mode', workMode);
      }

      // Experience Filter
      if (minExperience != null) {
        query = query.or('experience_required.ilike.%$minExperience year%,experience_required.ilike.%${minExperience + 1} year%');
      }

      // Skills Filter (if skills array exists)
      if (skills != null && skills.isNotEmpty) {
        query = query.overlaps('skills_required', skills);
      }

      // Sorting
      if (sortBy == 'Newest') {
        query = query.order('created_at', ascending: false);
      } else if (sortBy == 'Salary (High-Low)') {
        query = query.order('salary_max', ascending: false);
      } else if (sortBy == 'Salary (Low-High)') {
        query = query.order('salary_min', ascending: true);
      }

      // Pagination
      query = query.range(offset, offset + limit - 1);

      final response = await query;
      List<Map<String, dynamic>> jobs = List<Map<String, dynamic>>.from(response);

      // Calculate distance if user location is provided
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

        // Sort by distance
        jobs.sort((a, b) => (a['distance'] ?? 999999.0).compareTo(b['distance'] ?? 999999.0));
      }

      return jobs;
    } catch (e) {
      print('Error fetching jobs: $e');
      rethrow;
    }
  }

  // ============================================
  // FETCH PREMIUM/FEATURED JOBS
  // ============================================
  Future<List<Map<String, dynamic>>> fetchPremiumJobs({
    String? categoryId,
    int limit = 10,
    double? userLatitude,
    double? userLongitude,
  }) async {
    try {
      var query = _supabase
          .from('job_listings')
          .select('*')
          .eq('status', 'active')
          .eq('is_premium', true)
          .order('created_at', ascending: false)
          .limit(limit);

      if (categoryId != null && categoryId != 'All') {
        query = query.eq('job_category', categoryId);
      }

      final response = await query;
      List<Map<String, dynamic>> jobs = List<Map<String, dynamic>>.from(response);

      // Calculate distance if user location provided
      if (userLatitude != null && userLongitude != null) {
        for (var job in jobs) {
          if (job['latitude'] != null && job['longitude'] != null) {
            final distance = _calculateDistance(
              userLatitude,
              userLongitude,
              double.parse(job['latitude'].toString()),
              double.parse(job['longitude'].toString()),
            );
            job['distance'] = distance;
          }
        }
      }

      return jobs;
    } catch (e) {
      print('Error fetching premium jobs: $e');
      rethrow;
    }
  }

  // ============================================
  // GET JOB CATEGORIES
  // ============================================
  Future<List<Map<String, dynamic>>> getJobCategories() async {
    try {
      final response = await _supabase
          .from('job_categories_master')
          .select('*')
          .eq('is_active', true)
          .order('category_name', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching job categories: $e');
      rethrow;
    }
  }

  // ============================================
  // GET SAVED JOBS (User's Bookmarks)
  // ============================================
  Future<Set<String>> getUserSavedJobs() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};

      final response = await _supabase
          .from('saved_jobs')
          .select('job_id')
          .eq('user_id', userId);

      return Set<String>.from(
        List<Map<String, dynamic>>.from(response).map((item) => item['job_id'].toString()),
      );
    } catch (e) {
      print('Error fetching saved jobs: $e');
      return {};
    }
  }

  // ============================================
  // TOGGLE SAVE JOB (Bookmark)
  // ============================================
  Future<bool> toggleSaveJob(String jobId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Check if already saved
      final existingResponse = await _supabase
          .from('saved_jobs')
          .select('id')
          .eq('user_id', userId)
          .eq('job_id', jobId)
          .maybeSingle();

      if (existingResponse != null) {
        // Remove from saved jobs
        await _supabase
            .from('saved_jobs')
            .delete()
            .eq('user_id', userId)
            .eq('job_id', jobId);
        return false; // Unsaved
      } else {
        // Add to saved jobs
        await _supabase.from('saved_jobs').insert({
          'user_id': userId,
          'job_id': jobId,
          'saved_at': DateTime.now().toIso8601String(),
        });
        return true; // Saved
      }
    } catch (e) {
      print('Error toggling saved job: $e');
      rethrow;
    }
  }

  // ============================================
  // TRACK JOB VIEW
  // ============================================
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

  // ============================================
  // GET RECENTLY VIEWED JOBS
  // ============================================
  Future<List<Map<String, dynamic>>> getRecentlyViewedJobs({int limit = 10}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('job_views')
          .select('job_id, viewed_at, job_listings(*)')
          .eq('user_id', userId)
          .order('viewed_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response)
          .map((item) => item['job_listings'] as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Error fetching recently viewed jobs: $e');
      return [];
    }
  }

  // ============================================
  // APPLY TO JOB
  // ============================================
  Future<void> applyToJob({
    required String jobId,
    required String applicationId,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Check if already applied
      final existingApplication = await _supabase
          .from('job_applications_listings')
          .select('id')
          .eq('application_id', applicationId)
          .eq('listing_id', jobId)
          .maybeSingle();

      if (existingApplication != null) {
        throw Exception('You have already applied to this job');
      }

      // Create application record
      await _supabase.from('job_applications_listings').insert({
        'application_id': applicationId,
        'listing_id': jobId,
        'applied_at': DateTime.now().toIso8601String(),
        'application_status': 'applied',
      });

      // Increment application count
      await _supabase.rpc('increment_application_count', params: {'job_id': jobId});
    } catch (e) {
      print('Error applying to job: $e');
      rethrow;
    }
  }

  // ============================================
  // GET USER'S APPLIED JOBS
  // ============================================
  Future<List<Map<String, dynamic>>> getUserAppliedJobs() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      // First get user's application ID
      final applicationResponse = await _supabase
          .from('job_applications')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (applicationResponse == null) return [];

      final applicationId = applicationResponse['id'];

      // Get applied jobs
      final response = await _supabase
          .from('job_applications_listings')
          .select('*, job_listings(*)')
          .eq('application_id', applicationId)
          .order('applied_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching applied jobs: $e');
      return [];
    }
  }

  // ============================================
  // GET SIMILAR JOBS (Recommendations)
  // ============================================
  Future<List<Map<String, dynamic>>> getSimilarJobs(String jobId, {int limit = 5}) async {
    try {
      // Get current job details
      final currentJob = await _supabase
          .from('job_listings')
          .select('job_category, district')
          .eq('id', jobId)
          .single();

      // Fetch similar jobs (same category or location)
      final response = await _supabase
          .from('job_listings')
          .select('*')
          .eq('status', 'active')
          .neq('id', jobId)
          .or('job_category.eq.${currentJob['job_category']},district.eq.${currentJob['district']}')
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching similar jobs: $e');
      return [];
    }
  }

  // ============================================
  // GET COMPANIES
  // ============================================
  Future<List<Map<String, dynamic>>> getCompanies({int limit = 50}) async {
    try {
      final response = await _supabase
          .from('companies')
          .select('*')
          .order('total_jobs', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching companies: $e');
      return [];
    }
  }

  // ============================================
  // GET COMPANY JOBS
  // ============================================
  Future<List<Map<String, dynamic>>> getCompanyJobs(String companyName) async {
    try {
      final response = await _supabase
          .from('job_listings')
          .select('*')
          .eq('status', 'active')
          .ilike('company_name', companyName)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching company jobs: $e');
      return [];
    }
  }

  // ============================================
  // SEARCH JOBS (Autocomplete)
  // ============================================
  Future<List<Map<String, dynamic>>> searchJobs(String query, {int limit = 20}) async {
    try {
      final response = await _supabase
          .from('job_listings')
          .select('job_title, company_name, district')
          .eq('status', 'active')
          .or('job_title.ilike.%$query%,company_name.ilike.%$query%')
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error searching jobs: $e');
      return [];
    }
  }

  // ============================================
  // GET SKILLS (For Autocomplete)
  // ============================================
  Future<List<String>> getSkills({String? searchQuery}) async {
    try {
      var query = _supabase
          .from('skills_master')
          .select('skill_name')
          .order('usage_count', ascending: false)
          .limit(50);

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('skill_name', '%$searchQuery%');
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response)
          .map((item) => item['skill_name'].toString())
          .toList();
    } catch (e) {
      print('Error fetching skills: $e');
      return [];
    }
  }

  // ============================================
  // CALCULATE DISTANCE (Haversine Formula)
  // ============================================
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  // ============================================
  // GET JOB STATS (For Dashboard)
  // ============================================
  Future<Map<String, dynamic>> getJobStats() async {
    try {
      final totalJobs = await _supabase
          .from('job_listings')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('status', 'active');

      final totalCompanies = await _supabase
          .from('companies')
          .select('id', const FetchOptions(count: CountOption.exact));

      return {
        'total_jobs': totalJobs.count ?? 0,
        'total_companies': totalCompanies.count ?? 0,
      };
    } catch (e) {
      print('Error fetching job stats: $e');
      return {'total_jobs': 0, 'total_companies': 0};
    }
  }
}