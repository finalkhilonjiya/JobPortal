import 'package:supabase_flutter/supabase_flutter.dart';

class EmployerJobService {
  final _supabase = Supabase.instance.client;

  /// Get jobs posted by employer
  Future<List<Map<String, dynamic>>> getMyJobs() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final res = await _supabase
        .from('job_listings')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(res);
  }

  /// Get applicants for a job
  Future<List<Map<String, dynamic>>> getApplicants(String jobId) async {
    final res = await _supabase
        .from('job_applications_listings')
        .select('''
          id,
          application_status,
          applied_at,
          job_applications (
            id,
            name,
            phone,
            email,
            skills,
            resume_file_url,
            photo_file_url,
            experience_level
          )
        ''')
        .eq('listing_id', jobId)
        .order('applied_at', ascending: false);

    return List<Map<String, dynamic>>.from(res);
  }

  /// Update applicant status
  Future<void> updateStatus({
    required String linkId,
    required String status,
  }) async {
    await _supabase
        .from('job_applications_listings')
        .update({'application_status': status})
        .eq('id', linkId);
  }
}
