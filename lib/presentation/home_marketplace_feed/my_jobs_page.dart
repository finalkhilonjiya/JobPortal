import 'package:flutter/material.dart';

import '../../core/ui/khilonjiya_ui.dart';
import '../../services/job_seeker_home_service.dart';

import '../common/widgets/cards/job_card_widget.dart';
import '../common/widgets/pages/job_details_page.dart';

class MyJobsPage extends StatefulWidget {
  const MyJobsPage({Key? key}) : super(key: key);

  @override
  State<MyJobsPage> createState() => _MyJobsPageState();
}

class _MyJobsPageState extends State<MyJobsPage> {
  final JobSeekerHomeService _homeService = JobSeekerHomeService();

  bool _loading = true;
  bool _disposed = false;

  List<Map<String, dynamic>> _appliedJobs = [];
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

    // Load saved jobs for bookmark state
    try {
      _savedJobIds = await _homeService.getUserSavedJobs();
    } catch (_) {
      _savedJobIds = {};
    }

    // Load applied jobs
    try {
      _appliedJobs = await _homeService.fetchAppliedJobs(limit: 80);
    } catch (_) {
      _appliedJobs = [];
    }

    if (_disposed) return;
    setState(() => _loading = false);
  }

  // ------------------------------------------------------------
  // SAVE / UNSAVE
  // ------------------------------------------------------------
  Future<void> _toggleSaveJob(String jobId) async {
    try {
      final isSaved = await _homeService.toggleSaveJob(jobId);

      if (_disposed) return;
      setState(() {
        isSaved ? _savedJobIds.add(jobId) : _savedJobIds.remove(jobId);
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update saved job")),
      );
    }
  }

  // ------------------------------------------------------------
  // OPEN JOB DETAILS
  // ------------------------------------------------------------
  Future<void> _openJobDetails(Map<String, dynamic> job) async {
    final jobId = job['id']?.toString() ?? '';
    if (jobId.trim().isEmpty) return;

    _homeService.trackJobView(jobId);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JobDetailsPage(
          job: job,
          isSaved: _savedJobIds.contains(jobId),
          onSaveToggle: () => _toggleSaveJob(jobId),
        ),
      ),
    );

    // refresh saved state after coming back
    try {
      _savedJobIds = await _homeService.getUserSavedJobs();
    } catch (_) {}

    if (_disposed) return;
    setState(() {});
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------
  Widget _emptyState() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Container(
          decoration: KhilonjiyaUI.cardDecoration(radius: 22),
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Icon(
                Icons.description_outlined,
                size: 52,
                color: Colors.black.withOpacity(0.35),
              ),
              const SizedBox(height: 14),
              Text(
                "No applied jobs yet",
                style: KhilonjiyaUI.hTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                "When you apply to jobs, they will appear here.\nYou can track everything from one place.",
                style: KhilonjiyaUI.sub,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: KhilonjiyaUI.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: KhilonjiyaUI.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Tip: Apply to jobs from Home to start tracking.",
                        style: KhilonjiyaUI.body.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 13.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _appliedList() {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _appliedJobs.length,
        itemBuilder: (_, i) {
          final job = _appliedJobs[i];
          final jobId = job['id']?.toString() ?? '';

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: JobCardWidget(
              job: job,
              isSaved: _savedJobIds.contains(jobId),
              onSaveToggle: () => _toggleSaveJob(jobId),
              onTap: () => _openJobDetails(job),
            ),
          );
        },
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
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: KhilonjiyaUI.border)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "Applied Jobs",
                      style: KhilonjiyaUI.hTitle,
                    ),
                  ),
                  IconButton(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : (_appliedJobs.isEmpty ? _emptyState() : _appliedList()),
            ),
          ],
        ),
      ),
    );
  }
}