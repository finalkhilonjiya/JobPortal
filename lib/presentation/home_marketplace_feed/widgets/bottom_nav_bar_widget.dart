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
      height: 9.5.h, // Increased slightly to prevent overflow
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
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(Icons.home, 'Home', 0),
              _buildNavItem(Icons.search, 'Search', 1),
              SizedBox(width: 12.w), // Space for FAB
              _buildNavItem(Icons.star_outline, 'Package', 3),
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
      child: SizedBox(
        width: 16.w,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: isSelected ? Color(0xFF2563EB) : Colors.grey,
                  size: 5.5.w, // Slightly reduced to fit better
                ),
                if (index == 2 && hasMessageNotification)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 1.8.w,
                      height: 1.8.w,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 0.3.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 8.5.sp, // Slightly reduced font size
                color: isSelected ? Color(0xFF2563EB) : Colors.grey,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}