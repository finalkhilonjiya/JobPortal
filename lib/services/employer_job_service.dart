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

      // only update updated_at manually
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
  // DASHBOARD METHODS (NEW)
  // ------------------------------------------------------------

  /// Used by the new world-class dashboard UI.
  /// Returns:
  /// {
  ///   totalJobs, activeJobs, pausedJobs, closedJobs, expiredJobs,
  ///   totalApplicants, totalViews
  /// }
  Future<Map<String, dynamic>> fetchEmployerDashboardStats() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return {
        'totalJobs': 0,
        'activeJobs': 0,
        'pausedJobs': 0,
        'closedJobs': 0,
        'expiredJobs': 0,
        'totalApplicants': 0,
        'totalViews': 0,
      };
    }

    // We compute from job_listings only (fast + consistent)
    final res = await _client
        .from('job_listings')
        .select(
          'status, applications_count, views_count',
        )
        .eq('user_id', user.id);

    final rows = List<Map<String, dynamic>>.from(res);

    int totalJobs = rows.length;
    int activeJobs = 0;
    int pausedJobs = 0;
    int closedJobs = 0;
    int expiredJobs = 0;

    int totalApplicants = 0;
    int totalViews = 0;

    for (final r in rows) {
      final status = (r['status'] ?? 'active').toString().toLowerCase();

      if (status == 'active') activeJobs++;
      if (status == 'paused') pausedJobs++;
      if (status == 'closed') closedJobs++;
      if (status == 'expired') expiredJobs++;

      totalApplicants += (r['applications_count'] ?? 0) as int;
      totalViews += (r['views_count'] ?? 0) as int;
    }

    return {
      'totalJobs': totalJobs,
      'activeJobs': activeJobs,
      'pausedJobs': pausedJobs,
      'closedJobs': closedJobs,
      'expiredJobs': expiredJobs,
      'totalApplicants': totalApplicants,
      'totalViews': totalViews,
    };
  }

  /// Fetch latest applicants across all jobs (for employer)
  /// Uses job_applications_listings table (correct schema)
  Future<List<Map<String, dynamic>>> fetchRecentApplicants({
    int limit = 5,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    // Step 1: fetch employer jobs
    final jobsRes = await _client
        .from('job_listings')
        .select('id, job_title')
        .eq('user_id', user.id);

    final jobs = List<Map<String, dynamic>>.from(jobsRes);
    if (jobs.isEmpty) return [];

    final jobIds = jobs.map((e) => e['id'].toString()).toList();

    // Step 2: fetch latest applications for those job IDs
    final res = await _client
        .from('job_applications_listings')
        .select('''
          id,
          listing_id,
          applied_at,
          application_status,
          job_listings (
            id,
            job_title
          ),
          job_applications (
            id,
            name,
            phone,
            email,
            district,
            education,
            experience_level,
            skills
          )
        ''')
        .inFilter('listing_id', jobIds)
        .order('applied_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(res);
  }

  /// Fetch top jobs sorted by applications_count
  Future<List<Map<String, dynamic>>> fetchTopJobs({
    int limit = 5,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final res = await _client
        .from('job_listings')
        .select(
          'id, job_title, status, applications_count, views_count, created_at',
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
            user_profiles (
              id,
              full_name,
              mobile_number,
              email,
              district,
              address,
              gender,
              date_of_birth,
              education,
              experience_details,
              skills,
              expected_salary
            )
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
  // DEBUG HELPERS
  // ------------------------------------------------------------

  void logError(Object e) {
    debugPrint("EmployerJobService error: $e");
  }
}