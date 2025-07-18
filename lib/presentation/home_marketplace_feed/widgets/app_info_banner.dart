import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AppInfoBannerNew extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF0EA5E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF2563EB).withOpacity(0.2),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome to khilonjiya.com',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.5.h),
          Text(
            'A place where you can find and list jobs, rooms, properties, electronics, and Assamese traditional items. All sellers on this platform are verified for your safety and trust.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 11.sp,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
