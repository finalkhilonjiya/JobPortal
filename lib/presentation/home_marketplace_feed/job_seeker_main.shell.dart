import 'package:flutter/material.dart';

import '../../common/widgets/khilonjiya_bottom_nav.dart';

import 'home_jobs_feed.dart';
import 'saved_jobs_page.dart';
import 'recommended_jobs_page.dart';
import 'profile_performance_page.dart';
import 'job_search_page.dart';

class JobSeekerMainShell extends StatefulWidget {
  const JobSeekerMainShell({Key? key}) : super(key: key);

  @override
  State<JobSeekerMainShell> createState() => _JobSeekerMainShellState();
}

class _JobSeekerMainShellState extends State<JobSeekerMainShell> {
  int _index = 0;

  // IMPORTANT:
  // We keep pages in memory so it feels fast and world-class.
  // Home feed won't reload every time you switch tabs.
  late final List<Widget> _pages = [
    const HomeJobsFeed(), // Home
    const JobSearchPage(), // My Jobs (for now using your job_search_page.dart)
    const _MessagesPlaceholderPage(), // Messages (blank for now)
    const SavedJobsPage(), // Saved
    const ProfilePerformancePage(), // Profile (read-only style page)
  ];

  void _onTap(int i) {
    if (i == _index) return;
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      bottomNavigationBar: KhilonjiyaBottomNav(
        currentIndex: _index,
        onTap: _onTap,
      ),
    );
  }
}

// ------------------------------------------------------------
// TEMP MESSAGES PAGE (BLANK)
// ------------------------------------------------------------
class _MessagesPlaceholderPage extends StatelessWidget {
  const _MessagesPlaceholderPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Text(
            "Messages will be added here later",
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}