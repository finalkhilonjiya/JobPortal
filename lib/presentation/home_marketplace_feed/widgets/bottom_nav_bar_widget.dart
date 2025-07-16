// ===== File 1: widgets/bottom_nav_bar_widget.dart (Updated) =====
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class BottomNavBarWidget extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;
  final VoidCallback onFabPressed;
  final bool hasMessageNotification;

  const BottomNavBarWidget({
    Key? key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onFabPressed,
    this.hasMessageNotification = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: BottomAppBar(
          color: Colors.white,
          shape: CircularNotchedRectangle(),
          notchMargin: 8,
          child: Container(
            height: 8.h,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home, 'Home', 0),
                _buildNavItem(Icons.search, 'Search', 1),
                SizedBox(width: 12.w), // Space for FAB
                _buildNavItem(Icons.inventory_2, 'Packages', 3),
                Stack(
                  children: [
                    _buildNavItem(Icons.person, 'Profile', 4),
                    if (hasMessageNotification)
                      Positioned(
                        top: 0,
                        right: 0,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = currentIndex == index;
    final color = isSelected ? Color(0xFF2563EB) : Colors.grey[600];
    
    return InkWell(
      onTap: () => onTabSelected(index),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 6.w,
            ),
            SizedBox(height: 0.5.h),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}