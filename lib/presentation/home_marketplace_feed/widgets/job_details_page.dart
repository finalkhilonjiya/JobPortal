import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../job_application_form.dart';
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
      final appliedJobs = await _jobService.getMyApplications();
      final jobId = widget.job['id'];

      _isApplied = appliedJobs.any(
        (e) => e['listing_id'] == jobId,
      );
    } catch (_) {
      _isApplied = false;
    }

    if (mounted) {
      setState(() => _checkingStatus = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;

    final jobTitle = job['job_title'] ?? 'Job';
    final company = job['company_name'] ?? 'Company';
    final location = job['district'] ?? 'Location';
    final experience = job['experience_required'] ?? 'Not specified';
    final salaryMin = job['salary_min'];
    final salaryMax = job['salary_max'];
    final description = job['job_description'] ?? '';
    final companyDesc = job['company_description'] ?? '';
    final skillsList = job['skills_required'];
    final skills = skillsList is List ? skillsList.join(', ') : '';

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            elevation: 1,
            backgroundColor: Colors.white,
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
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
              tabs: const [
                Tab(text: 'Job Details'),
                Tab(text: 'About Company'),
              ],
            ),
          ),

          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                /// JOB DETAILS
                ListView(
                  padding: EdgeInsets.all(4.w),
                  children: [
                    Text(
                      jobTitle,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      company,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 1.5.h),

                    _iconText(Icons.location_on_outlined, location),
                    _iconText(Icons.work_outline, experience),
                    _iconText(
                      Icons.currency_rupee,
                      _salary(salaryMin, salaryMax),
                    ),

                    if (skills.isNotEmpty) ...[
                      SizedBox(height: 1.h),
                      Text(
                        skills,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],

                    SizedBox(height: 2.h),
                    Divider(),

                    Text(
                      'Job description',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12.sp,
                        height: 1.6,
                      ),
                    ),

                    SizedBox(height: 12.h),
                  ],
                ),

                /// ABOUT COMPANY
                ListView(
                  padding: EdgeInsets.all(4.w),
                  children: [
                    Text(
                      'About company',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 1.2.h),
                    Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        companyDesc.isNotEmpty
                            ? companyDesc
                            : 'Company description not available.',
                        style: TextStyle(fontSize: 12.sp),
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
          padding: EdgeInsets.fromLTRB(4.w, 1.5.h, 4.w, 2.h),
          color: Colors.white,
          child: SizedBox(
            height: 44,
            child: _checkingStatus
                ? const SizedBox.shrink()
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
                            await _checkAppliedStatus();
                            setState(() => _loadingApply = false);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isApplied
                          ? Colors.grey.shade400
                          : const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: _loadingApply
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isApplied ? 'Applied' : 'Apply',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _iconText(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 0.6.h),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 11.5.sp)),
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
}