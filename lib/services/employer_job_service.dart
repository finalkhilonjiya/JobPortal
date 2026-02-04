import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/supabase_service.dart';

/// Handles all Employer Job CRUD operations
class EmployerJobService {
  final SupabaseClient _client = SupabaseService().client;

  /// CREATE A NEW JOB
  Future<void> createJob({
    required String jobTitle,
    required String companyName,
    required String location,
    required String experience,
    required String salaryMin,
    required String salaryMax,
    required String description,
    required List<String> skills,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final response = await _client.from('job_listings').insert({
      'job_title': jobTitle,
      'company_name': companyName,
      'district': location,
      'experience_required': experience,
      'salary_min': int.tryParse(salaryMin),
      'salary_max': int.tryParse(salaryMax),
      'job_description': description,
      'skills_required': skills,
      'employer_id': user.id,
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    });

    if (response.error != null) {
      throw Exception(response.error!.message);
    }
  }

  /// FETCH JOBS POSTED BY LOGGED-IN EMPLOYER
  Future<List<Map<String, dynamic>>> fetchEmployerJobs() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final res = await _client
        .from('job_listings')
        .select('*')
        .eq('employer_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(res);
  }

  /// DELETE A JOB
  Future<void> deleteJob(String jobId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    await _client
        .from('job_listings')
        .delete()
        .eq('id', jobId)
        .eq('employer_id', user.id);
  }

  /// CLOSE / DEACTIVATE A JOB
  Future<void> closeJob(String jobId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    await _client
        .from('job_listings')
        .update({'status': 'closed'})
        .eq('id', jobId)
        .eq('employer_id', user.id);
  }
}