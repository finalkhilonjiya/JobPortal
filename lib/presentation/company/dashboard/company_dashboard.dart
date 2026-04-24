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

    setState(() => _loading = true);

    try {
      final user = _requireUser();

      Map<String, dynamic>? member;

      // 🔁 RETRY (fix delay issue after org creation)
      for (int i = 0; i < 3; i++) {
        final res = await Supabase.instance.client
            .from('company_members')
            .select('company_id')
            .eq('user_id', user.id)
            .maybeSingle();

        if (res != null) {
          member = res;
          break;
        }

        await Future.delayed(const Duration(milliseconds: 500));
      }

      // 🔁 FALLBACK (if membership not yet inserted)
      if (member == null) {
        final fallback = await Supabase.instance.client
            .from('companies')
            .select('id')
            .eq('created_by', user.id)
            .maybeSingle();

        if (fallback != null) {
          member = {'company_id': fallback['id']};
        }
      }

      // ❌ STILL NULL → show create org
      if (member == null) {
        setState(() {
          _needsOrganization = true;
          _loading = false;
        });
        return;
      }

      final companyId = member['company_id'].toString();

      // ============================================================
      // FETCH ALL DATA
      // ============================================================
      final company =
          await _service.fetchCompanyById(companyId: companyId);

      final results = await Future.wait([
        _service.fetchCompanyJobs(companyId: companyId),
        _service.fetchCompanyDashboardStats(companyId: companyId),
        _service.fetchRecentApplicants(companyId: companyId),
        _service.fetchTopJobs(companyId: companyId),
        _service.fetchTodayInterviews(companyId: companyId),
        _service.fetchLast7DaysPerformance(companyId: companyId),
        _service.fetchUnreadNotificationsCount(),
      ]);

      // ============================================================
      // SAFE CASTING
      // ============================================================
      final jobs = (results[0] as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final stats = Map<String, dynamic>.from(results[1] as Map);

      final applicants = (results[2] as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final topJobs = (results[3] as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final interviews = (results[4] as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final perf = Map<String, dynamic>.from(results[5] as Map);

      final unread = (results[6] as int?) ?? 0;

      if (!mounted) return;

      setState(() {
        _companyId = companyId;
        _company = company;

        _jobs = jobs;
        _stats = stats;
        _recentApplicants = applicants;
        _topJobs = topJobs;
        _todayInterviews = interviews;
        _perf7d = perf;
        _unreadNotifications = unread;

        _needsOrganization = false;
        _loading = false;
      });
    } catch (e) {
      debugPrint("DASHBOARD ERROR: $e");

      if (!mounted) return;

      setState(() {
        _needsOrganization = true;
        _loading = false;
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
  // BUILD
  // ============================================================
  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFFF7F8FA),

    body: _loading
        ? const Center(child: CircularProgressIndicator())
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
              if (res == true) await _loadDashboard();
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
          // ✅ ALL APPLICANTS (NOT FIRST JOB)
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

            QuickStats(stats: _stats),
            const SizedBox(height: 16),

            PrimaryActions(companyId: _companyId),
            const SizedBox(height: 20),

            const Text("Recent Applicants",
                style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),

            RecentApplicants(
              data: _recentApplicants,
              companyId: _companyId,
            ),

            const SizedBox(height: 20),

            const Text("Active Jobs",
                style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),

            ActiveJobs(jobs: _jobs, companyId: _companyId),

            const SizedBox(height: 20),

            const Text("Today's Interviews",
                style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),

            TodayInterviews(data: _todayInterviews),

            const SizedBox(height: 20),

            

            const Text("Top Jobs",
                style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),

            TopJobs(jobs: _topJobs, companyId: _companyId),

            const SizedBox(height: 20),

            const Text("Action Needed",
                style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),

            ActionNeeded(
              applicants: _recentApplicants,
              jobs: _jobs,
            ),

            const SizedBox(height: 100),
          ],
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
                const Text("Start hiring",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                const Text(
                  "Create your organization to post jobs",
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 16),

                ElevatedButton(
                  onPressed: () async {
                    final res = await Navigator.pushNamed(
                        context, AppRoutes.createOrganization);

                    if (res == true) {
                      await _loadDashboard();
                    }
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