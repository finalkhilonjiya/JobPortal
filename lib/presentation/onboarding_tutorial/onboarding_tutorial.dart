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
    "title": "Apply for Jobs & Get Notified",
    "description": "Apply for jobs, list jobs, and get notifications when new jobs appear. Stay updated and never miss an opportunity!",
    "illustration": "https://images.unsplash.com/photo-1504384308090-c894fdcc538d?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
    "features": [
      {"icon": "work", "text": "Apply for jobs easily"},
      {"icon": "notifications", "text": "Get job alerts when listed"},
      {"icon": "add", "text": "List your jobs"}
    ],
    "gesture": "tap_notification",
    "gestureText": "Tap to get job notifications"
  },
  {
    "id": 2,
    "title": "Buy & Sell with Ease",
    "description": "Discover amazing deals and sell your items quickly in our trusted marketplace community.",
    "illustration": "https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
    "features": [
      {"icon": "shopping_cart", "text": "Browse thousands of listings"},
      {"icon": "sell", "text": "List items in minutes"},
      {"icon": "verified", "text": "Verified seller badges"}
    ],
    "gesture": "swipe_horizontal",
    "gestureText": "Swipe to browse listings"
  },
  {
    "id": 3,
    "title": "Find Your Next Stay",
    "description": "Browse rooms for rent, PGs, and property for sale with trusted listings and verified owners.",
    "illustration": "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3", // Similar aesthetic
    "features": [
      {"icon": "home", "text": "Find rooms & PGs"},
      {"icon": "real_estate_agent", "text": "Explore property listings"},
      {"icon": "verified_user", "text": "Verified owners"}
    ],
    "gesture": "zoom_in",
    "gestureText": "Tap to view room details"
  },
  {
    "id": 4,
    "title": "Safe & Secure Deals",
    "description": "Trade with confidence using our safety features, verified profiles, and secure messaging system.",
    "illustration": "https://images.unsplash.com/photo-1563013544-824ae1b704d3?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
    "features": [
      {"icon": "security", "text": "Genuine Sellers"},
      {"icon": "chat", "text": "In-app messaging"},
      {"icon": "report", "text": "Get available deals nearby"}
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
    // Removed location permission check
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
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
      // Removed location permission check
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
                  backgroundColor: Color(0xFF2563EB), // Blue
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1.2,
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
                  color: Colors.white.withValues(alpha: 0.95 * 255),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1 * 255),
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
                          backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shadowColor: AppTheme.lightTheme.colorScheme.primary
                              .withValues(alpha: 0.3 * 255),
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
