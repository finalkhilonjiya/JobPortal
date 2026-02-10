import 'package:flutter/material.dart';
import '../../../../core/ui/khilonjiya_ui.dart';

class ProfileAndSearchCards extends StatelessWidget {
  final int profileCompletion; // 0..100
  final String profileName;
  final String profileUpdatedText;
  final String missingDetailsText;

  final int searchAppearances;
  final String searchAppearancesPeriodText;

  final VoidCallback? onProfileTap;
  final VoidCallback? onSearchTap;

  const ProfileAndSearchCards({
    Key? key,
    required this.profileCompletion,
    required this.profileName,
    required this.profileUpdatedText,
    required this.missingDetailsText,
    required this.searchAppearances,
    required this.searchAppearancesPeriodText,
    this.onProfileTap,
    this.onSearchTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final p = (profileCompletion.clamp(0, 100)) / 100.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          Expanded(
            child: _ProfileCard(
              progress: p,
              progressLabel: "${profileCompletion.clamp(0, 100)}%",
              title: "$profileName's profile",
              subtitle: profileUpdatedText,
              linkText: missingDetailsText,
              onTap: onProfileTap,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SearchAppearancesCard(
              value: searchAppearances,
              title: "Search appearances",
              subtitle: searchAppearancesPeriodText,
              linkText: "View all",
              onTap: onSearchTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final double progress;
  final String progressLabel;
  final String title;
  final String subtitle;
  final String linkText;
  final VoidCallback? onTap;

  const _ProfileCard({
    required this.progress,
    required this.progressLabel,
    required this.title,
    required this.subtitle,
    required this.linkText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: KhilonjiyaUI.cardDecoration(radius: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 46,
              height: 46,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 4,
                    backgroundColor: const Color(0xFFE8EEF8),
                    valueColor:
                        const AlwaysStoppedAnimation(KhilonjiyaUI.primary),
                  ),
                  Text(
                    progressLabel,
                    style: KhilonjiyaUI.caption.copyWith(
                      fontWeight: FontWeight.w800,
                      color: KhilonjiyaUI.text,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: KhilonjiyaUI.cardTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: KhilonjiyaUI.sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Text(
              linkText,
              style: KhilonjiyaUI.link,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchAppearancesCard extends StatelessWidget {
  final int value;
  final String title;
  final String subtitle;
  final String linkText;
  final VoidCallback? onTap;

  const _SearchAppearancesCard({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.linkText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: KhilonjiyaUI.cardDecoration(radius: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$value",
              style: KhilonjiyaUI.h1.copyWith(
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: KhilonjiyaUI.cardTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: KhilonjiyaUI.sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Text(
              linkText,
              style: KhilonjiyaUI.link,
            ),
          ],
        ),
      ),
    );
  }
}