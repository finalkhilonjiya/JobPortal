// File: lib/presentation/home_marketplace_feed/widgets/home_sections/profile_and_search_cards.dart

import 'package:flutter/material.dart';

import '../../../../core/ui/khilonjiya_ui.dart';
import '../../../../services/job_service.dart';

class ProfileAndSearchCards extends StatefulWidget {
  final VoidCallback? onMissingDetailsTap;
  final VoidCallback? onViewAllTap;

  /// Placeholder navigation:
  /// - Left card tap -> Complete Profile page (later)
  /// - Right card "View all" -> Jobs posted today page (later)
  const ProfileAndSearchCards({
    Key? key,
    this.onMissingDetailsTap,
    this.onViewAllTap,
  }) : super(key: key);

  @override
  State<ProfileAndSearchCards> createState() => _ProfileAndSearchCardsState();
}

class _ProfileAndSearchCardsState extends State<ProfileAndSearchCards> {
  final JobService _jobService = JobService();

  bool _loading = true;

  // LEFT CARD
  String _profileName = "Your Profile";
  int _profileCompletion = 0;
  String _lastUpdatedText = "Updated recently";
  int _missingDetails = 0;

  // RIGHT CARD
  int _jobsPostedToday = 0;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final summary = await _jobService.getHomeProfileSummary();
      final jobsCount = await _jobService.getJobsPostedTodayCount();

      if (!mounted) return;
      setState(() {
        _profileName = (summary['profileName'] ?? "Your Profile").toString();
        _profileCompletion = (summary['profileCompletion'] ?? 0) as int;
        _lastUpdatedText =
            (summary['lastUpdatedText'] ?? "Updated recently").toString();
        _missingDetails = (summary['missingDetails'] ?? 0) as int;

        _jobsPostedToday = jobsCount;

        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;

        _profileName = "Your Profile";
        _profileCompletion = 0;
        _lastUpdatedText = "Updated recently";
        _missingDetails = 0;
        _jobsPostedToday = 0;
      });
    }
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Row(
        children: [
          Expanded(child: _skeletonCard()),
          const SizedBox(width: 12),
          Expanded(child: _skeletonCard()),
        ],
      );
    }

    final value = (_profileCompletion.clamp(0, 100)) / 100.0;

    return Row(
      children: [
        // LEFT CARD (Profile)
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              // Placeholder: complete profile page will be created later
            },
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
                          "${_profileCompletion.clamp(0, 100)}%",
                          style: KhilonjiyaUI.caption.copyWith(
                            fontWeight: FontWeight.w900,
                            color: KhilonjiyaUI.text,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(_profileName, style: KhilonjiyaUI.cardTitle),
                  const SizedBox(height: 4),
                  Text(
                    _lastUpdatedText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KhilonjiyaUI.sub,
                  ),

                  const Spacer(),

                  InkWell(
                    onTap: widget.onMissingDetailsTap,
                    child: Text(
                      "$_missingDetails Missing details",
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
          child: _fixedHeightCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$_jobsPostedToday",
                  // Normal weight (as per your instruction)
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
                  onTap: widget.onViewAllTap,
                  child: Text("View all", style: KhilonjiyaUI.link),
                ),
              ],
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
      height: 164, // ✅ fixed height so both cards are always same size
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