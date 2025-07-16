// ===== File 1: widgets/search_bar_widget.dart =====
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class SearchBarWidget extends StatelessWidget {
  final VoidCallback onTap;
  
  const SearchBarWidget({Key? key, required this.onTap}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: Colors.grey[600], size: 5.w),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  'Search for items, locations...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11.sp,
                  ),
                ),
              ),
              Icon(Icons.filter_list, color: Colors.grey[600], size: 5.w),
            ],
          ),
        ),
      ),
    );
  }
}