import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../routes/app_routes.dart';
import '../../login_screen/mobile_auth_service.dart';
import '../../../services/employer_job_service.dart';

class CompanyDashboard extends StatefulWidget {
  const CompanyDashboard({Key? key}) : super(key: key);

  @override
  State<CompanyDashboard> createState() => _CompanyDashboardState();
}

class _CompanyDashboardState extends State<CompanyDashboard> {
  final EmployerJobService _service = EmployerJobService();

  bool _loading = true;

  // Existing
  List<Map<String, dynamic>> _jobs = [];

  // New dashboard data
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _recentApplicants = [];
  List<Map<String, dynamic>> _topJobs = [];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      // Load all in parallel
      final results = await Future.wait([
        _service.fetchEmployerJobs(),
        _service.fetchEmployerDashboardStats(),
        _service.fetchRecentApplicants(limit: 5),
        _service.fetchTopJobs(limit: 5),
      ]);

      _jobs = List<Map<String, dynamic>>.from(results[0] as List);
      _stats = Map<String, dynamic>.from(results[1] as Map);
      _recentApplicants = List<Map<String, dynamic>>.from(results[2] as List);
      _topJobs = List<Map<String, dynamic>>.from(results[3] as List);
    } catch (_) {
      _jobs = [];
      _stats = {};
      _recentApplicants = [];
      _topJobs = [];
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  // ------------------------------------------------------------
  // LOGOUT
  // ------------------------------------------------------------
  Future<void> _logout() async {
    await MobileAuthService().logout();
    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.roleSelection,
      (_) => false,
    );
  }

  // ------------------------------------------------------------
  // FALLBACK STATS (SAFE)
  // ------------------------------------------------------------
  int _s(String key) => _toInt(_stats[key]);

  int get _totalJobs => _s('total_jobs');
  int get _activeJobs => _s('active_jobs');
  int get _pausedJobs => _s('paused_jobs');
  int get _closedJobs => _s('closed_jobs');
  int get _expiredJobs => _s('expired_jobs');

  int get _totalApplicants => _s('total_applicants');
  int get _totalViews => _s('total_views');
  int get _applicants24h => _s('applicants_last_24h');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      drawer: _employerDrawer(),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        titleSpacing: 2.w,
        title: const Text(
          'Dashboard',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _loadDashboard,
          ),
          SizedBox(width: 2.w),
        ],
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              child: ListView(
                padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 3.h),
                children: [
                  _welcomeHeader(),
                  SizedBox(height: 2.2.h),

                  // NEW: Overview
                  _overviewCards(),
                  SizedBox(height: 2.2.h),

                  // Existing: Job status breakdown
                  _jobStatusBreakdown(),
                  SizedBox(height: 2.8.h),

                  // NEW: Recent applicants
                  _sectionHeader(
                    title: 'Recent Applicants',
                    subtitle: 'Latest candidates across your jobs',
                    actionLabel: null,
                    onAction: null,
                  ),
                  SizedBox(height: 1.2.h),
                  _recentApplicantsSection(),
                  SizedBox(height: 2.8.h),

                  // NEW: Top jobs
                  _sectionHeader(
                    title: 'Top Performing Jobs',
                    subtitle: 'Jobs with most applications',
                    actionLabel: null,
                    onAction: null,
                  ),
                  SizedBox(height: 1.2.h),
                  _topJobsSection(),
                  SizedBox(height: 2.8.h),

                  // Existing: jobs list
                  _sectionHeader(
                    title: 'My Job Listings',
                    subtitle: 'Manage, edit and view applicants',
                    actionLabel: null,
                    onAction: null,
                  ),
                  SizedBox(height: 1.4.h),
                  if (_jobs.isEmpty)
                    _emptyState()
                  else
                    ..._jobs.map(_jobCard).toList(),

                  SizedBox(height: 10.h),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await Navigator.pushNamed(context, AppRoutes.createJob);
          if (res == true) await _loadDashboard();
        },
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 2,
        label: const Text(
          'Create Job',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        icon: const Icon(Icons.add_rounded),
      ),
    );
  }

  // ------------------------------------------------------------
  // HEADER
  // ------------------------------------------------------------
  Widget _welcomeHeader() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7EAF0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDBEAFE)),
            ),
            child: const Icon(
              Icons.business_center_rounded,
              color: Color(0xFF2563EB),
              size: 26,
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Employer Dashboard',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Track performance and manage hiring',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: const Icon(Icons.menu_rounded),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // NEW: OVERVIEW CARDS
  // ------------------------------------------------------------
  Widget _overviewCards() {
    return Column(
      children: [
        Row(
          children: [
            _metricCard(
              title: 'Total Jobs',
              value: _totalJobs.toString(),
              icon: Icons.work_outline_rounded,
              bg: const Color(0xFFF1F5F9),
              fg: const Color(0xFF0F172A),
            ),
            SizedBox(width: 2.6.w),
            _metricCard(
              title: 'Applicants',
              value: _totalApplicants.toString(),
              icon: Icons.people_alt_outlined,
              bg: const Color(0xFFEFF6FF),
              fg: const Color(0xFF1D4ED8),
            ),
          ],
        ),
        SizedBox(height: 1.4.h),
        Row(
          children: [
            _metricCard(
              title: 'Total Views',
              value: _totalViews.toString(),
              icon: Icons.visibility_outlined,
              bg: const Color(0xFFECFDF5),
              fg: const Color(0xFF166534),
            ),
            SizedBox(width: 2.6.w),
            _metricCard(
              title: 'New (24h)',
              value: _applicants24h.toString(),
              icon: Icons.bolt_rounded,
              bg: const Color(0xFFFFFBEB),
              fg: const Color(0xFF7C2D12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color bg,
    required Color fg,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE7EAF0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black.withOpacity(0.04)),
              ),
              child: Icon(icon, color: fg, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // EXISTING STYLE: JOB STATUS BREAKDOWN
  // ------------------------------------------------------------
  Widget _jobStatusBreakdown() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7EAF0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Job Status',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
          SizedBox(height: 1.6.h),
          Row(
            children: [
              _statPill(
                title: 'Active',
                value: _activeJobs.toString(),
                bg: const Color(0xFFECFDF5),
                fg: const Color(0xFF14532D),
              ),
              SizedBox(width: 2.w),
              _statPill(
                title: 'Paused',
                value: _pausedJobs.toString(),
                bg: const Color(0xFFFFFBEB),
                fg: const Color(0xFF7C2D12),
              ),
            ],
          ),
          SizedBox(height: 1.2.h),
          Row(
            children: [
              _statPill(
                title: 'Closed',
                value: _closedJobs.toString(),
                bg: const Color(0xFFFFF1F2),
                fg: const Color(0xFF9F1239),
              ),
              SizedBox(width: 2.w),
              _statPill(
                title: 'Expired',
                value: _expiredJobs.toString(),
                bg: const Color(0xFFF1F5F9),
                fg: const Color(0xFF475569),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statPill({
    required String title,
    required String value,
    required Color bg,
    required Color fg,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: fg.withOpacity(0.70),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: fg,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.circle,
              color: fg.withOpacity(0.35),
              size: 10,
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // SECTION HEADER
  // ------------------------------------------------------------
  Widget _sectionHeader({
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12.8,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
      ],
    );
  }

  // ------------------------------------------------------------
  // NEW: RECENT APPLICANTS SECTION
  // ------------------------------------------------------------
  Widget _recentApplicantsSection() {
    if (_recentApplicants.isEmpty) {
      return _softEmptyCard(
        icon: Icons.people_alt_outlined,
        title: 'No applicants yet',
        subtitle: 'When someone applies, they will appear here.',
      );
    }

    return Container(
      padding: EdgeInsets.all(3.6.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7EAF0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          ..._recentApplicants.map((a) => _applicantTile(a)).toList(),
        ],
      ),
    );
  }

  Widget _applicantTile(Map<String, dynamic> row) {
    final listing = (row['job_listings'] ?? {}) as Map;
    final app = (row['job_applications'] ?? {}) as Map;

    final listingId = (row['listing_id'] ?? '').toString();
    final status = (row['application_status'] ?? 'applied').toString();
    final appliedAt = row['applied_at'];

    final name = (app['name'] ?? 'Candidate').toString();
    final jobTitle = (listing['job_title'] ?? 'Job').toString();

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        // Go to job applicants page
        await Navigator.pushNamed(
          context,
          AppRoutes.jobApplicants,
          arguments: listingId,
        );
        await _loadDashboard();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE7EAF0)),
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$jobTitle • ${_timeAgo(appliedAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _applicationStatusChip(status),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Widget _applicationStatusChip(String status) {
    final s = status.toLowerCase();

    Color bg = const Color(0xFFEFF6FF);
    Color fg = const Color(0xFF1D4ED8);
    String label = 'Applied';

    if (s == 'viewed') {
      bg = const Color(0xFFF1F5F9);
      fg = const Color(0xFF334155);
      label = 'Viewed';
    } else if (s == 'shortlisted') {
      bg = const Color(0xFFECFDF5);
      fg = const Color(0xFF166534);
      label = 'Shortlisted';
    } else if (s == 'interviewed') {
      bg = const Color(0xFFFFFBEB);
      fg = const Color(0xFF7C2D12);
      label = 'Interview';
    } else if (s == 'selected') {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF14532D);
      label = 'Selected';
    } else if (s == 'rejected') {
      bg = const Color(0xFFFFF1F2);
      fg = const Color(0xFF9F1239);
      label = 'Rejected';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
          color: fg,
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // NEW: TOP JOBS SECTION
  // ------------------------------------------------------------
  Widget _topJobsSection() {
    if (_topJobs.isEmpty) {
      return _softEmptyCard(
        icon: Icons.work_outline_rounded,
        title: 'No job performance yet',
        subtitle: 'Once applicants come in, top jobs will show here.',
      );
    }

    return Container(
      padding: EdgeInsets.all(3.6.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7EAF0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          ..._topJobs.map((j) => _topJobTile(j)).toList(),
        ],
      ),
    );
  }

  Widget _topJobTile(Map<String, dynamic> job) {
    final jobId = (job['id'] ?? '').toString();
    final title = (job['job_title'] ?? '').toString();
    final apps = _toInt(job['applications_count']);
    final views = _toInt(job['views_count']);
    final status = (job['status'] ?? 'active').toString();

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        await Navigator.pushNamed(
          context,
          AppRoutes.jobApplicants,
          arguments: jobId,
        );
        await _loadDashboard();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFDBEAFE)),
              ),
              child: const Icon(
                Icons.work_outline_rounded,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$apps applicants • $views views',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _statusChip(status),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // JOBS LIST UI (EXISTING)
  // ------------------------------------------------------------
  Widget _jobCard(Map<String, dynamic> job) {
    final jobId = (job['id'] ?? '').toString();
    final title = (job['job_title'] ?? '').toString();
    final status = (job['status'] ?? 'active').toString();
    final applicationsCount = _toInt(job['applications_count']);

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7EAF0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              _statusChip(status),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Posted ${_postedAgo(job['created_at'])} • $applicationsCount applications',
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.pushNamed(
                      context,
                      AppRoutes.jobApplicants,
                      arguments: jobId,
                    );
                    await _loadDashboard();
                  },
                  icon: const Icon(Icons.people_alt_outlined, size: 18),
                  label: const Text(
                    'Applicants',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Edit Job screen coming next"),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text(
                    'Edit',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    final s = status.toLowerCase();

    Color bg;
    Color fg;
    String label;

    if (s == 'active') {
      bg = const Color(0xFFECFDF5);
      fg = const Color(0xFF14532D);
      label = 'Active';
    } else if (s == 'paused') {
      bg = const Color(0xFFFFFBEB);
      fg = const Color(0xFF7C2D12);
      label = 'Paused';
    } else if (s == 'expired') {
      bg = const Color(0xFFF1F5F9);
      fg = const Color(0xFF475569);
      label = 'Expired';
    } else {
      bg = const Color(0xFFFFF1F2);
      fg = const Color(0xFF9F1239);
      label = 'Closed';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: fg,
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // EMPTY STATES
  // ------------------------------------------------------------
  Widget _softEmptyCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7EAF0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: const Color(0xFF0F172A)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7EAF0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.work_outline_rounded,
              size: 34,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 2.2.h),
          const Text(
            'No jobs posted yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
          SizedBox(height: 1.h),
          const Text(
            'Create your first job to start receiving applications.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          SizedBox(height: 3.h),
          ElevatedButton.icon(
            onPressed: () async {
              final res = await Navigator.pushNamed(
                context,
                AppRoutes.createJob,
              );
              if (res == true) await _loadDashboard();
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'Create Job',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // DRAWER UI
  // ------------------------------------------------------------
  Widget _employerDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(5.w, 2.4.h, 5.w, 2.2.h),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0F172A),
                    Color(0xFF111827),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.18),
                      ),
                    ),
                    child: const Icon(
                      Icons.apartment_rounded,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 3.5.w),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Employer",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.2,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          "Jobs • Applicants • Hiring",
                          style: TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
            SizedBox(height: 1.2.h),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _drawerTile(
                    icon: Icons.dashboard_rounded,
                    title: "Dashboard",
                    onTap: () => Navigator.pop(context),
                  ),
                  _drawerTile(
                    icon: Icons.add_circle_outline_rounded,
                    title: "Create Job",
                    onTap: () async {
                      Navigator.pop(context);
                      final res =
                          await Navigator.pushNamed(context, AppRoutes.createJob);
                      if (res == true) await _loadDashboard();
                    },
                  ),
                  _drawerTile(
                    icon: Icons.people_alt_outlined,
                    title: "Applicants (Job wise)",
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Open any job and click Applicants"),
                        ),
                      );
                    },
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                    child: Divider(color: Colors.grey.shade200, height: 1),
                  ),
                  _drawerTile(
                    icon: Icons.logout_rounded,
                    title: "Logout",
                    isDestructive: true,
                    onTap: () async {
                      Navigator.pop(context);
                      await _logout();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final iconColor = isDestructive ? const Color(0xFFEF4444) : null;
    final textColor = isDestructive ? const Color(0xFFEF4444) : null;

    return ListTile(
      dense: true,
      leading: Icon(icon, color: iconColor ?? const Color(0xFF0F172A)),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: textColor ?? const Color(0xFF0F172A),
        ),
      ),
      onTap: onTap,
    );
  }

  // ------------------------------------------------------------
  // UTILS
  // ------------------------------------------------------------
  String _postedAgo(dynamic date) {
    if (date == null) return 'recently';

    final d = DateTime.tryParse(date.toString());
    if (d == null) return 'recently';

    final diff = DateTime.now().difference(d);

    if (diff.inHours < 24) return 'today';
    if (diff.inDays == 1) return '1 day ago';
    return '${diff.inDays} days ago';
  }

  String _timeAgo(dynamic date) {
    if (date == null) return 'recent';

    final d = DateTime.tryParse(date.toString());
    if (d == null) return 'recent';

    final diff = DateTime.now().difference(d);

    if (diff.inMinutes < 2) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return '1d ago';
    return '${diff.inDays}d ago';
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}