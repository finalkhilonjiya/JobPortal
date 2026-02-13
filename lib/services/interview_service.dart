import 'package:supabase_flutter/supabase_flutter.dart';

class InterviewService {
  final SupabaseClient _db = Supabase.instance.client;

  // ------------------------------------------------------------
  // EMPLOYER: SCHEDULE INTERVIEW
  // Uses: public.interviews
  // Updates: job_applications_listings.application_status = interview_scheduled
  // ------------------------------------------------------------
  Future<void> scheduleInterview({
    required String jobApplicationListingId,
    required String companyId,
    required DateTime scheduledAt,
    int roundNumber = 1,
    String interviewType = 'video', // must match your enum in DB
    int durationMinutes = 30,
    String? meetingLink,
    String? locationAddress,
    String? notes,
  }) async {
    final user = _db.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

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

    await _db.from('job_applications_listings').update({
      'application_status': 'interview_scheduled',
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

    await _db.from('job_applications_listings').update({
      'application_status': 'interviewed',
    }).eq('id', jobApplicationListingId);
  }

  // ------------------------------------------------------------
  // CANDIDATE: UPCOMING INTERVIEWS
  // Uses Option A join: job_listings -> companies
  // ------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getMyUpcomingInterviews() async {
    final user = _db.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

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
        .gte('scheduled_at', DateTime.now().toIso8601String())
        .eq('job_applications_listings.user_id', user.id)
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