import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../login_screen/mobile_login_screen.dart';
import 'profile_page.dart';
import '../premium_package_page.dart';
import '../search_page.dart';
import '../my_applications_page.dart';
import '../saved_jobs_page.dart';
import '../profile_performance_page.dart';
import '../settings_page.dart';
import '../help_page.dart';

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
              padding: EdgeInsets.fromLTRB(4.w, 3.h, 3.w, 2.h),
              child: Row(
                children: [
                  _ProfileCompletionCircle(completion: profileCompletion),
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
                          ),
                        ),
                        SizedBox(height: 0.6.h),
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProfilePage(),
                              ),
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

            /// UPGRADE
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PremiumPackagePage(),
                    ),
                  );
                },
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.6.h),
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
                      Icon(Icons.workspace_premium,
                          color: Colors.amber.shade800),
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
                      Icon(Icons.arrow_forward_ios,
                          size: 14, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 3.h),

            /// MENU
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _item(
                    context,
                    Icons.search,
                    'Search jobs',
                    () => _go(context, const SearchPage()),
                  ),
                  _item(
                    context,
                    Icons.work_outline,
                    'Recommended jobs',
                    onClose,
                  ),
                  _item(
                    context,
                    Icons.assignment_turned_in_outlined,
                    'My applications',
                    () => _go(context, const MyApplicationsPage()),
                  ),
                  _item(
                    context,
                    Icons.bookmark_border,
                    'Saved jobs',
                    () => _go(context, const SavedJobsPage()),
                  ),
                  _item(
                    context,
                    Icons.bar_chart_outlined,
                    'Profile performance',
                    () => _go(context, const ProfilePerformancePage()),
                  ),

                  _divider(),

                  _item(
                    context,
                    Icons.settings_outlined,
                    'Settings',
                    () => _go(context, const SettingsPage()),
                  ),
                  _item(
                    context,
                    Icons.help_outline,
                    'Help',
                    () => _go(context, const HelpPage()),
                  ),

                  _divider(),

                  _item(
                    context,
                    Icons.logout,
                    'Logout',
                    () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MobileLoginScreen(),
                        ),
                        (_) => false,
                      );
                    },
                    iconColor: Colors.redAccent,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? iconColor,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 20, color: iconColor ?? Colors.grey.shade800),
      title: Text(
        label,
        style: TextStyle(fontSize: 11.5.sp),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  Widget _divider() => Padding(
        padding: EdgeInsets.symmetric(vertical: 1.h),
        child: Divider(color: Colors.grey.shade300),
      );

  void _go(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}

/// =================== COMPONENT ===================

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
            backgroundColor: Colors.grey.shade300,
          ),
        ),
        Text(
          '$completion%',
          style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
