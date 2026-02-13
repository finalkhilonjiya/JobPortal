import 'package:flutter/material.dart';

import '../../core/ui/khilonjiya_ui.dart';
import '../../services/job_seeker_home_service.dart';

import '../common/widgets/cards/job_card_widget.dart';
import '../common/widgets/pages/job_details_page.dart';

class SavedJobsPage extends StatefulWidget {
  const SavedJobsPage({Key? key}) : super(key: key);

  @override
  State<SavedJobsPage> createState() => _SavedJobsPageState();
}

class _SavedJobsPageState extends State<SavedJobsPage> {
  final JobSeekerHomeService _homeService = JobSeekerHomeService();

  List<Map<String, dynamic>> _jobs = [];
  bool _loading = true;
  bool _disposed = false;

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
      _jobs = await _homeService.getSavedJobs();
    } catch (_) {
      _jobs = [];
    }

    if (_disposed) return;
    setState(() => _loading = false);
  }

  Future<void> _toggleSaveJob(String jobId) async {
    try {
      await _homeService.toggleSaveJob(jobId);
      await _load(); // refresh list after unsave
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update saved job")),
      );
    }
  }

  Future<void> _openJobDetails(Map<String, dynamic> job) async {
    final jobId = job['id']?.toString() ?? '';
    if (jobId.trim().isEmpty) return;

    // track view (fire and forget)
    _homeService.trackJobView(jobId);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JobDetailsPage(
          job: job,
          isSaved: true,
          onSaveToggle: () => _toggleSaveJob(jobId),
        ),
      ),
    );

    // refresh saved list when coming back
    await _load();
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
                      "Saved jobs",
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
                                  Icons.bookmark_border_rounded,
                                  size: 44,
                                  color: Colors.black.withOpacity(0.35),
                                ),
                                const SizedBox(height: 14),
                                Center(
                                  child: Text(
                                    "No saved jobs",
                                    style: KhilonjiyaUI.hTitle,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Center(
                                  child: Text(
                                    "Save jobs you like and they will appear here.",
                                    style: KhilonjiyaUI.sub,
                                    textAlign: TextAlign.center,
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
                                final jobId = job['id']?.toString() ?? '';

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: JobCardWidget(
                                    job: job,
                                    isSaved: true,
                                    onSaveToggle: () => _toggleSaveJob(jobId),
                                    onTap: () => _openJobDetails(job),
                                  ),
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