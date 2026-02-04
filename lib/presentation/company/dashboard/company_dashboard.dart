import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/employer_job_service.dart';

class CompanyDashboard extends StatefulWidget {
  const CompanyDashboard({Key? key}) : super(key: key);

  @override
  State<CompanyDashboard> createState() => _CompanyDashboardState();
}

class _CompanyDashboardState extends State<CompanyDashboard> {
  final EmployerJobService _jobService = EmployerJobService();
  bool _loading = true;
  List<Map<String, dynamic>> _jobs = [];

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    setState(() => _loading = true);
    _jobs = await _jobService.fetchEmployerJobs();
    setState(() => _loading = false);
  }

  Future<void> _closeJob(String id) async {
    await _jobService.closeJob(id);
    _loadJobs();
  }

  Future<void> _deleteJob(String id) async {
    await _jobService.deleteJob(id);
    _loadJobs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Employer Dashboard'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // NEXT STEP: Job creation form
        },
        backgroundColor: const Color(0xFF2563EB),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _jobs.isEmpty
              ? _emptyState()
              : ListView.builder(
                  padding: EdgeInsets.all(4.w),
                  itemCount: _jobs.length,
                  itemBuilder: (_, i) => _jobCard(_jobs[i]),
                ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.work_outline, size: 60, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'No jobs posted yet',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _jobCard(Map<String, dynamic> job) {
    final status = job['status'] ?? 'active';

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TITLE + STATUS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

          const SizedBox(height: 6),

          /// COMPANY
          Text(
            job['company_name'] ?? '',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),

          const SizedBox(height: 12),

          /// META
          Row(
            children: [
              _meta(Icons.location_on_outlined, job['district']),
              const SizedBox(width: 12),
              _meta(Icons.work_outline, job['experience_required']),
            ],
          ),

          const SizedBox(height: 14),

          /// ACTIONS
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (status == 'active')
                TextButton(
                  onPressed: () => _closeJob(job['id']),
                  child: const Text('Close'),
                ),
              TextButton(
                onPressed: () => _deleteJob(job['id']),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _meta(IconData icon, String? text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.blueGrey),
        const SizedBox(width: 4),
        Text(
          text ?? '',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _statusChip(String status) {
    final isActive = status == 'active';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withOpacity(0.1)
            : Colors.grey.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isActive ? Colors.green : Colors.grey,
        ),
      ),
    );
  }
}