import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HeroSlider extends StatefulWidget {
  const HeroSlider({super.key});

  @override
  State<HeroSlider> createState() => _HeroSliderState();
}

class _HeroSliderState extends State<HeroSlider> {
  final PageController _controller = PageController();

  List<Map<String, dynamic>> _slides = [];
  bool _loading = true;

  Timer? _timer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadSlides();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD SLIDES
  // ============================================================
  Future<void> _loadSlides() async {
    try {
      final res = await Supabase.instance.client
          .from('slider')
          .select()
          .eq('is_active', true)
          .eq('slider_type', 'company')
          .order('display_order', ascending: true);

      _slides = (res as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      _slides = [];
    }

    if (!mounted) return;

    setState(() => _loading = false);

    if (_slides.length > 1) {
      _startAutoSlide();
    }
  }

  // ============================================================
  // AUTO SLIDER (4 SEC)
  // ============================================================
  void _startAutoSlide() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_controller.hasClients) return;

      _currentIndex++;

      if (_currentIndex >= _slides.length) {
        _currentIndex = 0;
      }

      _controller.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _shimmer();
    }

    if (_slides.isEmpty) {
      return _empty();
    }

    return AspectRatio(
      aspectRatio: 16 / 7, // 🔥 PERFECT FIT FOR YOUR IMAGES
      child: PageView.builder(
        controller: _controller,
        itemCount: _slides.length,
        onPageChanged: (i) {
          _currentIndex = i;
        },
        itemBuilder: (_, i) {
          final s = _slides[i];
          final image = s['image_url'] ?? '';

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                image,
                fit: BoxFit.cover, // 🔥 fills perfectly
                width: double.infinity,
                errorBuilder: (_, __, ___) => _empty(),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================
  Widget _empty() {
    return AspectRatio(
      aspectRatio: 16 / 7,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: const Text(
          "No slider images",
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
      ),
    );
  }

  // ============================================================
  // SHIMMER
  // ============================================================
  Widget _shimmer() {
    return AspectRatio(
      aspectRatio: 16 / 7,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}