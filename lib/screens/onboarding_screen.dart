import 'package:flutter/material.dart';

import '../core/anim.dart';
import '../core/prefs.dart';
import '../core/theme.dart';
import 'main_shell.dart';

class _Slide {
  final String image;
  final String title;
  final String text;
  const _Slide(this.image, this.title, this.text);
}

// The photos carry their own headline, so the title here is only for accessibility.
const List<_Slide> _slides = [
  _Slide('assets/onboarding/onb_1_find.jpg', 'Find your perfect place',
      'Flats, houses, villas, PGs, plots and shops - rent or buy across Assam and India.'),
  _Slide('assets/onboarding/onb_2_trust.jpg', 'Trusted owners and agents',
      'Verified listings, real reviews and direct chat with owners. No middlemen when you do not want one.'),
  _Slide('assets/onboarding/onb_3_manage.jpg', 'List and manage easily',
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
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedScale(
            scale: active ? 1 : 0.94,
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [BoxShadow(color: Color(0x40F26B0F), blurRadius: 30, offset: Offset(0, 16))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: AspectRatio(
                  aspectRatio: 1.85,
                  child: Image.asset(
                    s.image,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
                    semanticLabel: s.title,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: const BoxDecoration(gradient: AppColors.brand),
                      alignment: Alignment.center,
                      child: Text(s.title, style: const TextStyle(color: Colors.white, fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 36),
          Text(s.text, style: AppText.bodyM.copyWith(fontSize: 16, height: 1.55), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
