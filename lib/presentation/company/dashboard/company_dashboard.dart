// lib/presentation/company/dashboard/company_dashboard.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../routes/app_routes.dart';
import '../../../services/mobile_auth_service.dart';
import '../../../services/employer_dashboard_service.dart';
import '../../../services/employer_subscription_service.dart';
import '../subscription/employer_subscription_page.dart';
import '../candidates/candidate_database_page.dart';

import 'widgets/header_widget.dart';
import 'widgets/hero_slider.dart';
import 'widgets/quick_stats.dart';
import 'widgets/primary_actions.dart';
import 'widgets/recent_applicants.dart';
import 'widgets/active_jobs.dart';
import 'widgets/today_interviews.dart';
import 'widgets/top_jobs.dart';
import 'widgets/action_needed.dart';

class CompanyDashboard extends StatefulWidget {
  const CompanyDashboard({super.key});

  @override
  State<CompanyDashboard> createState() => _CompanyDashboardState();
}

class _CompanyDashboardState extends State<CompanyDashboard> {
  final EmployerDashboardService _service = EmployerDashboardService();
  final EmployerSubscriptionService _subService = EmployerSubscriptionService();

  // ============================================================
  // Gate: employer must have an active Khilonjiya Premium plan
  // before they can post a job. If not, send them to the
  // subscription page instead of the create-job form.
  // ============================================================
  Future<void> _onPostJobTapped() async {
    final active = await _subService.isPremiumActive();

    if (!mounted) return;

    if (!active) {
      final purchased = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              EmployerSubscriptionPage(companyId: _companyId),
        ),
      );

