// File: lib/presentation/home_marketplace_feed/widgets/job_details_page.dart

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;

    final jobTitle = job['job_title'] ?? '';
    final company = job['company_name'] ?? '';
    final location = job['district'] ?? '';
    final experience = job['experience_required'] ?? '';
    final salaryMin = job['salary_min'];
    final salaryMax = job['salary_max'];
    final description = job['job_description'] ?? '';
    final skills = (job['skills_required'] as List?)?.join(', ') ?? '';
    final createdAt = job['created_at'];
    final companyDesc = job['company_description'] ?? '';

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      body: CustomScrollView(
        slivers: [
          /// COLLAPSING HEADER
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
              IconButton(
                icon: const Icon(Icons.share, color: Colors.black),
                onPressed: () {
                  Share.share(
                    '$jobTitle at $company\nLocation: $location',
                  );
                },
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Job Details'),
                Tab(text: 'About Company'),
              ],
            ),
          ),

          /// TAB CONTENT
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                /// ================= JOB DETAILS =================
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
                    SizedBox(height: 0.6.h),
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
                    _iconText(Icons.currency_rupee, _salary(salaryMin, salaryMax)),

                    if (skills.isNotEmpty) ...[
                      SizedBox(height: 1.2.h),
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
                        color: Colors.grey.shade800,
                      ),
                    ),

                    SizedBox(height: 2.h),
                    Text(
                      _posted(createdAt),
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    /// -------- SIMILAR JOBS --------
                    SizedBox(height: 3.h),
                    Text(
                      'Similar jobs',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 1.h),

                    _similarJob('Desktop Support Engineer', 'Aforeserve'),
                    _similarJob('System Administrator', 'TechNova'),
                    _similarJob('IT Support Executive', 'Infratech'),

                    SizedBox(height: 12.h),
                  ],
                ),

                /// ================= ABOUT COMPANY =================
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            companyDesc.isNotEmpty
                                ? companyDesc
                                : 'Company description not available.',
                            style: TextStyle(
                              fontSize: 12.sp,
                              height: 1.6,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          _labelValue('Company Name', company),
                          _labelValue('Location', location),
                        ],
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

      /// APPLY BUTTON (NAUKRI SIZE)
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 3.h),
        color: Colors.white,
        child: SizedBox(
          height: 7.h,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              'Apply now',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ================= HELPERS =================
  Widget _iconText(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 0.6.h),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 11.5.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _labelValue(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 30.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 11.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _similarJob(String title, String company) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 1.4.h),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 0.3.h),
          Text(
            company,
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.grey.shade700,
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
    if (date == null) return 'Recently';
    final d = DateTime.tryParse(date);
    if (d == null) return 'Recently';
    final days = DateTime.now().difference(d).inDays;
    return days == 0 ? 'Today' : '${days}d ago';
  }
}