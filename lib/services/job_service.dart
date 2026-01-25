// File: lib/services/job_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import '../presentation/login_screen/mobile_auth_service.dart';

class JobService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final MobileAuthService _authService = MobileAuthService();

  Future<void> _ensureAuthenticated() async {
    final sessionValid = await _authService.ensureValidSession();
    if (!sessionValid) {
      throw Exception('Authentication required. Please login again.');
    }
    final currentUser = _supabase.auth.currentUser;
    final currentSession = _supabase.auth.currentSession;
    if (currentUser == null || currentSession == null) {
      throw Exception('Authentication required. Please login again.');
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371;
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    double a = 
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
      math.sin(dLon / 2) * math.sin(dLon / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * math.pi / 180;
  }

  // ============================================
  // FETCH REGULAR JOBS
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
    await _ensureAuthenticated();

    try {
      var query = _supabase
          .from('job_listings')
          .select('*')
          .eq('status', 'active');

      // Category Filter
      if (categoryId != null && categoryId != 'All' && categoryId != 'All Jobs') {
        query = query.eq('job_category', categoryId);
      }

      // Search Query Filter
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or(
          'job_title.ilike.%$searchQuery%,'
          'company_name.ilike.%$searchQuery%,'
          'job_description.ilike.%$searchQuery%'
        );
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

      // Apply sorting BEFORE range
      final List<Map<String, dynamic>> response;
      if (sortBy == 'Salary (High-Low)') {
        response = await query.order('salary_max', ascending: false).range(offset, offset + limit - 1);
      } else if (sortBy == 'Salary (Low-High)') {
        response = await query.order('salary_min', ascending: true).range(offset, offset + limit - 1);
      } else if (sortBy == 'Oldest') {
        response = await query.order('created_at', ascending: true).range(offset, offset + limit - 1);
      } else {
        // Default: Newest
        response = await query.order('created_at', ascending: false).range(offset, offset + limit - 1);
      }

      var jobs = List<Map<String, dynamic>>.from(response);

      // Calculate distance if user location is provided
      if (userLatitude != null && userLongitude != null) {
        jobs = jobs.map((job) {
          if (job['latitude'] != null && job['longitude'] != null) {
            job['distance'] = _calculateDistance(
              userLatitude,
              userLongitude,
              double.parse(job['latitude'].toString()),
              double.parse(job['longitude'].toString()),
            );
          } else {
            job['distance'] = 999999.0;
          }
          return job;
        }).toList();

        // Sort by distance if requested
        if (sortBy == 'Distance') {
          jobs.sort((a, b) {
            final distA = a['distance'] ?? 999999.0;
            final distB = b['distance'] ?? 999999.0;
            return distA.compareTo(distB);
          });
        }
      }

      return jobs;
    } catch (e) {
      debugPrint('Error fetching jobs: $e');
      if (e.toString().contains('JWT') || 
          e.toString().contains('auth') || 
          e.toString().contains('401') ||
          e.toString().contains('403')) {
        throw Exception('Authentication expired. Please login again.');
      }
      return [];
    }
  }

  // ============================================
  // FETCH PREMIUM JOBS
  // ============================================
  Future<List<Map<String, dynamic>>> fetchPremiumJobs({
    String? categoryId,
    int limit = 10,
    double? userLatitude,
    double? userLongitude,
  }) async {
    await _ensureAuthenticated();

    try {
      var query = _supabase
          .from('job_listings')
          .select('*')
          .eq('status', 'active')
          .eq('is_premium', true);

      if (categoryId != null && categoryId != 'All' && categoryId != 'All Jobs') {
        query = query.eq('job_category', categoryId);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      var jobs = List<Map<String, dynamic>>.from(response);

      // Calculate distance if user location provided
      if (userLatitude != null && userLongitude != null) {
        jobs = jobs.map((job) {
          if (job['latitude'] != null && job['longitude'] != null) {
            job['distance'] = _calculateDistance(
              userLatitude,
              userLongitude,
              double.parse(job['latitude'].toString()),
              double.parse(job['longitude'].toString()),
            );
          }
          return job;
        }).toList();

        jobs.sort((a, b) {
          final distA = a['distance'] ?? 999999.0;
          final distB = b['distance'] ?? 999999.0;
          return distA.compareTo(distB);
        });
      }

      return jobs;
    } catch (e) {
      debugPrint('Error fetching premium jobs: $e');
      if (e.toString().contains('JWT') || 
          e.toString().contains('auth') || 
          e.toString().contains('401') ||
          e.toString().contains('403')) {
        throw Exception('Authentication expired. Please login again.');
      }
      return [];
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
      debugPrint('Error fetching job categories: $e');
      return [];
    }
  }

  // ============================================
  // GET SAVED JOBS
  // ============================================
  Future<Set<String>> getUserSavedJobs() async {
    await _ensureAuthenticated();
    
    try {
      final user = _supabase.auth.currentUser!;
      final response = await _supabase
          .from('saved_jobs')
          .select('job_id')
          .eq('user_id', user.id);
      
      return Set<String>.from(
        List<Map<String, dynamic>>.from(response).map((item) => item['job_id'].toString())
      );
    } catch (e) {
      debugPrint('Error fetching saved jobs: $e');
      if (e.toString().contains('JWT') || 
          e.toString().contains('auth') || 
          e.toString().contains('401') ||
          e.toString().contains('403')) {
        throw Exception('Authentication expired. Please login again.');
      }
      return {};
    }
  }

  // ============================================
  // TOGGLE SAVE JOB
  // ============================================
  Future<bool> toggleSaveJob(String jobId) async {
    await _ensureAuthenticated();
    
    try {
      final user = _supabase.auth.currentUser!;
      
      final existing = await _supabase
          .from('saved_jobs')
          .select('id')
          .eq('user_id', user.id)
          .eq('job_id', jobId)
          .maybeSingle();

      if (existing != null) {
        await _supabase
            .from('saved_jobs')
            .delete()
            .eq('user_id', user.id)
            .eq('job_id', jobId);
        return false;
      } else {
        await _supabase
            .from('saved_jobs')
            .insert({
              'user_id': user.id,
              'job_id': jobId,
              'saved_at': DateTime.now().toIso8601String(),
            });
        return true;
      }
    } catch (e) {
      debugPrint('Error toggling saved job: $e');
      if (e.toString().contains('JWT') || 
          e.toString().contains('auth') || 
          e.toString().contains('401') ||
          e.toString().contains('403')) {
        throw Exception('Authentication expired. Please login again.');
      }
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
      debugPrint('Error tracking job view: $e');
    }
  }

  // ============================================
  // GET RECENTLY VIEWED JOBS
  // ============================================
  Future<List<Map<String, dynamic>>> getRecentlyViewedJobs({int limit = 10}) async {
    await _ensureAuthenticated();
    
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
      debugPrint('Error fetching recently viewed jobs: $e');
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
    await _ensureAuthenticated();
    
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
    } catch (e) {
      debugPrint('Error applying to job: $e');
      rethrow;
    }
  }

  // ============================================
  // GET USER'S APPLIED JOBS
  // ============================================
  Future<List<Map<String, dynamic>>> getUserAppliedJobs() async {
    await _ensureAuthenticated();
    
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
      debugPrint('Error fetching applied jobs: $e');
      return [];
    }
  }

  // ============================================
  // GET SIMILAR JOBS
  // ============================================
  Future<List<Map<String, dynamic>>> getSimilarJobs(String jobId, {int limit = 5}) async {
    await _ensureAuthenticated();
    
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
      debugPrint('Error fetching similar jobs: $e');
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
      debugPrint('Error fetching companies: $e');
      return [];
    }
  }

  // ============================================
  // GET COMPANY JOBS
  // ============================================
  Future<List<Map<String, dynamic>>> getCompanyJobs(String companyName) async {
    await _ensureAuthenticated();
    
    try {
      final response = await _supabase
          .from('job_listings')
          .select('*')
          .eq('status', 'active')
          .ilike('company_name', companyName)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching company jobs: $e');
      return [];
    }
  }

  // ============================================
  // SEARCH JOBS
  // ============================================
  Future<List<Map<String, dynamic>>> searchJobs(String query, {int limit = 20}) async {
    await _ensureAuthenticated();
    
    try {
      final response = await _supabase
          .from('job_listings')
          .select('job_title, company_name, district')
          .eq('status', 'active')
          .or('job_title.ilike.%$query%,company_name.ilike.%$query%')
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error searching jobs: $e');
      return [];
    }
  }

  // ============================================
  // GET SKILLS
  // ============================================
  Future<List<String>> getSkills({String? searchQuery}) async {
    try {
      var query = _supabase
          .from('skills_master')
          .select('skill_name');

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('skill_name', '%$searchQuery%');
      }

      final response = await query
          .order('usage_count', ascending: false)
          .limit(50);

      return List<Map<String, dynamic>>.from(response)
          .map((item) => item['skill_name'].toString())
          .toList();
    } catch (e) {
      debugPrint('Error fetching skills: $e');
      return [];
    }
  }

  // ============================================
  // GET JOB STATS
  // ============================================
  Future<Map<String, dynamic>> getJobStats() async {
    try {
      final jobsResponse = await _supabase
          .from('job_listings')
          .select('id')
          .eq('status', 'active');
      
      final companiesResponse = await _supabase
          .from('companies')
          .select('id');

      return {
        'total_jobs': (jobsResponse as List).length,
        'total_companies': (companiesResponse as List).length,
      };
    } catch (e) {
      debugPrint('Error fetching job stats: $e');
      return {'total_jobs': 0, 'total_companies': 0};
    }
  }
}