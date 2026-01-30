import 'package:supabase_flutter/supabase_flutter.dart';

class EmployerDashboardService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> getDashboardStats() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final jobs = await _supabase
        .from('job_listings')
        .select('id')
        .eq('user_id', user.id);

    final jobIds = (jobs as List).map((e) => e['id']).toList();

    if (jobIds.isEmpty) {
      return {
        'total_jobs': 0,
        'total_applications': 0,
        'total_views': 0,
      };
    }

    final applications = await _supabase
        .from('job_applications_listings')
        .select('id')
        .inFilter('listing_id', jobIds);

    final views = await _supabase
        .from('job_views')
        .select('id')
        .inFilter('job_id', jobIds);

    return {
      'total_jobs': jobIds.length,
      'total_applications': (applications as List).length,
      'total_views': (views as List).length,
    };
  }

  Future<List<Map<String, dynamic>>> getJobsWithStats() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final response = await _supabase
        .from('job_listings')
        .select('''
          id,
          job_title,
          district,
          applications_count,
          views_count,
          created_at
        ''')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}
