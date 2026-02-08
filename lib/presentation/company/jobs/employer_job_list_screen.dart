import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../routes/app_routes.dart';

class EmployerJobListScreen extends StatefulWidget {
  const EmployerJobListScreen({Key? key}) : super(key: key);

  @override
  State<EmployerJobListScreen> createState() => _EmployerJobListScreenState();
}

class _EmployerJobListScreenState extends State<EmployerJobListScreen> {
  final SupabaseClient _client = Supabase.instance.client;

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _jobs = [];

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      setState(() {
        _loading = false;
        _error = "Session expired. Please login again.";
      });
      return;
    }

    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      // ✅ Correct schema: job_listings.user_id
      // ✅ Correct counts: applications_count column
      final res = await _client
          .from('job_listings')
          .select('''
            id,
            job_title,
            district,
            job_type,
            salary_min,
            salary_max,
            salary_period,
            status,
            created_at,
            applications_count,
            views_count
          ''')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        _jobs = List<Map<String, dynamic>>.from(res);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = "Failed to load jobs";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text(
          'My Job Posts',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
            letterSpacing: -0.2,
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0.6,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        actions: [
          IconButton(
            onPressed: _loadJobs,
            tooltip: "Refresh",
            icon: const Icon(Icons.refresh_rounded),
          ),
          SizedBox(width: 2.w),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _errorState()
              : _jobs.isEmpty
                  ? _emptyState()
                  : RefreshIndicator(
                      onRefresh: _loadJobs,
                      child: ListView.builder(
                        padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 4.h),
                        itemCount: _jobs.length,
                        itemBuilder: (context, index) {
                          final job = _jobs[index];
                          return _jobCard(job);
                        },
                      ),
                    ),
    );
  }

  // ------------------------------------------------------------
  // CARD
  // ------------------------------------------------------------
  Widget _jobCard(Map<String, dynamic> job) {
    final jobId = (job['id'] ?? '').toString();
    final title = (job['job_title'] ?? '').toString();
    final district = (job['district'] ?? '').toString();
    final jobType = (job['job_type'] ?? '').toString();
    final status = (job['status'] ?? 'active').toString();

    final salaryMin = job['salary_min'];
    final salaryMax = job['salary_max'];
    final salaryPeriod = (job['salary_period'] ?? 'Monthly').toString();

    final apps = (job['applications_count'] ?? 0) as int;
    final views = (job['views_count'] ?? 0) as int;

    final salaryText = _salaryText(
      salaryMin: salaryMin,
      salaryMax: salaryMax,
      period: salaryPeriod,
    );

    final statusUi = _statusUi(status);

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7EAF0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + status
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              _statusChip(statusUi.label, statusUi.bg, statusUi.fg),
            ],
          ),

          SizedBox(height: 1.2.h),

          // Location
          if (district.trim().isNotEmpty)
            _metaRow(Icons.location_on_rounded, district),

          if (district.trim().isNotEmpty) SizedBox(height: 0.8.h),

          // Salary + Type
          Row(
            children: [
              Expanded(
                child: _metaRow(Icons.currency_rupee_rounded, salaryText),
              ),
              SizedBox(width: 3.w),
              _smallPill(jobType.isEmpty ? "Job" : jobType),
            ],
          ),

          SizedBox(height: 1.6.h),
          Divider(color: Colors.black.withOpacity(0.06), height: 1),
          SizedBox(height: 1.6.h),

          // Applicants + Views
          Row(
            children: [
              Expanded(
                child: _metric(
                  icon: Icons.people_alt_outlined,
                  label: "Applicants",
                  value: apps.toString(),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _metric(
                  icon: Icons.remove_red_eye_outlined,
                  label: "Views",
                  value: views.toString(),
                ),
              ),
            ],
          ),

          SizedBox(height: 1.8.h),

          // Actions
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
                    await _loadJobs();
                  },
                  icon: const Icon(Icons.people_alt_outlined, size: 18),
                  label: const Text(
                    "View Applicants",
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
                    "Edit",
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

  // ------------------------------------------------------------
  // UI PARTS
  // ------------------------------------------------------------
  Widget _metaRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF475569)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF334155),
            ),
          ),
        ),
      ],
    );
  }

  Widget _smallPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          color: Color(0xFF0F172A),
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _metric({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF334155)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, Color bg, Color fg) {
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

  _StatusUI _statusUi(String status) {
    final s = status.toLowerCase();

    if (s == 'active') {
      return _StatusUI(
        label: "Active",
        bg: const Color(0xFFECFDF5),
        fg: const Color(0xFF14532D),
      );
    }
    if (s == 'paused') {
      return _StatusUI(
        label: "Paused",
        bg: const Color(0xFFFFFBEB),
        fg: const Color(0xFF7C2D12),
      );
    }
    if (s == 'expired') {
      return _StatusUI(
        label: "Expired",
        bg: const Color(0xFFF1F5F9),
        fg: const Color(0xFF475569),
      );
    }

    return _StatusUI(
      label: "Closed",
      bg: const Color(0xFFFFF1F2),
      fg: const Color(0xFF9F1239),
    );
  }

  String _salaryText({
    required dynamic salaryMin,
    required dynamic salaryMax,
    required String period,
  }) {
    final min = int.tryParse((salaryMin ?? '').toString());
    final max = int.tryParse((salaryMax ?? '').toString());

    if (min == null || max == null) return "Salary not disclosed";

    final per = period.isEmpty ? "Monthly" : period;
    return "₹$min - ₹$max / $per";
  }

  // ------------------------------------------------------------
  // EMPTY / ERROR
  // ------------------------------------------------------------
  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(7.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(
                Icons.work_outline_rounded,
                size: 34,
                color: Color(0xFF334155),
              ),
            ),
            SizedBox(height: 2.4.h),
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
              'Create your first job to start hiring.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(7.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 34,
                color: Color(0xFF9F1239),
              ),
            ),
            SizedBox(height: 2.4.h),
            Text(
              _error ?? "Something went wrong",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 1.8.h),
            OutlinedButton.icon(
              onPressed: _loadJobs,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(
                "Try Again",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F172A),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusUI {
  final String label;
  final Color bg;
  final Color fg;

  _StatusUI({
    required this.label,
    required this.bg,
    required this.fg,
  });
}