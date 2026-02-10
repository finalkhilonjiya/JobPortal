import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../ui/app_styles.dart';

class NaukriDrawer extends StatelessWidget {
  final String userName;
  final int profileCompletion; // 0 - 100
  final VoidCallback onClose;

  const NaukriDrawer({
    Key? key,
    required this.userName,
    required this.profileCompletion,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final name = (userName.trim().isEmpty) ? "Pankaj" : userName.trim();

    final progress = (profileCompletion.clamp(0, 100)) / 100.0;
    final pctText = "${profileCompletion.clamp(0, 100)}%";

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // -----------------------------
            // HEADER
            // -----------------------------
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: AppTheme.border),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _ProfileRing(
                        progress: progress,
                        text: pctText,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.text,
                              ),
                            ),
                            const SizedBox(height: 3),
                            GestureDetector(
                              onTap: () {
                                // TODO: connect route later
                                Navigator.pop(context);
                              },
                              child: const Text(
                                "Update profile",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: onClose,
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Upgrade Card
                  _UpgradeCard(
                    onTap: () {
                      // TODO: connect route later
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),

            // -----------------------------
            // MENU
            // -----------------------------
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _MenuItem(
                    icon: Icons.edit_outlined,
                    title: "Set your job search status",
                    trailing: const Icon(Icons.edit, size: 16),
                    onTap: () => Navigator.pop(context),
                  ),
                  _MenuItem(
                    icon: Icons.auto_awesome_outlined,
                    title: "Neo - AI Job Agent",
                    badge: "New",
                    onTap: () => Navigator.pop(context),
                  ),
                  _MenuItem(
                    icon: Icons.search_rounded,
                    title: "Search jobs",
                    onTap: () => Navigator.pop(context),
                  ),
                  _MenuItem(
                    icon: Icons.star_border_rounded,
                    title: "Recommended jobs",
                    onTap: () => Navigator.pop(context),
                  ),
                  _MenuItem(
                    icon: Icons.bookmark_border_rounded,
                    title: "Saved jobs",
                    onTap: () => Navigator.pop(context),
                  ),
                  _MenuItem(
                    icon: Icons.trending_up_rounded,
                    title: "Profile performance",
                    onTap: () => Navigator.pop(context),
                  ),
                  _MenuItem(
                    icon: Icons.palette_outlined,
                    title: "Display preferences",
                    onTap: () => Navigator.pop(context),
                  ),
                  _MenuItem(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: "Chat for help",
                    onTap: () => Navigator.pop(context),
                  ),
                  _MenuItem(
                    icon: Icons.settings_outlined,
                    title: "Settings",
                    onTap: () => Navigator.pop(context),
                  ),

                  // Divider strip
                  Container(
                    height: 10,
                    color: AppTheme.bg,
                  ),

                  _MenuItem(
                    icon: Icons.work_outline_rounded,
                    title: "Jobseeker services",
                    badge: "Paid",
                    onTap: () => Navigator.pop(context),
                  ),
                  _MenuItem(
                    icon: Icons.workspace_premium_outlined,
                    title: "Khilonjiya Pro",
                    badge: "Paid",
                    onTap: () => Navigator.pop(context),
                  ),
                  _MenuItem(
                    icon: Icons.article_outlined,
                    title: "Khilonjiya blog",
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // -----------------------------
            // FEEDBACK STRIP
            // -----------------------------
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: AppTheme.bg,
                border: Border(
                  top: BorderSide(color: AppTheme.border),
                ),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Finding this app useful?",
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.text,
                      ),
                    ),
                  ),
                  _FeedbackButton(
                    icon: Icons.thumb_up_outlined,
                    onTap: () {},
                  ),
                  const SizedBox(width: 10),
                  _FeedbackButton(
                    icon: Icons.thumb_down_outlined,
                    onTap: () {},
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

// ===============================================================
// COMPONENTS
// ===============================================================

class _ProfileRing extends StatelessWidget {
  final double progress;
  final String text;

  const _ProfileRing({
    required this.progress,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 4,
            backgroundColor: AppTheme.border,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.blue),
          ),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppTheme.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _UpgradeCard extends StatelessWidget {
  final VoidCallback onTap;

  const _UpgradeCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppStyles.r16,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: AppStyles.r16,
          border: Border.all(color: AppTheme.blue.withOpacity(0.18)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.blue.withOpacity(0.07),
              Colors.deepPurple.withOpacity(0.06),
            ],
          ),
        ),
        child: Row(
          children: const [
            Icon(Icons.workspace_premium_rounded, color: AppTheme.blue),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "Upgrade to Khilonjiya Pro",
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.text,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppTheme.subText),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? badge;
  final Widget? trailing;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.badge,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      minLeadingWidth: 22,
      leading: Icon(icon, size: 20, color: AppTheme.subText),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 13.8,
          fontWeight: FontWeight.w600,
          color: AppTheme.text,
        ),
      ),
      trailing: badge != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.blue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppTheme.blue.withOpacity(0.12)),
              ),
              child: Text(
                badge!,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.blue,
                ),
              ),
            )
          : trailing,
      onTap: onTap,
    );
  }
}

class _FeedbackButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _FeedbackButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border),
        ),
        child: Icon(icon, size: 18, color: AppTheme.subText),
      ),
    );
  }
}