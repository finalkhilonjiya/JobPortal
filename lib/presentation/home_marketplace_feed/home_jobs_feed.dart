import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './widgets/top_bar_widget.dart';
import './widgets/job_card_widget.dart';
import './widgets/shimmer_widgets.dart';
import './widgets/job_details_page.dart';
import './widgets/naukri_drawer.dart';

import '../../routes/app_routes.dart';
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
  final SupabaseClient _supabase = Supabase.instance.client;

  late final TabController _tabController;

  bool _isCheckingAuth = true;
  bool _isDisposed = false;

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

  @override
  void dispose() {
    _isDisposed = true;
    _tabController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // INIT (NO MobileAuthService)
  // ------------------------------------------------------------
  Future<void> _initialize() async {
    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        _redirectToStart();
        return;
      }

      await _loadInitialData();
    } catch (_) {
      _redirectToStart();
    }
  }

  Future<void> _loadInitialData() async {
    if (_isDisposed) return;

    setState(() => _isCheckingAuth = false);

    try {
      _profileCompletion = await _jobService.calculateProfileCompletion();
      _savedJobIds = await _jobService.getUserSavedJobs();
      _premiumJobs = await _jobService.fetchPremiumJobs(limit: 5);
      _profileJobs = await _jobService.getRecommendedJobs();
    } finally {
      if (!_isDisposed) {
        setState(() => _isLoadingProfile = false);
      }
    }
  }

  // ------------------------------------------------------------
  // ROUTING (ALWAYS SAME START PAGE)
  // ------------------------------------------------------------
  void _redirectToStart() {
    if (_isDisposed) return;
    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.roleSelection,
      (_) => false,
    );
  }

  // ------------------------------------------------------------
  // UI EVENTS
  // ------------------------------------------------------------
  void _onLocationDetected(
    double lat,
    double lng,
    String locationName,
  ) {
    if (_isDisposed) return;
    setState(() => _currentLocation = locationName);
  }

  Future<void> _toggleSaveJob(String jobId) async {
    final isSaved = await _jobService.toggleSaveJob(jobId);
    if (_isDisposed) return;

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

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final jobs = _tabController.index == 0 ? _profileJobs : _activityJobs;

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
            /// TOP BAR
            Builder(
              builder: (scaffoldContext) {
                return TopBarWidget(
                  currentLocation: _currentLocation,
                  onMenuTap: () => Scaffold.of(scaffoldContext).openDrawer(),
                  onSearchTap: () {
                    Navigator.push(
                      scaffoldContext,
                      MaterialPageRoute(
                        builder: (_) => const SearchPage(),
                      ),
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
                onTap: (index) async {
                  if (index == 1 && _activityJobs.isEmpty) {
                    setState(() => _isLoadingActivity = true);

                    try {
                      _activityJobs = await _jobService.getJobsBasedOnActivity();
                    } finally {
                      if (!_isDisposed) {
                        setState(() => _isLoadingActivity = false);
                      }
                    }
                  }
                },
              ),
            ),

            /// JOB LIST
            Expanded(
              child: _isLoadingProfile
                  ? ListView.builder(
                      itemCount: 6,
                      itemBuilder: (_, __) => const ShimmerJobCard(),
                    )
                  : ListView.builder(
                      itemCount: _premiumJobs.length + jobs.length,
                      itemBuilder: (_, index) {
                        final job = index < _premiumJobs.length
                            ? _premiumJobs[index]
                            : jobs[index - _premiumJobs.length];

                        return JobCardWidget(
                          job: job,
                          isSaved: _savedJobIds.contains(job['id'].toString()),
                          onSaveToggle: () =>
                              _toggleSaveJob(job['id'].toString()),
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