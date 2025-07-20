import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AppInfoBannerNew extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF2563EB).withOpacity(0.3),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Text(
              'Welcome to khilonjiya.com',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 1.5.h),
          Text(
            '"Discover jobs, buy & sell locally, and explore the heart of Assamese tradition — all in one place."',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12.sp,
              height: 1.4,
              letterSpacing: 0.3,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildIconButton(
                'https://cdn-icons-png.flaticon.com/512/1077/1077063.png', // Replace with job seeker image
                'Apply for\nJobs',
              ),
              _buildIconButton(
                'https://cdn-icons-png.flaticon.com/512/3135/3135768.png', // Replace with job poster image
                'List Your\nJobs',
              ),
              _buildIconButton(
                'https://upload.wikimedia.org/wikipedia/commons/4/46/Japi_Assamese_traditional_headgear.jpg', // Assamese Japi
                'Assamese\nTraditional\nMarket',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(String imgUrl, String label) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: Image.network(
            imgUrl,
            fit: BoxFit.cover,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 10.sp,
            height: 1.2,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}