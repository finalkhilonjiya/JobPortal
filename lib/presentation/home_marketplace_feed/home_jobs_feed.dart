// File: lib/presentation/home_marketplace_feed/home_jobs_feed.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/ui/khilonjiya_ui.dart';
import '../../routes/app_routes.dart';
import '../../services/job_seeker_home_service.dart';
import 'package:geolocator/geolocator.dart';

import '../common/widgets/pages/job_details_page.dart';

import 'company_details_page.dart';
import 'top_companies_page.dart';

import 'recommended_jobs_page.dart';
import 'search_page.dart';

import 'expected_salary_edit_page.dart';
import 'jobs_by_salary_page.dart';

import 'latest_jobs_page.dart';
import 'jobs_nearby_page.dart';

import 'construction_services_home_page.dart';

import 'profile_edit_page.dart';

import 'widgets/naukri_drawer.dart';

import 'widgets/home_sections/ai_banner_card.dart';
import 'widgets/home_sections/profile_and_search_cards.dart';
import 'widgets/home_sections/boost_card.dart';
import 'widgets/home_sections/expected_salary_card.dart';
import 'widgets/home_sections/section_header.dart';
import 'widgets/home_sections/job_card_horizontal.dart';
import 'notifications_page.dart';

// ✅ NEW IMPORT
import '../common/widgets/cards/company_card_horizontal.dart';

// ✅ NEW PAGE
import 'jobs_posted_today_page.dart';

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

  // ------------------------------------------------------------
  // HOME SUMMARY
  // ------------------------------------------------------------
  String _profileName = "Your Profile";
  int _profileCompletion = 0;
  String _lastUpdatedText = "Updated recently";
  int _missingDetails = 0;
  int _jobsPostedToday = 0;

  // ------------------------------------------------------------
  // NOTIFICATIONS
  // ------------------------------------------------------------
  int _unreadNotifications = 0;

  // ------------------------------------------------------------
  // EXPECTED SALARY
  // ------------------------------------------------------------
  int _expectedSalaryPerMonth = 0;

  // ------------------------------------------------------------
  // JOBS + SAVED
  // ------------------------------------------------------------
  List<Map<String, dynamic>> _recommendedJobs = [];
  List<Map<String, dynamic>> _latestJobs = [];
  List<Map<String, dynamic>> _nearbyJobs = [];
  List<Map<String, dynamic>> _premiumJobs = [];
  Set<String> _savedJobIds = {};

  // ------------------------------------------------------------
  // COMPANIES
  // ------------------------------------------------------------
  List<Map<String, dynamic>> _topCompanies = [];
  bool _loadingCompanies = true;

  bool _isLoadingProfile = true;

  // ------------------------------------------------------------
  // AUTO SLIDER (DB)
  // ------------------------------------------------------------
  List<Map<String, dynamic>> _sliders = [];
  final PageController _sliderController = PageController();
  int _currentSliderIndex = 0;
  Timer? _sliderTimer;


RealtimeChannel? _notificationChannel;

  // ------------------------------------------------------------
  // Search hint slider
  // ------------------------------------------------------------
  final PageController _searchHintController = PageController();
  Timer? _searchHintTimer;

  final List<String> _searchHints = const [
    "Search jobs",
    "Find employers",
    "Search by district",
    "Search nearby jobs",
    "Search jobs by skills",
  ];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _isDisposed = true;

    _searchHintTimer?.cancel();
    _searchHintController.dispose();
    _sliderTimer?.cancel();
_sliderController.dispose();
_notificationChannel?.unsubscribe();

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
      await _homeService.updateMyCurrentLocationFromDevice();

      await _loadInitialData();
      _startSearchHintAutoSlide();
      _startSliderAutoSlide();
      _listenToNotificationChanges();
    } catch (_) {
      _redirectToStart();
    }
  }

  void _startSearchHintAutoSlide() {
    _searchHintTimer?.cancel();

    _searchHintTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_isDisposed) return;
      if (!_searchHintController.hasClients) return;

      final next = (_searchHintController.page?.round() ?? 0) + 1;

      _searchHintController.animateToPage(
        next % _searchHints.length,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOut,
      );
    });
  }


