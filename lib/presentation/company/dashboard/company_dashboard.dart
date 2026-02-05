import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../login_screen/mobile_auth_service.dart';
import '../../../routes/app_routes.dart';

class CompanyDashboard extends StatefulWidget {
  const CompanyDashboard({Key? key}) : super(key: key);

  @override
  State<CompanyDashboard> createState() => _CompanyDashboardState();
}

class _CompanyDashboardState extends State<CompanyDashboard> {
  final SupabaseClient _client = Supabase.instance.client;

  bool _loading = true;
  List<Map<String, dynamic>> _jobs = [];

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    setState(() => _loading = true);

    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        setState(() {
          _jobs = [];
          _loading = false;
        });
        return;
      }

      final res = await _client
          .from('job_listings')
          .select('id, job_title, status, created_at, applications_count')
          .eq('user_id', user.id) // ✅ correct column
          .order('created_at', ascending: false);

      _jobs = List<Map<String, dynamic>>.from(res);
    } catch (_) {
      _jobs = [];
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
  // STATS
  // ------------------------------------------------------------
  int get _activeJobs =>
      _jobs.where((e) => (e['status'] ?? '') == 'active').length;

  int get _closedJobs =>
      _jobs.where((e) => (e['status'] ?? '') == 'closed').length;

  int get _pausedJobs =>
      _jobs.where((e) => (e['status'] ?? '') == 'paused').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      // ------------------------------------------------------------
      // DRAWER
      // ------------------------------------------------------------
      drawer: _employerDrawer(),

      // ------------------------------------------------------------
      // APP BAR
      // ------------------------------------------------------------
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Employer Dashboard',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadJobs,
          ),
          const SizedBox(width: 6),
        ],
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),

      // ------------------------------------------------------------
      // BODY
      // ------------------------------------------------------------
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadJobs,
              child: ListView(
                padding: EdgeInsets.all(4.w),
                children: [
                  _statsHeader(),
                  SizedBox(height: 3.h),
                  _jobsHeader(),
                  SizedBox(height: 1.5.h),
                  if (_jobs.isEmpty)
                    _emptyState()
                  else
                    ..._jobs.map(_jobCard).toList(),
                  SizedBox(height: 10.h),
                ],
              ),
            ),

      // ------------------------------------------------------------
      // CREATE JOB BUTTON
      // ------------------------------------------------------------
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: we will create this screen next
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Create Job screen coming next")),
          );
        },
        backgroundColor: const Color(0xFF2563EB),
        label: const Text(
          'Create Job',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        icon: const Icon(Icons.add),
      ),
    );
  }

  // ------------------------------------------------------------
  // DRAWER UI
  // ------------------------------------------------------------
  Widget _employerDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Employer Menu",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _client.auth.currentUser?.email ?? "",
                    style: const TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // ------------------------------------------------------------
            // MENU ITEMS
            // ------------------------------------------------------------
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _drawerTile(
                    icon: Icons.work_outline,
                    title: "My Job Listings",
                    onTap: () {
                      Navigator.pop(context);
                      // You are already on dashboard.
                      // Next we will build a dedicated listings screen.
                    },
                  ),
                  _drawerTile(
                    icon: Icons.people_outline,
                    title: "Applicants (Coming next)",
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Applicants screen coming next"),
                        ),
                      );
                    },
                  ),
                  _drawerTile(
                    icon: Icons.business_outlined,
                    title: "Company Profile (Coming later)",
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Company profile coming later"),
                        ),
                      );
                    },
                  ),
                  _drawerTile(
                    icon: Icons.settings_outlined,
                    title: "Settings (Later)",
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  const Divider(height: 1),

                  _drawerTile(
                    icon: Icons.logout,
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
    final color = isDestructive ? const Color(0xFFEF4444) : null;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
      onTap: onTap,
    );
  }

  // ------------------------------------------------------------
  // DASHBOARD WIDGETS
  // ------------------------------------------------------------
  Widget _statsHeader() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          _statTile('Total', _jobs.length.toString()),
          _divider(),
          _statTile('Active', _activeJobs.toString()),
          _divider(),
          _statTile('Paused', _pausedJobs.toString()),
          _divider(),
          _statTile('Closed', _closedJobs.toString()),
        ],
      ),
    );
  }

  Widget _statTile(String title, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 0.6.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 10.5.sp,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 34,
      width: 1,
      color: const Color(0xFFE2E8F0),
    );
  }

  Widget _jobsHeader() {
    return const Text(
      'Recent Job Listings',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Color(0xFF0F172A),
      ),
    );
  }

  Widget _jobCard(Map<String, dynamic> job) {
    final title = (job['job_title'] ?? '').toString();
    final status = (job['status'] ?? 'active').toString();
    final applicationsCount = job['applications_count'] ?? 0;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TITLE + STATUS
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              _statusChip(status),
            ],
          ),
          SizedBox(height: 1.h),

          /// META
          Text(
            'Posted ${_postedAgo(job['created_at'])} • $applicationsCount applications',
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),

          /// ACTIONS
          Row(
            children: [
              _actionButton(
                icon: Icons.people_outline,
                label: 'Applicants',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Applicants screen next")),
                  );
                },
              ),
              SizedBox(width: 3.w),
              _actionButton(
                icon: Icons.edit_outlined,
                label: 'Edit',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Edit screen next")),
                  );
                },
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
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF166534);
      label = 'Active';
    } else if (s == 'paused') {
      bg = const Color(0xFFFEF9C3);
      fg = const Color(0xFF854D0E);
      label = 'Paused';
    } else if (s == 'expired') {
      bg = const Color(0xFFF1F5F9);
      fg = const Color(0xFF475569);
      label = 'Expired';
    } else {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFF991B1B);
      label = 'Closed';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
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

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(Icons.work_outline, size: 60, color: Colors.grey.shade400),
          SizedBox(height: 2.h),
          const Text(
            'No jobs posted yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 1.h),
          const Text(
            'Create your first job to start receiving applications.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 3.h),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Create Job screen coming next")),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text(
              'Create Job',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _postedAgo(dynamic date) {
    if (date == null) return 'recently';

    final d = DateTime.tryParse(date.toString());
    if (d == null) return 'recently';

    final diff = DateTime.now().difference(d);

    if (diff.inMinutes < 60) return 'today';
    if (diff.inHours < 24) return 'today';
    if (diff.inDays == 1) return '1 day ago';
    return '${diff.inDays} days ago';
  }
}