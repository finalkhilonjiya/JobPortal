import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/ui/khilonjiya_ui.dart';
import '../../routes/app_routes.dart';
import '../../services/job_service.dart';

import './search_page.dart';
import './widgets/job_details_page.dart';
import './widgets/naukri_drawer.dart';
import './widgets/job_card_horizontal.dart';
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

  int _profileCompletion = 0;

  List<Map<String, dynamic>> _profileJobs = [];
  List<Map<String, dynamic>> _premiumJobs = [];
  Set<String> _savedJobIds = {};

  bool _isLoadingProfile = true;

  // UI-only
  int _bottomIndex = 0;
  final TextEditingController _salaryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _salaryController.dispose();
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

  Future<void> _loadInitialData() async {
    if (_isDisposed) return;

    setState(() => _isCheckingAuth = false);

    try {
      _profileCompletion = await _jobService.calculateProfileCompletion();
      _savedJobIds = await _jobService.getUserSavedJobs();
      _premiumJobs = await _jobService.fetchPremiumJobs(limit: 8);
      _profileJobs = await _jobService.getRecommendedJobs();
    } finally {
      if (!_isDisposed) {
        setState(() => _isLoadingProfile = false);
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

    return Scaffold(
      backgroundColor: KhilonjiyaUI.bg,

      // Drawer (same functionality)
      drawer: NaukriDrawer(
        userName: 'Pankaj',
        profileCompletion: _profileCompletion,
        onClose: () => Navigator.pop(context),
      ),

      // Bottom Nav
      bottomNavigationBar: _buildBottomNav(),

      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: _isLoadingProfile
                  ? _buildLoading()
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 18),
                      children: [
                        const SizedBox(height: 14),

                        // A) Neo banner
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _neoBanner(),
                        ),

                        const SizedBox(height: 14),

                        // B) Profile + Search appearances
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _twoCardsRow(),
                        ),

                        const SizedBox(height: 14),

                        // C) Boost card
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _boostCard(),
                        ),

                        const SizedBox(height: 14),

                        // D) Expected salary
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _salaryCard(),
                        ),

                        const SizedBox(height: 18),

                        // E) Early access roles
                        _sectionHeader(
                          title: "Early access roles",
                          action: "View all",
                          onTap: () {},
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 190,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.only(left: 16),
                            itemCount: _premiumJobs.length,
                            itemBuilder: (_, i) {
                              final job = _premiumJobs[i];
                              return JobCardHorizontal(
                                job: job,
                                isSaved: _savedJobIds
                                    .contains(job['id'].toString()),
                                onSaveToggle: () =>
                                    _toggleSaveJob(job['id'].toString()),
                                onTap: () => _openJobDetails(job),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 18),

                        // F) AI interview prep
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _aiInterviewCard(),
                        ),

                        const SizedBox(height: 18),

                        // I) Jobs based on your applies
                        _sectionHeader(
                          title: "Jobs based on your applies",
                          action: "View all",
                          onTap: () {},
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 190,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.only(left: 16),
                            itemCount: _premiumJobs.length,
                            itemBuilder: (_, i) {
                              final job = _premiumJobs[i];
                              return JobCardHorizontal(
                                job: job,
                                isSaved: _savedJobIds
                                    .contains(job['id'].toString()),
                                onSaveToggle: () =>
                                    _toggleSaveJob(job['id'].toString()),
                                onTap: () => _openJobDetails(job),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 18),

                        // J) Jobs based on your profile
                        _sectionHeader(
                          title: "Jobs based on your profile",
                          action: "View all",
                          onTap: () {},
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: _profileJobs.map((job) {
                              return JobCardVertical(
                                job: job,
                                isSaved: _savedJobIds
                                    .contains(job['id'].toString()),
                                onSaveToggle: () =>
                                    _toggleSaveJob(job['id'].toString()),
                                onTap: () => _openJobDetails(job),
                              );
                            }).toList(),
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // TOP BAR (Figma-style)
  // ------------------------------------------------------------
  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: KhilonjiyaUI.border),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: const Icon(Icons.menu),
          ),

          // Search bar
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
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
                    Icon(Icons.search,
                        size: 20, color: Colors.grey.shade600),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Search for 'Remote Jobs'",
                        style: KhilonjiyaUI.sub.copyWith(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // AI icon
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const Icon(Icons.auto_awesome_outlined,
                color: KhilonjiyaUI.primary, size: 20),
          ),

          const SizedBox(width: 10),

          // Notification
          Stack(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: KhilonjiyaUI.border),
                ),
                child: const Icon(Icons.notifications_none,
                    color: KhilonjiyaUI.text, size: 22),
              ),
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 10,
                  height: 10,
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
  // LOADING
  // ------------------------------------------------------------
  Widget _buildLoading() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: 6,
      itemBuilder: (_, __) {
        return Container(
          height: 110,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: KhilonjiyaUI.cardDecoration(radius: KhilonjiyaUI.r16),
        );
      },
    );
  }

  // ------------------------------------------------------------
  // SECTION HEADER
  // ------------------------------------------------------------
  Widget _sectionHeader({
    required String title,
    required String action,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: Text(title, style: KhilonjiyaUI.hTitle)),
          InkWell(
            onTap: onTap,
            child: Text(action, style: KhilonjiyaUI.link),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // UI SECTIONS
  // ------------------------------------------------------------
  Widget _neoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "I’m Neo, your AI Job Agent.\nLet’s find your next job. Start now!",
              style: KhilonjiyaUI.body.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Icon(Icons.arrow_forward,
                color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _twoCardsRow() {
    return Row(
      children: [
        Expanded(child: _profileCard()),
        const SizedBox(width: 12),
        Expanded(child: _searchAppearancesCard()),
      ],
    );
  }

  Widget _profileCard() {
    final value = (_profileCompletion.clamp(0, 100)) / 100;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: KhilonjiyaUI.cardDecoration(radius: KhilonjiyaUI.r16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ring
          SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CircularProgressIndicator(
                    value: value,
                    strokeWidth: 4,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      KhilonjiyaUI.primary,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    "${_profileCompletion.clamp(0, 100)}%",
                    style: KhilonjiyaUI.sub.copyWith(
                      color: KhilonjiyaUI.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Text("Pankaj's profile", style: KhilonjiyaUI.cardTitle),
          const SizedBox(height: 4),
          Text("Updated 4d ago", style: KhilonjiyaUI.sub),
          const SizedBox(height: 10),
          Text("8 Missing details", style: KhilonjiyaUI.link),
        ],
      ),
    );
  }

  Widget _searchAppearancesCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: KhilonjiyaUI.cardDecoration(radius: KhilonjiyaUI.r16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "0",
            style: KhilonjiyaUI.h1.copyWith(
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text("Search appearances", style: KhilonjiyaUI.cardTitle),
          const SizedBox(height: 4),
          Text("Last 90 days", style: KhilonjiyaUI.sub),
          const SizedBox(height: 10),
          Text("View all", style: KhilonjiyaUI.link),
        ],
      ),
    );
  }

  Widget _boostCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: KhilonjiyaUI.cardDecoration(radius: KhilonjiyaUI.r16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Boost 2%",
            style: KhilonjiyaUI.sub.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Personal details help recruiters know more about you",
            style: KhilonjiyaUI.body.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton(
                onPressed: () {},
                child: const Text("Add details"),
              ),
              const Spacer(),
              Row(
                children: List.generate(4, (i) {
                  final active = i == 0;
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(left: 6),
                    decoration: BoxDecoration(
                      color: active
                          ? KhilonjiyaUI.primary
                          : const Color(0xFFE5E7EB),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _salaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: KhilonjiyaUI.cardDecoration(radius: KhilonjiyaUI.r16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Add your expected salary", style: KhilonjiyaUI.cardTitle),
                const SizedBox(height: 6),
                Text(
                  "30% of your colleagues have added their expected annual salary. Add yours now!",
                  style: KhilonjiyaUI.sub,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _salaryController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: "Eg: 7,00,000",
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: KhilonjiyaUI.border),
            ),
            child: const Icon(Icons.savings_outlined,
                color: KhilonjiyaUI.primary, size: 26),
          ),
        ],
      ),
    );
  }

  Widget _aiInterviewCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withOpacity(0.16),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    "AI-powered",
                    style: KhilonjiyaUI.sub.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Start your interview preparation for top companies",
                  style: KhilonjiyaUI.body.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "4 questions left",
                  style: KhilonjiyaUI.sub.copyWith(
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Icon(Icons.arrow_forward,
                color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // BOTTOM NAV (Figma style)
  // ------------------------------------------------------------
  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: KhilonjiyaUI.border)),
      ),
      child: BottomNavigationBar(
        currentIndex: _bottomIndex,
        onTap: (i) => setState(() => _bottomIndex = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0,
        selectedItemColor: KhilonjiyaUI.primary,
        unselectedItemColor: const Color(0xFF64748B),
        selectedFontSize: 12,
        unselectedFontSize: 12,
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
}