void _listenToNotificationChanges() {
  final user = _supabase.auth.currentUser;
  if (user == null) return;

  _notificationChannel = _supabase.channel('notifications_channel')
    ..onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'notifications',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: user.id,
      ),
      callback: (_) async {
        try {
          final count =
              await _homeService.getUnreadNotificationsCount();
          if (!_isDisposed && mounted) {
            setState(() => _unreadNotifications = count);
          }
        } catch (_) {}
      },
    )
    ..subscribe();
}
 void _startSliderAutoSlide() {
  _sliderTimer?.cancel();

  _sliderTimer = Timer.periodic(const Duration(seconds: 3), (_) {
    if (_isDisposed) return;
    if (!_sliderController.hasClients) return;
    if (_sliders.isEmpty) return;

    final next = (_currentSliderIndex + 1) % _sliders.length;

    _sliderController.animateToPage(
      next,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  });
}

  Future<void> _loadInitialData() async {
  if (_isDisposed) return;

  setState(() => _isCheckingAuth = false);

  try {
    // 1️⃣ Get device location first
    Position? position;

    try {
      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever) {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        // Save to profile
        await _supabase.from('user_profiles').update({
          'current_latitude': position.latitude,
          'current_longitude': position.longitude,
          'location_updated_at':
              DateTime.now().toIso8601String(),
        }).eq('id', _supabase.auth.currentUser!.id);
      }
    } catch (_) {}

    final futures = await Future.wait([
      _homeService.getHomeProfileSummary(),
      _homeService.getJobsPostedTodayCount(),
      _homeService.getExpectedSalaryPerMonth(),
      _homeService.getUserSavedJobs(),
      _homeService.fetchPremiumJobs(limit: 8),
      _homeService.getRecommendedJobs(limit: 40),
      _homeService.fetchLatestJobs(limit: 40),

      // ✅ Nearby using live GPS
      position == null
          ? _homeService.fetchLatestJobs(limit: 40)
          : _homeService.fetchJobsNearbyWithLatLng(
              userLat: position.latitude,
              userLng: position.longitude,
              limit: 40,
            ),

      _homeService.fetchTopCompanies(limit: 10),
      _homeService.getUnreadNotificationsCount(),
      _supabase
          .from('slider')
          .select()
          .eq('is_active', true)
          .eq('slider_type', 'home')
          .order('display_order', ascending: true),
    ]);

    final summary = futures[0] as Map<String, dynamic>;
    final jobsCount = futures[1] as int;
    _expectedSalaryPerMonth = futures[2] as int;
    _savedJobIds = futures[3] as Set<String>;
    _premiumJobs =
        List<Map<String, dynamic>>.from(futures[4] as List);
    _recommendedJobs =
        List<Map<String, dynamic>>.from(futures[5] as List);
    _latestJobs =
        List<Map<String, dynamic>>.from(futures[6] as List);
    _nearbyJobs =
        List<Map<String, dynamic>>.from(futures[7] as List);
    _topCompanies =
        List<Map<String, dynamic>>.from(futures[8] as List);
    _unreadNotifications = futures[9] as int;
    _sliders =
        List<Map<String, dynamic>>.from(futures[10] as List);

    _profileName =
        (summary['profileName'] ?? "Your Profile").toString();
    _profileCompletion =
        (summary['profileCompletion'] ?? 0) as int;
    _lastUpdatedText =
        (summary['lastUpdatedText'] ?? "Updated recently")
            .toString();
    _missingDetails =
        (summary['missingDetails'] ?? 0) as int;
    _jobsPostedToday = jobsCount;
  } catch (_) {
    // silent fail
  } finally {
    if (!_isDisposed && mounted) {
      setState(() {
        _isLoadingProfile = false;
        _loadingCompanies = false;
      });
    }
  }
}

  Future<void> _refreshHome() async {
    if (_isDisposed) return;

    setState(() {
      _isLoadingProfile = true;
      _loadingCompanies = true;
    });

    await _loadInitialData();
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

  void _openLatestJobsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LatestJobsPage(),
      ),
    );
  }

  void _openJobsNearbyPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const JobsNearbyPage(),
      ),
    );
  }

  void _openSearchPage() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const SearchPage(),
    ),
  );
}
  void _openTopCompaniesPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TopCompaniesPage(),
      ),
    );
  }

