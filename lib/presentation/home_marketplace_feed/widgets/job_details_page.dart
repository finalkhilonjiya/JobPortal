import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../job_application_form.dart';
import '../../../services/job_service.dart';

class JobDetailsPage extends StatefulWidget {
  final Map<String, dynamic> job;
  final bool isSaved;
  final VoidCallback onSaveToggle;

  const JobDetailsPage({
    Key? key,
    required this.job,
    required this.isSaved,
    required this.onSaveToggle,
  }) : super(key: key);

  @override
  State<JobDetailsPage> createState() => _JobDetailsPageState();
}

class _JobDetailsPageState extends State<JobDetailsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final JobService _jobService = JobService();

  bool _isApplied = false;
  bool _checkingStatus = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkApplied();
  }

  Future<void> _checkApplied() async {
    try {
      final apps = await _jobService.getUserAppliedJobs();
      _isApplied = apps.any(
        (e) => e['listing_id'] == widget.job['id'],
      );
    } catch (_) {}
    if (mounted) setState(() => _checkingStatus = false);
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      /// ================= BODY =================
      body: SafeArea(
        child: Column(
          children: [
            _header(context),
            _tabs(),
            Expanded(child: _tabViews()),
          ],
        ),
      ),

      /// ================= APPLY BUTTON =================
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: EdgeInsets.fromLTRB(4.w, 1.2.h, 4.w, 2.h),
          color: Colors.white,
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _checkingStatus || _isApplied
                  ? null
                  : () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              JobApplicationForm(jobId: job['id']),
                        ),
                      );
                      _checkApplied();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              child: Text(
                _isApplied ? 'Applied' : 'Apply now',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ================= HEADER =================
  Widget _header(BuildContext context) {
    final job = widget.job;
    final logoLetter =
        (job['company_name'] ?? 'C').toString()[0].toUpperCase();

    final color = Colors.primaries[
        Random(job['company_name'].hashCode).nextInt(Colors.primaries.length)];

    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 2.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job['job_title'] ?? '',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 0.4.h),
                  Text(
                    job['company_name'] ?? '',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 0.4.h),
                  Text(
                    'Posted ${_posted(job['created_at'])}',
                    style: TextStyle(
                      fontSize: 10.5.sp,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              logoLetter,
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ================= TABS =================
  Widget _tabs() {
    return Material(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        indicatorColor: Colors.orange,
        labelColor: Colors.black,
        unselectedLabelColor: Colors.grey,
        tabs: const [
          Tab(text: 'Details'),
          Tab(text: 'About Company'),
        ],
      ),
    );
  }

  /// ================= TAB VIEWS =================
  Widget _tabViews() {
    return TabBarView(
      controller: _tabController,
      children: [
        _detailsTab(),
        _aboutCompanyTab(),
      ],
    );
  }

  /// ================= DETAILS TAB =================
  Widget _detailsTab() {
    final job = widget.job;

    return ListView(
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 12.h),
      children: [
        _infoCard([
          _infoRow(Icons.access_time, '${job['experience_required'] ?? '—'}'),
          _infoRow(Icons.people, '${job['vacancies'] ?? '—'} vacancies'),
          _infoRow(Icons.location_on, job['district'] ?? ''),
          _infoRow(
            Icons.currency_rupee,
            _salary(job['salary_min'], job['salary_max']),
          ),
        ]),

        SizedBox(height: 2.h),

        _sectionCard(
          title: 'Must have skills',
          content: (job['skills_required'] as List?)?.join(', ') ?? '—',
        ),

        SizedBox(height: 2.h),

        _sectionCard(
          title: 'Description',
          content: job['job_description'] ?? '',
        ),
      ],
    );
  }

  /// ================= ABOUT COMPANY =================
  Widget _aboutCompanyTab() {
    return ListView(
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 12.h),
      children: [
        _sectionCard(
          title: 'About company',
          content: widget.job['company_description'] ??
              'Company description not available.',
        ),
      ],
    );
  }

  /// ================= UI HELPERS =================
  Widget _infoCard(List<Widget> children) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blueGrey),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required String content}) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style:
                TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 1.h),
          Text(
            content,
            style: TextStyle(
              fontSize: 12.sp,
              height: 1.6,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  String _salary(int? min, int? max) {
    String f(int v) => '${(v / 100000).toStringAsFixed(1)} Lacs PA';
    if (min != null && max != null) return '${f(min)} - ${f(max)}';
    if (min != null) return f(min);
    return 'Not disclosed';
  }

  String _posted(String? date) {
    if (date == null) return 'recently';
    final d = DateTime.tryParse(date);
    if (d == null) return 'recently';
    final days = DateTime.now().difference(d).inDays;
    return days == 0 ? 'today' : '$days d ago';
  }
}