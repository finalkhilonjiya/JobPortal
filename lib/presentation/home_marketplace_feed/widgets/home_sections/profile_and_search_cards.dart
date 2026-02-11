import 'package:flutter/material.dart';
import '../../../../core/ui/khilonjiya_ui.dart';

class ProfileAndSearchCards extends StatelessWidget {
  final int profileCompletion;
  final String profileName;
  final String lastUpdatedText;
  final int searchAppearances;
  final String searchWindowText;

  final VoidCallback? onMissingDetailsTap;
  final VoidCallback? onViewAllTap;

  const ProfileAndSearchCards({
    Key? key,
    required this.profileCompletion,
    this.profileName = "Pankaj's profile",
    this.lastUpdatedText = "Updated 4d ago",
    this.searchAppearances = 0,
    this.searchWindowText = "Last 90 days",
    this.onMissingDetailsTap,
    this.onViewAllTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final value = (profileCompletion.clamp(0, 100)) / 100.0;

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: KhilonjiyaUI.cardDecoration(radius: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: Stack(
                    children: [
                      CircularProgressIndicator(
                        value: value,
                        strokeWidth: 4,
                        backgroundColor: const Color(0xFFEFF2F6),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          KhilonjiyaUI.primary,
                        ),
                      ),
                      Center(
                        child: Text(
                          "${profileCompletion.clamp(0, 100)}%",
                          style: KhilonjiyaUI.caption.copyWith(
                            fontWeight: FontWeight.w800,
                            color: KhilonjiyaUI.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(profileName, style: KhilonjiyaUI.cardTitle),
                const SizedBox(height: 4),
                Text(lastUpdatedText, style: KhilonjiyaUI.sub),
                const SizedBox(height: 10),
                InkWell(
                  onTap: onMissingDetailsTap,
                  child: Text(
                    "8 Missing details",
                    style: KhilonjiyaUI.link,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: KhilonjiyaUI.cardDecoration(radius: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$searchAppearances",
                  style: KhilonjiyaUI.h1.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text("Search appearances", style: KhilonjiyaUI.cardTitle),
                const SizedBox(height: 4),
                Text(searchWindowText, style: KhilonjiyaUI.sub),
                const SizedBox(height: 10),
                InkWell(
                  onTap: onViewAllTap,
                  child: Text("View all", style: KhilonjiyaUI.link),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}