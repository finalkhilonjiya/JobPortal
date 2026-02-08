// File: lib/services/employer_job_service.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmployerJobService {
  final SupabaseClient _client = Supabase.instance.client;

  // ------------------------------------------------------------
  // JOB LISTINGS (EMPLOYER)
  // ------------------------------------------------------------

  Future<List<Map<String, dynamic>>> fetchEmployerJobs() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final res = await _client
        .from('job_listings')
        .select(
          'id, job_title, status, created_at, updated_at, applications_count, views_count, salary_min, salary_max, district, job_type',
        )
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(res);
  }

  Future<Map<String, dynamic>?> fetchJobById(String jobId) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final res = await _client
        .from('job_listings')
        .select('*')
        .eq('id', jobId)
        .eq('user_id', user.id)
        .maybeSingle();

    if (res == null) return null;
    return Map<String, dynamic>.from(res);
  }

  Future<void> createJob(Map<String, dynamic> data) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    await _client.from('job_listings').insert({
      ...data,
      'user_id': user.id,
      'status': data['status'] ?? 'active',
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateJob({
    required String jobId,
    required Map<String, dynamic> updates,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    await _client
        .from('job_listings')
        .update({
          ...updates,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', jobId)
        .eq('user_id', user.id);
  }

  Future<void> setJobStatus({
    required String jobId,
    required String status, // active / paused / closed / expired
  }) async {
    final allowed = {'active', 'paused', 'closed', 'expired'};
    if (!allowed.contains(status)) {
      throw Exception("Invalid status");
    }

    await updateJob(jobId: jobId, updates: {'status': status});
  }

  // ------------------------------------------------------------
  // DASHBOARD: STATS
  // ------------------------------------------------------------
  //
  // This returns safe numeric stats so UI never crashes.
  //
  // ------------------------------------------------------------

  Future<Map<String, dynamic>> fetchEmployerDashboardStats() async {
    final user = _client.auth.currentUser;
    if (user == null) return {};

    // Load all jobs (minimal fields) then compute in Dart
    final jobs = await _client
        .from('job_listings')
        .select(
          'id, status, views_count, applications_count, created_at',
        )
        .eq('user_id', user.id);

    final list = List<Map<String, dynamic>>.from(jobs);

    int totalJobs = list.length;
    int activeJobs = 0;
    int pausedJobs = 0;
    int closedJobs = 0;
    int expiredJobs = 0;

    int totalViews = 0;
    int totalApplicants = 0;

    for (final j in list) {
      final s = (j['status'] ?? 'active').toString().toLowerCase();
      if (s == 'active') activeJobs++;
      if (s == 'paused') pausedJobs++;
      if (s == 'closed') closedJobs++;
      if (s == 'expired') expiredJobs++;

      totalViews += _toInt(j['views_count']);
      totalApplicants += _toInt(j['applications_count']);
    }

    // Applicants in last 24h:
    // We count rows from job_applications_listings for jobs owned by employer.
    int applicants24h = 0;

    try {
      final since = DateTime.now().subtract(const Duration(hours: 24));

      // Get employer job ids
      final ids = list.map((e) => e['id']).where((e) => e != null).toList();

      if (ids.isNotEmpty) {
        final res = await _client
            .from('job_applications_listings')
            .select('id, applied_at')
            .inFilter('listing_id', ids)
            .gte('applied_at', since.toIso8601String());

        applicants24h = List<Map<String, dynamic>>.from(res).length;
      }
    } catch (_) {
      applicants24h = 0;
    }

    return {
      'total_jobs': totalJobs,
      'active_jobs': activeJobs,
      'paused_jobs': pausedJobs,
      'closed_jobs': closedJobs,
      'expired_jobs': expiredJobs,
      'total_views': totalViews,
      'total_applicants': totalApplicants,
      'applicants_last_24h': applicants24h,
    };
  }

  // ------------------------------------------------------------
  // DASHBOARD: RECENT APPLICANTS
  // ------------------------------------------------------------
  //
  // Reads from job_applications_listings (bridge table)
  // and joins job_listings + job_applications.
  //
  // ------------------------------------------------------------

  Future<List<Map<String, dynamic>>> fetchRecentApplicants({
    int limit = 5,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    // Get employer job ids first (safe + avoids RLS join issues)
    final jobs = await _client
        .from('job_listings')
        .select('id, job_title')
        .eq('user_id', user.id);

    final jobList = List<Map<String, dynamic>>.from(jobs);
    final jobIds = jobList.map((e) => e['id']).where((e) => e != null).toList();

    if (jobIds.isEmpty) return [];

    final res = await _client
        .from('job_applications_listings')
        .select('''
          id,
          listing_id,
          application_id,
          applied_at,
          application_status,

          job_listings (
            id,
            job_title
          ),

          job_applications (
            id,
            user_id,
            full_name,
            mobile_number,
            email
          )
        ''')
        .inFilter('listing_id', jobIds)
        .order('applied_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(res);
  }

  // ------------------------------------------------------------
  // DASHBOARD: TOP JOBS
  // ------------------------------------------------------------

  Future<List<Map<String, dynamic>>> fetchTopJobs({
    int limit = 5,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final res = await _client
        .from('job_listings')
        .select(
          'id, job_title, status, applications_count, views_count',
        )
        .eq('user_id', user.id)
        .order('applications_count', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(res);
  }

  // ------------------------------------------------------------
  // APPLICANTS (PER JOB)
  // ------------------------------------------------------------

  Future<List<Map<String, dynamic>>> fetchApplicantsForJob(String jobId) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    // Ensure employer owns this job
    final job = await _client
        .from('job_listings')
        .select('id')
        .eq('id', jobId)
        .eq('user_id', user.id)
        .maybeSingle();

    if (job == null) return [];

    final res = await _client
        .from('job_applications_listings')
        .select('''
          id,
          listing_id,
          application_id,
          applied_at,
          application_status,
          employer_notes,
          interview_date,

          job_applications (
            id,
            user_id,
            created_at,
            full_name,
            mobile_number,
            email,
            district,
            address,
            gender,
            date_of_birth,
            education,
            experience_years,
            skills,
            expected_salary,
            resume_file_url,
            photo_file_url
          )
        ''')
        .eq('listing_id', jobId)
        .order('applied_at', ascending: false);

    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> updateApplicantStatus({
    required String jobApplicationListingId,
    required String status, // applied/viewed/shortlisted/interviewed/selected/rejected
    String? employerNotes,
    DateTime? interviewDate,
  }) async {
    final allowed = {
      'applied',
      'viewed',
      'shortlisted',
      'interviewed',
      'selected',
      'rejected',
    };

    if (!allowed.contains(status)) {
      throw Exception("Invalid application status");
    }

    final payload = <String, dynamic>{
      'application_status': status,
    };

    if (employerNotes != null) {
      payload['employer_notes'] = employerNotes.trim();
    }

    if (interviewDate != null) {
      payload['interview_date'] = interviewDate.toIso8601String();
    }

    await _client
        .from('job_applications_listings')
        .update(payload)
        .eq('id', jobApplicationListingId);
  }

  // ------------------------------------------------------------
  // HELPERS
  // ------------------------------------------------------------

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  void logError(Object e) {
    debugPrint("EmployerJobService error: $e");
  }
}