// File: lib/presentation/home_marketplace_feed/jobs_by_salary_page.dart

import 'package:flutter/material.dart';

import '../../core/ui/khilonjiya_ui.dart';
import '../../services/job_seeker_home_service.dart';

import '../common/widgets/cards/job_card_widget.dart';
import '../common/widgets/pages/job_details_page.dart';

class JobsBySalaryPage extends StatefulWidget {
  /// Monthly expected salary entered by user (INR)
  final int minMonthlySalary;

  const JobsBySalaryPage({
    Key? key,
    required this.minMonthlySalary,
  }) : super(key: key);

  @override
  State<JobsBySalaryPage> createState() => _JobsBySalaryPageState();
}

class _JobsBySalaryPageState extends State<JobsBySalaryPage> {
  final JobSeekerHomeService _homeService = JobSeekerHomeService();

  bool _loading = true;
  bool _loadingSaved = true;

  List<Map<String, dynamic>> _jobs = [];
  Set<String> _savedJobIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadingSaved = true;
    });

    try {
      // Load saved job ids first (for heart icons)
      final saved = await _homeService.getUserSavedJobs();
      _savedJobIds = saved;

      setState(() => _loadingSaved = false);

      // Load salary filtered jobs
      final jobs = await _homeService.fetchJobsByMinSalaryMonthly(
        minMonthlySalary: widget.minMonthlySalary,
        limit: 80,
      );

      setState(() {
        _jobs = jobs;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _jobs = [];
        _loading = false;
        _loadingSaved = false;
      });
    }
  }

  Future<void> _toggleSaveJob(String jobId) async {
    final isSaved = await _homeService.toggleSaveJob(jobId);

    setState(() {
      isSaved ? _savedJobIds.add(jobId) : _savedJobIds.remove(jobId);
    });
  }

  void _openJobDetails(Map<String, dynamic> job) {
    _homeService.trackJobView(job['id'].toString());

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JobDetailsPage(
          job: job,
          isSaved: _savedJobIds.contains(job['id'].toString()),
          onSaveToggle: () => _toggleSaveJob(job['id'].toString()),
        ),
      ),
    );
  }

  String _formatMoney(int v) {
    // simple Indian formatting without intl
    final s = v.toString();
    if (s.length <= 3) return s;

    final last3 = s.substring(s.length - 3);
    final rest = s.substring(0, s.length - 3);

    final restWithCommas = rest.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{2})+(?!\d))'),
      (m) => '${m[1]},',
    );

    return '$restWithCommas,$last3';
  }

  @override
  Widget build(BuildContext context) {
    final salaryText = "₹${_formatMoney(widget.minMonthlySalary)}/month";

    return Scaffold(
      backgroundColor: KhilonjiyaUI.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        titleSpacing: 0,
        title: Text(
          "Jobs ≥ $salaryText",
          style: KhilonjiyaUI.h2.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                itemCount: 7,
                itemBuilder: (_, __) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  height: 92,
                  decoration: KhilonjiyaUI.cardDecoration(radius: 16),
                ),
              )
            : _jobs.isEmpty
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(16, 40, 16, 24),
                    children: [
                      Text(
                        "No jobs found",
                        style: KhilonjiyaUI.h2.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Try lowering your expected salary or check again later.",
                        style: KhilonjiyaUI.sub,
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: _jobs.length,
                    itemBuilder: (_, i) {
                      final job = _jobs[i];
                      final jobId = job['id'].toString();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: JobCardWidget(
                          job: job,
                          isSaved: !_loadingSaved && _savedJobIds.contains(jobId),
                          onSaveToggle: () => _toggleSaveJob(jobId),
                          onTap: () => _openJobDetails(job),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}