// lib/services/employer_dashboard_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class EmployerDashboardService {
  final SupabaseClient _db = Supabase.instance.client;

  // ============================================================
  // AUTH
  // ============================================================
  User _requireUser() {
    final u = _db.auth.currentUser;
    if (u == null) throw Exception("Session expired. Please login again.");
    return u;
  }

  // ============================================================
  // ORGANIZATION RESOLUTION (CRITICAL)
  // ============================================================
  Future<String?> resolveCompanyIdSafe() async {
    final user = _requireUser();

    // 1️⃣ Try company_members
    final member = await _db
        .from('company_members')
        .select('company_id')
        .eq('user_id', user.id)
        .maybeSingle();

    if (member != null) {
      return member['company_id'].toString();
    }

    // 2️⃣ Fallback (first-time create case)
    final company = await _db
        .from('companies')
        .select('id')
        .eq('created_by', user.id)
        .maybeSingle();

    if (company != null) {
      return company['id'].toString();
    }

    return null;
  }

  // ============================================================
  // COMPANY
  // ============================================================
  Future<Map<String, dynamic>> fetchCompanyById({
    required String companyId,
  }) async {
    final res = await _db
        .from('companies')
        .select()
        .eq('id', companyId)
        .maybeSingle();

    if (res == null) return {};

    return Map<String, dynamic>.from(res);
  }

  // ============================================================
  // JOBS
  // ============================================================
  Future<List<Map<String, dynamic>>> fetchCompanyJobs({
    required String companyId,
  }) async {
    final res = await _db
        .from('job_listings')
        .select()
        .eq('company_id', companyId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(res);
  }

  // ============================================================
  // STATS
  // ============================================================
  Future<Map<String, dynamic>> fetchCompanyDashboardStats({
    required String companyId,
  }) async {
    final jobs = await _db
        .from('job_listings')
        .select('status, applications_count, views_count')
        .eq('company_id', companyId);

    int active = 0;
    int applicants = 0;
    int views = 0;

    for (final j in jobs) {
      if (j['status'] == 'active') active++;
      applicants += (j['applications_count'] ?? 0) as int;
      views += (j['views_count'] ?? 0) as int;
    }

    return {
      "active_jobs": active,
      "total_applicants": applicants,
      "total_views": views,
    };
  }

  // ============================================================
  // RECENT APPLICANTS
  // ============================================================
  Future<List<Map<String, dynamic>>> fetchRecentApplicants({
    required String companyId,
    int limit = 6,
  }) async {
    final res = await _db
        .from('job_applications_listings')
        .select('''
          application_status,
          applied_at,
          job_listings (
            id,
            job_title,
            company_id
          ),
          job_applications (
            name
          )
        ''')
        .eq('job_listings.company_id', companyId)
        .order('applied_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(res);
  }

  // ============================================================
  // TOP JOBS
  // ============================================================
  Future<List<Map<String, dynamic>>> fetchTopJobs({
    required String companyId,
    int limit = 6,
  }) async {
    final res = await _db
        .from('job_listings')
        .select()
        .eq('company_id', companyId)
        .order('applications_count', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(res);
  }

  // ============================================================
  // TODAY INTERVIEWS
  // ============================================================
  Future<List<Map<String, dynamic>>> fetchTodayInterviews({
    required String companyId,
    int limit = 10,
  }) async {
    final today = DateTime.now();

    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));

    final res = await _db
        .from('interviews')
        .select('''
          scheduled_at,
          interview_type,
          duration_minutes,
          meeting_link,
          location_address,
          job_application_listing_id,
          job_applications_listings (
            job_listings (job_title),
            job_applications (name)
          )
        ''')
        .eq('company_id', companyId)
        .gte('scheduled_at', start.toIso8601String())
        .lt('scheduled_at', end.toIso8601String())
        .limit(limit);

    return List<Map<String, dynamic>>.from(res);
  }

  // ============================================================
  // PERFORMANCE
  // ============================================================
  Future<Map<String, dynamic>> fetchLast7DaysPerformance({
    required String companyId,
  }) async {
    final res = await _db
        .from('job_listings')
        .select('views_count, applications_count')
        .eq('company_id', companyId);

    int totalViews = 0;
    int totalApps = 0;

    for (final j in res) {
      totalViews += (j['views_count'] ?? 0) as int;
      totalApps += (j['applications_count'] ?? 0) as int;
    }

    return {
      "total_views": totalViews,
      "total_applications": totalApps,
      "days": [],
    };
  }

  // ============================================================
  // NOTIFICATIONS
  // ============================================================
  Future<int> fetchUnreadNotificationsCount() async {
    final user = _requireUser();

    final res = await _db
        .from('notifications')
        .select('id')
        .eq('user_id', user.id)
        .eq('is_read', false);

    return List<Map<String, dynamic>>.from(res).length;
  }

  // ============================================================
  // CREATE ORGANIZATION (FINAL SAFE VERSION)
  // ============================================================
  Future<String> createOrganization({
    required String name,
    required String businessTypeId,
    required String districtId,
    String website = '',
    String description = '',
  }) async {
    final user = _requireUser();

    // Prevent duplicate org
    final existing = await _db
        .from('company_members')
        .select('company_id')
        .eq('user_id', user.id)
        .maybeSingle();

    if (existing != null) {
      return existing['company_id'];
    }

    final distRow = await _db
        .from('assam_districts_master')
        .select('district_name')
        .eq('id', districtId)
        .maybeSingle();

    if (distRow == null) throw Exception("Invalid district");

    final inserted = await _db
        .from('companies')
        .insert({
          'name': name,
          'business_type_id': businessTypeId,
          'headquarters_city': distRow['district_name'],
          'headquarters_state': 'Assam',
          'website': website,
          'description': description,
          'created_by': user.id,
          'owner_id': user.id,
        })
        .select('id')
        .single();

    final companyId = inserted['id'];

    // ✅ role = member (as you requested)
    await _db.from('company_members').upsert({
      'company_id': companyId,
      'user_id': user.id,
      'role': 'member',
      'status': 'active',
    }, onConflict: 'user_id');

    return companyId;
  }
}