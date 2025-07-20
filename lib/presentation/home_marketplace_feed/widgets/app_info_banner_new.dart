// File: widgets/app_info_banner_new.dart
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AppInfoBannerNew extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      padding: EdgeInsets.all(6.w), // Increased padding
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20), // Larger radius
        boxShadow: [
          BoxShadow(
            color: Color(0xFF2563EB).withOpacity(0.3),
            blurRadius: 16,
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
              fontSize: 24.sp, // Increased from 18.sp
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 2.h), // Increased spacing
          Text(
            'Your trusted place to find jobs, buying and selling',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16.sp, // Increased from 12.sp
              height: 1.4,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}