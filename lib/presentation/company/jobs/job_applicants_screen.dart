import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/employer_job_service.dart';

class JobApplicantsScreen extends StatefulWidget {
  final String jobId;
  final String jobTitle;

  const JobApplicantsScreen({
    Key? key,
    required this.jobId,
    required this.jobTitle,
  }) : super(key: key);

  @override
  State<JobApplicantsScreen> createState() => _JobApplicantsScreenState();
}

class _JobApplicantsScreenState extends State<JobApplicantsScreen> {
  final EmployerJobService _service = EmployerJobService();
  bool _loading = true;
  List<Map<String, dynamic>> _apps = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _apps = await _service.fetchApplicants(widget.jobId);
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(widget.jobTitle),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _apps.isEmpty
              ? const Center(child: Text('No applicants yet'))
              : ListView.builder(
                  padding: EdgeInsets.all(4.w),
                  itemCount: _apps.length,
                  itemBuilder: (_, i) => _applicantCard(_apps[i]),
                ),
    );
  }

  Widget _applicantCard(Map<String, dynamic> app) {
    final user = app['user_profiles'];
    final name = user?['full_name'] ?? 'Candidate';
    final phone = user?['mobile_number'] ?? '';
    final email = user?['email'] ?? '';
    final status = app['status'] ?? 'applied';

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// NAME + STATUS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              _statusChip(status),
            ],
          ),

          const SizedBox(height: 8),

          if (phone.isNotEmpty)
            _meta(Icons.phone, phone),

          if (email.isNotEmpty)
            _meta(Icons.email, email),

          const SizedBox(height: 10),

          Row(
            children: [
              Text(
                'Applied on ',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              Text(
                _formatDate(app['created_at']),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _meta(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blueGrey),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.blue.shade700,
        ),
      ),
    );
  }

  String _formatDate(String date) {
    final d = DateTime.tryParse(date);
    if (d == null) return '';
    return '${d.day}/${d.month}/${d.year}';
  }
}