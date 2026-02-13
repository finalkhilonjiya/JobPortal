import 'package:supabase_flutter/supabase_flutter.dart';

class InterviewService {
  final SupabaseClient _db = Supabase.instance.client;

  /// Employer schedules an interview (creates a row in interviews table)
  Future<void> scheduleInterview({
    required String jobApplicationListingId,
    required String companyId,
    required DateTime scheduledAt,
    int roundNumber = 1,
    String interviewType = 'video', // must match your interview_type enum
    int durationMinutes = 30,
    String? meetingLink,
    String? locationAddress,
    String? notes,
  }) async {
    final user = _db.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // 1) Create interview record
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

    // 2) Update application status (recommended)
    await _db
        .from('job_applications_listings')
        .update({'application_status': 'interviewed'}) // change later in schema
        .eq('id', jobApplicationListingId);
  }

  /// Candidate: get upcoming interviews
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
        .order('scheduled_at', ascending: true);

    return List<Map<String, dynamic>>.from(res);
  }

  /// Employer: get interviews for a company
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
              resume_file_url
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