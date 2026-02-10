import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../routes/app_routes.dart';
import '../../services/job_service.dart';

import './search_page.dart';
import './widgets/job_details_page.dart';
import './widgets/naukri_drawer.dart';
import './widgets/shimmer_widgets.dart';

// NEW UI widgets (we created in steps)
import '../../core/ui/khilonjiya_ui.dart';
import './widgets/home_sections/ai_banner_card.dart';
import './widgets/home_sections/profile_and_search_cards.dart';
import './widgets/home_sections/boost_card.dart';
import './widgets/home_sections/expected_salary_card.dart';
import './widgets/home_sections/ai_interview_prep_card.dart';
import './widgets/home_sections/section_header.dart';
import './widgets/home_sections/mini_news_card.dart';
import './widgets/home_sections/company_card.dart';
import './widgets/home_sections/job_card_horizontal.dart';
import './widgets/job_card_vertical.dart';

class HomeJobsFeed extends StatefulWidget {
  const HomeJobsFeed({Key? key}) : super(key: key);

  @override
  State<HomeJobsFeed> createState() => _HomeJobsFeedState();
}

class _HomeJobsFeedState extends State<HomeJobsFeed> {
  final JobService _jobService = JobService();
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isCheckingAuth = true;
  bool _isDisposed = false;

  int _bottomIndex = 0;

  String _currentLocation = 'Detecting...';
  int _profileCompletion = 0;

  List<Map<String, dynamic>> _profileJobs = [];
  List<Map<String, dynamic>> _premiumJobs = [];
  Set<String> _savedJobIds = {};

  bool _isLoadingProfile = true;

  // Dummy sections data (UI only now)
  final List<Map<String, dynamic>> _dummyCompanies = [
    {"name": "TCS", "rating": 3.7, "reviews": "1.2L", "tag": "Corporate"},
    {"name": "Infosys", "rating": 3.6, "reviews": "90K", "tag": "Corporate"},
    {"name": "Accenture", "rating": 4.1, "reviews": "65K", "tag": "Foreign MNC"},
    {"name": "Amazon", "rating": 4.2, "reviews": "40K", "tag": "Foreign MNC"},
  ];

  final List<Map<String, dynamic>> _dummyMinis = [
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

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  // ------------------------------------------------------------
  // INIT (NO MobileAuthService) - KEEP SAME
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
  // ROUTING (KEEP SAME)
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
  // UI EVENTS (KEEP SAME)
  // ------------------------------------------------------------
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
  // TOP BAR (FIGMA)
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

          // Search pill
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.push(
                  scaffoldContext,
                  MaterialPageRoute(builder: (_) => const SearchPage()),
                );
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
                    const Icon(Icons.search,
                        size: 18, color: Color(0xFF64748B)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Search for 'Remote Jobs'",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: KhilonjiyaUI.sub.copyWith(
                          fontSize: 13.0,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Assistant icon
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

          // Notification with red dot
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
  // FIGMA SECTIONS (HOME FEED)
  // ------------------------------------------------------------
  Widget _buildHomeFeed() {
    if (_isLoadingProfile) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        itemCount: 6,
        itemBuilder: (_, __) => const ShimmerJobCard(),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        // A) AI banner
        const AIBannerCard(),

        const SizedBox(height: 14),

        // B) profile + search appearance cards
        ProfileAndSearchCards(profileCompletion: _profileCompletion),

        const SizedBox(height: 14),

        // C) boost card
        const BoostCard(),

        const SizedBox(height: 14),

        // D) expected salary
        const ExpectedSalaryCard(),

        const SizedBox(height: 18),

        // E) early access roles (horizontal)
        SectionHeader(
          title: "Early access roles",
          action: "View all",
          onTap: () {},
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: (_premiumJobs.isNotEmpty ? _premiumJobs : _profileJobs)
                .take(8)
                .length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final list =
                  (_premiumJobs.isNotEmpty ? _premiumJobs : _profileJobs);
              final job = list[i];
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

        // F) AI interview prep
        const AIInterviewPrepCard(),

        const SizedBox(height: 18),

        // G) top companies
        SectionHeader(
          title: "Top companies",
          action: "View all",
          onTap: () {},
        ),
        const SizedBox(height: 10),
        GridView.builder(
          itemCount: _dummyCompanies.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.08,
          ),
          itemBuilder: (_, i) => CompanyCard(data: _dummyCompanies[i]),
        ),

        const SizedBox(height: 18),

        // H) minis feed
        SectionHeader(
          title: "Stay informed with minis",
          action: "View feed",
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
          itemBuilder: (_, i) => MiniNewsCard(data: _dummyMinis[i]),
        ),

        const SizedBox(height: 18),

        // I) jobs based on your applies (horizontal)
        SectionHeader(
          title: "Jobs based on your applies",
          action: "View all",
          onTap: () {},
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _profileJobs.take(10).length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final job = _profileJobs[i];
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

        // J) jobs based on your profile (vertical list)
        SectionHeader(
          title: "Jobs based on your profile",
          action: "View all",
          onTap: () {},
        ),
        const SizedBox(height: 10),

        ..._profileJobs.take(10).map((job) {
          return JobCardVertical(
            job: job,
            isSaved: _savedJobIds.contains(job['id'].toString()),
            onSaveToggle: () => _toggleSaveJob(job['id'].toString()),
            onTap: () => _openJobDetails(job),
          );
        }).toList(),

        const SizedBox(height: 10),
      ],
    );
  }

  // ------------------------------------------------------------
  // BOTTOM NAV (FIGMA)
  // ------------------------------------------------------------
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: KhilonjiyaUI.border)),
      ),
      child: BottomNavigationBar(
        currentIndex: _bottomIndex,
        onTap: (i) {
          setState(() => _bottomIndex = i);

          // For now: only UI
          // Later: we will connect routes
        },
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
            Builder(
              builder: (scaffoldContext) {
                return _buildTopBar(scaffoldContext);
              },
            ),
            Expanded(child: _buildHomeFeed()),
          ],
        ),
      ),

      bottomNavigationBar: _buildBottomNav(),
    );
  }
}