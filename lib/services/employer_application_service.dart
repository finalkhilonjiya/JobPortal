import 'package:supabase_flutter/supabase_flutter.dart';

class EmployerApplicationsService {
  final SupabaseClient _db = Supabase.instance.client;

  static const Set<String> _allowedStatuses = {
    'applied',
    'viewed',
    'shortlisted',
    'interviewed',
    'selected',
    'rejected',
  };

  // ------------------------------------------------------------
  // EMPLOYER: GET APPLICATIONS FOR A JOB
  // Secure: only if job belongs to employer
  // ------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getApplicationsForJob(String jobId) async {
    final user = _db.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Verify ownership
    final job = await _db
        .from('job_listings')
        .select('id, employer_id, company_id')
        .eq('id', jobId)
        .maybeSingle();

    if (job == null) throw Exception('Job not found');

    final employerId = (job['employer_id'] ?? '').toString();
    if (employerId != user.id) {
      throw Exception('Not allowed: job does not belong to this employer');
    }

    final response = await _db
        .from('job_applications_listings')
        .select('''
          id,
          listing_id,
          application_id,
          application_status,
          applied_at,
          employer_notes,
          interview_date,
          user_id,

          job_applications (
            id,
            user_id,
            name,
            phone,
            email,
            district,
            education,
            experience_level,
            experience_details,
            skills,
            expected_salary,
            availability,
            resume_file_url,
            photo_file_url
          )
        ''')
        .eq('listing_id', jobId)
        .order('applied_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // ------------------------------------------------------------
  // EMPLOYER: UPDATE APPLICATION STATUS
  // Also logs application_events
  // ------------------------------------------------------------
  Future<void> updateApplicationStatus({
    required String applicationListingId,
    required String status,
    String? employerNotes,
  }) async {
    final user = _db.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final normalizedStatus = status.trim().toLowerCase();

    if (!_allowedStatuses.contains(normalizedStatus)) {
      throw Exception('Invalid status: $status');
    }

    // Fetch listing -> job -> employer check
    final listing = await _db
        .from('job_applications_listings')
        .select('''
          id,
          listing_id,
          application_status,

          job_listings (
            id,
            employer_id,
            company_id
          )
        ''')
        .eq('id', applicationListingId)
        .maybeSingle();

    if (listing == null) throw Exception('Application not found');

    final job = listing['job_listings'];
    if (job == null) throw Exception('Job not found for this application');

    final employerId = (job['employer_id'] ?? '').toString();
    if (employerId != user.id) {
      throw Exception('Not allowed');
    }

    final oldStatus = (listing['application_status'] ?? 'applied').toString();

    // Update listing
    final update = <String, dynamic>{
      'application_status': normalizedStatus,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (employerNotes != null) {
      update['employer_notes'] = employerNotes.trim();
    }

    await _db
        .from('job_applications_listings')
        .update(update)
        .eq('id', applicationListingId);

    // Log event
    await _db.from('application_events').insert({
      'job_application_listing_id': applicationListingId,
      'event_type': 'status_changed',
      'actor_user_id': user.id,
      'notes': 'Status: $oldStatus → $normalizedStatus',
    });
  }

  // ------------------------------------------------------------
  // OPTIONAL: MOVE APPLICATION TO A PIPELINE STAGE
  // (If you use company_pipeline_stages in UI)
  // ------------------------------------------------------------
  Future<void> moveToPipelineStage({
    required String applicationListingId,
    required String stageId,
  }) async {
    final user = _db.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Ensure listing belongs to employer
    final listing = await _db
        .from('job_applications_listings')
        .select('''
          id,
          listing_id,
          job_listings (
            employer_id,
            company_id
          )
        ''')
        .eq('id', applicationListingId)
        .maybeSingle();

    if (listing == null) throw Exception('Application not found');

    final job = listing['job_listings'];
    final employerId = (job?['employer_id'] ?? '').toString();
    final companyId = (job?['company_id'] ?? '').toString();

    if (employerId != user.id) throw Exception('Not allowed');

    // Ensure stage belongs to same company
    final stage = await _db
        .from('company_pipeline_stages')
        .select('id, company_id')
        .eq('id', stageId)
        .maybeSingle();

    if (stage == null) throw Exception('Stage not found');

    final stageCompanyId = (stage['company_id'] ?? '').toString();
    if (stageCompanyId != companyId) {
      throw Exception('Stage does not belong to this company');
    }

    // Insert stage history
    await _db.from('application_stage_history').insert({
      'job_application_listing_id': applicationListingId,
      'stage_id': stageId,
      'moved_by': user.id,
    });

    // Log event
    await _db.from('application_events').insert({
      'job_application_listing_id': applicationListingId,
      'event_type': 'stage_moved',
      'actor_user_id': user.id,
      'notes': 'Moved to stage_id=$stageId',
    });
  }
}