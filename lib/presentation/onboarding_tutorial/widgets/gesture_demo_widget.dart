import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class GestureDemoWidget extends StatefulWidget {
  final String gestureType;
  final String gestureText;
  final bool isActive;

  const GestureDemoWidget({
    Key? key,
    required this.gestureType,
    required this.gestureText,
    required this.isActive,
  }) : super(key: key);

  @override
  State<GestureDemoWidget> createState() => _GestureDemoWidgetState();
}

class _GestureDemoWidgetState extends State<GestureDemoWidget>
    with TickerProviderStateMixin {
  late AnimationController _gestureController;
  late AnimationController _pulseController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _gestureController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.3, 0),
      end: const Offset(0.3, 0),
    ).animate(CurvedAnimation(
      parent: _gestureController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _gestureController,
      curve: const Interval(0.0, 0.3),
    ));

    if (widget.isActive) {
      _startGestureAnimation();
    }
  }

  @override
  void didUpdateWidget(GestureDemoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _startGestureAnimation();
    } else if (!widget.isActive && oldWidget.isActive) {
      _stopGestureAnimation();
    }
  }

  void _startGestureAnimation() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted && widget.isActive) {
      _gestureController.repeat(reverse: true);
      _pulseController.repeat(reverse: true);
    }
  }

  void _stopGestureAnimation() {
    _gestureController.stop();
    _pulseController.stop();
  }

  @override
  void dispose() {
    _gestureController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildGestureIcon(),
          SizedBox(width: 3.w),
          Flexible(
            child: Text(
              widget.gestureText,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGestureIcon() {
    switch (widget.gestureType) {
      case 'swipe_horizontal':
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: CustomIconWidget(
              iconName: 'swipe',
              color: Colors.white,
              size: 20,
            ),
          ),
        );

      case 'tap_favorite':
        return ScaleTransition(
          scale: _pulseAnimation,
          child: CustomIconWidget(
            iconName: 'favorite',
            color: Colors.red[300] ?? Colors.red,
            size: 20,
          ),
        );

      case 'pull_refresh':
        return AnimatedBuilder(
          animation: _gestureController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, -5 * _gestureController.value),
              child: CustomIconWidget(
                iconName: 'refresh',
                color: Colors.white,
                size: 20,
              ),
            );
          },
        );

      default:
        return CustomIconWidget(
          iconName: 'touch_app',
          color: Colors.white,
          size: 20,
        );
    }
  }
}
