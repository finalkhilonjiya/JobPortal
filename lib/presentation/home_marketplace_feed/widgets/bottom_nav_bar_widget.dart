// File: widgets/bottom_nav_bar_widget.dart
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class BottomNavBarWidget extends StatelessWidget {
  final int currentIndex;
  final bool hasMessageNotification;
  final Function(int) onTabSelected;
  final VoidCallback onFabPressed;

  const BottomNavBarWidget({
    Key? key,
    required this.currentIndex,
    required this.hasMessageNotification,
    required this.onTabSelected,
    required this.onFabPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8.h,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 8,
        child: Container(
          height: 8.h,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Home', 0),
              _buildNavItem(Icons.search, 'Search', 1),
              SizedBox(width: 10.w), // Space for FAB
              _buildNavItem(Icons.chat_bubble_outline, 'Chat', 3, hasNotification: hasMessageNotification),
              _buildNavItem(Icons.person_outline, 'Profile', 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, {bool hasNotification = false}) {
    final isSelected = currentIndex == index;
    return InkWell(
      onTap: () => onTabSelected(index),
      child: Container(
        width: 15.w,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: isSelected ? Color(0xFF2563EB) : Colors.grey,
                  size: 6.w,
                ),
                if (hasNotification)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      width: 2.w,
                      height: 2.w,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 0.5.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 9.sp,
                color: isSelected ? Color(0xFF2563EB) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}