void _openNotificationsPage() async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const NotificationsPage(),
    ),
  );

  // Refresh unread count after returning
  try {
    final count = await _homeService.getUnreadNotificationsCount();
    if (!_isDisposed && mounted) {
      setState(() => _unreadNotifications = count);
    }
  } catch (_) {}
}

  void _openCompanyDetails(String companyId) {
    if (companyId.trim().isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CompanyDetailsPage(companyId: companyId),
      ),
    );
  }

  // ------------------------------------------------------------
  // PROFILE EDIT
  // ------------------------------------------------------------
  Future<void> _openProfileEditPage() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ProfileEditPage()),
    );

    if (updated == true) {
      await _refreshHome();
    }
  }

  // ------------------------------------------------------------
  // JOBS POSTED TODAY
  // ------------------------------------------------------------
  void _openJobsPostedTodayPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const JobsPostedTodayPage(),
      ),
    );
  }

  // ------------------------------------------------------------
  // EXPECTED SALARY FLOW
  // ------------------------------------------------------------
  Future<void> _openExpectedSalaryEditPage() async {
    if (!mounted) return;

    final result = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => ExpectedSalaryEditPage(
          initialSalaryPerMonth: _expectedSalaryPerMonth,
        ),
      ),
    );

    if (result == null) return;
    if (!mounted) return;

    setState(() => _expectedSalaryPerMonth = result);

    try {
      final fresh = await _homeService.getExpectedSalaryPerMonth();
      if (!_isDisposed && mounted) {
        setState(() => _expectedSalaryPerMonth = fresh);
      }
    } catch (_) {}
  }

  void _openJobsBySalary() {
    if (_expectedSalaryPerMonth <= 0) {
      _openExpectedSalaryEditPage();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JobsBySalaryPage(
          minMonthlySalary: _expectedSalaryPerMonth,
        ),
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
        Expanded(
          child: InkWell(
            onTap: _openSearchPage,
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
                    child: SizedBox(
                      height: 18,
                      child: PageView.builder(
                        controller: _searchHintController,
                        itemCount: _searchHints.length,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (_, i) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _searchHints[i],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: KhilonjiyaUI.sub.copyWith(
                                fontSize: 13.0,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
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

        // 🔔 Notifications
        InkWell(
          onTap: _openNotificationsPage,
          borderRadius: BorderRadius.circular(999),
          child: Stack(
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

              if (_unreadNotifications > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 2),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Center(
                      child: Text(
                        _unreadNotifications > 9
                            ? '9+'
                            : _unreadNotifications.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
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
        (_premiumJobs.isNotEmpty ? _premiumJobs : _recommendedJobs);

    final jobsForRecommendedHorizontal = earlyAccessList.take(10).toList();
    final jobsForLatestHorizontal = _latestJobs.take(10).toList();
    final jobsForNearbyHorizontal = _nearbyJobs.take(10).toList();

    return RefreshIndicator(
      onRefresh: _refreshHome,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          AIBannerCard(onTap: _openRecommendedJobsPage),
          const SizedBox(height: 14),

          ProfileAndSearchCards(
            profileName: _profileName,
            profileCompletion: _profileCompletion,
            lastUpdatedText: _lastUpdatedText,
            missingDetails: _missingDetails,
            jobsPostedToday: _jobsPostedToday,
            onProfileTap: _openProfileEditPage,
            onMissingDetailsTap: _openProfileEditPage,
            onProfileViewAllTap: _openProfileEditPage,
            onJobsPostedTodayViewAllTap: _openJobsPostedTodayPage,
          ),
          const SizedBox(height: 14),

          BoostCard(
            label: "Construction",
            title: "Khilonjiya Construction Service",
            subtitle: "Your trusted construction partner",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ConstructionServicesHomePage(),
                ),
              );
            },
          ),
          const SizedBox(height: 14),

          // ✅ FIXED: ExpectedSalaryCard only supports onTap
          ExpectedSalaryCard(
            onTap: _openJobsBySalary,
          ),
          const SizedBox(height: 18),

          SectionHeader(
            title: "Recommended jobs",
            ctaText: "View all",
            onTap: _openRecommendedJobsPage,
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 170,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: jobsForRecommendedHorizontal.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final job = jobsForRecommendedHorizontal[i];

                return JobCardHorizontal(
                  job: job,
                  onTap: () => _openJobDetails(job),
                );
              },
            ),
          ),

          const SizedBox(height: 18),

          SectionHeader(
            title: "Latest jobs",
            ctaText: "View all",
            onTap: _openLatestJobsPage,
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 170,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: jobsForLatestHorizontal.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final job = jobsForLatestHorizontal[i];

                return JobCardHorizontal(
                  job: job,
                  onTap: () => _openJobDetails(job),
                );
              },
            ),
          ),

          const SizedBox(height: 18),

          SectionHeader(
            title: "Nearby Jobs",
            ctaText: "View all",
            onTap: _openJobsNearbyPage,
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 170,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: jobsForNearbyHorizontal.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final job = jobsForNearbyHorizontal[i];

                return JobCardHorizontal(
                  job: job,
                  onTap: () => _openJobDetails(job),
                );
              },
            ),
          ),

          const SizedBox(height: 18),

          SectionHeader(
            title: "Top companies",
            ctaText: "View all",
            onTap: _openTopCompaniesPage,
          ),
          const SizedBox(height: 10),
          // ------------------------------------------------------------


          if (_loadingCompanies)
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 4,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, __) {
                  return Container(
                    width: 320,
                    decoration: KhilonjiyaUI.cardDecoration(radius: 16),
                  );
                },
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
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _topCompanies.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final c = _topCompanies[i];
                  final companyId = c['id']?.toString() ?? '';

                  return CompanyCardHorizontal(
                    company: c,
                    onTap: () => _openCompanyDetails(companyId),
                  );
                },
              ),
            ),

          const SizedBox(height: 10),
// AUTO SLIDER SECTION
// ------------------------------------------------------------
if (_sliders.isNotEmpty) ...[
  const SizedBox(height: 20),

  SizedBox(
    height: 150,
    child: PageView.builder(
      controller: _sliderController,
      itemCount: _sliders.length,
      onPageChanged: (index) {
        setState(() => _currentSliderIndex = index);
      },
      itemBuilder: (_, i) {
        final imageUrl =
            _sliders[i]['image_url']?.toString() ?? '';

        return Container(
          decoration: KhilonjiyaUI.cardDecoration(radius: 18),
          clipBehavior: Clip.antiAlias,
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
          ),
        );
      },
    ),
  ),

  const SizedBox(height: 8),

  Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(
      _sliders.length,
      (i) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: _currentSliderIndex == i ? 18 : 6,
        height: 6,
        decoration: BoxDecoration(
          color: _currentSliderIndex == i
              ? KhilonjiyaUI.primary
              : KhilonjiyaUI.border,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    ),
  ),

  const SizedBox(height: 24),
],
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
        userName: _profileName,
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
    );
  }
}