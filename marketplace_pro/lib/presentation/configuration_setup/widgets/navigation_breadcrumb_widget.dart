import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class NavigationBreadcrumbWidget extends StatelessWidget {
  final String currentPath;

  const NavigationBreadcrumbWidget({
    Key? key,
    required this.currentPath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pathSegments = currentPath.split('/');

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: 'folder_open',
            color: Colors.grey[600]!,
            size: 4.w,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _buildBreadcrumbItems(pathSegments),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBreadcrumbItems(List<String> pathSegments) {
    final List<Widget> items = [];

    for (int i = 0; i < pathSegments.length; i++) {
      final segment = pathSegments[i];
      final isLast = i == pathSegments.length - 1;

      // Add segment
      items.add(
        Text(
          segment,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: isLast ? FontWeight.w600 : FontWeight.w500,
            color: isLast ? Colors.grey[800] : Colors.grey[600],
          ),
        ),
      );

      // Add separator if not last
      if (!isLast) {
        items.add(
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.w),
            child: CustomIconWidget(
              iconName: 'keyboard_arrow_right',
              color: Colors.grey[500]!,
              size: 3.w,
            ),
          ),
        );
      }
    }

    return items;
  }
}
