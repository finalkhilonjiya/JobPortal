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
  late TabController _tabController;
  final JobService _jobService = JobService();

  bool _isApplied = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkApplied();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkApplied() async {
    try {
      final apps = await _jobService.getUserAppliedJobs();

      final jobId = widget.job['id']?.toString();

      _isApplied = apps.any((row) {
        // row is from job_applications_listings
        final listingId = row['listing_id']?.toString();
        return listingId == jobId;
      });
    } catch (_) {
      _isApplied = false;
    }

    if (!mounted) return;
    setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;

    final title = (job['job_title'] ?? '').toString();
    final company = (job['company_name'] ?? '').toString();
    final location = (job['district'] ?? '').toString();

    final salaryMin = job['salary_min'];
    final salaryMax = job['salary_max'];

    final description = (job['job_description'] ?? '').toString();
    final skills = (job['skills_required'] as List?) ?? [];

    final postedAt = job['created_at']?.toString();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      /// APPLY BUTTON
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.2.h),
          color: Colors.white,
          child: SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: _checking || _isApplied
                  ? null
                  : () async {
                      final res = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              JobApplicationForm(jobId: job['id'].toString()),
                        ),
                      );

                      // If applied successfully, instantly disable button
                      if (res == true) {
                        if (!mounted) return;
                        setState(() => _isApplied = true);
                      } else {
                        // still re-check for safety
                        await _checkApplied();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isApplied ? Colors.grey : const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                padding: EdgeInsets.zero,
              ),
              child: Text(
                _isApplied ? 'Already Applied' : 'Apply now',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ),
      ),

      body: Column(
        children: [
          /// APP BAR
          AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            leading: const BackButton(color: Colors.black),
            actions: [
              IconButton(
                icon: Icon(
                  widget.isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: Colors.black,
                ),
                onPressed: widget.onSaveToggle,
              ),
            ],
          ),

          /// HEADER
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 2.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CompanyLogo(company: company),
                SizedBox(width: 4.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 0.6.h),
                      Text(
                        company,
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 0.4.h),
                      Text(
                        _postedAgo(postedAt),
                        style: TextStyle(
                          fontSize: 10.5.sp,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          /// TABS
          Container(
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
          ),

          /// BODY
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                ListView(
                  padding: EdgeInsets.all(4.w),
                  children: [
                    _infoCard(children: [
                      _row(Icons.location_on, location),
                      _row(
                        Icons.currency_rupee,
                        _salary(salaryMin, salaryMax),
                      ),
                    ]),
                    SizedBox(height: 2.h),
                    _section('Description', description),
                    if (skills.isNotEmpty) ...[
                      SizedBox(height: 2.h),
                      _section('Must have skills', skills.join(', ')),
                    ],
                    SizedBox(height: 8.h),
                  ],
                ),

                ListView(
                  padding: EdgeInsets.all(4.w),
                  children: [
                    _section(
                      'About company',
                      (job['company_description'] ??
                              'Company information not available.')
                          .toString(),
                    ),
                    SizedBox(height: 8.h),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // HELPERS
  // ------------------------------------------------------------
  Widget _infoCard({required List<Widget> children}) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: children),
    );
  }

  Widget _row(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blueGrey),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, String body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14.5.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 1.h),
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            body,
            style: TextStyle(
              fontSize: 12.sp,
              height: 1.6,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _salary(dynamic min, dynamic max) {
    int? toInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    final mn = toInt(min);
    final mx = toInt(max);

    String f(int v) => '${(v / 100000).toStringAsFixed(1)} Lacs PA';

    if (mn != null && mx != null) return '${f(mn)} - ${f(mx)}';
    if (mn != null) return f(mn);
    return 'Not disclosed';
  }

  String _postedAgo(String? date) {
    if (date == null) return 'Recently';

    final d = DateTime.tryParse(date);
    if (d == null) return 'Recently';

    final diff = DateTime.now().difference(d);

    if (diff.inHours < 24) return 'Posted today';
    if (diff.inDays == 1) return 'Posted 1 day ago';
    return 'Posted ${diff.inDays} days ago';
  }
}

/// COMPANY LOGO
class _CompanyLogo extends StatelessWidget {
  final String company;
  const _CompanyLogo({required this.company});

  @override
  Widget build(BuildContext context) {
    final letter = company.isNotEmpty ? company[0].toUpperCase() : 'C';
    final color = Colors.primaries[
        Random(company.hashCode).nextInt(Colors.primaries.length)];

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}