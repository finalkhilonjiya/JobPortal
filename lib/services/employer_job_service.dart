// lib/services/employer_job_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class EmployerJobService {
  final SupabaseClient _client = Supabase.instance.client;

  // ------------------------------------------------------------
  // EMPLOYER JOBS LIST (Dashboard + Jobs list)
  // FIX: Return real applicants_count from join table
  // ------------------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchEmployerJobs() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    // NOTE:
    // Supabase count() on nested relationship is unreliable unless FK relation is defined.
    // So we fetch jobs, then fetch counts in one query using join table.
    final jobs = await _client
        .from('job_listings')
        .select('''
          id,
          job_title,
          district,
          job_type,
          salary_min,
          salary_max,
          status,
          views_count,
          created_at
        ''')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    final jobList = List<Map<String, dynamic>>.from(jobs);

    if (jobList.isEmpty) return [];

    final jobIds = jobList.map((e) => e['id'].toString()).toList();

    // Fetch counts from job_applications_listings
    final countsRes = await _client
        .from('job_applications_listings')
        .select('listing_id')
        .inFilter('listing_id', jobIds);

    final rows = List<Map<String, dynamic>>.from(countsRes);

    final Map<String, int> countMap = {};
    for (final r in rows) {
      final id = (r['listing_id'] ?? '').toString();
      if (id.isEmpty) continue;
      countMap[id] = (countMap[id] ?? 0) + 1;
    }

    // Attach applicants_count
    return jobList.map((j) {
      final id = (j['id'] ?? '').toString();
      return {
        ...j,
        'applications_count': countMap[id] ?? 0,
      };
    }).toList();
  }

  // ------------------------------------------------------------
  // DASHBOARD STATS
  // FIX: Works even if RPC does not exist
  // ------------------------------------------------------------
  Future<Map<String, dynamic>> fetchEmployerDashboardStats() async {
    final user = _client.auth.currentUser;
    if (user == null) return {};

    // Try RPC first (if exists)
    try {
      final rpcRes = await _client.rpc(
        'rpc_employer_dashboard_stats',
        params: {'p_employer_id': user.id},
      );

      if (rpcRes != null && rpcRes is Map) {
        final m = Map<String, dynamic>.from(rpcRes);

        // Ensure keys exist
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
    } catch (_) {
      // Ignore and fallback below
    }

    // FALLBACK: Compute from tables directly (always works)

    final jobsRes = await _client
        .from('job_listings')
        .select('id,status,views_count,created_at')
        .eq('user_id', user.id);

    final jobs = List<Map<String, dynamic>>.from(jobsRes);

    final jobIds = jobs.map((e) => e['id'].toString()).toList();

    int totalViews = 0;
    int active = 0;
    int paused = 0;
    int closed = 0;
    int expired = 0;

    for (final j in jobs) {
      final s = (j['status'] ?? 'active').toString().toLowerCase();
      totalViews += _toInt(j['views_count']);

      if (s == 'active') active++;
      if (s == 'paused') paused++;
      if (s == 'closed') closed++;
      if (s == 'expired') expired++;
    }

    int totalApplicants = 0;
    int applicants24h = 0;

    if (jobIds.isNotEmpty) {
      final appsRes = await _client
          .from('job_applications_listings')
          .select('listing_id, applied_at')
          .inFilter('listing_id', jobIds);

      final apps = List<Map<String, dynamic>>.from(appsRes);
      totalApplicants = apps.length;

      final now = DateTime.now();
      for (final a in apps) {
        final d = DateTime.tryParse((a['applied_at'] ?? '').toString());
        if (d == null) continue;
        if (now.difference(d).inHours <= 24) applicants24h++;
      }
    }

    return {
      'total_jobs': jobs.length,
      'active_jobs': active,
      'paused_jobs': paused,
      'closed_jobs': closed,
      'expired_jobs': expired,
      'total_applicants': totalApplicants,
      'total_views': totalViews,
      'applicants_last_24h': applicants24h,
    };
  }

  // ------------------------------------------------------------
  // RECENT APPLICANTS (across employer jobs)
  // FIX: Filter using listing_id list (100% reliable)
  // ------------------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchRecentApplicants({
    int limit = 5,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    // Step 1: Get employer job ids
    final jobsRes = await _client
        .from('job_listings')
        .select('id')
        .eq('user_id', user.id);

    final jobs = List<Map<String, dynamic>>.from(jobsRes);
    final jobIds = jobs.map((e) => e['id'].toString()).toList();

    if (jobIds.isEmpty) return [];

    // Step 2: Fetch recent applicants
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
            job_title
          ),

          job_applications (
            id,
            user_id,
            name,
            phone,
            email,
            district,
            education,
            experience_level,
            expected_salary
          )
        ''')
        .inFilter('listing_id', jobIds)
        .order('applied_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(res);
  }

  // ------------------------------------------------------------
  // TOP JOBS (by real applicants count)
  // FIX: uses join table counts, not applications_count column
  // ------------------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchTopJobs({
    int limit = 5,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final jobsRes = await _client
        .from('job_listings')
        .select('''
          id,
          job_title,
          status,
          views_count,
          created_at
        ''')
        .eq('user_id', user.id);

    final jobs = List<Map<String, dynamic>>.from(jobsRes);
    if (jobs.isEmpty) return [];

    final jobIds = jobs.map((e) => e['id'].toString()).toList();

    final appsRes = await _client
        .from('job_applications_listings')
        .select('listing_id')
        .inFilter('listing_id', jobIds);

    final apps = List<Map<String, dynamic>>.from(appsRes);

    final Map<String, int> countMap = {};
    for (final a in apps) {
      final id = (a['listing_id'] ?? '').toString();
      if (id.isEmpty) continue;
      countMap[id] = (countMap[id] ?? 0) + 1;
    }

    // Attach applications_count and sort
    final enriched = jobs.map((j) {
      final id = (j['id'] ?? '').toString();
      return {
        ...j,
        'applications_count': countMap[id] ?? 0,
      };
    }).toList();

    enriched.sort((a, b) {
      final ac = _toInt(a['applications_count']);
      final bc = _toInt(b['applications_count']);
      return bc.compareTo(ac);
    });

    return enriched.take(limit).toList();
  }

  // ------------------------------------------------------------
  // UTILS
  // ------------------------------------------------------------
  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}