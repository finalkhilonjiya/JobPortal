import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../login_screen/mobile_login_screen.dart';
import 'profile_page.dart';
import '../premium_package_page.dart';
import '../search_page.dart';

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER
            Padding(
              padding: EdgeInsets.fromLTRB(4.w, 3.h, 3.w, 2.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProfileCompletionCircle(
                    completion: profileCompletion,
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName.isEmpty ? 'Your Profile' : userName,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 0.6.h),
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ProfilePage()),
                            );
                          },
                          child: Text(
                            profileCompletion < 100
                                ? 'Complete your profile'
                                : 'View profile',
                            style: TextStyle(
                              fontSize: 10.5.sp,
                              color: Colors.blue.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClose,
                  ),
                ],
              ),
            ),

            /// UPGRADE CARD
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PremiumPackagePage()),
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 4.w,
                    vertical: 1.6.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.amber.shade100,
                        Colors.amber.shade50,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.workspace_premium,
                        color: Colors.amber.shade800,
                        size: 22,
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Text(
                          'Upgrade to Pro',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 3.h),

            /// MENU SECTION
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _DrawerItem(
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
                  _DrawerItem(
                    icon: Icons.work_outline,
                    label: 'Recommended jobs',
                    onTap: onClose,
                  ),
                  _DrawerItem(
                    icon: Icons.bookmark_border,
                    label: 'Saved jobs',
                    onTap: () {},
                  ),
                  _DrawerItem(
                    icon: Icons.bar_chart_outlined,
                    label: 'Profile performance',
                    onTap: () {},
                  ),

                  _Divider(),

                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    onTap: () {},
                  ),
                  _DrawerItem(
                    icon: Icons.help_outline,
                    label: 'Help',
                    onTap: () {},
                  ),

                  _Divider(),

                  _DrawerItem(
                    icon: Icons.logout,
                    label: 'Logout',
                    iconColor: Colors.redAccent,
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MobileLoginScreen(),
                        ),
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
}

/// ===================== COMPONENTS =====================

class _ProfileCompletionCircle extends StatelessWidget {
  final int completion;

  const _ProfileCompletionCircle({required this.completion});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 46,
          height: 46,
          child: CircularProgressIndicator(
            value: completion / 100,
            strokeWidth: 3,
            color: Colors.blue,
            backgroundColor: Colors.grey.shade300,
          ),
        ),
        Text(
          '$completion%',
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        size: 20,
        color: iconColor ?? Colors.grey.shade800,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 11.5.sp,
          color: Colors.black87,
        ),
      ),
      onTap: onTap,
      horizontalTitleGap: 2.w,
      dense: true,
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Divider(height: 1, color: Colors.grey.shade300),
    );
  }
}