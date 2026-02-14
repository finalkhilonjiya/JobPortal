import 'package:flutter/material.dart';
import '../../core/ui/khilonjiya_ui.dart';

class MyJobsPage extends StatefulWidget {
  const MyJobsPage({Key? key}) : super(key: key);

  @override
  State<MyJobsPage> createState() => _MyJobsPageState();
}

class _MyJobsPageState extends State<MyJobsPage> {
  bool _loading = false;

  // For now blank. Later we will connect:
  // - Applied jobs
  // - Interview calls
  // - Saved status
  // - Offer history

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhilonjiyaUI.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: KhilonjiyaUI.border)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "My Jobs",
                      style: KhilonjiyaUI.hTitle,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() => _loading = true);
                      Future.delayed(const Duration(milliseconds: 600), () {
                        if (!mounted) return;
                        setState(() => _loading = false);
                      });
                    },
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                      children: [
                        Container(
                          decoration: KhilonjiyaUI.cardDecoration(radius: 22),
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            children: [
                              Icon(
                                Icons.work_outline_rounded,
                                size: 52,
                                color: Colors.black.withOpacity(0.35),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                "No job activity yet",
                                style: KhilonjiyaUI.hTitle,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "When you apply to jobs, track them here.\nWe will add Applied, Interviews, and Offers.",
                                style: KhilonjiyaUI.sub,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: KhilonjiyaUI.border),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.auto_awesome_rounded,
                                      color: KhilonjiyaUI.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        "Next: Applied jobs + status tracking",
                                        style: KhilonjiyaUI.body.copyWith(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 13.2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // UI placeholders for future
                        _sectionCard(
                          icon: Icons.description_outlined,
                          title: "Applied",
                          subtitle:
                              "Track jobs you applied to with real status.",
                        ),
                        const SizedBox(height: 12),
                        _sectionCard(
                          icon: Icons.event_available_outlined,
                          title: "Interviews",
                          subtitle: "All interview calls will appear here.",
                        ),
                        const SizedBox(height: 12),
                        _sectionCard(
                          icon: Icons.verified_outlined,
                          title: "Offers",
                          subtitle: "Offer letters & joining updates.",
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      decoration: KhilonjiyaUI.cardDecoration(radius: 22),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: KhilonjiyaUI.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: KhilonjiyaUI.border),
            ),
            child: Icon(icon, color: KhilonjiyaUI.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: KhilonjiyaUI.body.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: KhilonjiyaUI.sub,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: KhilonjiyaUI.muted,
          ),
        ],
      ),
    );
  }
}