import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/candidate_applications_service.dart';

class MyApplicationsPage extends StatefulWidget {
  const MyApplicationsPage({Key? key}) : super(key: key);

  @override
  State<MyApplicationsPage> createState() => _MyApplicationsPageState();
}

class _MyApplicationsPageState extends State<MyApplicationsPage> {
  final _service = CandidateApplicationsService();
  bool _loading = true;
  List<Map<String, dynamic>> _apps = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _service.getMyApplications();
    setState(() {
      _apps = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Applications'),
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

  Widget _card(Map<String, dynamic> app) {
    return Container(
      margin: EdgeInsets.only(bottom: 3.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundImage: app['company_logo_url'] != null
                ? NetworkImage(app['company_logo_url'])
                : null,
            child: app['company_logo_url'] == null
                ? Text(app['company_name'][0])
                : null,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app['job_title'],
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${app['company_name']} • ${app['district']}',
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                ),
                SizedBox(height: 1.h),
                _timeline(app['application_status']),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeline(String status) {
    final steps = ['applied', 'shortlisted', 'interviewed', 'selected'];
    final rejected = status == 'rejected';

    return Row(
      children: steps.map((s) {
        final active = steps.indexOf(s) <= steps.indexOf(status);
        final color = rejected
            ? Colors.red
            : active
                ? Colors.green
                : Colors.grey.shade300;

        return Expanded(
          child: Column(
            children: [
              Container(
                height: 4,
                color: color,
              ),
              SizedBox(height: 0.5.h),
              Text(
                s.toUpperCase(),
                style: TextStyle(
                  fontSize: 7.sp,
                  color: color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
