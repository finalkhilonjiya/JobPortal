import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ProfilePerformancePage extends StatelessWidget {
  const ProfilePerformancePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar('Profile performance'),
      body: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          children: [
            _metric('Profile views', '128'),
            _metric('Job applications', '14'),
            _metric('Recruiter actions', '6'),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12.sp)),
          Text(value,
              style:
                  TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  AppBar _appBar(String t) => AppBar(
        title: Text(t),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      );
}
