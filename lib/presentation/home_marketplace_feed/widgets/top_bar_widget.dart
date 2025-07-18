import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class TopBarWidget extends StatelessWidget {
  final String currentLocation;
  final VoidCallback onLocationTap;

  const TopBarWidget({
    Key? key,
    required this.currentLocation,
    required this.onLocationTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          Row(
            children: [
              Container(
                width: 10.w,
                height: 10.w,
                decoration: BoxDecoration(
                  color: Color(0xFF2563EB),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    'K',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Text(
                'khilonjiya',
                style: TextStyle(
                  color: Color(0xFF2563EB),
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          // Location
          InkWell(
            onTap: onLocationTap,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: Color(0xFF2563EB).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: Color(0xFF2563EB), size: 4.5.w),
                  SizedBox(width: 1.w),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 30.w),
                    child: Text(
                      currentLocation,
                      style: TextStyle(
                        color: Color(0xFF2563EB),
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
