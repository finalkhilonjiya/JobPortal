import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/ui/khilonjiya_ui.dart';
import '../../routes/app_routes.dart';

import '../../services/job_seeker_home_service.dart';

import '../common/widgets/pages/job_details_page.dart';
import '../common/widgets/cards/company_card.dart';
import '../common/widgets/cards/job_card_widget.dart';

import 'recommended_jobs_page.dart';
import 'widgets/naukri_drawer.dart';

import 'widgets/home_sections/ai_banner_card.dart';
import 'widgets/home_sections/profile_and_search_cards.dart';
import 'widgets/home_sections/boost_card.dart';
import 'widgets/home_sections/expected_salary_card.dart';
import 'widgets/home_sections/section_header.dart';
import 'widgets/home_sections/mini_news_card.dart';
import 'widgets/home_sections/job_card_horizontal.dart';

class HomeJobsFeed extends StatefulWidget {
  const HomeJobsFeed({Key? key}) : super(key: key);

  @override
  State<HomeJobsFeed> createState() => _HomeJobsFeedState();
}

class _HomeJobsFeedState extends State<HomeJobsFeed> {
  final JobSeekerHomeService _homeService = JobSeekerHomeService();
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isCheckingAuth = true;
  bool _isDisposed = false;

  int _bottomIndex = 0;

  int _profileCompletion = 0;

  List<Map<String, dynamic>> _profileJobs = [];
  List<Map<String, dynamic>> _premiumJobs = [];
  Set<String> _savedJobIds = {};

  // Companies
  List<Map<String, dynamic>> _topCompanies = [];
  bool _loadingCompanies = true;

  bool _isLoadingProfile = true;

  // Minis (dummy for now)
  final List<Map<String, dynamic>> _dummyMinis = const [
    {
      "title": "Top 10 remote jobs hiring now",
      "source": "Khilonjiya Minis",
      "time": "2h ago",
    },
    {
      "title": "How to optimize your resume in 2026",
      "source": "Career Desk",
      "time": "5h ago",
    },
    {
      "title": "Interview tips for IT roles",
      "source": "Neo AI",
      "time": "1d ago",
    },
    {
      "title": "Best companies hiring in Assam",
      "source": "Jobs Radar",
      "time": "2d ago",
    },
  ];

  // Search hint rotation
  final List<String> _searchHints = const [
    "Search jobs",
    "Find employers",
    "Search by district",
    "Search by skills",
    "Search by salary",
  ];
  int _searchHintIndex = 0;

