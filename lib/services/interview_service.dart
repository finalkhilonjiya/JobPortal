import 'package:supabase_flutter/supabase_flutter.dart';

class InterviewService {
  final SupabaseClient _db = Supabase.instance.client;

  // ------------------------------------------------------------
  // EMPLOYER: SCHEDULE INTERVIEW
  // Uses: public.interviews
  // Updates: job_applications_listings.application_status = shortlisted
  // ------------------------------------------------------------
  Future<void> scheduleInterview({
    required String jobApplicationListingId,
    required String companyId,
    required DateTime scheduledAt,
    int roundNumber = 1,
    String interviewType = 'video', // must match DB enum
    int durationMinutes = 30,
    String? meetingLink,
    String? locationAddress,
    String? notes,
  }) async {
    final user = _db.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Security: confirm this listing belongs to employer + company
    final listing = await _db
        .from('job_applications_listings')
        .select('''
          id,
          listing_id,
          job_listings (
            id,
            employer_id,
            company_id
          )
        ''')
        .eq('id', jobApplicationListingId)
        .maybeSingle();

    if (listing == null) throw Exception('Application listing not found');

    final job = listing['job_listings'];
    if (job == null) throw Exception('Job not found for this application');

    final employerId = (job['employer_id'] ?? '').toString();
    final jobCompanyId = (job['company_id'] ?? '').toString();

    if (employerId != user.id) {
      throw Exception('Not allowed: job does not belong to this employer');
    }

    if (jobCompanyId != companyId) {
      throw Exception('Not allowed: company mismatch');
    }

    // Insert interview row
    await _db.from('interviews').insert({
      'job_application_listing_id': jobApplicationListingId,
      'company_id': companyId,
      'round_number': roundNumber,
      'interview_type': interviewType,
      'scheduled_at': scheduledAt.toIso8601String(),
      'duration_minutes': durationMinutes,
      'meeting_link': meetingLink,
      'location_address': locationAddress,
      'notes': notes,
      'created_by': user.id,
    });

    // IMPORTANT: status must match your DB check constraint
    await _db.from('job_applications_listings').update({
      'application_status': 'shortlisted',
    }).eq('id', jobApplicationListingId);
  }

  // ------------------------------------------------------------
  // EMPLOYER: MARK INTERVIEW COMPLETED
  // ------------------------------------------------------------
  Future<void> markInterviewCompleted({
    required String jobApplicationListingId,
  }) async {
    final user = _db.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Security check (same as above)
    final listing = await _db
        .from('job_applications_listings')
        .select('''
          id,
          job_listings (
            employer_id
          )
        ''')
        .eq('id', jobApplicationListingId)
        .maybeSingle();

    if (listing == null) throw Exception('Application listing not found');

    final job = listing['job_listings'];
    final employerId = (job?['employer_id'] ?? '').toString();

    if (employerId != user.id) {
      throw Exception('Not allowed');
    }

    await _db.from('job_applications_listings').update({
      'application_status': 'interviewed',
    }).eq('id', jobApplicationListingId);
  }

  // ------------------------------------------------------------
  // CANDIDATE: UPCOMING INTERVIEWS (RELIABLE)
  // ------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getMyUpcomingInterviews() async {
    final user = _db.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Step 1: get candidate application listing ids
    final listingRes = await _db
        .from('job_applications_listings')
        .select('id')
        .eq('user_id', user.id);

    final listings = List<Map<String, dynamic>>.from(listingRes);
    final listingIds = listings.map((e) => e['id'].toString()).toList();

    if (listingIds.isEmpty) return [];

    // Step 2: fetch interviews
    final res = await _db
        .from('interviews')
        .select('''
          id,
          scheduled_at,
          round_number,
          interview_type,
          duration_minutes,
          meeting_link,
          location_address,
          notes,

          job_applications_listings (
            id,
            user_id,
            listing_id,

            job_listings (
              id,
              job_title,
              district,
              company_id,

              companies (
                id,
                name,
                logo_url
              )
            )
          )
        ''')
        .inFilter('job_application_listing_id', listingIds)
        .gte('scheduled_at', DateTime.now().toIso8601String())
        .order('scheduled_at', ascending: true);

    return List<Map<String, dynamic>>.from(res);
  }

  // ------------------------------------------------------------
  // EMPLOYER: COMPANY INTERVIEWS
  // ------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getCompanyInterviews({
    required String companyId,
    int limit = 50,
  }) async {
    final user = _db.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Security: verify user is company member or owner
    final member = await _db
        .from('company_members')
        .select('id')
        .eq('company_id', companyId)
        .eq('user_id', user.id)
        .maybeSingle();

    final company = await _db
        .from('companies')
        .select('id, owner_id')
        .eq('id', companyId)
        .maybeSingle();

    final ownerId = (company?['owner_id'] ?? '').toString();

    if (member == null && ownerId != user.id) {
      throw Exception('Not allowed for this company');
    }

    final res = await _db
        .from('interviews')
        .select('''
          id,
          scheduled_at,
          round_number,
          interview_type,
          duration_minutes,
          meeting_link,
          location_address,
          notes,

          job_applications_listings (
            id,
            application_status,

            job_applications (
              id,
              user_id,
              name,
              phone,
              email,
              education,
              experience_level,
              skills,
              resume_file_url,
              photo_file_url
            ),

            job_listings (
              id,
              job_title
            )
          )
        ''')
        .eq('company_id', companyId)
        .order('scheduled_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(res);
  }
}