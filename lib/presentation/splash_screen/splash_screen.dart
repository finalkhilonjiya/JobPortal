import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../utils/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _gradientAnimationController;
  late Animation<double> _gradientAnimation;
  
  bool _isInitializing = true;
  bool _hasError = false;
  String _errorMessage = '';
  double _initializationProgress = 0.0;

  // Beautiful gradient colors for khilonjiya.com
  final List<Color> _gradientColors = [
    const Color(0xFF6366F1), // Indigo
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFFEC4899), // Pink
    const Color(0xFFF59E0B), // Amber
    const Color(0xFF10B981), // Emerald
    const Color(0xFF3B82F6), // Blue
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    _gradientAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _gradientAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _gradientAnimationController,
      curve: Curves.easeInOut,
    ));

    // Start the gradient animation and repeat
    _gradientAnimationController.forward();
    _gradientAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _gradientAnimationController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _gradientAnimationController.forward();
      }
    });
  }

  Future<void> _initializeApp() async {
    try {
      await _performInitializationSteps();

      if (mounted) {
        await _navigateToNextScreen();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to initialize app. Please try again.';
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _performInitializationSteps() async {
    final steps = [
      'Initializing Supabase...',
      'Checking authentication status...',
      'Loading user preferences...',
      'Preparing cached data...',
      'Finalizing setup...',
    ];

    for (int i = 0; i < steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 400));

      // Actual initialization on first step
      if (i == 0) {
        try {
          await SupabaseService.initialize();
        } catch (e) {
          debugPrint('Supabase initialization error: $e');
        }
      }

      if (mounted) {
        setState(() {
          _initializationProgress = (i + 1) / steps.length;
        });
      }
    }
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    final isAuthenticated = await _checkAuthenticationStatus();
    final isFirstTime = await _checkFirstTimeUser();

    String nextRoute;
    if (isFirstTime) {
      nextRoute = AppRoutes.onboardingTutorial;
    } else if (isAuthenticated) {
      nextRoute = AppRoutes.homeMarketplaceFeed;
    } else {
      nextRoute = AppRoutes.loginScreen;
    }

    if (mounted) {
      Navigator.pushReplacementNamed(context, nextRoute);
    }
  }

  Future<bool> _checkAuthenticationStatus() async {
    try {
      return AuthService().isAuthenticated();
    } catch (e) {
      debugPrint('Auth check error: $e');
      return false;
    }
  }

  Future<bool> _checkFirstTimeUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasCompletedOnboarding = prefs.getBool('has_completed_onboarding');
      return hasCompletedOnboarding == null || !hasCompletedOnboarding;
    } catch (e) {
      debugPrint('First time check error: $e');
      return true;
    }
  }

  void _retryInitialization() {
    setState(() {
      _hasError = false;
      _isInitializing = true;
      _initializationProgress = 0.0;
    });
    _initializeApp();
  }

  Color _getGradientColor(double progress) {
    final colorIndex = (progress * (_gradientColors.length - 1));
    final lowerIndex = colorIndex.floor();
    final upperIndex = (lowerIndex + 1) % _gradientColors.length;
    final t = colorIndex - lowerIndex;
    
    return Color.lerp(_gradientColors[lowerIndex], _gradientColors[upperIndex], t) ?? _gradientColors[0];
  }

  @override
  void dispose() {
    _gradientAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: SafeArea(
          child: _hasError ? _buildErrorView() : _buildSplashContent(),
        ),
      ),
    );
  }

  Widget _buildSplashContent() {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _gradientAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getGradientColor(_gradientAnimation.value),
                    _getGradientColor((_gradientAnimation.value + 0.3) % 1.0),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            );
          },
        ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 10.h),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                  gradient: LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF6366F1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    'K',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
              SizedBox(height: 3.h),
              Text(
                'Welcome to khilonjiya.com',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 1.5.h),
              Text(
                'Your trusted Assamese marketplace',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.white.withOpacity(0.92),
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 6.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: LinearProgressIndicator(
                  value: _isInitializing ? _initializationProgress : null,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              SizedBox(height: 2.h),
              if (_isInitializing)
                Text(
                  'Loading... Please wait',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontFamily: 'Poppins',
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedAppName() {
    return AnimatedBuilder(
      animation: _gradientAnimation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                _getGradientColor(_gradientAnimation.value),
                _getGradientColor((_gradientAnimation.value + 0.3) % 1.0),
                _getGradientColor((_gradientAnimation.value + 0.6) % 1.0),
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: Text(
            'khilonjiya.com',
            style: TextStyle(
              fontSize: 8.5.w,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: Colors.white,
              shadows: [
                Shadow(
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                  color: Colors.black.withValues(alpha: 0.1 * 255),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTagline() {
    return Column(
      children: [
        // Assamese text
        Text(
          'আমাৰ সংস্কৃতি, আমাৰ গৌৰৱ',
          style: TextStyle(
            fontSize: 4.2.w,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B7280),
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 0.8.h),
        // English translation
        Text(
          'Our Culture, Our Pride',
          style: TextStyle(
            fontSize: 3.8.w,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF9CA3AF),
            letterSpacing: 0.8,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      width: 70.w,
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: _initializationProgress,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF3B82F6), // Blue-500
                Color(0xFF1D4ED8), // Blue-700
              ],
            ),
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.3 * 255),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressText() {
    return Text(
      _isInitializing ? 'Loading your marketplace...' : 'Ready to explore!',
      style: TextStyle(
        fontSize: 3.5.w,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF6B7280),
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: const Color(0xFFFECACA),
                  width: 2,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.error_outline,
                  color: const Color(0xFFEF4444),
                  size: 10.w,
                ),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Connection Error',
              style: TextStyle(
                fontSize: 5.5.w,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            Text(
              _errorMessage,
              style: TextStyle(
                fontSize: 4.w,
                color: const Color(0xFF6B7280),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            ElevatedButton.icon(
              onPressed: _retryInitialization,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: 8.w,
                  vertical: 2.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
              icon: Icon(
                Icons.refresh,
                size: 5.w,
              ),
              label: Text(
                'Try Again',
                style: TextStyle(
                  fontSize: 4.w,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}