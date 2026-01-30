// File: lib/services/job_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import '../presentation/login_screen/mobile_auth_service.dart';

class JobService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final MobileAuthService _authService = MobileAuthService();

  /* ========================= AUTH ========================= */

  Future<void> _ensureAuthenticated() async {
    final ok = await _authService.ensureValidSession();
    if (!ok ||
        _supabase.auth.currentUser == null ||
        _supabase.auth.currentSession == null) {
      throw Exception('Authentication required');
    }
  }

  /* ========================= HELPERS ========================= */

  double _toRad(double v) => v * math.pi / 180;

  double _distance(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  /* ========================= JOB FEED ========================= */

  Future<List<Map<String, dynamic>>> fetchJobs({
    String? category,
    String sortBy = 'Newest',
    int offset = 0,
    int limit = 20,
    String? location,
    String? query,
  }) async {
    await _ensureAuthenticated();

    var q = _supabase.from('job_listings').select('*').eq('status', 'active');

    if (category != null && category != 'All') {
      q = q.eq('job_category', category);
    }

    if (location != null && location.isNotEmpty) {
      q = q.ilike('district', '%$location%');
    }

    if (query != null && query.isNotEmpty) {
      q = q.or(
        'job_title.ilike.%$query%,company_name.ilike.%$query%',
      );
    }

    if (sortBy == 'Oldest') {
      q = q.order('created_at', ascending: true);
    } else {
      q = q.order('created_at', ascending: false);
    }

    final res = await q.range(offset, offset + limit - 1);
    return List<Map<String, dynamic>>.from(res);
  }

  Future<List<Map<String, dynamic>>> fetchPremiumJobs({int limit = 5}) async {
    await _ensureAuthenticated();

    final res = await _supabase
        .from('job_listings')
        .select('*')
        .eq('status', 'active')
        .eq('is_premium', true)
        .order('created_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(res);
  }

  /* ========================= SAVED JOBS ========================= */

  Future<Set<String>> getUserSavedJobs() async {
    await _ensureAuthenticated();

    final userId = _supabase.auth.currentUser!.id;

    final res = await _supabase
        .from('saved_jobs')
        .select('job_id')
        .eq('user_id', userId);

    return res.map<String>((e) => e['job_id'].toString()).toSet();
  }

  Future<bool> toggleSaveJob(String jobId) async {
    await _ensureAuthenticated();

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

  /// UI PAGE EXPECTS THIS
  Future<List<Map<String, dynamic>>> getSavedJobs() async {
    await _ensureAuthenticated();

    final userId = _supabase.auth.currentUser!.id;

    final res = await _supabase
        .from('saved_jobs')
        .select('job_listings(*)')
        .eq('user_id', userId)
        .order('saved_at', ascending: false);

    return res.map<Map<String, dynamic>>((e) => e['job_listings']).toList();
  }

  /* ========================= APPLY ========================= */

  Future<void> applyToJob({
    required String jobId,
    required String applicationId,
  }) async {
    await _ensureAuthenticated();

    final existing = await _supabase
        .from('job_applications_listings')
        .select('id')
        .eq('application_id', applicationId)
        .eq('listing_id', jobId)
        .maybeSingle();

    if (existing != null) {
      throw Exception('Already applied');
    }

    await _supabase.from('job_applications_listings').insert({
      'application_id': applicationId,
      'listing_id': jobId,
      'application_status': 'applied',
      'applied_at': DateTime.now().toIso8601String(),
    });
  }

  /// UI PAGE EXPECTS THIS
  Future<List<Map<String, dynamic>>> getMyApplications() async {
    await _ensureAuthenticated();

    final userId = _supabase.auth.currentUser!.id;

    final app = await _supabase
        .from('job_applications')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    if (app == null) return [];

    final res = await _supabase
        .from('job_applications_listings')
        .select('job_listings(*)')
        .eq('application_id', app['id'])
        .order('applied_at', ascending: false);

    return res.map<Map<String, dynamic>>((e) => e['job_listings']).toList();
  }

  /* ========================= TRACKING ========================= */

  Future<void> trackJobView(String jobId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      await _supabase.from('job_views').upsert({
        'user_id': userId,
        'job_id': jobId,
        'viewed_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,job_id');
    } catch (_) {}
  }

  /* ========================= RECOMMENDATIONS ========================= */

  Future<List<Map<String, dynamic>>> getRecommendedJobs({int limit = 50}) async {
    await _ensureAuthenticated();

    final userId = _supabase.auth.currentUser!.id;

    final profile = await _supabase
        .from('user_profiles')
        .select('preferred_locations')
        .eq('id', userId)
        .maybeSingle();

    var q = _supabase.from('job_listings').select('*').eq('status', 'active');

    if (profile != null &&
        profile['preferred_locations'] != null &&
        (profile['preferred_locations'] as List).isNotEmpty) {
      q = q.inFilter('district', profile['preferred_locations']);
    }

    final res =
        await q.order('created_at', ascending: false).limit(limit);

    return List<Map<String, dynamic>>.from(res);
  }

  Future<List<Map<String, dynamic>>> getJobsBasedOnActivity(
      {int limit = 50}) async {
    await _ensureAuthenticated();

    final userId = _supabase.auth.currentUser!.id;

    final recent = await _supabase
        .from('job_views')
        .select('job_listings(job_category)')
        .eq('user_id', userId)
        .limit(5);

    if (recent.isEmpty) return getRecommendedJobs(limit: limit);

    final cats = recent
        .map((e) => e['job_listings']['job_category'])
        .toSet()
        .toList();

    final res = await _supabase
        .from('job_listings')
        .select('*')
        .inFilter('job_category', cats)
        .eq('status', 'active')
        .limit(limit);

    return List<Map<String, dynamic>>.from(res);
  }

  /* ========================= PROFILE ========================= */

  Future<int> calculateProfileCompletion() async {
    await _ensureAuthenticated();

    final userId = _supabase.auth.currentUser!.id;
    final p = await _supabase
        .from('user_profiles')
        .select('*')
        .eq('id', userId)
        .single();

    int done = 0;
    int total = 10;

    if ((p['full_name'] ?? '').toString().isNotEmpty) done++;
    if ((p['resume_url'] ?? '').toString().isNotEmpty) done++;
    if ((p['skills'] as List?)?.isNotEmpty == true) done++;
    if ((p['preferred_locations'] as List?)?.isNotEmpty == true) done++;
    if ((p['current_job_title'] ?? '').toString().isNotEmpty) done++;
    if ((p['current_company'] ?? '').toString().isNotEmpty) done++;
    if (p['expected_salary_min'] != null) done++;
    if (p['total_experience_years'] != null) done++;
    if ((p['bio'] ?? '').toString().isNotEmpty) done++;
    if (p['notice_period_days'] != null) done++;

    final percent = ((done / total) * 100).round();

    await _supabase
        .from('user_profiles')
        .update({'profile_completion_percentage': percent})
        .eq('id', userId);

    return percent;
  }
}