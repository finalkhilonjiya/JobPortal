import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/onboarding_page_widget.dart';
import './widgets/page_indicator_widget.dart';

class OnboardingTutorial extends StatefulWidget {
  const OnboardingTutorial({Key? key}) : super(key: key);

  @override
  State<OnboardingTutorial> createState() => _OnboardingTutorialState();
}

class _OnboardingTutorialState extends State<OnboardingTutorial>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _currentPage = 0;
  bool _isAnimating = false;

  final List<Map<String, dynamic>> _onboardingData = [
    {
      "id": 1,
      "title": "Buy & Sell with Ease",
      "description":
          "Discover amazing deals and sell your items quickly in our trusted marketplace community.",
      "illustration":
          "https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
      "features": [
        {"icon": "shopping_cart", "text": "Browse thousands of listings"},
        {"icon": "sell", "text": "List items in minutes"},
        {"icon": "verified", "text": "Verified seller badges"}
      ],
      "gesture": "swipe_horizontal",
      "gestureText": "Swipe to browse listings"
    },
    {
      "id": 2,
      "title": "Find Items Near You",
      "description":
          "Use location-based search to discover great deals in your neighborhood and nearby areas.",
      "illustration":
          "https://images.unsplash.com/photo-1524661135-423995f22d0b?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
      "features": [
        {"icon": "location_on", "text": "GPS-powered search"},
        {"icon": "map", "text": "Interactive map view"},
        {"icon": "near_me", "text": "Distance-based results"}
      ],
      "gesture": "tap_favorite",
      "gestureText": "Tap ♥ to save favorites"
    },
    {
      "id": 3,
      "title": "Safe & Secure Trading",
      "description":
          "Trade with confidence using our safety features, verified profiles, and secure messaging system.",
      "illustration":
          "https://images.unsplash.com/photo-1563013544-824ae1b704d3?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
      "features": [
        {"icon": "security", "text": "Secure transactions"},
        {"icon": "chat", "text": "In-app messaging"},
        {"icon": "report", "text": "Report & block users"}
      ],
      "gesture": "pull_refresh",
      "gestureText": "Pull down to refresh"
    }
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
    _checkLocationPermission();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _checkLocationPermission() async {
    // Simulate location permission check
    if (_currentPage == 1) {
      // Show location permission dialog when on location screen
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        _showLocationPermissionDialog();
      }
    }
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              CustomIconWidget(
                iconName: 'location_on',
                color: AppTheme.lightTheme.primaryColor,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Text(
                'Location Access',
                style: AppTheme.lightTheme.textTheme.titleMedium,
              ),
            ],
          ),
          content: Text(
            'Allow MarketPlace Pro to access your location to find items near you and provide better search results.',
            style: AppTheme.lightTheme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Not Now',
                style: TextStyle(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showLocationGrantedFeedback();
              },
              child: const Text('Allow'),
            ),
          ],
        );
      },
    );
  }

  void _showLocationGrantedFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            CustomIconWidget(
              iconName: 'check_circle',
              color: AppTheme.getSuccessColor(true),
              size: 20,
            ),
            SizedBox(width: 2.w),
            const Text('Location access granted!'),
          ],
        ),
        backgroundColor: AppTheme.getSuccessColor(true),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _nextPage() async {
    if (_isAnimating) return;

    _isAnimating = true;
    HapticFeedback.lightImpact();

    if (_currentPage < _onboardingData.length - 1) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      if (_currentPage == 1) {
        _checkLocationPermission();
      }
    } else {
      _completeOnboarding();
    }

    _isAnimating = false;
  }

  void _skipOnboarding() {
    HapticFeedback.lightImpact();
    _completeOnboarding();
  }

  void _completeOnboarding() {
    // Mark onboarding as completed (in real app, save to SharedPreferences)
    Navigator.pushReplacementNamed(context, '/login-screen');
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });

    // Restart animation for new page
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: _onboardingData.length,
              itemBuilder: (context, index) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: OnboardingPageWidget(
                    data: _onboardingData[index],
                    isActive: index == _currentPage,
                  ),
                );
              },
            ),

            // Skip button
            Positioned(
              top: 2.h,
              right: 4.w,
              child: TextButton(
                onPressed: _skipOnboarding,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  'Skip',
                  style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),

            // Bottom navigation area
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Page indicator
                    PageIndicatorWidget(
                      currentPage: _currentPage,
                      totalPages: _onboardingData.length,
                    ),

                    SizedBox(height: 4.h),

                    // Action button
                    SizedBox(
                      width: double.infinity,
                      height: 6.h,
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.lightTheme.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shadowColor: AppTheme.lightTheme.primaryColor
                              .withValues(alpha: 0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentPage == _onboardingData.length - 1
                                  ? 'Get Started'
                                  : 'Next',
                              style: AppTheme.lightTheme.textTheme.titleMedium
                                  ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (_currentPage < _onboardingData.length - 1) ...[
                              SizedBox(width: 2.w),
                              CustomIconWidget(
                                iconName: 'arrow_forward',
                                color: Colors.white,
                                size: 20,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 2.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
