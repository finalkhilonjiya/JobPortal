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

  List<Map<String, dynamic>> _jobs = [];
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
      final results = await Future.wait([
        _service.fetchEmployerJobs(),
        _service.fetchEmployerDashboardStats(),
        _service.fetchRecentApplicants(limit: 6),
        _service.fetchTopJobs(limit: 6),
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
  // SAFE STATS
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

  // ------------------------------------------------------------
  // FLUENT LIGHT PALETTE (Premium)
  // ------------------------------------------------------------
  static const _bg = Color(0xFFF6F7FB);
  static const _card = Colors.white;
  static const _text = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);
  static const _line = Color(0xFFE6EAF2);
  static const _primary = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      drawer: _employerDrawer(),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: _bg,
        surfaceTintColor: _bg,
        titleSpacing: 4.w,
        title: const Text(
          'Employer Dashboard',
          style: TextStyle(
            color: _text,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _loadDashboard,
          ),
          SizedBox(width: 1.w),
        ],
        iconTheme: const IconThemeData(color: _text),
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              child: ListView(
                padding: EdgeInsets.fromLTRB(4.w, 1.h, 4.w, 12.h),
                children: [
                  _heroHeader(),
                  SizedBox(height: 2.2.h),

                  _kpiGrid(),
                  SizedBox(height: 2.2.h),

                  _jobStatusStrip(),
                  SizedBox(height: 2.4.h),

                  _sectionTitle(
                    title: "Recent Applicants",
                    subtitle: "Latest candidates across your jobs",
                  ),
                  SizedBox(height: 1.2.h),
                  _recentApplicantsSection(),
                  SizedBox(height: 2.4.h),

                  _sectionTitle(
                    title: "Top Jobs",
                    subtitle: "Jobs with most applications",
                  ),
                  SizedBox(height: 1.2.h),
                  _topJobsSection(),
                  SizedBox(height: 2.6.h),

                  _sectionTitle(
                    title: "My Job Listings",
                    subtitle: "Manage posts and view applicants",
                  ),
                  SizedBox(height: 1.2.h),

                  if (_jobs.isEmpty)
                    _emptyState()
                  else
                    ..._jobs.map(_jobCard).toList(),
                ],
              ),
            ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await Navigator.pushNamed(context, AppRoutes.createJob);
          if (res == true) await _loadDashboard();
        },
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 1.5,
        label: const Text(
          'Create Job',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        icon: const Icon(Icons.add_rounded),
      ),
    );
  }

  // ------------------------------------------------------------
  // HERO HEADER (Premium)
  // ------------------------------------------------------------
  Widget _heroHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(4.w, 2.2.h, 4.w, 2.2.h),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 18,
            offset: const Offset(0, 10),
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
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFDBEAFE)),
            ),
            child: const Icon(
              Icons.apartment_rounded,
              color: _primary,
              size: 26,
            ),
          ),
          SizedBox(width: 4.w),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome back",
                  style: TextStyle(
                    fontSize: 12.5,
                    color: _muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  "Track hiring performance in one place",
                  style: TextStyle(
                    fontSize: 15.5,
                    color: _text,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // KPI GRID
  // ------------------------------------------------------------
  Widget _kpiGrid() {
    return Column(
      children: [
        Row(
          children: [
            _kpiCard(
              title: "Total Jobs",
              value: _totalJobs.toString(),
              icon: Icons.work_outline_rounded,
              accent: const Color(0xFF0EA5E9),
            ),
            SizedBox(width: 2.6.w),
            _kpiCard(
              title: "Applicants",
              value: _totalApplicants.toString(),
              icon: Icons.people_alt_outlined,
              accent: const Color(0xFF2563EB),
            ),
          ],
        ),
        SizedBox(height: 1.4.h),
        Row(
          children: [
            _kpiCard(
              title: "Total Views",
              value: _totalViews.toString(),
              icon: Icons.visibility_outlined,
              accent: const Color(0xFF7C3AED),
            ),
            SizedBox(width: 2.6.w),
            _kpiCard(
              title: "New (24h)",
              value: _applicants24h.toString(),
              icon: Icons.bolt_rounded,
              accent: const Color(0xFFF59E0B),
            ),
          ],
        ),
      ],
    );
  }

  Widget _kpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accent,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _line),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.025),
              blurRadius: 14,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accent.withOpacity(0.18)),
              ),
              child: Icon(icon, color: accent, size: 20),
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
                      color: _muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _text,
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
  // JOB STATUS STRIP (Clean)
  // ------------------------------------------------------------
  Widget _jobStatusStrip() {
    return Container(
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 2.h),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Job Status",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _text,
            ),
          ),
          SizedBox(height: 1.4.h),
          Row(
            children: [
              _statusMini("Active", _activeJobs, const Color(0xFF16A34A)),
              SizedBox(width: 2.w),
              _statusMini("Paused", _pausedJobs, const Color(0xFFF59E0B)),
              SizedBox(width: 2.w),
              _statusMini("Closed", _closedJobs, const Color(0xFFEF4444)),
              SizedBox(width: 2.w),
              _statusMini("Expired", _expiredJobs, const Color(0xFF64748B)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusMini(String label, int value, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withOpacity(0.16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: _text.withOpacity(0.75),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // SECTION TITLE
  // ------------------------------------------------------------
  Widget _sectionTitle({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: _text,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12.6,
            color: _muted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // RECENT APPLICANTS
  // ------------------------------------------------------------
  Widget _recentApplicantsSection() {
    if (_recentApplicants.isEmpty) {
      return _softEmptyCard(
        icon: Icons.people_alt_outlined,
        title: "No applicants yet",
        subtitle: "When someone applies, they will appear here.",
      );
    }

    return Container(
      padding: EdgeInsets.fromLTRB(4.w, 1.2.h, 4.w, 1.2.h),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < _recentApplicants.length; i++) ...[
            _recentApplicantTile(_recentApplicants[i]),
            if (i != _recentApplicants.length - 1)
              Divider(height: 18, color: Colors.black.withOpacity(0.06)),
          ],
        ],
      ),
    );
  }

  Widget _recentApplicantTile(Map<String, dynamic> row) {
    final listing = (row['job_listings'] ?? {}) as Map;
    final app = (row['job_applications'] ?? {}) as Map;

    final listingId = (row['listing_id'] ?? '').toString();
    final status = (row['application_status'] ?? 'applied').toString();
    final appliedAt = row['applied_at'];

    final name = (app['name'] ?? 'Candidate').toString();
    final jobTitle = (listing['job_title'] ?? 'Job').toString();

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () async {
        await Navigator.pushNamed(
          context,
          AppRoutes.jobApplicants,
          arguments: listingId,
        );
        await _loadDashboard();
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 1.2.h),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _line),
              ),
              child: const Icon(Icons.person_outline_rounded, color: _text),
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
                      fontWeight: FontWeight.w800,
                      color: _text,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "$jobTitle • ${_timeAgo(appliedAt)}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: _muted,
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
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // TOP JOBS
  // ------------------------------------------------------------
  Widget _topJobsSection() {
    if (_topJobs.isEmpty) {
      return _softEmptyCard(
        icon: Icons.work_outline_rounded,
        title: "No performance yet",
        subtitle: "Once applicants come in, top jobs will show here.",
      );
    }

    return Container(
      padding: EdgeInsets.fromLTRB(4.w, 1.2.h, 4.w, 1.2.h),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < _topJobs.length; i++) ...[
            _topJobTile(_topJobs[i]),
            if (i != _topJobs.length - 1)
              Divider(height: 18, color: Colors.black.withOpacity(0.06)),
          ],
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
      borderRadius: BorderRadius.circular(18),
      onTap: () async {
        await Navigator.pushNamed(
          context,
          AppRoutes.jobApplicants,
          arguments: jobId,
        );
        await _loadDashboard();
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 1.2.h),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDBEAFE)),
              ),
              child: const Icon(
                Icons.work_outline_rounded,
                color: _primary,
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
                      fontWeight: FontWeight.w800,
                      color: _text,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "$apps applicants • $views views",
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: _muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _jobStatusChip(status),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // JOB LISTINGS
  // ------------------------------------------------------------
  Widget _jobCard(Map<String, dynamic> job) {
    final jobId = (job['id'] ?? '').toString();
    final title = (job['job_title'] ?? '').toString();
    final status = (job['status'] ?? 'active').toString();
    final applicationsCount = _toInt(job['applications_count']);

    final district = (job['district'] ?? '').toString();
    final salaryMin = job['salary_min'];
    final salaryMax = job['salary_max'];

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // title + status
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15.8,
                    fontWeight: FontWeight.w800,
                    color: _text,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              _jobStatusChip(status),
            ],
          ),

          SizedBox(height: 0.8.h),

          Text(
            district.isEmpty ? "Location not set" : district,
            style: const TextStyle(
              fontSize: 12.6,
              color: _muted,
              fontWeight: FontWeight.w700,
            ),
          ),

          SizedBox(height: 1.2.h),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _tinyPill(
                icon: Icons.currency_rupee_rounded,
                text: "${salaryMin ?? "-"} - ${salaryMax ?? "-"}",
              ),
              _tinyPill(
                icon: Icons.people_alt_outlined,
                text: "$applicationsCount applicants",
              ),
            ],
          ),

          SizedBox(height: 1.6.h),
          Divider(color: Colors.black.withOpacity(0.06), height: 1),
          SizedBox(height: 1.4.h),

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
                    "Applicants",
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Edit job coming next")),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text(
                    "Edit",
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _text,
                    side: const BorderSide(color: _line),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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

  Widget _tinyPill({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF334155)),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  Widget _jobStatusChip(String status) {
    final s = status.toLowerCase();

    Color bg;
    Color fg;
    String label;

    if (s == 'active') {
      bg = const Color(0xFFECFDF5);
      fg = const Color(0xFF166534);
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
        border: Border.all(color: fg.withOpacity(0.10)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
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
        color: _card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _line),
            ),
            child: Icon(icon, color: _text),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: _muted,
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
    return _softEmptyCard(
      icon: Icons.work_outline_rounded,
      title: "No jobs posted yet",
      subtitle: "Create your first job to start receiving applications.",
    );
  }

  // ------------------------------------------------------------
  // DRAWER (Premium light)
  // ------------------------------------------------------------
  Widget _employerDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(5.w, 2.2.h, 5.w, 2.2.h),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: _line),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFDBEAFE)),
                    ),
                    child: const Icon(Icons.apartment_rounded, color: _primary),
                  ),
                  SizedBox(width: 3.5.w),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Employer",
                          style: TextStyle(
                            color: _text,
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          "Manage jobs and applicants",
                          style: TextStyle(
                            color: _muted,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
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
                      final res = await Navigator.pushNamed(
                        context,
                        AppRoutes.createJob,
                      );
                      if (res == true) await _loadDashboard();
                    },
                  ),
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                    child: Divider(color: Colors.black.withOpacity(0.06)),
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
            Padding(
              padding: EdgeInsets.fromLTRB(4.w, 1.h, 4.w, 2.2.h),
              child: Column(
                children: const [
                  Text(
                    "Made in Assam",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF475569),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "© Khilonjiya",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF94A3B8),
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

  Widget _drawerTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final iconColor = isDestructive ? const Color(0xFFEF4444) : _text;
    final textColor = isDestructive ? const Color(0xFFEF4444) : _text;

    return ListTile(
      dense: true,
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
      ),
      onTap: onTap,
    );
  }

  // ------------------------------------------------------------
  // UTILS
  // ------------------------------------------------------------
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