// File: lib/services/job_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import '../presentation/login_screen/mobile_auth_service.dart';

class JobService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final MobileAuthService _authService = MobileAuthService();

  /* ===================== AUTH ===================== */

  Future<void> _ensureAuthenticated() async {
    final ok = await _authService.ensureValidSession();
    if (!ok ||
        _supabase.auth.currentUser == null ||
        _supabase.auth.currentSession == null) {
      throw Exception('Authentication required');
    }
  }

  /* ===================== DISTANCE ===================== */

  double _toRad(double d) => d * math.pi / 180;

  double _distance(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  /* ===================== JOB FETCH ===================== */

  Future<List<Map<String, dynamic>>> fetchJobs({
    int limit = 20,
    int offset = 0,
  }) async {
    await _ensureAuthenticated();

    final res = await _supabase
        .from('job_listings')
        .select('*')
        .eq('status', 'active')
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

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

  /* ===================== SAVED JOBS ===================== */

  /// ✅ USED BY HOME FEED (IDs)
  Future<Set<String>> getUserSavedJobs() async {
    await _ensureAuthenticated();

    final uid = _supabase.auth.currentUser!.id;

    final res = await _supabase
        .from('saved_jobs')
        .select('job_id')
        .eq('user_id', uid);

    return res.map<String>((e) => e['job_id'].toString()).toSet();
  }

  /// ✅ REQUIRED BY SavedJobsPage (FULL JOB OBJECTS)
  Future<List<Map<String, dynamic>>> getSavedJobs() async {
    await _ensureAuthenticated();

    final uid = _supabase.auth.currentUser!.id;

    final res = await _supabase
        .from('saved_jobs')
        .select('job_listings(*)')
        .eq('user_id', uid)
        .order('saved_at', ascending: false);

    return res
        .map<Map<String, dynamic>>(
            (e) => e['job_listings'] as Map<String, dynamic>)
        .toList();
  }

  Future<bool> toggleSaveJob(String jobId) async {
    await _ensureAuthenticated();

    final uid = _supabase.auth.currentUser!.id;

    final existing = await _supabase
        .from('saved_jobs')
        .select('id')
        .eq('user_id', uid)
        .eq('job_id', jobId)
        .maybeSingle();

    if (existing != null) {
      await _supabase
          .from('saved_jobs')
          .delete()
          .eq('user_id', uid)
          .eq('job_id', jobId);
      return false;
    }

    await _supabase.from('saved_jobs').insert({
      'user_id': uid,
      'job_id': jobId,
    });
    return true;
  }

  /* ===================== APPLICATIONS ===================== */

  /// ✅ REQUIRED BY MyApplicationsPage
  Future<List<Map<String, dynamic>>> getMyApplications() async {
    await _ensureAuthenticated();

    final uid = _supabase.auth.currentUser!.id;

    final app = await _supabase
        .from('job_applications')
        .select('id')
        .eq('user_id', uid)
        .maybeSingle();

    if (app == null) return [];

    final res = await _supabase
        .from('job_applications_listings')
        .select('*, job_listings(*)')
        .eq('application_id', app['id'])
        .order('applied_at', ascending: false);

    return res
        .map<Map<String, dynamic>>(
            (e) => e['job_listings'] as Map<String, dynamic>)
        .toList();
  }

  Future<void> applyToJob({
    required String jobId,
    required String applicationId,
  }) async {
    await _ensureAuthenticated();

    final exists = await _supabase
        .from('job_applications_listings')
        .select('id')
        .eq('listing_id', jobId)
        .eq('application_id', applicationId)
        .maybeSingle();

    if (exists != null) {
      throw Exception('Already applied');
    }

    await _supabase.from('job_applications_listings').insert({
      'listing_id': jobId,
      'application_id': applicationId,
    });
  }

  /* ===================== ACTIVITY ===================== */

  Future<void> trackJobView(String jobId) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;

    await _supabase.from('job_views').upsert({
      'user_id': uid,
      'job_id': jobId,
      'viewed_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,job_id');
  }

  Future<List<Map<String, dynamic>>> getJobsBasedOnActivity() async {
    await _ensureAuthenticated();

    final uid = _supabase.auth.currentUser!.id;

    final res = await _supabase
        .from('job_views')
        .select('job_listings(*)')
        .eq('user_id', uid)
        .order('viewed_at', ascending: false)
        .limit(20);

    return res
        .map<Map<String, dynamic>>(
            (e) => e['job_listings'] as Map<String, dynamic>)
        .toList();
  }

  /* ===================== PROFILE ===================== */

  Future<int> calculateProfileCompletion() async {
    await _ensureAuthenticated();

    final uid = _supabase.auth.currentUser!.id;

    final profile = await _supabase
        .from('user_profiles')
        .select('*')
        .eq('id', uid)
        .single();

    int filled = 0;
    const total = 10;

    if ((profile['full_name'] ?? '').toString().isNotEmpty) filled++;
    if ((profile['mobile_number'] ?? '').toString().isNotEmpty) filled++;
    if ((profile['current_city'] ?? '').toString().isNotEmpty) filled++;
    if ((profile['skills'] as List?)?.isNotEmpty == true) filled++;
    if ((profile['resume_url'] ?? '').toString().isNotEmpty) filled++;
    if ((profile['highest_education'] ?? '').toString().isNotEmpty) filled++;
    if (profile['total_experience_years'] != null) filled++;

    return ((filled / total) * 100).round();
  }
}