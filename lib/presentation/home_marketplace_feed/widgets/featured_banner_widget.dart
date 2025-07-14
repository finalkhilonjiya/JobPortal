import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../../theme/app_theme.dart';

class FeaturedBannerWidget extends StatelessWidget {
  const FeaturedBannerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final banners = [
      {
        'title': 'ELITE Giveaway',
        'subtitle': 'Rewards at Lightning Speed',
        'image': 'assets/images/banner1.png',
        'gradient': [AppTheme.secondaryLight, AppTheme.successLight],
      },
      {
        'title': 'Sell Your Car',
        'subtitle': 'Get Best Price',
        'image': 'assets/images/banner2.png',
        'gradient': [AppTheme.errorLight, AppTheme.warningLight],
      },
    ];
    return CarouselSlider(
      options: CarouselOptions(
        height: 120,
        viewportFraction: 0.9,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 5),
        enlargeCenterPage: true,
      ),
      items: banners.map((banner) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: (banner['gradient'] as List<Color>),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 16,
                top: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      banner['title'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      banner['subtitle'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Explore Now',
                        style: TextStyle(
                          color: AppTheme.primaryLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Image.asset(
                  banner['image'] as String,
                  height: 100,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}