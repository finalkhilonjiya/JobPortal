import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/job_service.dart';

class MyApplicationsPage extends StatefulWidget {
  const MyApplicationsPage({Key? key}) : super(key: key);

  @override
  State<MyApplicationsPage> createState() => _MyApplicationsPageState();
}

class _MyApplicationsPageState extends State<MyApplicationsPage> {
  final JobService _jobService = JobService();
  bool _loading = true;
  List<Map<String, dynamic>> _applications = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _applications = await _jobService.getMyApplications();
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar('My applications'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _applications.isEmpty
              ? _empty('You haven’t applied to any jobs yet')
              : ListView.builder(
                  itemCount: _applications.length,
                  itemBuilder: (_, i) {
                    final a = _applications[i];
                    return _card(
                      a['job_title'],
                      a['company_name'],
                      a['application_status'],
                      a['applied_at'],
                    );
                  },
                ),
    );
  }

  Widget _card(String title, String company, String status, String date) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600)),
          SizedBox(height: 0.5.h),
          Text(company, style: TextStyle(fontSize: 11.sp)),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(status.toUpperCase(),
                  style: TextStyle(
                      fontSize: 9.5.sp,
                      color: _statusColor(status))),
              Text(date, style: TextStyle(fontSize: 9.5.sp)),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'shortlisted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  AppBar _appBar(String t) => AppBar(
        title: Text(t),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      );

  Widget _empty(String text) =>
      Center(child: Text(text, style: TextStyle(fontSize: 12.sp)));
}
