// File: lib/presentation/home_marketplace_feed/widgets/three_option_section.dart
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ThreeOptionSection extends StatelessWidget {
  final VoidCallback? onJobsTap;
  final VoidCallback? onConstructionTap;

  const ThreeOptionSection({
    Key? key,
    this.onJobsTap,
    this.onConstructionTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        children: [
          // Top Row - Apply for Jobs | List Jobs
          Row(
            children: [
              Expanded(
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
                child: _buildOption(
                  context,
                  'List Jobs',
                  'assets/images/ListJobs.png',
                  Colors.orange,
                  onJobsTap,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          // Bottom Row - Construction Services (Full Width)
          _buildOption(
            context,
            'Khilonjiya Construction Services',
            'assets/images/construction_services.png',
            Colors.purple,
            onConstructionTap,
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
    VoidCallback? onTap,
  ) {
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
        height: 14.h,
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon container
            Container(
              width: 18.w,
              height: 18.w,
              child: ClipOval(
                child: Image.asset(
                  imagePath,
                  width: 18.w,
                  height: 18.w,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        label.contains('Apply') ? Icons.work :
                        label.contains('List') ? Icons.post_add :
                        Icons.construction,
                        color: color,
                        size: 9.w,
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 0.8.h),
            // Text
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 8.5.sp,
                  fontWeight: FontWeight.w600,
                  color: color,
                  height: 1.1,
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