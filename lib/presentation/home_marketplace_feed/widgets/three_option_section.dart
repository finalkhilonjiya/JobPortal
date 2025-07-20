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
          _buildOption(
            context,
            'Apply Job',
            'assets/images/ApplyJobs.png',
            Colors.green,
            onJobsTap,
          ),
          _buildOption(
            context,
            'List Job',
            'assets/images/ListJobs.png',
            Colors.orange,
            onJobsTap,
          ),
          _buildOption(
            context,
            'Assamese Traditional',
            'assets/images/ATM.png',
            Colors.purple,
            onTraditionalTap,
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
            ClipOval(
              child: Image.asset(
                imagePath,
                width: 10.w,
                height: 10.w,
                fit: BoxFit.cover, // Ensures no blank space
              ),
            ),
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