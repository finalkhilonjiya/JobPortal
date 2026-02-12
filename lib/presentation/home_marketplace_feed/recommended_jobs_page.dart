import 'package:flutter/material.dart';

import '../../services/job_service.dart';
import '../../core/ui/khilonjiya_ui.dart';

import '../common/widgets/cards/job_card_widget.dart';
import '../common/widgets/pages/job_details_page.dart';

class RecommendedJobsPage extends StatefulWidget {
  const RecommendedJobsPage({Key? key}) : super(key: key);

  @override
  State<RecommendedJobsPage> createState() => _RecommendedJobsPageState();
}

class _RecommendedJobsPageState extends State<RecommendedJobsPage> {
  final JobService _jobService = JobService();

  bool _loading = true;
  bool _disposed = false;

  List<Map<String, dynamic>> _jobs = [];
  Set<String> _savedJobIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _load() async {
    if (!_disposed) setState(() => _loading = true);

    try {
      // 1) load saved jobs (for bookmark UI)
      _savedJobIds = await _jobService.getUserSavedJobs();

      // 2) load recommended jobs
      final recommended = await _jobService.getRecommendedJobs(limit: 80);

      // 3) keep only match_score >= 50 (if match_score exists)
      final strongMatches = recommended.where((j) {
        final ms = j['match_score'];
        if (ms == null) return false;
        if (ms is int) return ms >= 50;
        return int.tryParse(ms.toString()) != null &&
            int.parse(ms.toString()) >= 50;
      }).toList();

      // 4) fallback to all active jobs if no strong matches
      if (strongMatches.isEmpty) {
        _jobs = await _jobService.fetchJobs(limit: 80);
      } else {
        _jobs = strongMatches;
      }
    } catch (_) {
      // fallback
      try {
        _jobs = await _jobService.fetchJobs(limit: 80);
      } catch (_) {
        _jobs = [];
      }
    }

    if (_disposed) return;
    setState(() => _loading = false);
  }

  Future<void> _toggleSaveJob(String jobId) async {
    final isSaved = await _jobService.toggleSaveJob(jobId);

    if (_disposed) return;
    setState(() {
      isSaved ? _savedJobIds.add(jobId) : _savedJobIds.remove(jobId);
    });
  }

  void _openJobDetails(Map<String, dynamic> job) {
    _jobService.trackJobView(job['id'].toString());

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhilonjiyaUI.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: KhilonjiyaUI.border)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      "Recommended jobs",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KhilonjiyaUI.hTitle,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: _jobs.isEmpty
                          ? ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
                                const SizedBox(height: 80),
                                Icon(
                                  Icons.work_outline_rounded,
                                  size: 44,
                                  color: Colors.black.withOpacity(0.35),
                                ),
                                const SizedBox(height: 14),
                                Center(
                                  child: Text(
                                    "No jobs found",
                                    style: KhilonjiyaUI.hTitle,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Center(
                                  child: Text(
                                    "Try again later.",
                                    style: KhilonjiyaUI.sub,
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 16, 16, 16),
                              itemCount: _jobs.length,
                              itemBuilder: (_, i) {
                                final job = _jobs[i];
                                final jobId = job['id'].toString();

                                return JobCardWidget(
                                  job: job,
                                  isSaved: _savedJobIds.contains(jobId),
                                  onSaveToggle: () => _toggleSaveJob(jobId),
                                  onTap: () => _openJobDetails(job),
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}