// lib/presentation/company/dashboard/company_dashboard.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../routes/app_routes.dart';
import '../../../services/mobile_auth_service.dart';
import '../../../services/employer_dashboard_service.dart';

// UI Widgets
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
    _loadDashboard();
  }



  User _requireUser() {
    final u = Supabase.instance.client.auth.currentUser;
    if (u == null) throw Exception("Session expired");
    return u;
  }


void _openProfile() {
  Navigator.pushNamed(context, AppRoutes.employerProfile);
}

  // ============================================================
  // LOAD DASHBOARD (FINAL FIXED LOGIC)
  // ============================================================
  Future<void> _loadDashboard() async {
  if (!mounted) return;

  setState(() {
    _loading = true;
    _needsOrganization = false;
  });

  try {
    String? companyId = _companyId.isNotEmpty ? _companyId : null;

    // RETRY resolve
    if (companyId == null) {
      int tries = 0;

      while (tries < 5) {
        companyId = await _service.resolveCompanyIdSafe();

        if (companyId != null && companyId.isNotEmpty) break;

        await Future.delayed(const Duration(milliseconds: 300));
        tries++;
      }

      if (companyId == null || companyId.isEmpty) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _needsOrganization = true;
        });
        return;
      }
    }

    // RETRY fetch company
    Map<String, dynamic> company = {};
    int tries = 0;

    while (tries < 5) {
      company = await _service.fetchCompanyById(companyId: companyId);

      if (company.isNotEmpty) break;

      await Future.delayed(const Duration(milliseconds: 300));
      tries++;
    }

    if (company.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _needsOrganization = true;
      });
      return;
    }

    final results = await Future.wait([
      _service.fetchCompanyJobs(companyId: companyId),
      _service.fetchCompanyDashboardStats(companyId: companyId),
      _service.fetchRecentApplicants(companyId: companyId),
      _service.fetchTopJobs(companyId: companyId),
      _service.fetchTodayInterviews(companyId: companyId),
      _service.fetchLast7DaysPerformance(companyId: companyId),
      _service.fetchUnreadNotificationsCount(),
    ]);

    if (!mounted) return;

    setState(() {
      _companyId = companyId!;

      _company = Map<String, dynamic>.from(company);

      _jobs = (results[0] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      _stats = (results[1] is Map)
          ? Map<String, dynamic>.from(results[1])
          : {};

      _recentApplicants = (results[2] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      _topJobs = (results[3] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      _todayInterviews = (results[4] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      _perf7d = (results[5] is Map)
          ? Map<String, dynamic>.from(results[5])
          : {};

      _unreadNotifications = results[6] as int? ?? 0;

      _loading = false;
      _needsOrganization = false;
    });
  } catch (e, st) {
    print("❌ DASHBOARD ERROR: $e");
    print(st);

    if (!mounted) return;

    setState(() {
      _loading = false;
      _needsOrganization = true;
    });
  }
}
  // ============================================================
  // LOGOUT
  // ============================================================



Widget _preparingScreen() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
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
  // BUILD
  // ============================================================
  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFFF7F8FA),
    drawer: _drawer(),
    body: _loading
        ? _preparingScreen()
        : _needsOrganization
            ? _noOrg()
            : _dashboard(),
    floatingActionButton: _needsOrganization
        ? null
        : FloatingActionButton(
            backgroundColor: const Color(0xFF16A34A),
            onPressed: () async {
              final res =
                  await Navigator.pushNamed(context, AppRoutes.createJob);

              if (!mounted) return;

              if (res == true) {
                await _loadDashboard();
              }
            },
            child: const Icon(Icons.add),
          ),
    bottomNavigationBar: BottomNavigationBar(
      currentIndex: 0,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF16A34A),
      onTap: (i) {
        if (i == 1) {
          Navigator.pushNamed(context, AppRoutes.employerJobs);
        } else if (i == 2) {
          Navigator.pushNamed(
            context,
            AppRoutes.jobApplicants,
            arguments: {
              'jobId': 'all',
              'companyId': _companyId,
            },
          );
        } else if (i == 3) {
          _openProfile();
        }
      },
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.home), label: "Dashboard"),
        BottomNavigationBarItem(
            icon: Icon(Icons.work), label: "Jobs"),
        BottomNavigationBarItem(
            icon: Icon(Icons.people), label: "Applicants"),
        BottomNavigationBarItem(
            icon: Icon(Icons.person), label: "Profile"),
      ],
    ),
  );
}

  // ============================================================
  // DASHBOARD UI
  // ============================================================
  Widget _dashboard() {
  // 🔥 HARD GUARD
  if (_company.isEmpty) {
    return _preparingScreen();
  }

  return SafeArea(
    child: RefreshIndicator(
      onRefresh: _loadDashboard,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          HeaderWidget(company: _company, unread: _unreadNotifications),

          const SizedBox(height: 16),
          const HeroSlider(),
          const SizedBox(height: 16),

          QuickStats(stats: _stats.isEmpty ? {} : _stats),
          const SizedBox(height: 16),

          PrimaryActions(companyId: _companyId),
          const SizedBox(height: 20),

          const Text("Recent Applicants",
              style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),

          RecentApplicants(
            data: _recentApplicants.isEmpty ? [] : _recentApplicants,
            companyId: _companyId,
          ),

          const SizedBox(height: 20),

          const Text("Active Jobs",
              style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),

          ActiveJobs(
            jobs: _jobs.isEmpty ? [] : _jobs,
            companyId: _companyId,
          ),

          const SizedBox(height: 20),

          const Text("Today's Interviews",
              style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),

          TodayInterviews(
            data: _todayInterviews.isEmpty ? [] : _todayInterviews,
            companyId: _companyId,
          ),

          const SizedBox(height: 20),

          const Text("Top Jobs",
              style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),

          TopJobs(
            jobs: _topJobs.isEmpty ? [] : _topJobs,
            companyId: _companyId,
          ),

          const SizedBox(height: 100),
        ],
      ),
    ),
  );
}



