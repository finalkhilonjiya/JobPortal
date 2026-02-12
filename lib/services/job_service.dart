// File: lib/services/job_service.dart
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class JobService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ------------------------------------------------------------
  // AUTH (KEEP SIMPLE)
  // ------------------------------------------------------------
  void _ensureAuthenticatedSync() {
    final user = _supabase.auth.currentUser;
    final session = _supabase.auth.currentSession;

    if (user == null || session == null) {
      throw Exception('Authentication required. Please login again.');
    }
  }

  /* ================= UTILS ================= */

  double _toRadians(double degree) => degree * math.pi / 180;

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    return earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  int _calculateMatchScore(
    Map<String, dynamic> job,
    Map<String, dynamic> profile,
  ) {
    int score = 0;

    final jobSkills = (job['skills_required'] as List?)?.cast<String>() ?? [];
    final userSkills = (profile['skills'] as List?)?.cast<String>() ?? [];

    if (jobSkills.isNotEmpty && userSkills.isNotEmpty) {
      final match = jobSkills.where((s) => userSkills.contains(s)).length;
      score += ((match / jobSkills.length) * 40).round();
    }

    if ((profile['preferred_job_types'] as List?)?.contains(job['job_type']) ==
        true) {
      score += 20;
    }

    if ((profile['preferred_locations'] as List?)?.contains(job['district']) ==
        true) {
      score += 20;
    }

    final expected = profile['expected_salary_min'];
    if (expected != null && job['salary_min'] != null) {
      if (job['salary_min'] >= expected) score += 20;
    }

    return score.clamp(0, 100);
  }

  /* ================= JOB FETCH ================= */

  Future<List<Map<String, dynamic>>> fetchJobs({
    int offset = 0,
    int limit = 20,
  }) async {
    _ensureAuthenticatedSync();

    final nowIso = DateTime.now().toIso8601String();

    final res = await _supabase
        .from('job_listings')
        .select('*')
        .eq('status', 'active')
        .gte('expires_at', nowIso)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return List<Map<String, dynamic>>.from(res);
  }

  Future<List<Map<String, dynamic>>> fetchPremiumJobs({int limit = 5}) async {
    _ensureAuthenticatedSync();

    final nowIso = DateTime.now().toIso8601String();

    final res = await _supabase
        .from('job_listings')
        .select('*')
        .eq('status', 'active')
        .eq('is_premium', true)
        .gte('expires_at', nowIso)
        .order('created_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(res);
  }

  /* ================= REQUIRED BY HOME ================= */

  /// USED IN HomeJobsFeed
  Future<List<Map<String, dynamic>>> getRecommendedJobs({
    int limit = 40,
  }) async {
    _ensureAuthenticatedSync();

    final userId = _supabase.auth.currentUser!.id;
    final nowIso = DateTime.now().toIso8601String();

    final profile = await _supabase
        .from('user_profiles')
        .select(
          'skills, preferred_job_types, preferred_locations, expected_salary_min',
        )
        .eq('id', userId)
        .maybeSingle();

    if (profile == null) {
      return fetchJobs(limit: limit);
    }

    final res = await _supabase
        .from('job_listings')
        .select('*')
        .eq('status', 'active')
        .gte('expires_at', nowIso)
        .order('created_at', ascending: false)
        .limit(limit);

    final jobs = List<Map<String, dynamic>>.from(res)
        .map((j) => {
              ...j,
              'match_score': _calculateMatchScore(j, profile),
            })
        .toList();

    jobs.sort((a, b) =>
        (b['match_score'] as int).compareTo(a['match_score'] as int));

    return jobs;
  }

  /// USED IN HomeJobsFeed
  Future<List<Map<String, dynamic>>> getJobsBasedOnActivity({
    int limit = 50,
  }) async {
    _ensureAuthenticatedSync();

    final userId = _supabase.auth.currentUser!.id;
    final nowIso = DateTime.now().toIso8601String();

    final views = await _supabase
        .from('job_views')
        .select('job_id')
        .eq('user_id', userId)
        .order('viewed_at', ascending: false)
        .limit(10);

    if (views.isEmpty) {
      return getRecommendedJobs(limit: limit);
    }

    final jobIds = views.map<String>((e) => e['job_id'].toString()).toList();

    final res = await _supabase
        .from('job_listings')
        .select('*')
        .inFilter('id', jobIds)
        .eq('status', 'active')
        .gte('expires_at', nowIso);

    return List<Map<String, dynamic>>.from(res);
  }

  /// USED IN HomeJobsFeed + JobDetailsPage
  Future<void> trackJobView(String jobId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('job_views').insert({
        'user_id': userId,
        'job_id': jobId,
        'viewed_at': DateTime.now().toIso8601String(),
        'device_type': 'mobile',
      });
    } catch (e) {
      debugPrint('trackJobView error: $e');
    }
  }

  /* ================= SAVED JOBS ================= */

  Future<Set<String>> getUserSavedJobs() async {
    _ensureAuthenticatedSync();

    final userId = _supabase.auth.currentUser!.id;

    final res =
        await _supabase.from('saved_jobs').select('job_id').eq('user_id', userId);

    return res.map<String>((e) => e['job_id'].toString()).toSet();
  }

  Future<List<Map<String, dynamic>>> getSavedJobs() async {
    _ensureAuthenticatedSync();

    final userId = _supabase.auth.currentUser!.id;

    final res = await _supabase
        .from('saved_jobs')
        .select('job_listings(*)')
        .eq('user_id', userId)
        .order('saved_at', ascending: false);

    return res.map<Map<String, dynamic>>((e) => e['job_listings']).toList();
  }

  Future<bool> toggleSaveJob(String jobId) async {
    _ensureAuthenticatedSync();

    final userId = _supabase.auth.currentUser!.id;

    final existing = await _supabase
        .from('saved_jobs')
        .select('id')
        .eq('user_id', userId)
        .eq('job_id', jobId)
        .maybeSingle();

    if (existing != null) {
      await _supabase
          .from('saved_jobs')
          .delete()
          .eq('user_id', userId)
          .eq('job_id', jobId);

      return false;
    }

    await _supabase.from('saved_jobs').insert({
      'user_id': userId,
      'job_id': jobId,
      'saved_at': DateTime.now().toIso8601String(),
    });

    return true;
  }

  /* ================= APPLY JOB ================= */

  Future<void> applyToJob({
    required String jobId,
    required String applicationId,
  }) async {
    _ensureAuthenticatedSync();

    final exists = await _supabase
        .from('job_applications_listings')
        .select('id')
        .eq('application_id', applicationId)
        .eq('listing_id', jobId)
        .maybeSingle();

    if (exists != null) {
      throw Exception('Already applied');
    }

    await _supabase.from('job_applications_listings').insert({
      'application_id': applicationId,
      'listing_id': jobId,
      'applied_at': DateTime.now().toIso8601String(),
      'application_status': 'applied',
    });
  }

  Future<List<Map<String, dynamic>>> getMyApplications() async {
    return getUserAppliedJobs();
  }

  Future<List<Map<String, dynamic>>> getUserAppliedJobs() async {
    _ensureAuthenticatedSync();

    final userId = _supabase.auth.currentUser!.id;

    final app = await _supabase
        .from('job_applications')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    if (app == null) return [];

    final res = await _supabase
        .from('job_applications_listings')
        .select('*, job_listings(*)')
        .eq('application_id', app['id'])
        .order('applied_at', ascending: false);

    return List<Map<String, dynamic>>.from(res);
  }

  /* ================= PROFILE ================= */

  Future<int> calculateProfileCompletion() async {
    _ensureAuthenticatedSync();

    final userId = _supabase.auth.currentUser!.id;

    final profile = await _supabase
        .from('user_profiles')
        .select('*')
        .eq('id', userId)
        .single();

    final filled = profile.values.where((v) => v != null).length;

    return ((filled / 20) * 100).round().clamp(0, 100);
  }

  /* ================= HOME: PROFILE + JOBS POSTED TODAY ================= */

  /// Used by ProfileAndSearchCards (UI only widget)
  /// Returns:
  /// {
  ///   profileName: String,
  ///   profileCompletion: int (0-100),
  ///   lastUpdatedText: String,
  ///   missingDetails: int
  /// }
  ///
  /// NOTE:
  /// - Experience is NOT required for missing details count (as per your instruction)
  /// - If user is not logged in, returns default safe values
  Future<Map<String, dynamic>> getHomeProfileSummary() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      return {
        "profileName": "Your Profile",
        "profileCompletion": 0,
        "lastUpdatedText": "Updated recently",
        "missingDetails": 0,
      };
    }

    try {
      final profile = await _supabase
          .from('user_profiles')
          .select(
            'full_name, profile_completion_percentage, last_profile_update, '
            'email, mobile_number, '
            'skills, highest_education, preferred_job_types, preferred_locations, '
            'expected_salary_min, expected_salary_max, '
            'current_city, current_state, is_open_to_work',
          )
          .eq('id', user.id)
          .maybeSingle();

      // Defaults
      String profileName = "Your Profile";
      int completion = 0;
      String lastUpdatedText = "Updated recently";

      if (profile != null) {
        // Name
        final fullName = (profile['full_name'] ?? '').toString().trim();
        profileName = _firstNameOrFallback(fullName);

        // Completion %
        completion =
            _toInt(profile['profile_completion_percentage']).clamp(0, 100);

        // Last updated
        final lastUpdateRaw = profile['last_profile_update']?.toString();
        lastUpdatedText = _formatLastUpdated(lastUpdateRaw);
      }

      // Missing details
      final missingDetails = await _calculateMissingDetailsCount(profile);

      return {
        "profileName": profileName,
        "profileCompletion": completion,
        "lastUpdatedText": lastUpdatedText,
        "missingDetails": missingDetails,
      };
    } catch (_) {
      return {
        "profileName": "Your Profile",
        "profileCompletion": 0,
        "lastUpdatedText": "Updated recently",
        "missingDetails": 0,
      };
    }
  }

  /// Used by ProfileAndSearchCards
  /// Returns jobs posted today count (All India, active only)
  Future<int> getJobsPostedTodayCount() async {
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final end = start.add(const Duration(days: 1));

      final startIso = start.toIso8601String();
      final endIso = end.toIso8601String();

      final res = await _supabase
          .from('job_listings')
          .select('id')
          .eq('status', 'active')
          .gte('created_at', startIso)
          .lt('created_at', endIso);

      return (res as List).length;
    } catch (_) {
      return 0;
    }
  }

  // ------------------------------------------------------------
  // PRIVATE HELPERS (HOME PROFILE SUMMARY)
  // ------------------------------------------------------------

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  String _firstNameOrFallback(String fullName) {
    if (fullName.trim().isEmpty) return "Your Profile";
    final parts = fullName.trim().split(RegExp(r"\s+"));
    if (parts.isEmpty) return "Your Profile";
    return "${parts.first}'s profile";
  }

  String _formatLastUpdated(String? iso) {
    if (iso == null || iso.trim().isEmpty) return "Updated recently";

    final d = DateTime.tryParse(iso);
    if (d == null) return "Updated recently";

    final diff = DateTime.now().difference(d);

    if (diff.inMinutes < 60) return "Updated just now";
    if (diff.inHours < 24) return "Updated today";
    if (diff.inDays == 1) return "Updated 1d ago";
    if (diff.inDays < 7) return "Updated ${diff.inDays}d ago";
    if (diff.inDays < 30) return "Updated ${(diff.inDays / 7).floor()}w ago";

    return "Updated ${(diff.inDays / 30).floor()}mo ago";
  }

  Future<int> _calculateMissingDetailsCount(Map<String, dynamic>? profile) async {
    int missing = 0;

    if (profile == null) {
      return 12;
    }

    bool isEmpty(dynamic v) {
      if (v == null) return true;
      if (v is String) return v.trim().isEmpty;
      if (v is List) return v.isEmpty;
      return false;
    }

    // REQUIRED fields
    if (isEmpty(profile['full_name'])) missing++;
    if (isEmpty(profile['email'])) missing++;
    if (isEmpty(profile['mobile_number'])) missing++;
    if (isEmpty(profile['current_city'])) missing++;
    if (isEmpty(profile['current_state'])) missing++;
    if (isEmpty(profile['highest_education'])) missing++;
    if (isEmpty(profile['skills'])) missing++;
    if (profile['expected_salary_min'] == null) missing++;
    if (profile['expected_salary_max'] == null) missing++;
    if (isEmpty(profile['preferred_locations'])) missing++;
    if (isEmpty(profile['preferred_job_types'])) missing++;
    if (profile['is_open_to_work'] != true) missing++;

    // Education requirement: at least 1 row
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      final edu = await _supabase
          .from('user_education')
          .select('id')
          .eq('user_id', userId)
          .limit(1);

      if ((edu as List).isEmpty) missing++;
    }

    return missing;
  }
}