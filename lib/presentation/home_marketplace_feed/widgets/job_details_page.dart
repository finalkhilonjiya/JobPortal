import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'dart:math';

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
  bool _loadingApply = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkAppliedStatus();
  }

  Future<void> _checkAppliedStatus() async {
    try {
      final appliedJobs = await _jobService.getUserAppliedJobs();
      final jobId = widget.job['id'];
      _isApplied =
          appliedJobs.any((e) => e['listing_id'] == jobId);
    } catch (_) {
      _isApplied = false;
    }
    if (mounted) setState(() => _checkingStatus = false);
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;

    final title = job['job_title'] ?? '';
    final company = job['company_name'] ?? '';
    final location = job['district'] ?? '';
    final experience = job['experience_required'] ?? 'Not specified';
    final salaryMin = job['salary_min'];
    final salaryMax = job['salary_max'];
    final vacancies = job['vacancies'];
    final description = job['job_description'] ?? '';
    final highlights = (job['job_highlights'] as List?) ?? [];
    final mustSkills = (job['must_have_skills'] as List?) ?? [];
    final goodSkills = (job['good_to_have_skills'] as List?) ?? [];
    final applicants = job['applicants_count'];
    final createdAt = job['created_at'];

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      body: CustomScrollView(
        slivers: [
          /// APP BAR
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
                Tab(text: 'Job Details'),
                Tab(text: 'About Company'),
              ],
            ),
          ),

          /// CONTENT
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                /// ================= JOB DETAILS =================
                ListView(
                  padding: EdgeInsets.all(4.w),
                  children: [
                    /// HEADER
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(title,
                                  style: TextStyle(
                                      fontSize: 18.sp,
                                      fontWeight:
                                          FontWeight.w700)),
                              SizedBox(height: 0.6.h),
                              Text(company,
                                  style: TextStyle(
                                      fontSize: 12.sp,
                                      color: Colors
                                          .grey.shade700)),
                              SizedBox(height: 0.4.h),
                              Text('Posted by $company',
                                  style: TextStyle(
                                      fontSize: 11.sp,
                                      color: Colors
                                          .grey.shade600)),
                              SizedBox(height: 0.6.h),
                              Row(
                                children: [
                                  if (applicants != null)
                                    Text(
                                      '$applicants applicants',
                                      style: TextStyle(
                                          fontSize: 11.sp,
                                          color: Colors
                                              .grey.shade600),
                                    ),
                                  const Spacer(),
                                  Text(
                                    _posted(createdAt),
                                    style: TextStyle(
                                        fontSize: 11.sp,
                                        color: Colors
                                            .grey.shade600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        _CompanyLogo(company: company),
                      ],
                    ),

                    SizedBox(height: 2.h),

                    /// HIGHLIGHTS
                    if (highlights.isNotEmpty)
                      Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius:
                              BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.orange.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text('Job highlights',
                                style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight:
                                        FontWeight.w600)),
                            SizedBox(height: 1.h),
                            ...highlights.map(
                              (e) => Padding(
                                padding: EdgeInsets.only(
                                    bottom: 0.6.h),
                                child: Text(
                                  '• $e',
                                  style: TextStyle(
                                      fontSize: 12.sp,
                                      color: Colors
                                          .grey.shade800),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    SizedBox(height: 2.h),

                    _infoRow(Icons.work_outline, experience),
                    if (vacancies != null)
                      _infoRow(Icons.people_outline,
                          '$vacancies vacancies'),
                    _infoRow(Icons.location_on_outlined,
                        location),
                    _infoRow(Icons.currency_rupee,
                        _salary(salaryMin, salaryMax)),

                    SizedBox(height: 2.h),
                    const Divider(),

                    _section(
                        'Must have skills', mustSkills),
                    _section(
                        'Good to have skills', goodSkills),

                    SizedBox(height: 2.h),
                    const Divider(),

                    Text('Job description',
                        style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight:
                                FontWeight.w600)),
                    SizedBox(height: 1.h),
                    Text(description,
                        style: TextStyle(
                            fontSize: 12.sp,
                            height: 1.6)),

                    SizedBox(height: 2.h),
                    _disclaimer(),
                    SizedBox(height: 12.h),
                  ],
                ),

                /// ================= ABOUT COMPANY =================
                ListView(
                  padding: EdgeInsets.all(4.w),
                  children: [
                    Text('About company',
                        style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight:
                                FontWeight.w600)),
                    SizedBox(height: 1.h),
                    Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                      child: Text(
                        job['company_description'] ??
                            'Company information not available.',
                        style: TextStyle(
                            fontSize: 12.sp,
                            height: 1.6),
                      ),
                    ),
                    SizedBox(height: 12.h),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),

      /// APPLY BUTTON
      bottomNavigationBar: SafeArea(
        child: Container(
          padding:
              EdgeInsets.fromLTRB(4.w, 1.5.h, 4.w, 2.h),
          color: Colors.white,
          child: SizedBox(
            height: 48,
            child: _checkingStatus
                ? const SizedBox.shrink()
                : ElevatedButton(
                    onPressed: _isApplied || _loadingApply
                        ? null
                        : () async {
                            setState(() =>
                                _loadingApply = true);
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    JobApplicationForm(
                                        jobId: job['id']),
                              ),
                            );
                            await _checkAppliedStatus();
                            setState(() =>
                                _loadingApply = false);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isApplied
                          ? Colors.grey
                          : const Color(0xFF4F7DF3),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(24),
                      ),
                    ),
                    child: _loadingApply
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : Text(
                            _isApplied
                                ? 'Applied'
                                : 'Apply now',
                            style: const TextStyle(
                                fontWeight:
                                    FontWeight.w600),
                          ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          SizedBox(width: 3.w),
          Expanded(
              child: Text(text,
                  style:
                      TextStyle(fontSize: 12.sp))),
        ],
      ),
    );
  }

  Widget _section(String title, List list) {
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey)),
        SizedBox(height: 0.6.h),
        Text(list.join(', '),
            style: TextStyle(fontSize: 12.sp)),
      ],
    );
  }

  Widget _disclaimer() {
    return Text(
      'Naukri does not promise a job or interview in exchange of money. '
      'Beware of frauds asking for registration fees.',
      style: TextStyle(
          fontSize: 10.sp, color: Colors.grey),
    );
  }

  String _salary(int? min, int? max) {
    String f(int v) =>
        '${(v / 100000).toStringAsFixed(1)} Lacs PA';
    if (min != null && max != null)
      return '${f(min)} - ${f(max)}';
    if (min != null) return f(min);
    return 'Not disclosed';
  }

  String _posted(String? date) {
    if (date == null) return 'Recently';
    final d = DateTime.tryParse(date);
    if (d == null) return 'Recently';
    final days = DateTime.now().difference(d).inDays;
    return days == 0 ? 'Today' : 'Posted $days d ago';
  }
}

class _CompanyLogo extends StatelessWidget {
  final String company;
  const _CompanyLogo({required this.company});

  @override
  Widget build(BuildContext context) {
    final letter =
        company.isNotEmpty ? company[0] : 'C';
    final color = Colors.primaries[
        Random(company.hashCode)
            .nextInt(Colors.primaries.length)];

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: color.withOpacity(0.3)),
      ),
      alignment: Alignment.center,
      child: Text(
        letter.toUpperCase(),
        style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            color: color),
      ),
    );
  }
}