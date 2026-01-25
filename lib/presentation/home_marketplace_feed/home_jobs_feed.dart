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
import './widgets/marketplace_helpers.dart';
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
import '../../core/app_export.dart';

class HomeJobsFeed extends StatefulWidget {
  const HomeJobsFeed({Key? key}) : super(key: key);

  @override
  State<HomeJobsFeed> createState() => _HomeJobsFeedState();
}

class _HomeJobsFeedState extends State<HomeJobsFeed> with WidgetsBindingObserver {
  final JobService _jobService = JobService();
  final MobileAuthService _authService = MobileAuthService();

  // Auth related state
  bool _isCheckingAuth = true;
  bool _isAuthenticatedUser = false;
  String? _currentUserId;

  int _currentIndex = 0;
  bool _isLoadingPremium = true;
  bool _isLoadingFeed = true;
  bool _isLoadingMore = false;
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _jobs = [];
  List<Map<String, dynamic>> _premiumJobs = [];
  String _selectedCategory = 'All Jobs';
  String _selectedCategoryId = 'All';
  Set<String> _savedJobIds = {};
  String _currentLocation = 'Detecting location...';

  // User coordinates for distance-based sorting
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
  String _priceRange = 'All';
  String _sortBy = 'Newest';
  double _maxDistance = 50.0;
  String? _selectedJobType;
  String? _selectedWorkMode;
  int? _minSalary;
  int? _maxSalary;

