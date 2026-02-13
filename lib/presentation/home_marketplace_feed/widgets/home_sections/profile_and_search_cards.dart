// File: lib/presentation/home_marketplace_feed/widgets/home_sections/profile_and_search_cards.dart

import 'package:flutter/material.dart';
import '../../../../core/ui/khilonjiya_ui.dart';

class ProfileAndSearchCards extends StatelessWidget {
  // LOADING
  final bool isLoading;

  // LEFT CARD (PROFILE)
  final String profileName;
  final int profileCompletion; // 0-100
  final String lastUpdatedText;
  final int missingDetailsCount;

  // RIGHT CARD (JOBS TODAY)
  final int jobsPostedToday;

  // ACTIONS (REAL NAVIGATION WILL BE DONE IN HOME PAGE)
  final VoidCallback? onProfileTap;
  final VoidCallback? onMissingDetailsTap;
  final VoidCallback? onJobsTodayTap;
  final VoidCallback? onViewAllTap;

  const ProfileAndSearchCards({
    Key? key,
    this.isLoading = false,
    this.profileName = "Your Profile",
    this.profileCompletion = 0,
    this.lastUpdatedText = "Updated recently",
    this.missingDetailsCount = 0,
    this.jobsPostedToday = 0,
    this.onProfileTap,
    this.onMissingDetailsTap,
    this.onJobsTodayTap,
    this.onViewAllTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Row(
        children: [
          Expanded(child: _skeletonCard()),
          const SizedBox(width: 12),
          Expanded(child: _skeletonCard()),
        ],
      );
    }

    final safeCompletion = profileCompletion.clamp(0, 100);
    final value = safeCompletion / 100.0;

    return Row(
      children: [
        // LEFT CARD (Profile)
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onProfileTap,
            child: _fixedHeightCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress Circle
                  SizedBox(
                    width: 54,
                    height: 54,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 54,
                          height: 54,
                          child: CircularProgressIndicator(
                            value: value,
                            strokeWidth: 4,
                            backgroundColor: const Color(0xFFEFF2F6),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              KhilonjiyaUI.primary,
                            ),
                          ),
                        ),
                        Text(
                          "$safeCompletion%",
                          style: KhilonjiyaUI.caption.copyWith(
                            fontWeight: FontWeight.w900,
                            color: KhilonjiyaUI.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(profileName, style: KhilonjiyaUI.cardTitle),
                  const SizedBox(height: 4),
                  Text(
                    lastUpdatedText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KhilonjiyaUI.sub,
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: onMissingDetailsTap,
                    child: Text(
                      "$missingDetailsCount Missing details",
                      style: KhilonjiyaUI.link,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // RIGHT CARD (Jobs posted today)
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onJobsTodayTap,
            child: _fixedHeightCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$jobsPostedToday",
                    style: KhilonjiyaUI.h1.copyWith(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text("Jobs posted today", style: KhilonjiyaUI.cardTitle),
                  const SizedBox(height: 4),
                  Text(
                    "All India • Active only",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KhilonjiyaUI.sub,
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: onViewAllTap,
                    child: Text("View all", style: KhilonjiyaUI.link),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // UI HELPERS
  // ------------------------------------------------------------

  Widget _fixedHeightCard({required Widget child}) {
    return Container(
      height: 164,
      padding: const EdgeInsets.all(14),
      decoration: KhilonjiyaUI.cardDecoration(radius: 16),
      child: child,
    );
  }

  Widget _skeletonCard() {
    return Container(
      height: 164,
      decoration: KhilonjiyaUI.cardDecoration(radius: 16),
      padding: const EdgeInsets.all(14),
      child: const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}