// File: lib/services/job_seeker_home_service.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class JobSeekerHomeService {
  final SupabaseClient _db = Supabase.instance.client;

  void _ensureAuthenticatedSync() {
    final user = _db.auth.currentUser;
    final session = _db.auth.currentSession;

    if (user == null || session == null) {
      throw Exception('Authentication required. Please login again.');
    }
  }

  // ============================================================
  // JOB FEED
  // ============================================================

  Future<List<Map<String, dynamic>>> fetchJobs({
    int offset = 0,
    int limit = 20,
  }) async {
    _ensureAuthenticatedSync();

    final nowIso = DateTime.now().toIso8601String();

    final res = await _db
        .from('job_listings')
        .select('''
          *,
          companies (
            id,
            name,
            logo_url,
            industry,
            is_verified,
            rating,
            total_reviews
          )
        ''')
        .eq('status', 'active')
        .gte('expires_at', nowIso)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return List<Map<String, dynamic>>.from(res);
  }

  Future<List<Map<String, dynamic>>> fetchPremiumJobs({int limit = 5}) async {
    _ensureAuthenticatedSync();

    final nowIso = DateTime.now().toIso8601String();

    final res = await _db
        .from('job_listings')
        .select('''
          *,
          companies (
            id,
            name,
            logo_url,
            industry,
            is_verified,
            rating,
            total_reviews
          )
        ''')
        .eq('status', 'active')
        .eq('is_premium', true)
        .gte('expires_at', nowIso)
        .order('created_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(res);
  }

  Future<List<Map<String, dynamic>>> getRecommendedJobs({
    int limit = 40,
  }) async {
    return fetchJobs(limit: limit);
  }

  Future<List<Map<String, dynamic>>> getJobsBasedOnActivity({
    int limit = 50,
  }) async {
    return getRecommendedJobs(limit: limit);
  }

  Future<void> trackJobView(String jobId) async {
    try {
      final userId = _db.auth.currentUser?.id;
      if (userId == null) return;

      await _db.from('job_views').insert({
        'user_id': userId,
        'job_id': jobId,
        'viewed_at': DateTime.now().toIso8601String(),
        'device_type': 'mobile',
      });
    } catch (e) {
      debugPrint('trackJobView error: $e');
    }
  }

  // ============================================================
  // JOBS FILTERED BY SALARY (MONTHLY)
  // ============================================================

  /// Returns jobs where:
  /// - salary_period = Monthly
  /// - salary_max >= minMonthlySalary
  /// - active + not expired
  Future<List<Map<String, dynamic>>> fetchJobsByMinSalaryMonthly({
    required int minMonthlySalary,
    int limit = 80,
  }) async {
    _ensureAuthenticatedSync();

    final nowIso = DateTime.now().toIso8601String();

    final minSalary = minMonthlySalary < 0 ? 0 : minMonthlySalary;

    final res = await _db
        .from('job_listings')
        .select('''
          *,
          companies (
            id,
            name,
            logo_url,
            industry,
            is_verified,
            rating,
            total_reviews
          )
        ''')
        .eq('status', 'active')
        .gte('expires_at', nowIso)
        .eq('salary_period', 'Monthly')
        .gte('salary_max', minSalary)
        .order('salary_max', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(res);
  }

  // ============================================================
  // SAVED JOBS
  // ============================================================

  Future<Set<String>> getUserSavedJobs() async {
    _ensureAuthenticatedSync();

    final userId = _db.auth.currentUser!.id;

    final res =
        await _db.from('saved_jobs').select('job_id').eq('user_id', userId);

    return res.map<String>((e) => e['job_id'].toString()).toSet();
  }

  Future<List<Map<String, dynamic>>> getSavedJobs() async {
    _ensureAuthenticatedSync();

    final userId = _db.auth.currentUser!.id;

    final res = await _db
        .from('saved_jobs')
        .select('job_listings(*, companies(id,name,logo_url,is_verified))')
        .eq('user_id', userId)
        .order('saved_at', ascending: false);

    return res.map<Map<String, dynamic>>((e) => e['job_listings']).toList();
  }

  Future<bool> toggleSaveJob(String jobId) async {
    _ensureAuthenticatedSync();

    final userId = _db.auth.currentUser!.id;

    final existing = await _db
        .from('saved_jobs')
        .select('id')
        .eq('user_id', userId)
        .eq('job_id', jobId)
        .maybeSingle();

    if (existing != null) {
      await _db
          .from('saved_jobs')
          .delete()
          .eq('user_id', userId)
          .eq('job_id', jobId);

      return false;
    }

    await _db.from('saved_jobs').insert({
      'user_id': userId,
      'job_id': jobId,
      'saved_at': DateTime.now().toIso8601String(),
    });

    return true;
  }

  // ============================================================
  // HOME SUMMARY
  // ============================================================

  Future<Map<String, dynamic>> getHomeProfileSummary() async {
    final user = _db.auth.currentUser;

    if (user == null) {
      return {
        "profileName": "Your Profile",
        "profileCompletion": 0,
        "lastUpdatedText": "Updated recently",
        "missingDetails": 0,
      };
    }

    try {
      final profile = await _db
          .from('user_profiles')
          .select(
            'full_name, profile_completion_percentage, last_profile_update',
          )
          .eq('id', user.id)
          .maybeSingle();

      String profileName = "Your Profile";
      int completion = 0;
      String lastUpdatedText = "Updated recently";

      if (profile != null) {
        final fullName = (profile['full_name'] ?? '').toString().trim();
        profileName = _firstNameOrFallback(fullName);

        completion =
            _toInt(profile['profile_completion_percentage']).clamp(0, 100);

        lastUpdatedText =
            _formatLastUpdated(profile['last_profile_update']?.toString());
      }

      return {
        "profileName": profileName,
        "profileCompletion": completion,
        "lastUpdatedText": lastUpdatedText,
        "missingDetails": 0,
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

  Future<int> getJobsPostedTodayCount() async {
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final end = start.add(const Duration(days: 1));

      final res = await _db
          .from('job_listings')
          .select('id')
          .eq('status', 'active')
          .gte('created_at', start.toIso8601String())
          .lt('created_at', end.toIso8601String());

      return (res as List).length;
    } catch (_) {
      return 0;
    }
  }

  // ============================================================
  // EXPECTED SALARY (PER MONTH) - USER PROFILE
  // ============================================================

  /// We use:
  /// user_profiles.expected_salary_min (monthly)
  Future<int> getExpectedSalaryPerMonth() async {
    _ensureAuthenticatedSync();

    final userId = _db.auth.currentUser!.id;

    try {
      final profile = await _db
          .from('user_profiles')
          .select('expected_salary_min')
          .eq('id', userId)
          .maybeSingle();

      if (profile == null) return 0;

      final raw = profile['expected_salary_min'];
      if (raw == null) return 0;

      if (raw is int) return raw;
      return int.tryParse(raw.toString()) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Updates:
  /// user_profiles.expected_salary_min
  /// user_profiles.expected_salary_max (auto = min + 5000)
  Future<void> updateExpectedSalaryPerMonth(int salary) async {
    _ensureAuthenticatedSync();

    final userId = _db.auth.currentUser!.id;

    final clean = salary < 0 ? 0 : salary;

    // auto max
    final max = clean + 5000;

    await _db.from('user_profiles').update({
      'expected_salary_min': clean,
      'expected_salary_max': max,
      'last_profile_update': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  // ============================================================
  // JOB APPLICATIONS
  // ============================================================

  /// Checks if the logged-in user already applied to a job
  /// Table: job_applications_listings(user_id, listing_id)
  Future<bool> hasAppliedToJob(String jobId) async {
    _ensureAuthenticatedSync();

    final userId = _db.auth.currentUser!.id;

    try {
      final res = await _db
          .from('job_applications_listings')
          .select('id')
          .eq('user_id', userId)
          .eq('listing_id', jobId)
          .maybeSingle();

      return res != null;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // TOP COMPANIES
  // ============================================================

  Future<List<Map<String, dynamic>>> fetchTopCompanies({
    int limit = 8,
  }) async {
    _ensureAuthenticatedSync();

    final res = await _db
        .from('companies')
        .select(
          'id, name, slug, logo_url, industry, company_size, rating, total_reviews, total_jobs, is_verified',
        )
        .order('rating', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(res);
  }

  // ============================================================
  // HELPERS
  // ============================================================

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
}