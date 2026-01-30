import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/employer_application_service.dart';

class JobApplicationsPage extends StatefulWidget {
  final String jobId;

  const JobApplicationsPage({Key? key, required this.jobId}) : super(key: key);

  @override
  State<JobApplicationsPage> createState() => _JobApplicationsPageState();
}

class _JobApplicationsPageState extends State<JobApplicationsPage> {
  final _service = EmployerApplicationService();
  bool _loading = true;
  List<Map<String, dynamic>> _apps = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _service.getApplicationsForJob(widget.jobId);
    setState(() {
      _apps = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Applications'),
        backgroundColor: const Color(0xFF2563EB),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: EdgeInsets.all(4.w),
              itemCount: _apps.length,
              itemBuilder: (_, i) => _card(_apps[i]),
            ),
    );
  }

  Widget _card(Map<String, dynamic> item) {
    final app = item['job_applications'];

    return Container(
      margin: EdgeInsets.only(bottom: 3.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: app['photo_file_url'] != null
                    ? NetworkImage(app['photo_file_url'])
                    : null,
                child: app['photo_file_url'] == null
                    ? Text(app['name'][0])
                    : null,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app['name'],
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${app['experience_level']} • ${app['education']}',
                      style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              _statusChip(item['application_status']),
            ],
          ),
          SizedBox(height: 2.h),
          Wrap(
            spacing: 2.w,
            children: [
              _action('Shortlist', 'shortlisted', Colors.blue),
              _action('Reject', 'rejected', Colors.red),
              _action('Select', 'selected', Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _action(String label, String status, Color color) {
    return OutlinedButton(
      onPressed: () async {
        await _service.updateApplicationStatus(
          applicationListingId: _apps
              .firstWhere((e) => e['application_status'] != null)['id'],
          status: status,
        );
        _load();
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
      ),
      child: Text(label),
    );
  }

  Widget _statusChip(String status) {
    final map = {
      'applied': Colors.grey,
      'shortlisted': Colors.blue,
      'interviewed': Colors.orange,
      'selected': Colors.green,
      'rejected': Colors.red,
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.6.h),
      decoration: BoxDecoration(
        color: map[status]!.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 8.sp, color: map[status]),
      ),
    );
  }
}
