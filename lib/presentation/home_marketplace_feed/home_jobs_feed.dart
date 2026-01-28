// File: lib/presentation/home_marketplace_feed/home_jobs_feed.dart
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import './widgets/top_bar_widget.dart';
import './widgets/search_bar_full_width.dart';
import './widgets/three_option_section.dart';
import './widgets/job_card_widget.dart';
import './widgets/premium_jobs_section.dart';
import '../login_screen/mobile_login_screen.dart';
import './widgets/shimmer_widgets.dart';
import './widgets/job_filter_sheet.dart';
import './widgets/job_details_page.dart';
import './widgets/profile_page.dart';
import './widgets/bottom_nav_bar_widget.dart';
import './search_page.dart';
import '../../services/job_service.dart';
import './construction_services_home_page.dart';
import 'dart:async';
import './premium_package_page.dart';
import 'widgets/job_categories_section.dart';
import '../login_screen/mobile_auth_service.dart';

class HomeJobsFeed extends StatefulWidget {
  const HomeJobsFeed({Key? key}) : super(key: key);

  @override
  State<HomeJobsFeed> createState() => _HomeJobsFeedState();
}

class _HomeJobsFeedState extends State<HomeJobsFeed> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final JobService _jobService = JobService();
  final MobileAuthService _authService = MobileAuthService();

  // Tab Controller
  late TabController _tabController;

  // Auth related state
  bool _isCheckingAuth = true;
  bool _isAuthenticatedUser = false;
  String? _currentUserId;

  int _currentIndex = 0;
  bool _isLoadingPremium = true;
  bool _isLoadingProfileJobs = true;
  bool _isLoadingActivityJobs = false;
  bool _isLoadingMore = false;
  
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _profileJobs = [];
  List<Map<String, dynamic>> _activityJobs = [];
  List<Map<String, dynamic>> _premiumJobs = [];
  
  String _selectedCategory = 'All Jobs';
  String _selectedCategoryId = 'All';
  Set<String> _savedJobIds = {};
  String _currentLocation = 'Detecting location...';

  // Profile completion
  int _profileCompletion = 0;
  List<String> _missingFields = [];

  // User coordinates
  double? _userLatitude;
  double? _userLongitude;
  bool _locationDetected = false;

  final ScrollController _scrollController = ScrollController();

  // Pagination
  int _currentOffset = 0;
  final int _pageSize = 20;
  bool _hasMoreData = true;
  bool _hasInitialLoadError = false;

  // Filter states
  String _sortBy = 'Newest';
  double _maxDistance = 50.0;
  String? _selectedJobType;
  String? _selectedWorkMode;
  int? _minSalary;
  int? _maxSalary;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeWithAuth();
    });

    Timer.periodic(Duration(minutes: 10), (timer) {
      if (mounted && _isAuthenticatedUser) {
        _authService.keepSessionAlive();
      } else if (!mounted) {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.index == 1 && _activityJobs.isEmpty && !_isLoadingActivityJobs) {
      _loadActivityJobs();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _verifyAuthState();
    }
  }

  Future<void> _initializeWithAuth() async {
    setState(() => _isCheckingAuth = true);

    try {
      await _authService.initialize();
      final isAuthenticated = _authService.isAuthenticated;
      final userId = _authService.userId;

      if (isAuthenticated && userId != null) {
        setState(() {
          _isAuthenticatedUser = true;
          _currentUserId = userId;
          _isCheckingAuth = false;
        });

        final sessionValid = await _authService.refreshSession();
        if (!sessionValid) {
          _redirectToLogin();
          return;
        }

        await _fetchData();
      } else {
        _redirectToLogin();
      }
    } catch (e) {
      debugPrint('Auth initialization error: $e');
      _redirectToLogin();
    }
  }

  Future<void> _verifyAuthState() async {
    if (!_authService.isAuthenticated) {
      _redirectToLogin();
      return;
    }

    final sessionValid = await _authService.refreshSession();
    if (!sessionValid) {
      _redirectToLogin();
    }
  }

  void _redirectToLogin() {
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => MobileLoginScreen()),
        (route) => false,
      );
    }
  }

  void _onLocationDetected(double latitude, double longitude, String locationName) {
    if (mounted) {
      setState(() {
        _userLatitude = latitude;
        _userLongitude = longitude;
        _currentLocation = locationName;
        if (!_locationDetected) {
          _locationDetected = true;
          _sortBy = 'Distance';
        }
      });
      _loadProfileJobs();
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreJobs();
    }
  }

  Future<void> _loadMoreJobs() async {
    if (!_isLoadingMore && !_isLoadingProfileJobs && _hasMoreData && _isAuthenticatedUser) {
      setState(() => _isLoadingMore = true);

      try {
        if (!_authService.isSupabaseAuthenticated) {
          final refreshed = await _authService.refreshSession();
          if (!refreshed) {
            _redirectToLogin();
            return;
          }
        }

        final currentJobs = _tabController.index == 0 ? _profileJobs : _activityJobs;
        
        List<Map<String, dynamic>> newJobs;
        if (_tabController.index == 0) {
          newJobs = await _jobService.getRecommendedJobs(
            limit: _pageSize,
            offset: currentJobs.length,
          );
        } else {
          newJobs = await _jobService.getJobsBasedOnActivity(limit: _pageSize);
        }

        if (mounted) {
          setState(() {
            if (newJobs.isEmpty) {
              _hasMoreData = false;
            } else {
              if (_tabController.index == 0) {
                _profileJobs.addAll(newJobs);
              } else {
                _activityJobs.addAll(newJobs);
              }
            }
            _isLoadingMore = false;
          });
        }
      } catch (e) {
        debugPrint('Error loading more jobs: $e');
        if (mounted) setState(() => _isLoadingMore = false);
        if (e.toString().contains('auth') || e.toString().contains('401')) {
          _verifyAuthState();
        }
      }
    }
  }

  Future<void> _fetchData() async {
    if (!_isAuthenticatedUser) return;

    setState(() {
      _isLoadingPremium = true;
      _isLoadingProfileJobs = true;
      _currentOffset = 0;
      _profileJobs = [];
      _hasInitialLoadError = false;
    });

    try {
      if (!_authService.isSupabaseAuthenticated) {
        final refreshed = await _authService.refreshSession();
        if (!refreshed) {
          _redirectToLogin();
          return;
        }
      }

      // Fetch profile completion
      try {
        final completionData = await _jobService.getProfileCompletionData();
        if (mounted) {
          setState(() {
            _profileCompletion = completionData['percentage'] ?? 0;
            _missingFields = List<String>.from(completionData['missing_fields'] ?? []);
          });
        }
      } catch (e) {
        debugPrint('Error fetching profile completion: $e');
      }

      // Fetch categories
      List<Map<String, dynamic>> categories = [];
      try {
        categories = await _jobService.getJobCategories();
      } catch (e) {
        debugPrint('Error fetching categories: $e');
      }

      // Fetch saved jobs
      Set<String> savedJobs = {};
      try {
        savedJobs = await _jobService.getUserSavedJobs();
      } catch (e) {
        debugPrint('Error fetching saved jobs: $e');
      }

      // Fetch recommended jobs
      await _loadProfileJobs();

      // Fetch premium jobs
      List<Map<String, dynamic>> premiumJobs = [];
      try {
        premiumJobs = await _jobService.fetchPremiumJobs(
          limit: 10,
          userLatitude: _userLatitude,
          userLongitude: _userLongitude,
        );
      } catch (e) {
        debugPrint('Error fetching premium jobs: $e');
      }

      if (mounted) {
        setState(() {
          _categories = categories;
          _savedJobIds = savedJobs;
          _premiumJobs = premiumJobs;
          _isLoadingPremium = false;
          if (_profileJobs.isEmpty && premiumJobs.isEmpty && categories.isEmpty) {
            _hasInitialLoadError = true;
          }
        });
      }
    } catch (e) {
      debugPrint('Unexpected error in _fetchData: $e');
      if (mounted) {
        setState(() {
          _isLoadingPremium = false;
          _isLoadingProfileJobs = false;
          _hasInitialLoadError = true;
        });
      }
      if (e.toString().contains('auth') || e.toString().contains('401')) {
        _verifyAuthState();
      }
    }
  }

  Future<void> _loadProfileJobs() async {
    if (_isLoadingProfileJobs) return;
    
    setState(() => _isLoadingProfileJobs = true);
    
    try {
      final jobs = await _jobService.getRecommendedJobs(limit: 43);
      
      if (mounted) {
        setState(() {
          _profileJobs = jobs;
          _isLoadingProfileJobs = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile jobs: $e');
      if (mounted) setState(() => _isLoadingProfileJobs = false);
    }
  }

  Future<void> _loadActivityJobs() async {
    if (_isLoadingActivityJobs) return;
    
    setState(() => _isLoadingActivityJobs = true);
    
    try {
      final jobs = await _jobService.getJobsBasedOnActivity(limit: 75);
      
      if (mounted) {
        setState(() {
          _activityJobs = jobs;
          _isLoadingActivityJobs = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading activity jobs: $e');
      if (mounted) setState(() => _isLoadingActivityJobs = false);
    }
  }

  void _onCategorySelected(String categoryName) {
    setState(() {
      _selectedCategory = categoryName;
      _selectedCategoryId = categoryName;
      _currentOffset = 0;
      _hasMoreData = true;
    });
    _loadProfileJobs();
  }

  void _toggleSaveJob(String jobId) async {
    if (!_isAuthenticatedUser) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please login to save jobs'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      if (!_authService.isSupabaseAuthenticated) {
        final refreshed = await _authService.refreshSession();
        if (!refreshed) {
          _redirectToLogin();
          return;
        }
      }

      final isSaved = await _jobService.toggleSaveJob(jobId);

      if (mounted) {
        setState(() {
          if (isSaved) {
            _savedJobIds.add(jobId);
          } else {
            _savedJobIds.remove(jobId);
          }
        });
      }
    } catch (e) {
      debugPrint('Toggle save job error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update saved jobs'), backgroundColor: Colors.red),
        );
      }
      if (e.toString().contains('auth') || e.toString().contains('401')) {
        _verifyAuthState();
      }
    }
  }

  void _openJobFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => JobFilterSheet(
        selectedCategory: _selectedCategory,
        sortBy: _sortBy,
        maxDistance: _maxDistance,
        selectedJobType: _selectedJobType,
        selectedWorkMode: _selectedWorkMode,
        minSalary: _minSalary,
        maxSalary: _maxSalary,
        onApplyFilter: (filters) {
          setState(() {
            _sortBy = filters['sortBy'];
            _maxDistance = filters['maxDistance'];
            _selectedJobType = filters['jobType'];
            _selectedWorkMode = filters['workMode'];
            _minSalary = filters['minSalary'];
            _maxSalary = filters['maxSalary'];
          });
          Navigator.pop(context);
          _loadProfileJobs();
        },
      ),
    );
  }

  void _showJobDetails(Map<String, dynamic> job) {
    _jobService.trackJobView(job['id']);
    _jobService.trackJobActivity(job['id'], 'viewed');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobDetailsPage(
          job: job,
          isSaved: _savedJobIds.contains(job['id']),
          onSaveToggle: () => _toggleSaveJob(job['id']),
        ),
      ),
    );
  }

  void _navigateToProfile() {
    if (!_isAuthenticatedUser) {
      _redirectToLogin();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfilePage()),
    );
  }

  void _navigateToConstructionServices() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ConstructionServicesHomePage()),
    );
  }

  Widget _buildProfileCompletionBanner() {
    return InkWell(
      onTap: _navigateToProfile,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Color(0xFF2563EB).withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Progress Circle
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 11.w,
                  height: 11.w,
                  child: CircularProgressIndicator(
                    value: _profileCompletion / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                    strokeWidth: 3,
                  ),
                ),
                Text(
                  '$_profileCompletion%',
                  style: TextStyle(
                    color: Color(0xFF2563EB),
                    fontSize: 9.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(width: 3.w),
            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What are you missing out?',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 0.3.h),
                  Text(
                    _missingFields.isNotEmpty
                        ? '${_missingFields.take(2).join(", ")}'
                        : 'Daily job recommendations for you',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 9.5.sp,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 4.w),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF2563EB)),
              SizedBox(height: 2.h),
              Text(
                'Verifying authentication...',
                style: TextStyle(fontSize: 11.sp, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      );
    }

    final currentJobs = _tabController.index == 0 ? _profileJobs : _activityJobs;
    final isCurrentTabLoading = _tabController.index == 0 ? _isLoadingProfileJobs : _isLoadingActivityJobs;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _verifyAuthState();
            if (_isAuthenticatedUser) {
              await _fetchData();
            }
          },
          color: Color(0xFF2563EB),
          child: CustomScrollView(
            controller: _scrollController,
            physics: AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: TopBarWidget(
                  currentLocation: _currentLocation,
                  onLocationDetected: _onLocationDetected,
                ),
              ),

              SliverToBoxAdapter(
                child: SearchBarFullWidth(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SearchPage()),
                    );
                  },
                ),
              ),

              SliverToBoxAdapter(
                child: ThreeOptionSection(
                  onConstructionTap: _navigateToConstructionServices,
                ),
              ),

              // Premium Jobs Section
              if (_premiumJobs.isNotEmpty)
                SliverToBoxAdapter(
                  child: _isLoadingPremium
                      ? ShimmerPremiumSection()
                      : PremiumJobsSection(
                          jobs: _premiumJobs,
                          onTap: _showJobDetails,
                          savedJobIds: _savedJobIds,
                          onSaveToggle: _toggleSaveJob,
                        ),
                ),

              // Categories Section
              SliverToBoxAdapter(
                child: JobCategoriesSection(
                  categories: _categories,
                  selected: _selectedCategory,
                  onSelect: _onCategorySelected,
                ),
              ),

              // Profile Completion Banner
              if (_profileCompletion < 100)
                SliverToBoxAdapter(child: _buildProfileCompletionBanner()),

              // Tabs Header
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  Container(
                    color: Colors.white,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: Color(0xFF2563EB),
                      unselectedLabelColor: Colors.grey.shade600,
                      indicatorColor: Color(0xFF2563EB),
                      indicatorWeight: 2.5,
                      labelStyle: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                      ),
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Profile'),
                              SizedBox(width: 1.w),
                              Text(
                                '(${_profileJobs.length})',
                                style: TextStyle(fontSize: 9.sp),
                              ),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Recent activity'),
                              SizedBox(width: 1.w),
                              Text(
                                '(${_activityJobs.length})',
                                style: TextStyle(fontSize: 9.sp),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Jobs List
              if (_hasInitialLoadError && currentJobs.isEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    height: 50.h,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.wifi_off, size: 15.w, color: Colors.grey),
                          SizedBox(height: 2.h),
                          Text(
                            'Unable to load jobs',
                            style: TextStyle(fontSize: 11.sp, color: Colors.grey[700]),
                          ),
                          SizedBox(height: 2.h),
                          ElevatedButton(
                            onPressed: _fetchData,
                            child: Text('Retry', style: TextStyle(fontSize: 10.sp)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (isCurrentTabLoading && currentJobs.isEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => ShimmerJobCard(),
                    childCount: 6,
                  ),
                )
              else if (currentJobs.isEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    height: 40.h,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.work_off, size: 15.w, color: Colors.grey),
                          SizedBox(height: 2.h),
                          Text(
                            'No jobs found',
                            style: TextStyle(fontSize: 11.sp, color: Colors.grey[700]),
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            'Try adjusting your preferences',
                            style: TextStyle(fontSize: 9.sp, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, index) => JobCardWidget(
                      job: currentJobs[index],
                      isSaved: _savedJobIds.contains(currentJobs[index]['id']),
                      onSaveToggle: () => _toggleSaveJob(currentJobs[index]['id']),
                      onTap: () => _showJobDetails(currentJobs[index]),
                    ),
                    childCount: currentJobs.length,
                  ),
                ),

              if (_isLoadingMore)
                SliverToBoxAdapter(
                  child: Container(
                    padding: EdgeInsets.all(2.h),
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                    ),
                  ),
                ),

              SliverPadding(padding: EdgeInsets.only(bottom: 10.h)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBarWidget(
        currentIndex: _currentIndex,
        hasMessageNotification: true,
        onTabSelected: (index) {
          setState(() => _currentIndex = index);
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SearchPage()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PremiumPackagePage()),
            );
          } else if (index == 4) {
            _navigateToProfile();
          }
        },
      ),
    );
  }
}

// Custom SliverPersistentHeaderDelegate for TabBar
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return tabBar;
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
