// File: screens/traditional_market/traditional_market_home_page.dart
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class TraditionalMarketHomePage extends StatefulWidget {
  const TraditionalMarketHomePage({Key? key}) : super(key: key);

  @override
  State<TraditionalMarketHomePage> createState() => _TraditionalMarketHomePageState();
}

class _TraditionalMarketHomePageState extends State<TraditionalMarketHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.purple,
        elevation: 0,
        title: Text(
          'Assamese Traditional - khilonjiya.com',
          style: TextStyle(color: Colors.white, fontSize: 16.sp),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.storefront,
              size: 20.w,
              color: Colors.purple,
            ),
            SizedBox(height: 2.h),
            Text(
              'Assamese Traditional Market',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Coming Soon!',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Traditional items and handicrafts',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
