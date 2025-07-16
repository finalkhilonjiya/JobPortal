// ===== File 4: widgets/bottom_nav_bar_widget.dart =====
import 'package:flutter/material.dart';

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
            height: 65,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home, 'Home', 0),
                _buildNavItem(Icons.search, 'Search', 1),
                SizedBox(width: 60), // Space for FAB
                _buildNavItem(Icons.inventory_2, 'Packages', 3),
                _buildNavItem(Icons.person, 'Profile', 4),
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
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// This is the wrapper that includes the FAB
class ScaffoldWithNavBar extends StatelessWidget {
  final Widget body;
  final int currentIndex;
  final Function(int) onTabSelected;
  final VoidCallback onFabPressed;
  final bool hasMessageNotification;

  const ScaffoldWithNavBar({
    Key? key,
    required this.body,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onFabPressed,
    this.hasMessageNotification = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: body,
      bottomNavigationBar: BottomNavBarWidget(
        currentIndex: currentIndex,
        onTabSelected: onTabSelected,
        onFabPressed: onFabPressed,
        hasMessageNotification: hasMessageNotification,
      ),
      floatingActionButton: Container(
        height: 56,
        width: 56,
        child: FittedBox(
          child: FloatingActionButton(
            onPressed: onFabPressed,
            backgroundColor: Color(0xFF2563EB),
            elevation: 8,
            child: Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}