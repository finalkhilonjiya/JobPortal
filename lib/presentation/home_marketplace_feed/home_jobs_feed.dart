import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import './widgets/top_bar_widget.dart';
import './widgets/job_card_widget.dart';
import './widgets/shimmer_widgets.dart';
import './widgets/job_details_page.dart';
import './widgets/naukri_drawer.dart';

import '../login_screen/mobile_login_screen.dart';
import '../login_screen/mobile_auth_service.dart';

import '../../services/job_service.dart';

import './search_page.dart';

class HomeJobsFeed extends StatefulWidget {
  const HomeJobsFeed({Key? key}) : super(key: key);

  @override
  State<HomeJobsFeed> createState() => _HomeJobsFeedState();
}

class _HomeJobsFeedState extends State<HomeJobsFeed>
    with SingleTickerProviderStateMixin {
  final JobService _jobService = JobService();
  final MobileAuthService _authService = MobileAuthService();

  late TabController _tabController;

  bool _isCheckingAuth = true;

  String _currentLocation = 'Detecting...';
  int _profileCompletion = 0;

  List<Map<String, dynamic>> _profileJobs = [];
  List<Map<String, dynamic>> _activityJobs = [];
  List<Map<String, dynamic>> _premiumJobs = [];
  Set<String> _savedJobIds = {};

  bool _isLoadingProfile = true;
  bool _isLoadingActivity = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _authService.initialize();
      if (!_authService.isAuthenticated) {
        _redirectToLogin();
        return;
      }

      await _authService.refreshSession();
      await _loadInitialData();
    } catch (_) {
      _redirectToLogin();
    }
  }

  Future<void> _loadInitialData() async {
    setState(() => _isCheckingAuth = false);

    _profileCompletion =
        await _jobService.calculateProfileCompletion();

    _savedJobIds = await _jobService.getUserSavedJobs();

    _premiumJobs = await _jobService.fetchPremiumJobs(limit: 5);

    _profileJobs = await _jobService.getRecommendedJobs();

    setState(() => _isLoadingProfile = false);
  }

  /// ✅ CORRECT + USED
  void _redirectToLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => MobileLoginScreen()),
      (_) => false,
    );
  }

  void _onLocationDetected(
      double lat, double lng, String locationName) {
    setState(() => _currentLocation = locationName);
  }

  void _toggleSaveJob(String jobId) async {
    final isSaved = await _jobService.toggleSaveJob(jobId);
    setState(() {
      isSaved ? _savedJobIds.add(jobId) : _savedJobIds.remove(jobId);
    });
  }

  void _openJobDetails(Map<String, dynamic> job) {
    _jobService.trackJobView(job['id']); // ✅ fixed

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JobDetailsPage(
          job: job,
          isSaved: _savedJobIds.contains(job['id']),
          onSaveToggle: () => _toggleSaveJob(job['id']),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final jobs =
        _tabController.index == 0 ? _profileJobs : _activityJobs;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,

      drawer: NaukriDrawer(
        userName: '',
        profileCompletion: _profileCompletion,
        onClose: () => Navigator.pop(context),
      ),

      body: SafeArea(
        child: Column(
          children: [
            /// TOP BAR (drawer-safe)
            Builder(
              builder: (scaffoldContext) {
                return TopBarWidget(
                  currentLocation: _currentLocation,
                  onMenuTap: () =>
                      Scaffold.of(scaffoldContext).openDrawer(),
                  onSearchTap: () {
                    Navigator.push(
                      scaffoldContext,
                      MaterialPageRoute(
                          builder: (_) => SearchPage()),
                    );
                  },
                  onLocationDetected: _onLocationDetected,
                );
              },
            ),

            /// TABS
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.blue,
                tabs: const [
                  Tab(text: 'Profile'),
                  Tab(text: 'Recent activity'),
                ],
                onTap: (i) async {
                  if (i == 1 && _activityJobs.isEmpty) {
                    setState(() => _isLoadingActivity = true);
                    _activityJobs =
                        await _jobService.getJobsBasedOnActivity();
                    setState(() => _isLoadingActivity = false);
                  }
                },
              ),
            ),

            /// JOB LIST
            Expanded(
              child: _isLoadingProfile
                  ? ListView.builder(
                      itemCount: 6,
                      itemBuilder: (_, __) =>
                          const ShimmerJobCard(),
                    )
                  : ListView.builder(
                      itemCount:
                          _premiumJobs.length + jobs.length,
                      itemBuilder: (_, index) {
                        final job = index < _premiumJobs.length
                            ? _premiumJobs[index]
                            : jobs[index - _premiumJobs.length];

                        return JobCardWidget(
                          job: job,
                          isSaved:
                              _savedJobIds.contains(job['id']),
                          onSaveToggle: () =>
                              _toggleSaveJob(job['id']),
                          onTap: () => _openJobDetails(job),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}