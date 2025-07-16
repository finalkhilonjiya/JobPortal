
// ===== File 3: widgets/shimmer_widgets.dart (Updated) =====
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sizer/sizer.dart';

class ShimmerPremiumSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 3.w),
        itemCount: 3,
        itemBuilder: (_, __) => Container(
          width: 85.w,
          margin: EdgeInsets.only(right: 3.w),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

class ShimmerProductCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
      height: 15.h,
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(color: Colors.white),
        ),
      ),
    );
  }
}