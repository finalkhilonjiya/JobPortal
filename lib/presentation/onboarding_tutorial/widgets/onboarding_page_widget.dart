import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import './feature_list_widget.dart';
import './gesture_demo_widget.dart';

class OnboardingPageWidget extends StatefulWidget {
  final Map<String, dynamic> data;
  final bool isActive;

  const OnboardingPageWidget({
    Key? key,
    required this.data,
    required this.isActive,
  }) : super(key: key);

  @override
  State<OnboardingPageWidget> createState() => _OnboardingPageWidgetState();
}

class _OnboardingPageWidgetState extends State<OnboardingPageWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    if (widget.isActive) {
      _startAnimations();
    }
  }

  @override
  void didUpdateWidget(OnboardingPageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _startAnimations();
    }
  }

  void _startAnimations() async {
    _slideController.reset();
    _scaleController.reset();

    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      _slideController.forward();
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) {
        _scaleController.forward();
      }
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.w),
        child: Column(
          children: [
            SizedBox(height: 8.h),

            // Main illustration
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 80.w,
                height: 35.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CustomImageWidget(
                        imageUrl: widget.data["illustration"] as String,
                        width: 80.w,
                        height: 35.h,
                        fit: BoxFit.cover,
                      ),

                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.3),
                            ],
                          ),
                        ),
                      ),

                      // Gesture demonstration overlay
                      Positioned(
                        bottom: 4.h,
                        left: 4.w,
                        right: 4.w,
                        child: GestureDemoWidget(
                          gestureType: widget.data["gesture"] as String,
                          gestureText: widget.data["gestureText"] as String,
                          isActive: widget.isActive,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 6.h),

            // Content section
            SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  // Title
                  Text(
                    widget.data["title"] as String,
                    style:
                        AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 2.h),

                  // Description
                  Text(
                    widget.data["description"] as String,
                    style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 4.h),

                  // Features list
                  FeatureListWidget(
                    features: (widget.data["features"] as List)
                        .map((feature) => feature as Map<String, dynamic>)
                        .toList(),
                    isActive: widget.isActive,
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.h), // Space for bottom navigation
          ],
        ),
      ),
    );
  }
}
