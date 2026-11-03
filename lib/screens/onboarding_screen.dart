import 'package:flutter/material.dart';

import '../core/anim.dart';
import '../core/prefs.dart';
import '../core/theme.dart';
import 'main_shell.dart';

class _Slide {
  final IconData a;
  final IconData b;
  final IconData c;
  final String title;
  final String text;
  const _Slide(this.a, this.b, this.c, this.title, this.text);
}

const List<_Slide> _slides = [
  _Slide(Icons.home_rounded, Icons.apartment_rounded, Icons.villa_rounded, 'Find your perfect place',
      'Flats, houses, villas, PGs, plots and shops - rent or buy across Assam and India.'),
  _Slide(Icons.verified_rounded, Icons.person_pin_circle_rounded, Icons.handshake_rounded, 'Trusted owners and agents',
      'Verified listings, real reviews and direct chat with owners. No middlemen when you do not want one.'),
  _Slide(Icons.add_home_work_rounded, Icons.insights_rounded, Icons.notifications_active_rounded, 'List and manage easily',
      'Post a property in minutes, track enquiries and get alerts when new homes match your search.'),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _c = PageController();
  int _i = 0;

  Future<void> _finish() async {
    await Prefs.setOnboardingSeen();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(fadeRoute(const MainShell()));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last = _i == _slides.length - 1;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: _finish, child: const Text('Skip')),
            ),
            Expanded(
              child: PageView.builder(
                controller: _c,
                itemCount: _slides.length,
                onPageChanged: (v) => setState(() => _i = v),
                itemBuilder: (context, i) => _SlideView(_slides[i], active: i == _i),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (i) {
                final on = i == _i;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: on ? 28 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: on ? AppColors.primary : AppColors.line,
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
              child: FilledButton(
                onPressed: () {
                  if (last) {
                    _finish();
                  } else {
                    _c.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
                  }
                },
                child: Text(last ? 'Get started' : 'Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  final _Slide s;
  final bool active;
  const _SlideView(this.s, {required this.active});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 300,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: AppColors.brand,
              borderRadius: BorderRadius.circular(36),
              boxShadow: const [BoxShadow(color: Color(0x40F26B0F), blurRadius: 30, offset: Offset(0, 16))],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(top: -30, right: -30, child: _blob(150)),
                Positioned(bottom: -40, left: -20, child: _blob(120)),
                AnimatedScale(
                  scale: active ? 1 : 0.8,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutBack,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 130,
                        height: 130,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Icon(s.a, size: 64, color: AppColors.primary),
                      ),
                      Positioned(left: -58, bottom: 4, child: _mini(s.b)),
                      Positioned(right: -58, top: 4, child: _mini(s.c)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Text(s.title, style: AppText.h1.copyWith(fontSize: 26), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(s.text, style: AppText.bodyM.copyWith(fontSize: 15), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _blob(double size) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(color: Color(0x22FFFFFF), shape: BoxShape.circle),
      );

  Widget _mini(IconData i) => Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFFFFE3CC),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: Icon(i, size: 30, color: AppColors.primaryDark),
      );
}
