import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/employer_dashboard_service.dart';

class EmployerDashboardPage extends StatefulWidget {
  const EmployerDashboardPage({Key? key}) : super(key: key);

  @override
  State<EmployerDashboardPage> createState() =>
      _EmployerDashboardPageState();
}

class _EmployerDashboardPageState extends State<EmployerDashboardPage> {
  final _service = EmployerDashboardService();

  bool _loading = true;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _jobs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stats = await _service.getDashboardStats();
    final jobs = await _service.getJobsWithStats();

    setState(() {
      _stats = stats;
      _jobs = jobs;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Employer Dashboard'),
        backgroundColor: const Color(0xFF2563EB),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _statsRow(),
                  SizedBox(height: 4.w),
                  Text(
                    'Your Job Listings',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2.w),
                  ..._jobs.map(_jobCard),
                ],
              ),
            ),
    );
  }

  Widget _statsRow() {
    return Row(
      children: [
        _statBox('Jobs', _stats['total_jobs'], Icons.work),
        _statBox(
            'Applications', _stats['total_applications'], Icons.people),
        _statBox('Views', _stats['total_views'], Icons.visibility),
      ],
    );
  }

  Widget _statBox(String label, int value, IconData icon) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 1.w),
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF2563EB), size: 6.w),
            SizedBox(height: 1.h),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _jobCard(Map<String, dynamic> job) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.w),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            job['job_title'],
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            job['district'],
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              _miniStat(Icons.people, job['applications_count']),
              SizedBox(width: 4.w),
              _miniStat(Icons.visibility, job['views_count']),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(IconData icon, int value) {
    return Row(
      children: [
        Icon(icon, size: 4.w, color: Colors.grey),
        SizedBox(width: 1.w),
        Text(
          value.toString(),
          style: TextStyle(fontSize: 10.sp),
        ),
      ],
    );
  }
}
