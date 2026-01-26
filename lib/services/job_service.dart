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
 // ============================================
  // GET RECOMMENDED JOBS (PROFILE-BASED)
  // ============================================
  Future<List<Map<String, dynamic>>> getRecommendedJobs({
    int limit = 43,
    int offset = 0,
  }) async {
    await _ensureAuthenticated();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      // Get user profile for matching
      final profile = await _supabase
          .from('user_profiles')
          .select('skills, preferred_job_types, preferred_locations, expected_salary_min, total_experience_years, current_city')
          .eq('id', userId)
          .maybeSingle();

      if (profile == null) {
        return await fetchJobs(limit: limit, offset: offset);
      }

      // Get jobs matching user profile
      var query = _supabase
          .from('job_listings')
          .select('*')
          .eq('status', 'active');

      // Filter by preferred locations if available
      if (profile['preferred_locations'] != null && 
          (profile['preferred_locations'] as List).isNotEmpty) {
        final locations = (profile['preferred_locations'] as List).join(',');
        query = query.in_('district', profile['preferred_locations']);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      var jobs = List<Map<String, dynamic>>.from(response);

      // Calculate match score for each job
      jobs = jobs.map((job) {
        final matchScore = _calculateMatchScore(job, profile);
        return {...job, 'match_score': matchScore};
      }).toList();

      // Sort by match score
      jobs.sort((a, b) => (b['match_score'] as int).compareTo(a['match_score'] as int));

      return jobs;
    } catch (e) {
      debugPrint('Error getting recommended jobs: $e');
      return [];
    }
  }

  // ============================================
  // GET JOBS BASED ON RECENT ACTIVITY
  // ============================================
  Future<List<Map<String, dynamic>>> getJobsBasedOnActivity({
    int limit = 75,
  }) async {
    await _ensureAuthenticated();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      // Get user's recent viewed/applied jobs
      final recentJobs = await _supabase
          .from('job_views')
          .select('job_id, job_listings(job_category, district, skills_required)')
          .eq('user_id', userId)
          .order('viewed_at', ascending: false)
          .limit(10);

      if (recentJobs.isEmpty) {
        return await getRecommendedJobs(limit: limit);
      }

      // Extract categories and locations from recent activity
      final categories = <String>{};
      final locations = <String>{};
      final skills = <String>{};

      for (var item in List<Map<String, dynamic>>.from(recentJobs)) {
        final job = item['job_listings'] as Map<String, dynamic>?;
        if (job != null) {
          if (job['job_category'] != null) categories.add(job['job_category']);
          if (job['district'] != null) locations.add(job['district']);
          if (job['skills_required'] != null) {
            skills.addAll((job['skills_required'] as List).cast<String>());
          }
        }
      }

      // Find similar jobs
      var query = _supabase
          .from('job_listings')
          .select('*')
          .eq('status', 'active');

      if (categories.isNotEmpty) {
        query = query.in_('job_category', categories.toList());
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting jobs based on activity: $e');
      return [];
    }
  }

  // ============================================
  // CALCULATE PROFILE COMPLETION
  // ============================================
  Future<int> calculateProfileCompletion() async {
    await _ensureAuthenticated();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final profile = await _supabase
          .from('user_profiles')
          .select('*')
          .eq('id', userId)
          .single();

      int completedFields = 0;
      int totalFields = 20;

      // Basic info (5 fields)
      if (profile['full_name'] != null && profile['full_name'].toString().isNotEmpty) completedFields++;
      if (profile['email'] != null && profile['email'].toString().isNotEmpty) completedFields++;
      if (profile['mobile_number'] != null && profile['mobile_number'].toString().isNotEmpty) completedFields++;
      if (profile['current_city'] != null && profile['current_city'].toString().isNotEmpty) completedFields++;
      if (profile['avatar_url'] != null && profile['avatar_url'].toString().isNotEmpty) completedFields++;

      // Work info (5 fields)
      if (profile['current_job_title'] != null && profile['current_job_title'].toString().isNotEmpty) completedFields++;
      if (profile['current_company'] != null && profile['current_company'].toString().isNotEmpty) completedFields++;
      if (profile['total_experience_years'] != null && profile['total_experience_years'] > 0) completedFields++;
      if (profile['resume_url'] != null && profile['resume_url'].toString().isNotEmpty) completedFields++;
      if (profile['resume_headline'] != null && profile['resume_headline'].toString().isNotEmpty) completedFields++;

      // Skills and preferences (5 fields)
      if (profile['skills'] != null && (profile['skills'] as List).isNotEmpty) completedFields++;
      if (profile['highest_education'] != null && profile['highest_education'].toString().isNotEmpty) completedFields++;
      if (profile['preferred_job_types'] != null && (profile['preferred_job_types'] as List).isNotEmpty) completedFields++;
      if (profile['preferred_locations'] != null && (profile['preferred_locations'] as List).isNotEmpty) completedFields++;
      if (profile['expected_salary_min'] != null) completedFields++;

      // Additional info (5 fields)
      if (profile['bio'] != null && profile['bio'].toString().isNotEmpty) completedFields++;
      if (profile['notice_period_days'] != null) completedFields++;
      if (profile['is_open_to_work'] != null) completedFields++;
      
      // Check for education records
      final education = await _supabase
          .from('user_education')
          .select('id')
          .eq('user_id', userId)
          .limit(1);
      if (education.isNotEmpty) completedFields++;

      // Check for experience records
      final experience = await _supabase
          .from('user_experience')
          .select('id')
          .eq('user_id', userId)
          .limit(1);
      if (experience.isNotEmpty) completedFields++;

      final percentage = ((completedFields / totalFields) * 100).round();

      // Update profile completion percentage
      await _supabase
          .from('user_profiles')
          .update({'profile_completion_percentage': percentage})
          .eq('id', userId);

      return percentage;
    } catch (e) {
      debugPrint('Error calculating profile completion: $e');
      return 0;
    }
  }

  // ============================================
  // CALCULATE MATCH SCORE
  // ============================================
  int _calculateMatchScore(Map<String, dynamic> job, Map<String, dynamic> profile) {
    int score = 0;

    // Skills match (40 points max)
    final jobSkills = (job['skills_required'] as List?)?.cast<String>() ?? [];
    final userSkills = (profile['skills'] as List?)?.cast<String>() ?? [];
    if (jobSkills.isNotEmpty && userSkills.isNotEmpty) {
      final matchingSkills = jobSkills.where((s) => 
        userSkills.any((us) => us.toLowerCase() == s.toLowerCase())
      ).length;
      score += ((matchingSkills / jobSkills.length) * 40).round();
    }

    // Job type match (20 points)
    final jobType = job['job_type'] as String?;
    final preferredTypes = (profile['preferred_job_types'] as List?)?.cast<String>() ?? [];
    if (jobType != null && preferredTypes.contains(jobType)) {
      score += 20;
    }

    // Location match (20 points)
    final jobLocation = job['district'] as String?;
    final preferredLocations = (profile['preferred_locations'] as List?)?.cast<String>() ?? [];
    final currentCity = profile['current_city'] as String?;
    if (jobLocation != null) {
      if (preferredLocations.contains(jobLocation)) {
        score += 20;
      } else if (currentCity != null && jobLocation.toLowerCase().contains(currentCity.toLowerCase())) {
        score += 15;
      }
    }

    // Salary match (20 points)
    final salaryMin = job['salary_min'] as int?;
    final expectedMin = profile['expected_salary_min'] as int?;
    if (salaryMin != null && expectedMin != null) {
      if (salaryMin >= expectedMin) {
        score += 20;
      } else if (salaryMin >= (expectedMin * 0.8)) {
        score += 10;
      }
    }

    return score.clamp(0, 100);
  }

  // ============================================
  // TRACK JOB ACTIVITY
  // ============================================
  Future<void> trackJobActivity(String jobId, String activityType) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('user_job_activity').insert({
        'user_id': userId,
        'job_id': jobId,
        'activity_type': activityType,
        'activity_date': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error tracking job activity: $e');
    }
  }

  // ============================================
  // GET USER PROFILE COMPLETION DATA
  // ============================================
  Future<Map<String, dynamic>> getProfileCompletionData() async {
    await _ensureAuthenticated();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {'percentage': 0, 'missing_fields': []};

      final profile = await _supabase
          .from('user_profiles')
          .select('*')
          .eq('id', userId)
          .single();

      final missingFields = <String>[];

      if (profile['full_name'] == null || profile['full_name'].toString().isEmpty) {
        missingFields.add('Full Name');
      }
      if (profile['current_job_title'] == null || profile['current_job_title'].toString().isEmpty) {
        missingFields.add('Current Job Title');
      }
      if (profile['resume_url'] == null || profile['resume_url'].toString().isEmpty) {
        missingFields.add('Resume');
      }
      if (profile['skills'] == null || (profile['skills'] as List).isEmpty) {
        missingFields.add('Skills');
      }
      if (profile['preferred_locations'] == null || (profile['preferred_locations'] as List).isEmpty) {
        missingFields.add('Preferred Locations');
      }

      final percentage = await calculateProfileCompletion();

      return {
        'percentage': percentage,
        'missing_fields': missingFields,
      };
    } catch (e) {
      debugPrint('Error getting profile completion data: $e');
      return {'percentage': 0, 'missing_fields': []};
    }
  }
}