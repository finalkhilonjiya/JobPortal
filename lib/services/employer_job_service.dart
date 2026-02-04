import 'package:supabase_flutter/supabase_flutter.dart';

class EmployerJobService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Fetch jobs posted by employer
  Future<List<Map<String, dynamic>>> fetchEmployerJobs() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final res = await _client
        .from('job_listings')
        .select()
        .eq('created_by', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(res);
  }

  /// Create job
  Future<void> createJob(Map<String, dynamic> data) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client.from('job_listings').insert({
      ...data,
      'created_by': user.id,
    });
  }

  /// Fetch applicants for a job
  Future<List<Map<String, dynamic>>> fetchApplicants(String jobId) async {
    final res = await _client
        .from('job_applications')
        .select('''
          id,
          status,
          created_at,
          user_profiles (
            id,
            full_name,
            mobile_number,
            email
          )
        ''')
        .eq('listing_id', jobId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(res);
  }
}