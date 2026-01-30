import 'package:supabase_flutter/supabase_flutter.dart';

class InterviewService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Employer schedules interview
  Future<void> scheduleInterview({
    required String applicationListingId,
    required DateTime interviewDate,
    String? employerNotes,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _supabase
        .from('job_applications_listings')
        .update({
          'interview_date': interviewDate.toIso8601String(),
          'employer_notes': employerNotes,
          'application_status': 'interviewed',
        })
        .eq('id', applicationListingId);
  }

  /// Candidate: get upcoming interviews
  Future<List<Map<String, dynamic>>> getMyInterviews() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final response = await _supabase
        .from('job_applications_listings')
        .select('''
          id,
          interview_date,
          employer_notes,
          application_status,
          job_listings (
            job_title,
            company_name,
            district
          )
        ''')
        .eq('user_id', user.id)
        .not('interview_date', 'is', null)
        .order('interview_date', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }
}
