import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class JobApplicantsScreen extends StatefulWidget {
  final String jobId;

  const JobApplicantsScreen({
    Key? key,
    required this.jobId,
  }) : super(key: key);

  @override
  State<JobApplicantsScreen> createState() => _JobApplicantsScreenState();
}

class _JobApplicantsScreenState extends State<JobApplicantsScreen> {
  final SupabaseClient _client = Supabase.instance.client;

  bool _loading = true;
  List<Map<String, dynamic>> _applicants = [];

  @override
  void initState() {
    super.initState();
    _loadApplicants();
  }

  Future<void> _loadApplicants() async {
    try {
      final res = await _client
          .from('job_applications')
          .select('''
            id,
            status,
            created_at,
            user_profiles (
              id,
              full_name,
              mobile_number,
              experience_years,
              expected_salary
            )
          ''')
          .eq('job_id', widget.jobId)
          .order('created_at', ascending: false);

      setState(() {
        _applicants = List<Map<String, dynamic>>.from(res);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(String applicationId, String status) async {
    await _client
        .from('job_applications')
        .update({'status': status})
        .eq('id', applicationId);

    _loadApplicants();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      appBar: AppBar(
        title: const Text(
          'Applicants',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _applicants.isEmpty
              ? _emptyState()
              : ListView.builder(
                  padding: EdgeInsets.all(4.w),
                  itemCount: _applicants.length,
                  itemBuilder: (context, index) {
                    final app = _applicants[index];
                    final user = app['user_profiles'];

                    return _applicantCard(
                      applicationId: app['id'],
                      status: app['status'],
                      name: user['full_name'] ?? 'Candidate',
                      mobile: user['mobile_number'] ?? '',
                      experience: user['experience_years'],
                      salary: user['expected_salary'],
                    );
                  },
                ),
    );
  }

  /// ---------------- UI ----------------

  Widget _applicantCard({
    required String applicationId,
    required String status,
    required String name,
    required String mobile,
    int? experience,
    int? salary,
  }) {
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
          /// Name + Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 14.5.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              _statusChip(status),
            ],
          ),

          SizedBox(height: 0.8.h),

          /// Mobile
          Text(
            mobile,
            style: TextStyle(
              fontSize: 11.5.sp,
              color: Colors.grey.shade600,
            ),
          ),

          SizedBox(height: 1.2.h),

          /// Experience + Salary
          Row(
            children: [
              _iconText(
                Icons.work_outline,
                experience != null ? '$experience yrs' : 'Fresher',
              ),
              SizedBox(width: 4.w),
              _iconText(
                Icons.currency_rupee,
                salary != null ? '$salary' : 'Not disclosed',
              ),
            ],
          ),

          SizedBox(height: 1.8.h),
          const Divider(height: 1),
          SizedBox(height: 1.2.h),

          /// Actions
          if (status == 'applied')
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        _updateStatus(applicationId, 'shortlisted'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text('Shortlist'),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        _updateStatus(applicationId, 'rejected'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'shortlisted':
        bg = Colors.green.shade50;
        fg = Colors.green;
        label = 'Shortlisted';
        break;
      case 'rejected':
        bg = Colors.red.shade50;
        fg = Colors.red;
        label = 'Rejected';
        break;
      default:
        bg = Colors.blue.shade50;
        fg = Colors.blue;
        label = 'Applied';
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
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: fg,
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
          Icon(Icons.people_outline,
              size: 64, color: Colors.grey.shade400),
          SizedBox(height: 2.h),
          const Text(
            'No applicants yet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 1.h),
          const Text(
            'Candidates will appear here once they apply',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}