  @override
  void initState() {
    super.initState();
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
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _verifyAuthState();
    }
  }

  Future<void> _initializeWithAuth() async {
    setState(() {
      _isCheckingAuth = true;
    });

    try {
      await _authService.initialize();
      final isAuthenticated = _authService.isAuthenticated;
      final userId = _authService.userId;

      debugPrint('Auth Check - Authenticated: $isAuthenticated, User ID: $userId');

      if (isAuthenticated && userId != null) {
        setState(() {
          _isAuthenticatedUser = true;
          _currentUserId = userId;
          _isCheckingAuth = false;
        });

        final sessionValid = await _authService.refreshSession();
        if (!sessionValid) {
          debugPrint('Session refresh failed, redirecting to login');
          _redirectToLogin();
          return;
        }

        await _fetchData();
      } else {
        debugPrint('User not authenticated, redirecting to login');
        _redirectToLogin();
      }
    } catch (e) {
      debugPrint('Auth initialization error: $e');
      _redirectToLogin();
    }
  }

  Future<void> _verifyAuthState() async {
    if (!_authService.isAuthenticated) {
      debugPrint('Auth verification failed, redirecting to login');
      _redirectToLogin();
      return;
    }

    final sessionValid = await _authService.refreshSession();
    if (!sessionValid) {
      debugPrint('Session verification failed, redirecting to login');
      _redirectToLogin();
    }
  }

  void _redirectToLogin() {
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => MobileLoginScreen(),
        ),
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
          debugPrint('Location detected, switching default sort to Distance');
        }
      });

      debugPrint('Location updated: $locationName (Lat: $latitude, Lng: $longitude)');
      _fetchFilteredJobs();
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreJobs();
    }
  }

  Future<void> _loadMoreJobs() async {
    if (!_isLoadingMore && !_isLoadingFeed && _hasMoreData && _isAuthenticatedUser) {
      setState(() => _isLoadingMore = true);

      try {
        if (!_authService.isSupabaseAuthenticated) {
          debugPrint('Not authenticated for API call, refreshing session');
          final refreshed = await _authService.refreshSession();
          if (!refreshed) {
            _redirectToLogin();
            return;
          }
        }

        final newJobs = await _jobService.fetchJobs(
          categoryId: _selectedCategoryId == 'All' ? null : _selectedCategoryId,
          sortBy: _sortBy,
          offset: _currentOffset + _pageSize,
          limit: _pageSize,
          userLatitude: _userLatitude,
          userLongitude: _userLongitude,
          jobType: _selectedJobType,
          workMode: _selectedWorkMode,
          minSalary: _minSalary,
          maxSalary: _maxSalary,
        );

        if (mounted) {
          setState(() {
            if (newJobs.isEmpty) {
              _hasMoreData = false;
            } else {
              _jobs.addAll(newJobs);
              _currentOffset += _pageSize;
            }
            _isLoadingMore = false;
          });
        }
      } catch (e) {
        debugPrint('Error loading more jobs: $e');
        if (mounted) {
          setState(() => _isLoadingMore = false);
        }

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
      _isLoadingFeed = true;
      _currentOffset = 0;
      _jobs = [];
      _hasInitialLoadError = false;
    });

    try {
      if (!_authService.isSupabaseAuthenticated) {
        debugPrint('Supabase not authenticated, attempting refresh');
        final refreshed = await _authService.refreshSession();
        if (!refreshed) {
          debugPrint('Session refresh failed during data fetch');
          _redirectToLogin();
          return;
        }
      }

      debugPrint('Fetching data for authenticated user: $_currentUserId');

      // Fetch categories
      List<Map<String, dynamic>> categories = [];
      try {
        categories = await _jobService.getJobCategories();
        debugPrint('Fetched ${categories.length} job categories');
      } catch (e) {
        debugPrint('Error fetching categories: $e');
      }

      // Fetch saved jobs
      Set<String> savedJobs = {};
      try {
        savedJobs = await _jobService.getUserSavedJobs();
        debugPrint('Fetched ${savedJobs.length} saved jobs');
      } catch (e) {
        debugPrint('Error fetching saved jobs: $e');
      }

      // Determine sort method
      String sortMethod = _sortBy;
      if (_locationDetected && _userLatitude != null && _userLongitude != null) {
        sortMethod = 'Distance';
      } else {
        sortMethod = 'Newest';
      }

      // Fetch jobs
      List<Map<String, dynamic>> jobs = [];
      try {
        jobs = await _jobService.fetchJobs(
          sortBy: sortMethod,
          offset: 0,
          limit: _pageSize,
          userLatitude: _userLatitude,
          userLongitude: _userLongitude,
        );
        debugPrint('Fetched ${jobs.length} jobs');
      } catch (e) {
        debugPrint('Error fetching jobs: $e');
      }

      // Fetch premium jobs
      List<Map<String, dynamic>> premiumJobs = [];
      try {
        premiumJobs = await _jobService.fetchPremiumJobs(
          limit: 10,
          userLatitude: _userLatitude,
          userLongitude: _userLongitude,
        );
        debugPrint('Fetched ${premiumJobs.length} premium jobs');
      } catch (e) {
        debugPrint('Error fetching premium jobs: $e');
      }

      if (mounted) {
        setState(() {
          _categories = categories;
          _savedJobIds = savedJobs;
          _jobs = jobs;
          _premiumJobs = premiumJobs;
          _isLoadingPremium = false;
          _isLoadingFeed = false;

          if (jobs.isEmpty && premiumJobs.isEmpty && categories.isEmpty) {
            _hasInitialLoadError = true;
          }
        });
      }
    } catch (e) {
      debugPrint('Unexpected error in _fetchData: $e');
      if (mounted) {
        setState(() {
          _isLoadingPremium = false;
          _isLoadingFeed = false;
          _hasInitialLoadError = true;
        });
      }

      if (e.toString().contains('auth') || e.toString().contains('401')) {
        _verifyAuthState();
      }
    }
  }

  void _onCategorySelected(String categoryName) {
    setState(() {
      _selectedCategory = categoryName;
      _selectedCategoryId = categoryName; // For job categories, name is the ID
      _currentOffset = 0;
      _hasMoreData = true;
    });

    _fetchFilteredJobs();
  }

  Future<void> _fetchFilteredJobs() async {
    if (!_isAuthenticatedUser) return;

    setState(() {
      _isLoadingFeed = true;
      _jobs = [];
      _currentOffset = 0;
    });

    try {
      if (!_authService.isSupabaseAuthenticated) {
        final refreshed = await _authService.refreshSession();
        if (!refreshed) {
          _redirectToLogin();
          return;
        }
      }

      String sortMethod = _sortBy;
      if (_sortBy == 'Distance' && (_userLatitude == null || _userLongitude == null)) {
        sortMethod = 'Newest';
        debugPrint('Distance sort requested but no location, falling back to Newest');
      }

      final jobs = await _jobService.fetchJobs(
        categoryId: _selectedCategoryId == 'All Jobs' ? null : _selectedCategoryId,
        sortBy: sortMethod,
        offset: 0,
        limit: _pageSize,
        userLatitude: _userLatitude,
        userLongitude: _userLongitude,
        jobType: _selectedJobType,
        workMode: _selectedWorkMode,
        minSalary: _minSalary,
        maxSalary: _maxSalary,
      );

      List<Map<String, dynamic>> premiumJobs = [];
      try {
        premiumJobs = await _jobService.fetchPremiumJobs(
          categoryId: _selectedCategoryId == 'All Jobs' ? null : _selectedCategoryId,
          limit: 10,
          userLatitude: _userLatitude,
          userLongitude: _userLongitude,
        );
      } catch (e) {
        debugPrint('Error fetching filtered premium jobs: $e');
        premiumJobs = _premiumJobs;
      }

      if (mounted) {
        setState(() {
          _jobs = jobs;
          _premiumJobs = premiumJobs;
          _currentOffset = 0;
          _isLoadingFeed = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching filtered jobs: $e');
      if (mounted) {
        setState(() {
          _jobs = [];
          _isLoadingFeed = false;
        });
      }

      if (e.toString().contains('auth') || e.toString().contains('401')) {
        _verifyAuthState();
      }
    }
  }

  void _toggleSaveJob(String jobId) async {
    if (!_isAuthenticatedUser) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please login to save jobs'),
          backgroundColor: Colors.red,
        ),
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Job saved'), duration: Duration(seconds: 1)),
            );
          } else {
            _savedJobIds.remove(jobId);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Job removed'), duration: Duration(seconds: 1)),
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Toggle save job error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update saved jobs'),
            backgroundColor: Colors.red,
          ),
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
          _fetchFilteredJobs();
        },
      ),
    );
  }

  void _showJobDetails(Map<String, dynamic> job) {
    // Track view
    _jobService.trackJobView(job['id']);

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
      MaterialPageRoute(
        builder: (context) => ConstructionServicesHomePage(),
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
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      );
    }

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
                      MaterialPageRoute(
                        builder: (context) => SearchPage(),
                      ),
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

              // Filter Header
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedCategory == 'All Jobs' ? 'All Jobs' : _selectedCategory,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      InkWell(
                        onTap: _openJobFilter,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                          decoration: BoxDecoration(
                            border: Border.all(color: Color(0xFF2563EB)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.filter_list,
                                color: Color(0xFF2563EB),
                                size: 4.5.w,
                              ),
                              SizedBox(width: 1.w),
                              Text(
                                'Filter',
                                style: TextStyle(
                                  color: Color(0xFF2563EB),
                                  fontSize: 11.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Jobs List
              if (_hasInitialLoadError && _jobs.isEmpty)
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
                            style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
                          ),
                          SizedBox(height: 2.h),
                          ElevatedButton(
                            onPressed: _fetchData,
                            child: Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (_isLoadingFeed && _jobs.isEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => ShimmerJobCard(),
                    childCount: 6,
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, index) => JobCardWidget(
                      job: _jobs[index],
                      isSaved: _savedJobIds.contains(_jobs[index]['id']),
                      onSaveToggle: () => _toggleSaveJob(_jobs[index]['id']),
                      onTap: () => _showJobDetails(_jobs[index]),
                    ),
                    childCount: _jobs.length,
                  ),
                ),

              if (_isLoadingMore)
                SliverToBoxAdapter(
                  child: Container(
                    padding: EdgeInsets.all(2.h),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2563EB),
                      ),
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
  hasMessageNotification: false,
  onFabPressed: _openCreateListing,
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