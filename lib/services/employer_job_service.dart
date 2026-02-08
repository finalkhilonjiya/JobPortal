// lib/services/employer_job_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class EmployerJobService {
  final SupabaseClient _client = Supabase.instance.client;

  // ------------------------------------------------------------
  // EMPLOYER JOBS LIST (for dashboard + job list)
  // ------------------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchEmployerJobs() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final res = await _client
        .from('job_listings')
        .select('''
          id,
          job_title,
          district,
          job_type,
          salary_min,
          salary_max,
          status,
          applications_count,
          views_count,
          created_at
        ''')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(res);
  }

  // ------------------------------------------------------------
  // DASHBOARD STATS
  // Requires RPC:
  // rpc_employer_dashboard_stats(p_employer_id uuid) returns json
  // ------------------------------------------------------------
  Future<Map<String, dynamic>> fetchEmployerDashboardStats() async {
    final user = _client.auth.currentUser;
    if (user == null) return {};

    // 1) Get stats from rpc
    final rpcRes = await _client.rpc(
      'rpc_employer_dashboard_stats',
      params: {'p_employer_id': user.id},
    );

    final stats = (rpcRes ?? {}) as Map;

    // 2) Convert to map
    final m = Map<String, dynamic>.from(stats);

    // 3) Fill missing keys safely (UI expects these)
    m.putIfAbsent('total_jobs', () => 0);
    m.putIfAbsent('active_jobs', () => 0);
    m.putIfAbsent('paused_jobs', () => 0);
    m.putIfAbsent('closed_jobs', () => 0);
    m.putIfAbsent('expired_jobs', () => 0);

    m.putIfAbsent('total_applicants', () => 0);
    m.putIfAbsent('total_views', () => 0);
    m.putIfAbsent('applicants_last_24h', () => 0);

    return m;
  }

  // ------------------------------------------------------------
  // RECENT APPLICANTS (across employer jobs)
  // Uses job_applications_listings join:
  // job_listings + job_applications
  // ------------------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchRecentApplicants({
    int limit = 5,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    // We filter employer jobs using nested filter:
    // job_listings.user_id == employer_id
    final res = await _client
        .from('job_applications_listings')
        .select('''
          id,
          listing_id,
          application_id,
          applied_at,
          application_status,

          job_listings (
            id,
            user_id,
            job_title
          ),

          job_applications (
            id,
            user_id,
            name,
            phone,
            email
          )
        ''')
        .eq('job_listings.user_id', user.id)
        .order('applied_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(res);
  }

  // ------------------------------------------------------------
  // TOP JOBS (most applications)
  // ------------------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchTopJobs({
    int limit = 5,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final res = await _client
        .from('job_listings')
        .select('''
          id,
          job_title,
          status,
          applications_count,
          views_count,
          created_at
        ''')
        .eq('user_id', user.id)
        .order('applications_count', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(res);
  }
}