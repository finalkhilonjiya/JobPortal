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
  // APPLICANTS (PER JOB)
  // ------------------------------------------------------------
  //
  // job_applications_listings.listing_id -> job_listings.id
  // job_applications_listings.application_id -> job_applications.id
  //
  // job_applications.user_id -> user_profiles.id
  //
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
              experience_years,
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