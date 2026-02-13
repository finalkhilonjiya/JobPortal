import 'package:supabase_flutter/supabase_flutter.dart';

class EmployerApplicationsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get applications for a job (employer view)
  Future<List<Map<String, dynamic>>> getApplicationsForJob(String jobId) async {
    final response = await _supabase
        .from('job_applications_listings')
        .select('''
          id,
          application_status,
          applied_at,
          employer_notes,
          user_id,
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
          )
        ''')
        .eq('listing_id', jobId)
        .order('applied_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Update application status (shortlist/reject/etc.)
  Future<void> updateApplicationStatus({
    required String applicationListingId,
    required String status,
    String? employerNotes,
  }) async {
    final update = <String, dynamic>{
      'application_status': status,
    };

    if (employerNotes != null) {
      update['employer_notes'] = employerNotes.trim();
    }

    await _supabase
        .from('job_applications_listings')
        .update(update)
        .eq('id', applicationListingId);
  }
}