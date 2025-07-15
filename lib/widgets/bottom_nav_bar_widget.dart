import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../theme/app_theme.dart';

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
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          margin: EdgeInsets.only(bottom: 2.5.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(context, 0, Icons.home_rounded, 'Home'),
                _buildNavItem(context, 1, Icons.search_rounded, 'Search'),
                SizedBox(width: 14.w), // Space for FAB
                _buildNavItem(context, 3, Icons.card_giftcard_rounded, 'Packages'),
                _buildNavItem(context, 4, Icons.person_rounded, 'Profile', hasNotification: hasMessageNotification),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          child: SizedBox(
            height: 7.5.h,
            width: 14.w,
            child: FloatingActionButton(
              key: const Key('fab_create_listing'),
              backgroundColor: AppTheme.primaryLight,
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              onPressed: onFabPressed,
              child: const Icon(Icons.add, size: 32, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, String label, {bool hasNotification = false}) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      key: Key('nav_item_$label'),
      onTap: () => onTabSelected(index),
      child: Container(
        width: 14.w,
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppTheme.primaryLight : AppTheme.textSecondaryLight,
                  size: 26,
                ),
                if (hasNotification && index == 4)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
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
                color: isSelected ? AppTheme.primaryLight : AppTheme.textSecondaryLight,
                fontSize: 10.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}