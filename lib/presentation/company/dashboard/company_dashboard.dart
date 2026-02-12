import 'package:flutter/material.dart';

import '../../../routes/app_routes.dart';
import '../../../services/employer_job_service.dart';
import '../../../services/mobile_auth_service.dart';

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

  // Bottom nav (UI only now)
  int _bottomIndex = 0;

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
  // FIGMA UI TOKENS
  // ------------------------------------------------------------
  static const Color _bg = Color(0xFFF7F8FA);
  static const Color _card = Colors.white;
  static const Color _border = Color(0xFFE6E8EC);
  static const Color _text = Color(0xFF111827);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _primary = Color(0xFF2563EB);

  static const double _r16 = 16;
  static const double _r20 = 20;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      drawer: _newEmployerDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            Builder(
              builder: (scaffoldContext) {
                return _buildTopHeader(scaffoldContext);
              },
            ),
            if (_loading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadDashboard,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                    children: [
                      _buildCompanyProfileRow(),
                      const SizedBox(height: 14),

                      _sectionHeader(
                        title: "Quick Stats",
                        ctaText: "Refresh",
                        onTap: _loadDashboard,
                      ),
                      const SizedBox(height: 10),
                      _buildQuickStatsRow(),

                      const SizedBox(height: 18),

                      _sectionHeader(title: "Primary Actions"),
                      const SizedBox(height: 10),
                      _buildPrimaryActionsGrid(),

                      const SizedBox(height: 18),

                      _sectionHeader(
                        title: "Recent Applicants",
                        ctaText: "View all",
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.employerJobs);
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildRecentApplicantsCard(),

                      const SizedBox(height: 18),

                      _sectionHeader(
                        title: "Your Active Jobs",
                        ctaText: "View all",
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.employerJobs);
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildActiveJobsList(),

                      const SizedBox(height: 18),

                      _sectionHeader(title: "Today’s Interviews"),
                      const SizedBox(height: 10),
                      _buildInterviewsUIOnly(),

                      const SizedBox(height: 18),

                      _sectionHeader(title: "Job Performance (Last 7 days)"),
                      const SizedBox(height: 10),
                      _buildPerformanceUIOnly(),

                      const SizedBox(height: 18),

                      _sectionHeader(title: "Action Needed"),
                      const SizedBox(height: 10),
                      _buildActionNeededUIOnly(),
                    ],
                  ),
                ),
              ),
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
        elevation: 1,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          "Post a Job",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ------------------------------------------------------------
  // TOP HEADER
  // ------------------------------------------------------------
  Widget _buildTopHeader(BuildContext scaffoldContext) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Scaffold.of(scaffoldContext).openDrawer(),
            borderRadius: BorderRadius.circular(999),
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Icon(Icons.menu, size: 22, color: _text),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              "Employer Dashboard",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: _text,
                letterSpacing: -0.2,
              ),
            ),
          ),
          Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _border),
                ),
                child: const Icon(
                  Icons.notifications_none_outlined,
                  size: 22,
                  color: Color(0xFF334155),
                ),
              ),
              Positioned(
                right: 9,
                top: 9,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // COMPANY PROFILE ROW
  // ------------------------------------------------------------
  Widget _buildCompanyProfileRow() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDeco(radius: _r20),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFDBEAFE)),
            ),
            child: const Icon(Icons.apartment_rounded, color: _primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Khilonjiya Pvt Ltd",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: _text,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: _primary,
                          ),
                          SizedBox(width: 6),
                          Text(
                            "Verified",
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: _primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 16, color: _muted),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "Assam, India",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.8,
                          fontWeight: FontWeight.w700,
                          color: _muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // SECTION HEADER
  // ------------------------------------------------------------
  Widget _sectionHeader({
    required String title,
    String? ctaText,
    VoidCallback? onTap,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: _text,
              letterSpacing: -0.2,
            ),
          ),
        ),
        if (ctaText != null && onTap != null)
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Text(
                ctaText,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: _primary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ------------------------------------------------------------
  // SECTION 1: QUICK STATS
  // ------------------------------------------------------------
  Widget _buildQuickStatsRow() {
    final active = _activeJobs;
    final newApplicants = _applicants24h;
    final interviewsToday = 0;

    return SizedBox(
      height: 122,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _quickStatCard(
            icon: Icons.work_outline,
            value: active.toString(),
            label: "Active Jobs",
            trendText: "+${_safeTrend(active)}%",
            positive: true,
          ),
          const SizedBox(width: 12),
          _quickStatCard(
            icon: Icons.people_outline,
            value: newApplicants.toString(),
            label: "New Applicants",
            trendText: "+${_safeTrend(newApplicants)}%",
            positive: true,
          ),
          const SizedBox(width: 12),
          _quickStatCard(
            icon: Icons.calendar_today_outlined,
            value: interviewsToday.toString(),
            label: "Interviews Today",
            trendText: "-0%",
            positive: false,
          ),
        ],
      ),
    );
  }

  Widget _quickStatCard({
    required IconData icon,
    required String value,
    required String label,
    required String trendText,
    required bool positive,
  }) {
    final trendColor =
        positive ? const Color(0xFF16A34A) : const Color(0xFFEF4444);

    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: _cardDeco(radius: _r20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                child: Icon(icon, color: _primary, size: 20),
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(
                    positive ? Icons.trending_up : Icons.trending_down,
                    size: 14,
                    color: trendColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    trendText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: trendColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: _text,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: _muted,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // SECTION 2: PRIMARY ACTIONS
  // ------------------------------------------------------------
  Widget _buildPrimaryActionsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.65,
      children: [
        _actionTile(
          icon: Icons.add_circle_outline,
          label: "Post a Job",
          onTap: () async {
            final res = await Navigator.pushNamed(context, AppRoutes.createJob);
            if (res == true) await _loadDashboard();
          },
        ),
        _actionTile(
          icon: Icons.people_outline,
          label: "View Applicants",
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.employerJobs);
          },
        ),
        _actionTile(
          icon: Icons.work_outline,
          label: "Manage Jobs",
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.employerJobs);
          },
        ),
        _actionTile(
          icon: Icons.calendar_month_outlined,
          label: "Schedule Interview",
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Interview scheduling coming next")),
            );
          },
        ),
        _actionTile(
          icon: Icons.search,
          label: "Search Candidates",
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Candidate search coming next")),
            );
          },
        ),
        _actionTile(
          icon: Icons.flash_on_outlined,
          label: "Boost Job",
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Boost job coming next")),
            );
          },
        ),
      ],
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(_r20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _cardDeco(radius: _r20, shadow: false),
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
              child: Icon(icon, color: _primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: _text,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // SECTION 3: RECENT APPLICANTS
  // ------------------------------------------------------------
  Widget _buildRecentApplicantsCard() {
    if (_recentApplicants.isEmpty) {
      return _softEmptyCard(
        icon: Icons.people_outline,
        title: "No applicants yet",
        subtitle: "When candidates apply, they will appear here.",
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDeco(radius: _r20),
      child: Column(
        children: [
          for (int i = 0; i < _recentApplicants.length; i++) ...[
            _recentApplicantTile(_recentApplicants[i]),
            if (i != _recentApplicants.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: Color(0xFFE6E8EC)),
              ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.employerJobs);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: _text,
                backgroundColor: const Color(0xFFF8FAFC),
                side: const BorderSide(color: _border),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                "View All Applicants",
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
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

    final name = (app['full_name'] ?? 'Candidate').toString();
    final jobTitle = (listing['job_title'] ?? 'Job').toString();

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
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
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: _border),
              ),
              alignment: Alignment.center,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : "C",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: _text,
                ),
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
                      color: _text,
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
        border: Border.all(color: fg.withOpacity(0.12)),
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
  // SECTION 4: ACTIVE JOB POSTS
  // ------------------------------------------------------------
  Widget _buildActiveJobsList() {
    if (_jobs.isEmpty) {
      return _softEmptyCard(
        icon: Icons.work_outline,
        title: "No jobs posted yet",
        subtitle: "Post your first job to start receiving applications.",
      );
    }

    final activeJobs = _jobs
        .where((j) =>
            (j['status'] ?? 'active').toString().toLowerCase() == 'active')
        .toList();

    final list = activeJobs.isNotEmpty ? activeJobs : _jobs;

    return Column(
      children: list.take(4).map((job) => _activeJobCard(job)).toList(),
    );
  }

  Widget _activeJobCard(Map<String, dynamic> job) {
    final jobId = (job['id'] ?? '').toString();
    final title = (job['job_title'] ?? 'Job').toString();
    final status = (job['status'] ?? 'active').toString();

    final district = (job['district'] ?? '').toString();
    final jobType = (job['job_type'] ?? 'Full-time').toString();
    final postedAt = job['created_at'];

    final applicants = _toInt(job['applications_count']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: _cardDeco(radius: _r20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: _text,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _jobStatusChip(status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: _muted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  district.isEmpty ? "Assam" : district,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: _muted,
                  ),
                ),
              ),
              const Text(
                " • ",
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _muted,
                ),
              ),
              Text(
                jobType,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: _muted),
              const SizedBox(width: 6),
              Text(
                postedAt == null ? "Recently posted" : _timeAgo(postedAt),
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _muted,
                ),
              ),
              const Text(
                " • ",
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _muted,
                ),
              ),
              const Icon(Icons.people_outline, size: 16, color: _muted),
              const SizedBox(width: 6),
              Text(
                "$applicants applicants",
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
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
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _text,
                    backgroundColor: const Color(0xFFF8FAFC),
                    side: const BorderSide(color: _border),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Navigator.pushNamed(
                      context,
                      AppRoutes.jobApplicants,
                      arguments: jobId,
                    );
                    await _loadDashboard();
                  },
                  icon: const Icon(Icons.people_outline, size: 18),
                  label: const Text(
                    "Applicants",
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primary,
                    backgroundColor: const Color(0xFFEFF6FF),
                    side: const BorderSide(color: Color(0xFFBFDBFE)),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withOpacity(0.12)),
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
  // SECTION 5: INTERVIEW SCHEDULE (UI ONLY)
  // ------------------------------------------------------------
  Widget _buildInterviewsUIOnly() {
    final interviews = [
      {
        "time": "10:30 AM",
        "name": "Rahul Sharma",
        "role": "Frontend Developer",
        "mode": "Online",
      },
      {
        "time": "2:00 PM",
        "name": "Priya Devi",
        "role": "UI/UX Designer",
        "mode": "In-person",
      },
      {
        "time": "4:30 PM",
        "name": "Amit Kumar",
        "role": "Backend Developer",
        "mode": "Online",
      },
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDeco(radius: _r20),
      child: Column(
        children: [
          for (int i = 0; i < interviews.length; i++) ...[
            _interviewTile(interviews[i]),
            if (i != interviews.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: Color(0xFFE6E8EC)),
              ),
          ],
        ],
      ),
    );
  }

  Widget _interviewTile(Map<String, dynamic> i) {
    final mode = (i['mode'] ?? '').toString();
    final isOnline = mode.toLowerCase().contains('online');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: Icon(
            isOnline ? Icons.videocam_outlined : Icons.location_on_outlined,
            color: _primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    (i['time'] ?? '').toString(),
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      color: _primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: _border),
                    ),
                    child: Text(
                      mode,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: _muted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                (i['name'] ?? '').toString(),
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                  color: _text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                (i['role'] ?? '').toString(),
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _muted,
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isOnline ? "Join" : "Call",
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // SECTION 6: PERFORMANCE SUMMARY (UI ONLY)
  // ------------------------------------------------------------
  Widget _buildPerformanceUIOnly() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDeco(radius: _r20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            alignment: Alignment.center,
            child: const Text(
              "Chart UI placeholder\n(fl_chart integration later)",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: _muted,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _metricMini(
                  label: "Views",
                  value: _totalViews.toString(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _metricMini(
                  label: "Applications",
                  value: _totalApplicants.toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricMini({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: _muted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: _text,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // SECTION 7: ACTION NEEDED (UI ONLY)
  // ------------------------------------------------------------
  Widget _buildActionNeededUIOnly() {
    return Column(
      children: [
        _actionNeededCard(
          icon: Icons.people_outline,
          title: "3 applicants waiting for review",
          buttonText: "Review now",
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.employerJobs);
          },
        ),
        const SizedBox(height: 12),
        _actionNeededCard(
          icon: Icons.warning_amber_outlined,
          title: "1 job post expiring tomorrow",
          buttonText: "Manage jobs",
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.employerJobs);
          },
        ),
        const SizedBox(height: 12),
        _actionNeededCard(
          icon: Icons.check_circle_outline,
          title: "Complete company profile to boost trust",
          buttonText: "Complete",
          onTap: () {},
        ),
      ],
    );
  }

  Widget _actionNeededCard({
    required IconData icon,
    required String title,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDeco(radius: _r20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border),
                ),
                child: Icon(icon, color: _primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: _text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: _text,
                backgroundColor: const Color(0xFFF8FAFC),
                side: const BorderSide(color: _border),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // DRAWER
  // ------------------------------------------------------------
  Widget _newEmployerDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: _border)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFDBEAFE)),
                    ),
                    child: const Icon(Icons.apartment_rounded, color: _primary),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Khilonjiya Pvt Ltd",
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w900,
                            color: _text,
                            letterSpacing: -0.2,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          "Employer Account",
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: _muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                children: [
                  _drawerItem(
                    icon: Icons.dashboard_outlined,
                    title: "Dashboard",
                    onTap: () => Navigator.pop(context),
                  ),
                  _drawerItem(
                    icon: Icons.work_outline,
                    title: "My Jobs",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.employerJobs);
                    },
                  ),
                  _drawerItem(
                    icon: Icons.add_circle_outline,
                    title: "Post a Job",
                    onTap: () async {
                      Navigator.pop(context);
                      final res = await Navigator.pushNamed(
                        context,
                        AppRoutes.createJob,
                      );
                      if (res == true) await _loadDashboard();
                    },
                  ),
                  _drawerItem(
                    icon: Icons.people_outline,
                    title: "Applicants",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.employerJobs);
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    child: Divider(height: 1, color: _border),
                  ),
                  _drawerItem(
                    icon: Icons.logout_rounded,
                    title: "Logout",
                    destructive: true,
                    onTap: () async {
                      Navigator.pop(context);
                      await _logout();
                    },
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 18),
              child: Column(
                children: [
                  Text(
                    "Made in Assam",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF475569),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "© Khilonjiya",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
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

  Widget _drawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    final fg = destructive ? const Color(0xFFEF4444) : _text;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Icon(icon, color: fg),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  color: fg,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // BOTTOM NAV
  // ------------------------------------------------------------
  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: BottomNavigationBar(
        currentIndex: _bottomIndex,
        onTap: (i) {
          setState(() => _bottomIndex = i);

          // UI only for now (routes later)
          if (i == 1) {
            Navigator.pushNamed(context, AppRoutes.employerJobs);
          } else if (i == 2) {
            Navigator.pushNamed(context, AppRoutes.employerJobs);
          }
        },
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        backgroundColor: Colors.white,
        selectedItemColor: _primary,
        unselectedItemColor: const Color(0xFF64748B),
        selectedLabelStyle: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            label: "Jobs",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: "Applicants",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: "Messages",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Profile",
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // HELPERS
  // ------------------------------------------------------------
  BoxDecoration _cardDeco({double radius = 16, bool shadow = true}) {
    return BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: _border),
      boxShadow: shadow
          ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ]
          : [],
    );
  }

  Widget _softEmptyCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDeco(radius: _r20),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: Icon(icon, color: _text),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: _text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: _muted,
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

  int _safeTrend(int value) {
    if (value <= 0) return 0;
    if (value > 99) return 99;
    return value;
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