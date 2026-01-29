import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../login_screen/mobile_login_screen.dart';
import '../profile_page.dart';
import '../premium_package_page.dart';
import '../search_page.dart';
import '../profile_page.dart';


class NaukriDrawer extends StatelessWidget {
  final String userName;
  final int profileCompletion;
  final VoidCallback onClose;

  const NaukriDrawer({
    Key? key,
    required this.userName,
    required this.profileCompletion,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            /// HEADER
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  _profileCircle(),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName.isEmpty ? 'Your Profile' : userName,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ProfilePage()),
                            );
                          },
                          child: Text(
                            'Complete profile',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: onClose,
                  ),
                ],
              ),
            ),

            /// UPGRADE
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PremiumPackagePage()),
                  );
                },
                child: Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.workspace_premium, color: Colors.amber),
                      SizedBox(width: 3.w),
                      Text(
                        'Upgrade to Pro',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 2.h),

            /// MENU
            Expanded(
              child: ListView(
                children: [
                  _menuItem(
                    context,
                    icon: Icons.search,
                    label: 'Search jobs',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => SearchPage()),
                      );
                    },
                  ),
                  _menuItem(
                    context,
                    icon: Icons.work_outline,
                    label: 'Recommended jobs',
                    onTap: onClose,
                  ),
                  _menuItem(
                    context,
                    icon: Icons.bookmark_border,
                    label: 'Saved jobs',
                    onTap: () {},
                  ),
                  _menuItem(
                    context,
                    icon: Icons.bar_chart,
                    label: 'Profile performance',
                    onTap: () {},
                  ),
                  Divider(),
                  _menuItem(
                    context,
                    icon: Icons.settings,
                    label: 'Settings',
                    onTap: () {},
                  ),
                  _menuItem(
                    context,
                    icon: Icons.help_outline,
                    label: 'Help',
                    onTap: () {},
                  ),
                  Divider(),
                  _menuItem(
                    context,
                    icon: Icons.logout,
                    label: 'Logout',
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => MobileLoginScreen()),
                        (_) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileCircle() {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 14.w,
          height: 14.w,
          child: CircularProgressIndicator(
            value: profileCompletion / 100,
            strokeWidth: 3,
          ),
        ),
        Text(
          '$profileCompletion%',
          style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _menuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, size: 6.w),
      title: Text(
        label,
        style: TextStyle(fontSize: 11.sp),
      ),
      onTap: onTap,
    );
  }
}
