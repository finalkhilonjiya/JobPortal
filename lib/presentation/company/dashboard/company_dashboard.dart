import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      final res = await _client
          .from('job_listings')
          .select('id, job_title, status, created_at')
          .eq('employer_id', user.id)
          .order('created_at', ascending: false);

      _jobs = List<Map<String, dynamic>>.from(res);
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      /// APP BAR
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Employer Dashboard',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Create Job',
            onPressed: () {
              Navigator.pushNamed(context, '/create-job');
            },
          ),
          const SizedBox(width: 8),
        ],
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),

      /// BODY
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
                  SizedBox(height: 8.h),
                ],
              ),
            ),

      /// CREATE JOB BUTTON
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/create-job');
        },
        backgroundColor: const Color(0xFF2563EB),
        label: const Text(
          'Create Job',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        icon: const Icon(Icons.add),
      ),
    );
  }

  /// ---------------- WIDGETS ----------------

  Widget _statsHeader() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _statTile('Jobs', _jobs.length.toString()),
          _divider(),
          _statTile(
            'Open',
            _jobs.where((e) => e['status'] == 'open').length.toString(),
          ),
          _divider(),
          _statTile(
            'Closed',
            _jobs.where((e) => e['status'] == 'closed').length.toString(),
          ),
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
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 32,
      width: 1,
      color: Colors.grey.shade300,
    );
  }

  Widget _jobsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Posted Jobs',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        TextButton(
          onPressed: _loadJobs,
          child: const Text('Refresh'),
        ),
      ],
    );
  }

  Widget _jobCard(Map<String, dynamic> job) {
    final status = job['status'] ?? 'open';

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TITLE + STATUS
          Row(
            children: [
              Expanded(
                child: Text(
                  job['job_title'] ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _statusChip(status),
            ],
          ),
          SizedBox(height: 1.h),

          /// META
          Text(
            'Posted ${_postedAgo(job['created_at'])}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 2.h),

          /// ACTIONS
          Row(
            children: [
              _actionButton(
                icon: Icons.people_outline,
                label: 'Applications',
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/job-applicants',
                    arguments: job['id'],
                  );
                },
              ),
              SizedBox(width: 3.w),
              _actionButton(
                icon: Icons.edit_outlined,
                label: 'Edit',
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/edit-job',
                    arguments: job['id'],
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
    final isOpen = status == 'open';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOpen ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isOpen ? 'Open' : 'Closed',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isOpen ? Colors.green : Colors.red,
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
      ),
      child: Column(
        children: [
          Icon(Icons.work_outline, size: 60, color: Colors.grey.shade400),
          SizedBox(height: 2.h),
          const Text(
            'No jobs posted yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Create your first job to start receiving applications.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          SizedBox(height: 3.h),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/create-job');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Create Job'),
          ),
        ],
      ),
    );
  }

  String _postedAgo(String? date) {
    if (date == null) return 'recently';
    final d = DateTime.tryParse(date);
    if (d == null) return 'recently';
    final days = DateTime.now().difference(d).inDays;
    return days == 0 ? 'today' : '$days days ago';
  }
}