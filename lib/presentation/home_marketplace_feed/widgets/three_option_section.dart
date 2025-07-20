// File: widgets/three_option_section.dart
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
// Import the future homepage files
// import '../../jobs/jobs_home_page.dart';
// import '../../traditional_market/traditional_market_home_page.dart';

class ThreeOptionSection extends StatelessWidget {
  final VoidCallback? onJobsTap;
  final VoidCallback? onTraditionalTap;

  const ThreeOptionSection({
    Key? key,
    this.onJobsTap,
    this.onTraditionalTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildOption(
            context,
            'Apply Job',
            Icons.work_outline,
            Colors.green,
            () {
              // Navigate to Jobs Homepage
              if (onJobsTap != null) {
                onJobsTap!();
              } else {
                // Uncomment when JobsHomePage is created
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => JobsHomePage(),
                //   ),
                // );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Jobs section coming soon!')),
                );
              }
            },
          ),
          _buildOption(
            context,
            'List Job',
            Icons.post_add,
            Colors.orange,
            () {
              // Navigate to Jobs Homepage (same page, different tab/mode)
              if (onJobsTap != null) {
                onJobsTap!();
              } else {
                // Uncomment when JobsHomePage is created
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => JobsHomePage(initialTab: 'post'),
                //   ),
                // );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Jobs section coming soon!')),
                );
              }
            },
          ),
          _buildOption(
            context,
            'Assamese Traditional',
            Icons.storefront,
            Colors.purple,
            () {
              // Navigate to Traditional Market Homepage
              if (onTraditionalTap != null) {
                onTraditionalTap!();
              } else {
                // Uncomment when TraditionalMarketHomePage is created
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => TraditionalMarketHomePage(),
                //   ),
                // );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Traditional market coming soon!')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 28.w,
        padding: EdgeInsets.symmetric(vertical: 2.h),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 7.w),
            SizedBox(height: 1.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 9.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}