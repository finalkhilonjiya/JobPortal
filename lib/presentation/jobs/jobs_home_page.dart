// File: screens/jobs/jobs_home_page.dart
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class JobsHomePage extends StatefulWidget {
  final String? initialTab;
  
  const JobsHomePage({Key? key, this.initialTab}) : super(key: key);

  @override
  State<JobsHomePage> createState() => _JobsHomePageState();
}

class _JobsHomePageState extends State<JobsHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Color(0xFF2563EB),
        elevation: 0,
        title: Text(
          'Jobs - khilonjiya.com',
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
              Icons.work,
              size: 20.w,
              color: Colors.green,
            ),
            SizedBox(height: 2.h),
            Text(
              'Jobs Section',
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
            if (widget.initialTab == 'post') ...[
              SizedBox(height: 2.h),
              Text(
                'Post Job Feature',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.orange,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
