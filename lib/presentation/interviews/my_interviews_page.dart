import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/interview_service.dart';

class MyInterviewsPage extends StatefulWidget {
  const MyInterviewsPage({Key? key}) : super(key: key);

  @override
  State<MyInterviewsPage> createState() => _MyInterviewsPageState();
}

class _MyInterviewsPageState extends State<MyInterviewsPage> {
  final _service = InterviewService();
  bool _loading = true;
  List<Map<String, dynamic>> _interviews = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _service.getMyInterviews();
    setState(() {
      _interviews = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Interviews'),
        backgroundColor: const Color(0xFF2563EB),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _interviews.isEmpty
              ? const Center(child: Text('No interviews scheduled'))
              : ListView.builder(
                  padding: EdgeInsets.all(4.w),
                  itemCount: _interviews.length,
                  itemBuilder: (_, i) => _card(_interviews[i]),
                ),
    );
  }

  Widget _card(Map<String, dynamic> item) {
    final job = item['job_listings'];

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
          Text(
            job['job_title'],
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
          ),
          Text(
            job['company_name'],
            style: TextStyle(fontSize: 10.sp, color: Colors.grey),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              const Icon(Icons.schedule, size: 16),
              SizedBox(width: 2.w),
              Text(item['interview_date']),
            ],
          ),
          if (item['employer_notes'] != null) ...[
            SizedBox(height: 1.h),
            Text(
              item['employer_notes'],
              style: TextStyle(fontSize: 10.sp),
            ),
          ],
        ],
      ),
    );
  }
}
