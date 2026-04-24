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

  @override
  void initState() {
    super.initState();
    _loadSlides();
  }

  Future<void> _loadSlides() async {
  try {
    final res = await Supabase.instance.client
        .from('slider')
        .select()
        .eq('is_active', true)
        .eq('slider_type', 'company') // ✅ FIXED
        .order('display_order', ascending: true);

    _slides = (res as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  } catch (_) {
    _slides = [];
  }

  if (!mounted) return;
  setState(() => _loading = false);
}

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _shimmer();
    }

    if (_slides.isEmpty) {
      return _empty();
    }

    return SizedBox(
      height: 160,
      child: PageView.builder(
        controller: _controller,
        itemCount: _slides.length,
        itemBuilder: (_, i) {
          final s = _slides[i];
          final image = s['image_url'] ?? '';

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                image,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => _empty(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _empty() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: const Text(
        "No slider images",
        style: TextStyle(color: Color(0xFF6B7280)),
      ),
    );
  }

  Widget _shimmer() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}