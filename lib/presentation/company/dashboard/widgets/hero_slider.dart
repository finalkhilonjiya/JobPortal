import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HeroSlider extends StatefulWidget {
  const HeroSlider({super.key});

  @override
  State<HeroSlider> createState() => _HeroSliderState();
}

class _HeroSliderState extends State<HeroSlider> {
  final _client = Supabase.instance.client;

  bool _loading = true;
  List<Map<String, dynamic>> _slides = [];

  final PageController _controller = PageController(viewportFraction: 0.92);
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _loadSlides();
  }

  Future<void> _loadSlides() async {
    try {
      final res = await _client
          .from('slider')
          .select()
          .eq('is_active', true)
          .order('display_order', ascending: true);

      final data = (res as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      if (!mounted) return;

      setState(() {
        _slides = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _skeleton();
    }

    if (_slides.isEmpty) {
      return const SizedBox();
    }

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _controller,
            itemCount: _slides.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) {
              final slide = _slides[i];
              final imageUrl = (slide['image_url'] ?? '').toString();

              return _card(imageUrl);
            },
          ),
        ),

        const SizedBox(height: 8),

        // DOT INDICATOR
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_slides.length, (i) {
            final active = i == _current;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // SLIDE CARD
  // ------------------------------------------------------------
  Widget _card(String url) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6E8EC)),
        color: Colors.white,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),

        // ✅ FIXED FIT
        child: Image.network(
          url,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover, // 🔥 best for banner images
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
          errorBuilder: (_, __, ___) {
            return const Center(
              child: Icon(Icons.image_not_supported),
            );
          },
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // LOADING SKELETON
  // ------------------------------------------------------------
  Widget _skeleton() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}