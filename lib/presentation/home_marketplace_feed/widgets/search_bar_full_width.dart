import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class SearchBarFullWidth extends StatelessWidget {
  final VoidCallback onTap;

  const SearchBarFullWidth({Key? key, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: Colors.grey[600], size: 5.w),
              SizedBox(width: 3.w),
              Text(
                'Search for items, jobs, rooms...',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}