  @override
  void initState() {
    super.initState();
    _initialize();
    _startSearchHintRotation();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  // ------------------------------------------------------------
  // INIT
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

  void _startSearchHintRotation() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return false;

      setState(() {
        _searchHintIndex = (_searchHintIndex + 1) % _searchHints.length;
      });

      return true;
    });
  }

  Future<void> _loadInitialData() async {
    if (_isDisposed) return;

    setState(() => _isCheckingAuth = false);

    try {
      // Profile completion (from summary)
      final summary = await _homeService.getHomeProfileSummary();
      _profileCompletion = (summary['profileCompletion'] ?? 0) as int;

      // Saved jobs
      _savedJobIds = await _homeService.getUserSavedJobs();

      // Premium jobs
      _premiumJobs = await _homeService.fetchPremiumJobs(limit: 8);

      // Recommended jobs
      _profileJobs = await _homeService.getRecommendedJobs(limit: 40);

      // Top companies from DB
      _topCompanies = await _homeService.fetchTopCompanies(limit: 8);
    } finally {
      if (!_isDisposed) {
        setState(() {
          _isLoadingProfile = false;
          _loadingCompanies = false;
        });
      }
    }
  }

  // ------------------------------------------------------------
  // ROUTING
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
  Future<void> _toggleSaveJob(String jobId) async {
    final isSaved = await _homeService.toggleSaveJob(jobId);
    if (_isDisposed) return;

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

  void _openRecommendedJobsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RecommendedJobsPage(),
      ),
    );
  }

  // ------------------------------------------------------------
  // TOP BAR
  // ------------------------------------------------------------
  Widget _buildTopBar(BuildContext scaffoldContext) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: KhilonjiyaUI.border)),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Scaffold.of(scaffoldContext).openDrawer(),
            borderRadius: BorderRadius.circular(999),
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Icon(Icons.menu, size: 22),
            ),
          ),
          const SizedBox(width: 10),

          // Search pill (animated placeholder)
          Expanded(
            child: InkWell(
              onTap: () {
                // Step 2: open JobSearchPage
                // Keeping empty for now to avoid missing file errors.
              },
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: KhilonjiyaUI.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search,
                      size: 18,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        transitionBuilder: (child, anim) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.35),
                              end: Offset.zero,
                            ).animate(anim),
                            child: FadeTransition(
                              opacity: anim,
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          _searchHints[_searchHintIndex],
                          key: ValueKey(_searchHintIndex),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: KhilonjiyaUI.sub.copyWith(
                            fontSize: 13.0,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Assistant icon (future)
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFDBEAFE)),
            ),
            child: const Icon(
              Icons.auto_awesome_outlined,
              size: 20,
              color: KhilonjiyaUI.primary,
            ),
          ),

          const SizedBox(width: 8),

          // Notification (future)
          Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: KhilonjiyaUI.border),
                ),
                child: const Icon(
                  Icons.notifications_none_outlined,
                  size: 22,
                  color: Color(0xFF334155),
                ),
              ),
              Positioned(
                right: 9,
                top: 9,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // HOME FEED
  // ------------------------------------------------------------
  Widget _buildHomeFeed() {
    if (_isLoadingProfile) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 90,
          decoration: KhilonjiyaUI.cardDecoration(radius: 16),
        ),
      );
    }

    final earlyAccessList =
        (_premiumJobs.isNotEmpty ? _premiumJobs : _profileJobs);

    final jobsForHorizontal = earlyAccessList.take(10).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        AIBannerCard(onTap: _openRecommendedJobsPage),
        const SizedBox(height: 14),

        ProfileAndSearchCards(
          onMissingDetailsTap: () {},
          onViewAllTap: () {},
        ),
        const SizedBox(height: 14),

        BoostCard(onTap: () {}),
        const SizedBox(height: 14),

        ExpectedSalaryCard(onIconTap: () {}),
        const SizedBox(height: 18),

        // Recommended jobs horizontal
        SectionHeader(
          title: "Recommended jobs",
          ctaText: "View all",
          onTap: _openRecommendedJobsPage,
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: jobsForHorizontal.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final job = jobsForHorizontal[i];
              return JobCardHorizontal(
                job: job,
                isSaved: _savedJobIds.contains(job['id'].toString()),
                onSaveToggle: () => _toggleSaveJob(job['id'].toString()),
                onTap: () => _openJobDetails(job),
              );
            },
          ),
        ),

        const SizedBox(height: 18),

        // Top companies
        SectionHeader(
          title: "Top companies",
          ctaText: "View all",
          onTap: () {},
        ),
        const SizedBox(height: 10),

        if (_loadingCompanies)
          GridView.builder(
            itemCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.08,
            ),
            itemBuilder: (_, __) => Container(
              decoration: KhilonjiyaUI.cardDecoration(radius: 16),
              padding: const EdgeInsets.all(14),
              child: const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          )
        else if (_topCompanies.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              "No companies found",
              style: KhilonjiyaUI.sub,
            ),
          )
        else
          GridView.builder(
            itemCount: _topCompanies.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.08,
            ),
            itemBuilder: (_, i) => CompanyCard(
              company: _topCompanies[i],
              onTap: () {},
            ),
          ),

        const SizedBox(height: 18),

        // minis feed (still dummy)
        SectionHeader(
          title: "Stay informed with minis",
          ctaText: "View feed",
          onTap: () {},
        ),
        const SizedBox(height: 10),
        GridView.builder(
          itemCount: _dummyMinis.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.95,
          ),
          itemBuilder: (_, i) => MiniNewsCard(news: _dummyMinis[i]),
        ),

        const SizedBox(height: 18),

        // Jobs based on your profile (vertical)
        SectionHeader(
          title: "Jobs based on your profile",
          ctaText: "View all",
          onTap: _openRecommendedJobsPage,
        ),
        const SizedBox(height: 10),

        ..._profileJobs.take(10).map((job) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: JobCardWidget(
              job: job,
              isSaved: _savedJobIds.contains(job['id'].toString()),
              onSaveToggle: () => _toggleSaveJob(job['id'].toString()),
              onTap: () => _openJobDetails(job),
            ),
          );
        }).toList(),

        const SizedBox(height: 10),
      ],
    );
  }

  // ------------------------------------------------------------
  // BOTTOM NAV
  // ------------------------------------------------------------
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: KhilonjiyaUI.border)),
      ),
      child: BottomNavigationBar(
        currentIndex: _bottomIndex,
        onTap: (i) => setState(() => _bottomIndex = i),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        backgroundColor: Colors.white,
        selectedItemColor: KhilonjiyaUI.primary,
        unselectedItemColor: const Color(0xFF64748B),
        selectedLabelStyle: KhilonjiyaUI.sub.copyWith(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
        ),
        unselectedLabelStyle: KhilonjiyaUI.sub.copyWith(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description_outlined),
            label: "Apply",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mail_outline),
            label: "NVites",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Profile",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes_outlined),
            label: "Naukri 360",
          ),
        ],
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

    return Scaffold(
      backgroundColor: KhilonjiyaUI.bg,
      drawer: NaukriDrawer(
        userName: '',
        profileCompletion: _profileCompletion,
        onClose: () => Navigator.pop(context),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Builder(builder: (scaffoldContext) => _buildTopBar(scaffoldContext)),
            Expanded(child: _buildHomeFeed()),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }
}