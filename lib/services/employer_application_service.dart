import 'package:supabase_flutter/supabase_flutter.dart';

class EmployerApplicationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get applications for a job
  Future<List<Map<String, dynamic>>> getApplicationsForJob(String jobId) async {
    final response = await _supabase
        .from('job_applications_listings')
        .select('''
          id,
          application_status,
          applied_at,
          employer_notes,
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

  /// Update application status
  Future<void> updateApplicationStatus({
    required String applicationListingId,
    required String status,
    String? employerNotes,
  }) async {
    await _supabase
        .from('job_applications_listings')
        .update({
          'application_status': status,
          'employer_notes': employerNotes,
        })
        .eq('id', applicationListingId);
  }
}