Widget _drawer() {
  final name = (_company.isNotEmpty &&
          _company['name'] is String &&
          _company['name'] != null)
      ? _company['name'] as String
      : 'Company';

  return Drawer(
    backgroundColor: Colors.white,
    child: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: Color(0xFFDCFCE7),
                  child: Icon(Icons.business, color: Color(0xFF16A34A)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 6),
              children: [
                _drawerItem(Icons.work_outline, "My Jobs", () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.employerJobs);
                }),
                _drawerItem(Icons.people_outline, "Applicants", () {
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
                _drawerItem(Icons.person_outline, "Edit Profile", () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.employerProfile);
                }),
                const Divider(),
                _drawerItem(Icons.info_outline, "About Us", () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.aboutApp);
                }),
                _drawerItem(Icons.support_agent, "Contact Us", () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.contactSupport);
                }),
                _drawerItem(Icons.description_outlined, "Terms & Conditions",
                    () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                      context, AppRoutes.termsAndConditions);
                }),
                _drawerItem(Icons.lock_outline, "Privacy Policy", () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.privacyPolicy);
                }),
                const Divider(),
                _drawerItem(
                  Icons.logout_rounded,
                  "Logout",
                  () async {
                    Navigator.pop(context);
                    await _logout();

                    if (!mounted) return;

                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.employerLogin,
                      (_) => false,
                    );
                  },
                  color: const Color(0xFFEF4444),
                ),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color ?? const Color(0xFF334155)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color ?? const Color(0xFF111827),
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
  return SafeArea(
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE6E8EC)),
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

  if (res == null || res.toString().isEmpty) return;

  // 🔥 DO NOT reset everything blindly
  setState(() {
    _companyId = res.toString();
    _loading = true;
    _needsOrganization = false;
  });

  await _loadDashboard();
},

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                ),

                child: const Text("Create Organization"),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}