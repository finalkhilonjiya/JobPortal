import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/job_service.dart';
import '../common/widgets/cards/job_card_widget.dart';

class SavedJobsPage extends StatefulWidget {
  const SavedJobsPage({Key? key}) : super(key: key);

  @override
  State<SavedJobsPage> createState() => _SavedJobsPageState();
}

class _SavedJobsPageState extends State<SavedJobsPage> {
  final JobService _jobService = JobService();
  List<Map<String, dynamic>> _jobs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _jobs = await _jobService.getSavedJobs();
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar('Saved jobs'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _jobs.isEmpty
              ? _empty('No saved jobs')
              : ListView.builder(
                  itemCount: _jobs.length,
                  itemBuilder: (_, i) => JobCardWidget(
                    job: _jobs[i],
                    isSaved: true,
                    onSaveToggle: _load,
                    onTap: () {},
                  ),
                ),
    );
  }

  AppBar _appBar(String t) => AppBar(
        title: Text(t),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      );

  Widget _empty(String text) =>
      Center(child: Text(text, style: TextStyle(fontSize: 12.sp)));
}