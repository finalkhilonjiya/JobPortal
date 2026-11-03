import 'dart:async';
import 'package:flutter/material.dart';

import '../core/anim.dart';
import '../core/config.dart';
import '../core/prefs.dart';
import '../services/api.dart';
import '../widgets/housing_mark.dart';
import 'main_shell.dart';
import 'onboarding_screen.dart';

const Color _splashOrange = Color(0xFFF26B0F);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _mark =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));
  late final AnimationController _text =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
  late final AnimationController _ring =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    final started = DateTime.now();
    _mark.forward();
    Timer(const Duration(milliseconds: 900), () {
      if (mounted) _text.forward();
    });

    try {
      await Prefs.init();
      await Api.bootstrap();
    } catch (_) {}

    final elapsed = DateTime.now().difference(started).inMilliseconds;
    final wait = 2500 - elapsed;
    if (wait > 0) await Future<void>.delayed(Duration(milliseconds: wait));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      fadeRoute(Prefs.onboardingSeen ? const MainShell() : const OnboardingScreen()),
    );
  }

  @override
  void dispose() {
    _mark.dispose();
    _text.dispose();
    _ring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _splashOrange,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // soft expanding rings
          AnimatedBuilder(
            animation: _ring,
            builder: (context, _) => CustomPaint(painter: _RingPainter(_ring.value)),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00FFFFFF), Color(0x22000000)],
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _mark,
                  builder: (context, _) {
                    final t = Curves.easeOutCubic.transform(_mark.value);
                    return Transform.scale(
                      scale: 0.85 + 0.15 * t,
                      child: HousingMark(size: 112, progress: t),
                    );
                  },
                ),
                const SizedBox(height: 26),
                AnimatedBuilder(
                  animation: _text,
                  builder: (context, _) {
                    final t = Curves.easeOutCubic.transform(_text.value);
                    return Opacity(
                      opacity: t,
                      child: Transform.translate(
                        offset: Offset(0, (1 - t) * 14),
                        child: Column(children: [
                          Text(
                            AppInfo.name,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 38,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Find your place',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              color: Color(0xE6FFFFFF),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ]),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 46,
            child: FadeTransition(
              opacity: _text,
              child: const Text(
                'RENT  ·  BUY  ·  SELL',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xB3FFFFFF), letterSpacing: 3, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double t;
  _RingPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2 - 20);
    final maxR = size.longestSide * 0.7;
    for (int i = 0; i < 3; i++) {
      final v = (t + i / 3) % 1.0;
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Color.fromARGB((46 * (1 - v)).round(), 255, 255, 255);
      canvas.drawCircle(c, 60 + v * maxR, p);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.t != t;
}
