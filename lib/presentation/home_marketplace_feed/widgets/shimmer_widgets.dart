// ===== File 4: widgets/marketplace/shimmer_widgets.dart =====
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sizer/sizer.dart';

class ShimmerPremiumSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 25.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
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
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(height: 14.h, color: Colors.white),
        ),
      ),
    );
  }
}
