import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/job_service.dart';
import '../job_application_form.dart';

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
  bool _checking = true;
  bool _loadingApply = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkApplied();
  }

  Future<void> _checkApplied() async {
    try {
      final apps = await _jobService.getUserAppliedJobs();
      _isApplied =
          apps.any((e) => e['listing_id'] == widget.job['id']);
    } catch (_) {}
    if (mounted) setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;

    final title = job['job_title'] ?? '';
    final company = job['company_name'] ?? '';
    final postedAgo = job['created_at'] ?? '';
    final location = job['district'] ?? '';
    final experience = job['experience_required'] ?? '';
    final salaryMin = job['salary_min'];
    final salaryMax = job['salary_max'];
    final vacancies = job['vacancies'];
    final duration = job['duration'];
    final startInfo = job['start_info'];
    final description = job['job_description'] ?? '';
    final companyDesc = job['company_description'] ?? '';
    final mustSkills = job['skills_required'];
    final goodSkills = job['good_to_have_skills'];

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      /// APPLY BUTTON (FIXED)
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: EdgeInsets.all(4.w),
          color: Colors.white,
          child: SizedBox(
            height: 48,
            child: _checking
                ? const SizedBox()
                : ElevatedButton(
                    onPressed: _isApplied || _loadingApply
                        ? null
                        : () async {
                            setState(() => _loadingApply = true);
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    JobApplicationForm(jobId: job['id']),
                              ),
                            );
                            await _checkApplied();
                            setState(() => _loadingApply = false);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isApplied
                          ? Colors.grey.shade400
                          : const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
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

      body: CustomScrollView(
        slivers: [
          /// APP BAR + TABS
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 1,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  widget.isSaved
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                  color: Colors.black,
                ),
                onPressed: widget.onSaveToggle,
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.orange,
              tabs: const [
                Tab(text: 'Details'),
                Tab(text: 'About Company'),
              ],
            ),
          ),

          /// HEADER ABOVE TABS
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(4.w, 3.h, 4.w, 2.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LogoBox(company: company),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 0.6.h),
                        Text(
                          company,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        SizedBox(height: 0.6.h),
                        Text(
                          'Posted ${_ago(postedAgo)}',
                          style: TextStyle(
                            fontSize: 10.5.sp,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// TAB CONTENT
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                /// DETAILS TAB
                ListView(
                  padding: EdgeInsets.all(4.w),
                  children: [
                    _InfoCard(children: [
                      if (duration != null)
                        _iconRow(Icons.schedule, duration),
                      if (startInfo != null)
                        _iconRow(Icons.calendar_today, startInfo),
                      if (vacancies != null)
                        _iconRow(Icons.people, '$vacancies vacancies'),
                      _iconRow(Icons.location_on, location),
                      _iconRow(
                        Icons.currency_rupee,
                        _salary(salaryMin, salaryMax),
                      ),
                      if (mustSkills != null)
                        _skillsBlock(
                            'Must have skills', mustSkills),
                      if (goodSkills != null)
                        _skillsBlock(
                            'Good to have skills', goodSkills),
                    ]),
                    SizedBox(height: 2.h),
                    _SectionTitle('Description'),
                    _TextCard(description),
                    SizedBox(height: 2.h),
                    _MetaCard(job),
                    SizedBox(height: 10.h),
                  ],
                ),

                /// ABOUT COMPANY TAB
                ListView(
                  padding: EdgeInsets.all(4.w),
                  children: [
                    _SectionTitle('About company'),
                    _TextCard(
                      companyDesc.isNotEmpty
                          ? companyDesc
                          : 'Company details not available.',
                    ),
                    SizedBox(height: 10.h),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ---------- UI HELPERS ----------

  Widget _iconRow(IconData icon, String text) {
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

  Widget _skillsBlock(String title, dynamic list) {
    final skills =
        list is List ? list.join(', ') : list.toString();
    return Padding(
      padding: EdgeInsets.only(top: 1.5.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 0.4.h),
          Text(
            skills,
            style: TextStyle(fontSize: 12.sp),
          ),
        ],
      ),
    );
  }

  Widget _SectionTitle(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _TextCard(String text) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12.sp, height: 1.6),
      ),
    );
  }

  Widget _InfoCard({required List<Widget> children}) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  Widget _MetaCard(Map<String, dynamic> job) {
    return _InfoCard(children: [
      _metaRow('Industry type', job['industry']),
      _metaRow('Department', job['department']),
      _metaRow('Role', job['role']),
      _metaRow('Employment type', job['employment_type']),
      _metaRow('Education', job['education']),
    ]);
  }

  Widget _metaRow(String label, dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return const SizedBox();
    }
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5.sp,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 0.2.h),
          Text(
            value.toString(),
            style: TextStyle(fontSize: 12.sp),
          ),
        ],
      ),
    );
  }

  String _salary(int? min, int? max) {
    String f(int v) =>
        '${(v / 100000).toStringAsFixed(1)} Lacs PA';
    if (min != null && max != null) return '${f(min)} - ${f(max)}';
    if (min != null) return f(min);
    return 'Not disclosed';
  }

  String _ago(String? date) {
    if (date == null) return '';
    final d = DateTime.tryParse(date);
    if (d == null) return '';
    final days = DateTime.now().difference(d).inDays;
    return days == 0 ? 'Today' : '$days d ago';
  }
}

/// LOGO PLACEHOLDER
class _LogoBox extends StatelessWidget {
  final String company;

  const _LogoBox({required this.company});

  @override
  Widget build(BuildContext context) {
    final letter =
        company.isNotEmpty ? company[0].toUpperCase() : 'C';
    final color = Colors.primaries[
        Random(company.hashCode).nextInt(Colors.primaries.length)];

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 24.sp,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}