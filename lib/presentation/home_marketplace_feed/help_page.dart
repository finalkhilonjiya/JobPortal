import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar('Help & support'),
      body: Padding(
        padding: EdgeInsets.all(4.w),
        child: Text(
          'For any help, contact support@khilonjiya.com',
          style: TextStyle(fontSize: 12.sp),
        ),
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
