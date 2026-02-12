import 'package:flutter/material.dart';

import '../../../core/ui/khilonjiya_ui.dart';
import '../../../routes/app_routes.dart';
import '../../../services/mobile_auth_service.dart';

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

  Future<void> _logout(BuildContext context) async {
    try {
      await MobileAuthService().logout();
    } catch (_) {}

    if (!context.mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.roleSelection,
      (_) => false,
    );
  }

  void _goNamed(BuildContext context, String route) {
    Navigator.pop(context); // close drawer
    Navigator.pushNamed(context, route);
  }

  void _openSearch(BuildContext context) {
    Navigator.pop(context); // close drawer
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SearchPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = profileCompletion.clamp(0, 100);
    final value = p / 100;

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // ------------------------------------------------------------
            // HEADER
            // ------------------------------------------------------------
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: KhilonjiyaUI.border)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 54,
                        height: 54,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: CircularProgressIndicator(
                                value: value,
                                strokeWidth: 4,
                                backgroundColor: const Color(0xFFE5E7EB),
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                  KhilonjiyaUI.primary,
                                ),
                              ),
                            ),
                            Center(
                              child: Text(
                                "$p%",
                                style: KhilonjiyaUI.sub.copyWith(
                                  color: KhilonjiyaUI.text,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName.isEmpty ? "User" : userName,
                              style: KhilonjiyaUI.hTitle.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Update profile",
                              style: KhilonjiyaUI.link.copyWith(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: onClose,
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Upgrade card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEFF6FF), Color(0xFFF5F3FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: KhilonjiyaUI.r16,
                      border: Border.all(color: const Color(0xFFDBEAFE)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: KhilonjiyaUI.border),
                          ),
                          child: const Icon(
                            Icons.workspace_premium_outlined,
                            color: KhilonjiyaUI.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Upgrade to Khilonjiya Pro",
                            style: KhilonjiyaUI.body.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: KhilonjiyaUI.muted,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ------------------------------------------------------------
            // MENU
            // ------------------------------------------------------------
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 8),

                  _menuItem(
                    context,
                    icon: Icons.edit_outlined,
                    title: "Set your job search status",
                    trailing: const Icon(
                      Icons.edit,
                      size: 18,
                      color: KhilonjiyaUI.muted,
                    ),
                    onTap: () {
                      // TODO: later (job search status page)
                    },
                  ),

                  _menuItem(
                    context,
                    icon: Icons.auto_awesome_outlined,
                    title: "Neo - AI Job Agent",
                    badge: "New",
                    onTap: () {
                      // TODO: later
                    },
                  ),

                  _menuItem(
                    context,
                    icon: Icons.search,
                    title: "Search jobs",
                    onTap: () => _openSearch(context),
                  ),

                  _menuItem(
                    context,
                    icon: Icons.star_outline,
                    title: "Recommended jobs",
                    onTap: () => _goNamed(context, AppRoutes.recommendedJobs),
                  ),

                  _menuItem(
                    context,
                    icon: Icons.bookmark_outline,
                    title: "Saved jobs",
                    onTap: () => _goNamed(context, AppRoutes.savedJobs),
                  ),

                  _menuItem(
                    context,
                    icon: Icons.person_outline,
                    title: "Profile performance",
                    onTap: () =>
                        _goNamed(context, AppRoutes.profilePerformance),
                  ),

                  _menuItem(
                    context,
                    icon: Icons.palette_outlined,
                    title: "Display preferences",
                    onTap: () {
                      // TODO: later
                    },
                  ),

                  _menuItem(
                    context,
                    icon: Icons.chat_outlined,
                    title: "Chat for help",
                    onTap: () {
                      // TODO: later
                    },
                  ),

                  _menuItem(
                    context,
                    icon: Icons.settings_outlined,
                    title: "Settings",
                    onTap: () {
                      // TODO: later
                    },
                  ),

                  const SizedBox(height: 8),

                  Container(
                    height: 10,
                    color: const Color(0xFFF7F8FA),
                  ),

                  const SizedBox(height: 8),

                  _menuItem(
                    context,
                    icon: Icons.work_outline,
                    title: "Jobseeker services",
                    badge: "Paid",
                    badgeColor: const Color(0xFFFFF7ED),
                    badgeTextColor: const Color(0xFFEA580C),
                    badgeBorderColor: const Color(0xFFFED7AA),
                    onTap: () {
                      // TODO: later
                    },
                  ),

                  _menuItem(
                    context,
                    icon: Icons.workspace_premium_outlined,
                    title: "Khilonjiya Pro",
                    badge: "Paid",
                    badgeColor: const Color(0xFFFFF7ED),
                    badgeTextColor: const Color(0xFFEA580C),
                    badgeBorderColor: const Color(0xFFFED7AA),
                    onTap: () {
                      // TODO: later
                    },
                  ),

                  _menuItem(
                    context,
                    icon: Icons.article_outlined,
                    title: "Khilonjiya blog",
                    onTap: () {
                      // TODO: later
                    },
                  ),

                  const SizedBox(height: 8),

                  // ------------------------------------------------------------
                  // LOGOUT
                  // ------------------------------------------------------------
                  _menuItem(
                    context,
                    icon: Icons.logout_rounded,
                    title: "Logout",
                    titleColor: const Color(0xFFEF4444),
                    iconColor: const Color(0xFFEF4444),
                    trailing: const SizedBox.shrink(),
                    onTap: () => _logout(context),
                  ),

                  const SizedBox(height: 14),
                ],
              ),
            ),

            // ------------------------------------------------------------
            // FEEDBACK STRIP
            // ------------------------------------------------------------
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF7F8FA),
                border: Border(top: BorderSide(color: KhilonjiyaUI.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Finding this app useful?",
                      style: KhilonjiyaUI.body.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _feedbackBtn(Icons.thumb_up_outlined),
                  const SizedBox(width: 10),
                  _feedbackBtn(Icons.thumb_down_outlined),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // UI HELPERS
  // ------------------------------------------------------------
  Widget _menuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    String? badge,
    Widget? trailing,
    Color? badgeColor,
    Color? badgeTextColor,
    Color? badgeBorderColor,
    Color? titleColor,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: KhilonjiyaUI.r16,
            border: Border.all(color: Colors.transparent),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: iconColor ?? const Color(0xFF334155),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: KhilonjiyaUI.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: titleColor ?? KhilonjiyaUI.text,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor ?? const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: badgeBorderColor ?? const Color(0xFFBFDBFE),
                    ),
                  ),
                  child: Text(
                    badge,
                    style: KhilonjiyaUI.sub.copyWith(
                      fontWeight: FontWeight.w900,
                      color: badgeTextColor ?? KhilonjiyaUI.primary,
                    ),
                  ),
                )
              else
                (trailing ??
                    const Icon(
                      Icons.chevron_right,
                      color: KhilonjiyaUI.muted,
                    )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _feedbackBtn(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KhilonjiyaUI.border),
      ),
      child: Icon(icon, size: 20, color: const Color(0xFF475569)),
    );
  }
}