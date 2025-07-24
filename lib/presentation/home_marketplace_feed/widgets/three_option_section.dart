import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

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
          Expanded(
            flex: 1,
            child: _buildOption(
              context,
              'Apply for Jobs',
              'assets/images/ApplyJobs.png',
              Colors.green,
              onJobsTap,
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            flex: 1,
            child: _buildOption(
              context,
              'List Jobs',
              'assets/images/ListJobs.png',
              Colors.orange,
              onJobsTap,
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            flex: 1,
            child: _buildOption(
              context,
              'Assamese Traditional Market',
              'assets/images/ATM.png',
              Colors.purple,
              onTraditionalTap,
              isExpanded: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context,
    String label,
    String imagePath,
    Color color,
    VoidCallback? onTap, {
    bool isExpanded = false,
  }) {
    return InkWell(
      onTap: () {
        if (onTap != null) {
          onTap();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$label section coming soon!')),
          );
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 16.h, // Fixed height for all cards
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.5.h),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon container with doubled size
            Container(
              width: 20.w, // Doubled from 10.w
              height: 20.w, // Doubled from 10.w
              child: ClipOval(
                child: Image.asset(
                  imagePath,
                  width: 20.w,
                  height: 20.w,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.image,
                        color: color,
                        size: 10.w,
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 1.h),
            // Text with proper constraints
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: isExpanded ? 8.sp : 9.sp, // Smaller font for longer text
                  fontWeight: FontWeight.w600,
                  color: color,
                  height: 1.2, // Line height to prevent overflow
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}