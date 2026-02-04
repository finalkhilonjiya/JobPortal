import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmployerJobListScreen extends StatefulWidget {
  const EmployerJobListScreen({Key? key}) : super(key: key);

  @override
  State<EmployerJobListScreen> createState() => _EmployerJobListScreenState();
}

class _EmployerJobListScreenState extends State<EmployerJobListScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  bool _loading = true;
  List<Map<String, dynamic>> _jobs = [];

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      final res = await _client
          .from('job_listings')
          .select('''
            id,
            job_title,
            district,
            job_type,
            salary_min,
            salary_max,
            status,
            job_applications(count)
          ''')
          .eq('employer_id', user.id)
          .order('created_at', ascending: false);

      setState(() {
        _jobs = List<Map<String, dynamic>>.from(res);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      appBar: AppBar(
        title: const Text(
          'My Job Posts',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _jobs.isEmpty
              ? _emptyState()
              : ListView.builder(
                  padding: EdgeInsets.all(4.w),
                  itemCount: _jobs.length,
                  itemBuilder: (context, index) {
                    final job = _jobs[index];
                    final applicants =
                        (job['job_applications'] as List).isNotEmpty
                            ? job['job_applications'][0]['count']
                            : 0;

                    return _jobCard(job, applicants);
                  },
                ),
    );
  }

  /// ---------------- UI ----------------

  Widget _jobCard(Map<String, dynamic> job, int applicants) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Title + Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  job['job_title'] ?? '',
                  style: TextStyle(
                    fontSize: 14.5.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _statusChip(job['status']),
            ],
          ),

          SizedBox(height: 0.8.h),

          /// Location
          Text(
            job['district'] ?? '',
            style: TextStyle(
              fontSize: 11.5.sp,
              color: Colors.grey.shade600,
            ),
          ),

          SizedBox(height: 1.2.h),

          /// Salary + Type
          Row(
            children: [
              _iconText(
                Icons.currency_rupee,
                '${job['salary_min'] ?? '-'} - ${job['salary_max'] ?? '-'}',
              ),
              SizedBox(width: 4.w),
              _iconText(Icons.work_outline, job['job_type'] ?? ''),
            ],
          ),

          SizedBox(height: 1.8.h),
          const Divider(height: 1),

          SizedBox(height: 1.5.h),

          /// Applicants
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$applicants Applicants',
                style: TextStyle(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () {
                  // NEXT STEP: Applicants screen
                },
                child: const Text('View'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String? status) {
    final isOpen = status == 'open';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOpen ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isOpen ? 'Open' : 'Closed',
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: isOpen ? Colors.green : Colors.red,
        ),
      ),
    );
  }

  Widget _iconText(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade700),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 11.5.sp),
        ),
      ],
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.work_outline, size: 64, color: Colors.grey.shade400),
          SizedBox(height: 2.h),
          const Text(
            'No jobs posted yet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 1.h),
          const Text(
            'Create your first job to start hiring',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}