      if (purchased != true) return;
    }

    if (!mounted) return;

    final res = await Navigator.pushNamed(context, AppRoutes.createJob);
    if (!mounted) return;
    if (res == true) {
      await _loadDashboard();
    }
  }

  // Each call to _loadDashboard increments this. Any in-flight
  // coroutine that sees its generation is stale simply exits
  // without touching state. This eliminates every race condition.
  int _generation = 0;

  bool _loading = true;
  bool _needsOrganization = false;

  String _companyId = "";

  Map<String, dynamic> _company = {};
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _jobs = [];
  List<Map<String, dynamic>> _recentApplicants = [];
  List<Map<String, dynamic>> _todayInterviews = [];
  Map<String, dynamic> _perf7d = {};
  List<Map<String, dynamic>> _topJobs = [];

  int _unreadNotifications = 0;

  @override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['companyId'] != null) {
      final id = args['companyId'].toString().trim();
      if (id.isNotEmpty) {
        _companyId = id;
      }
    }
    _loadDashboard();
  });
}

  void _openProfile() {
    Navigator.pushNamed(context, AppRoutes.employerProfile);
  }

  // ============================================================
  // LOAD DASHBOARD
  // Generation-based: every new call cancels all previous ones.
  // ============================================================
  Future<void> _loadDashboard({String? withCompanyId}) async {
    if (!mounted) return;

    // Stamp this call. Any older in-flight call will see its
    // generation no longer matches and will silently abort.
    _generation++;
    final int myGeneration = _generation;

    // If a specific companyId is provided (post-creation path),
    // lock it in immediately as a direct field write.
    if (withCompanyId != null && withCompanyId.isNotEmpty) {
      _companyId = withCompanyId;
    }

    setState(() {
      _loading = true;
      _needsOrganization = false;
    });

    // Helper: check if this call is still the current one.
    bool stale() => !mounted || _generation != myGeneration;

    try {
      // -------------------------------------------------------
      // STEP 1: Resolve company ID
      // -------------------------------------------------------
      String? companyId =
          _companyId.isNotEmpty ? _companyId : null;

      if (companyId == null) {
        for (int i = 0; i < 6; i++) {
          if (stale()) return;
          try {
            companyId = await _service.resolveCompanyIdSafe();
            if (companyId != null && companyId.isNotEmpty) break;
          } catch (_) {}
          if (stale()) return;
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      if (stale()) return;

      if (companyId == null || companyId.isEmpty) {
        setState(() {
          _loading = false;
          _needsOrganization = true;
        });
        return;
      }

      // -------------------------------------------------------
      // STEP 2: Fetch company row
      // -------------------------------------------------------
      Map<String, dynamic> company = {};

      for (int i = 0; i < 6; i++) {
        if (stale()) return;
        try {
          final res = await _service.fetchCompanyById(
              companyId: companyId);
          if (res.isNotEmpty) {
            company = Map<String, dynamic>.from(res);
            break;
          }
        } catch (_) {}
        if (stale()) return;
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (stale()) return;

      if (company.isEmpty) {
        setState(() {
          _loading = false;
          _needsOrganization = true;
        });
        return;
      }

      // -------------------------------------------------------
      // STEP 3: Fetch all dashboard data
      // -------------------------------------------------------
      List<Map<String, dynamic>> jobs = [];
      Map<String, dynamic> stats = {};
      List<Map<String, dynamic>> applicants = [];
      List<Map<String, dynamic>> topJobs = [];
      List<Map<String, dynamic>> interviews = [];
      Map<String, dynamic> perf = {};
      int unread = 0;

      try {
        jobs = await _service.fetchCompanyJobs(
            companyId: companyId);
      } catch (e) {
        print("❌ jobs: $e");
      }
      if (stale()) return;

      try {
        stats = await _service.fetchCompanyDashboardStats(
            companyId: companyId);
      } catch (e) {
        print("❌ stats: $e");
      }
      if (stale()) return;

      try {
        applicants = await _service.fetchRecentApplicants(
            companyId: companyId);
      } catch (e) {
        print("❌ applicants: $e");
      }
      if (stale()) return;

      try {
        topJobs = await _service.fetchTopJobs(
            companyId: companyId);
      } catch (e) {
        print("❌ topJobs: $e");
      }
      if (stale()) return;

      try {
        interviews = await _service.fetchTodayInterviews(
            companyId: companyId);
      } catch (e) {
        print("❌ interviews: $e");
      }
      if (stale()) return;

      try {
        perf = await _service.fetchLast7DaysPerformance(
            companyId: companyId);
      } catch (e) {
        print("❌ perf: $e");
      }
      if (stale()) return;

      try {
        unread =
            await _service.fetchUnreadNotificationsCount();
      } catch (e) {
        print("❌ unread: $e");
      }
      if (stale()) return;

      // Single atomic setState — only runs if we are still
      // the current generation (no newer call has started).
      setState(() {
        _companyId = companyId!;
        _company = company;
        _jobs = jobs;
        _stats = stats;
        _recentApplicants = applicants;
        _topJobs = topJobs;
        _todayInterviews = interviews;
        _perf7d = perf;
        _unreadNotifications = unread;
        _loading = false;
        _needsOrganization = false;
      });
    } catch (e, st) {
      print("❌ DASHBOARD CRASH: $e\n$st");
      if (stale()) return;
      setState(() {
        _loading = false;
        _needsOrganization = true;
      });
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================
  Future<void> _logout() async {
    await MobileAuthService().logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.roleSelection,
      (_) => false,
    );
  }

  // ============================================================
  // PREPARING SCREEN
  // ============================================================
  Widget _preparingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Color(0xFF16A34A),
            ),
          ),
          SizedBox(height: 20),
          Text(
            "Your dashboard is being prepared...",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
Widget build(BuildContext context) {
  // No org — show ONLY the bare start hiring screen
  // No bottom bar, no drawer, no FAB
  if (_needsOrganization) {
    return _noOrg();
  }

  // Loading — show spinner inside full scaffold
  // so bottom bar shows during load for returning employers
  if (_loading) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: _preparingScreen(),
    );
  }

  // Has org — full dashboard with everything
  return Scaffold(
    backgroundColor: const Color(0xFFF7F8FA),
    drawer: _drawer(),
    body: _dashboard(),
    floatingActionButton: FloatingActionButton(
      backgroundColor: const Color(0xFF16A34A),
      onPressed: _onPostJobTapped,
      child: const Icon(Icons.add),
    ),
    bottomNavigationBar: BottomNavigationBar(
      currentIndex: 0,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF16A34A),
      onTap: (i) {
        if (i == 1) {
          Navigator.pushNamed(
            context,
            AppRoutes.jobApplicants,
            arguments: {
              'jobId': 'all',
              'companyId': _companyId,
            },
          );
        } else if (i == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  CandidateDatabasePage(companyId: _companyId),
            ),
          );
        } else if (i == 3) {
          _openProfile();
        }
      },
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.home), label: "Dashboard"),
        BottomNavigationBarItem(
            icon: Icon(Icons.people), label: "Applicants"),
        BottomNavigationBarItem(
            icon: Icon(Icons.storage), label: "Database"),
        BottomNavigationBarItem(
            icon: Icon(Icons.person), label: "Profile"),
      ],
    ),
  );
}

  // ============================================================
  // DASHBOARD BODY
  // ============================================================
  Widget _dashboard() {
    if (_company.isEmpty) {
      return _preparingScreen();
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await _loadDashboard();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            HeaderWidget(
                company: _company,
                unread: _unreadNotifications),
            const SizedBox(height: 16),
            const HeroSlider(),
            const SizedBox(height: 16),
            QuickStats(stats: _stats),
            const SizedBox(height: 16),
            PrimaryActions(companyId: _companyId),
            const SizedBox(height: 20),
            const Text("Recent Applicants",
                style:
                    TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            RecentApplicants(
                data: _recentApplicants,
                companyId: _companyId),
            const SizedBox(height: 20),
            const Text("Active Jobs",
                style:
                    TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            ActiveJobs(
                jobs: _jobs, companyId: _companyId),
            const SizedBox(height: 20),
            const Text("Today's Interviews",
                style:
                    TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            TodayInterviews(
                data: _todayInterviews,
                companyId: _companyId),
            const SizedBox(height: 20),
            const Text("Top Jobs",
                style:
                    TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            TopJobs(
                jobs: _topJobs, companyId: _companyId),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DRAWER
  // ============================================================
  Widget _drawer() {
    final name = (_company['name'] is String)
        ? _company['name'] as String
        : 'Company';

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Color(0xFFDCFCE7),
                    child: Icon(Icons.business,
                        color: Color(0xFF16A34A)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          "Employer Account",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                    vertical: 6),
                children: [
                  _drawerItem(
                      Icons.work_outline, "My Jobs", () {
                    Navigator.pop(context);
                    Navigator.pushNamed(
                        context, AppRoutes.employerJobs);
                  }),
                  _drawerItem(Icons.people_outline,
                      "Applicants", () {
                    Navigator.pop(context);
                    Navigator.pushNamed(
                      context,
                      AppRoutes.jobApplicants,
                      arguments: {
                        'jobId': 'all',
                        'companyId': _companyId,
                      },
                    );
                  }),
                  _drawerItem(Icons.person_outline,
                      "Edit Profile", () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context,
                        AppRoutes.employerProfile);
                  }),
                  _drawerItem(Icons.workspace_premium_outlined,
                      "Subscription", () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EmployerSubscriptionPage(
                          companyId: _companyId,
                        ),
                      ),
                    );
                  }),
                  const Divider(),
                  _drawerItem(Icons.logout_rounded,
                      "Logout", () async {
                    Navigator.pop(context);
                    await _logout();
                    if (!mounted) return;
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.employerLogin,
                      (_) => false,
                    );
                  }, color: const Color(0xFFEF4444)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color? color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Ink(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon,
                    size: 20,
                    color:
                        color ?? const Color(0xFF334155)),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color ??
                          const Color(0xFF111827),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // NO ORG
  // ============================================================
  Widget _noOrg() {
  return Scaffold(
    backgroundColor: const Color(0xFFF7F8FA),
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: const Color(0xFFE6E8EC)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Start hiring",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Create your organization to post jobs",
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    final res = await Navigator.pushNamed(
                      context,
                      AppRoutes.createOrganization,
                    );

                    if (!mounted) return;

                    final String newCompanyId =
                        (res != null &&
                                res.toString().trim().isNotEmpty)
                            ? res.toString().trim()
                            : '';

                    if (newCompanyId.isEmpty) return;

                    await _loadDashboard(
                        withCompanyId: newCompanyId);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    "Create Organization",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
}