import 'package:flutter/material.dart';

import '../../core/ui/khilonjiya_ui.dart';
import '../../services/job_seeker_home_service.dart';

class ProfilePerformancePage extends StatefulWidget {
  const ProfilePerformancePage({Key? key}) : super(key: key);

  @override
  State<ProfilePerformancePage> createState() => _ProfilePerformancePageState();
}

class _ProfilePerformancePageState extends State<ProfilePerformancePage> {
  final JobSeekerHomeService _homeService = JobSeekerHomeService();

  bool _loading = true;
  bool _disposed = false;

  Map<String, dynamic> _summary = {};
  int _jobsToday = 0;

  int _expectedSalary = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _load() async {
    if (!_disposed) setState(() => _loading = true);

    try {
      _summary = await _homeService.getHomeProfileSummary();
    } catch (_) {
      _summary = {};
    }

    try {
      _jobsToday = await _homeService.getJobsPostedTodayCount();
    } catch (_) {
      _jobsToday = 0;
    }

    try {
      _expectedSalary = await _homeService.getExpectedSalaryPerMonth();
    } catch (_) {
      _expectedSalary = 0;
    }

    if (_disposed) return;
    setState(() => _loading = false);
  }

  // ------------------------------------------------------------
  // EXPECTED SALARY EDIT
  // ------------------------------------------------------------
  Future<void> _editExpectedSalary() async {
    final ctrl = TextEditingController(
      text: _expectedSalary <= 0 ? '' : _expectedSalary.toString(),
    );

    final res = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Expected salary (per month)",
                        style: KhilonjiyaUI.hTitle,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  style: KhilonjiyaUI.body.copyWith(fontWeight: FontWeight.w900),
                  decoration: InputDecoration(
                    hintText: "Enter salary in INR (monthly)",
                    hintStyle: KhilonjiyaUI.sub,
                    prefixIcon: const Icon(Icons.currency_rupee_rounded),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: KhilonjiyaUI.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: KhilonjiyaUI.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                        color: KhilonjiyaUI.primary.withOpacity(0.6),
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      final raw = ctrl.text.trim();
                      final v = int.tryParse(raw) ?? 0;
                      Navigator.pop(context, v);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KhilonjiyaUI.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      "Save",
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );

    if (res == null) return;

    final clean = res < 0 ? 0 : res;

    try {
      await _homeService.updateExpectedSalaryPerMonth(clean);
      _expectedSalary = clean;
      if (!_disposed) setState(() {});
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update expected salary")),
      );
    }
  }

  // ------------------------------------------------------------
  // UI HELPERS
  // ------------------------------------------------------------
  String _money(int v) {
    if (v <= 0) return "Not set";
    return "₹$v / month";
  }

  @override
  Widget build(BuildContext context) {
    final profileName = (_summary['profileName'] ?? 'Your Profile').toString();
    final completion = (_summary['profileCompletion'] ?? 0) as int;
    final lastUpdated = (_summary['lastUpdatedText'] ?? 'Updated recently')
        .toString();

    return Scaffold(
      backgroundColor: KhilonjiyaUI.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: KhilonjiyaUI.border)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      "Profile performance",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KhilonjiyaUI.hTitle,
                    ),
                  ),
                  IconButton(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 26),
                      children: [
                        // ----------------------------------------------------
                        // PROFILE COMPLETION CARD
                        // ----------------------------------------------------
                        Container(
                          decoration: KhilonjiyaUI.cardDecoration(radius: 22),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(profileName, style: KhilonjiyaUI.hTitle),
                              const SizedBox(height: 6),
                              Text(
                                lastUpdated,
                                style: KhilonjiyaUI.sub,
                              ),
                              const SizedBox(height: 14),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: (completion.clamp(0, 100)) / 100,
                                  minHeight: 10,
                                  backgroundColor: const Color(0xFFE2E8F0),
                                  color: KhilonjiyaUI.primary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "$completion% completed",
                                style: KhilonjiyaUI.body.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // ----------------------------------------------------
                        // EXPECTED SALARY CARD
                        // ----------------------------------------------------
                        InkWell(
                          onTap: _editExpectedSalary,
                          borderRadius: BorderRadius.circular(22),
                          child: Container(
                            decoration: KhilonjiyaUI.cardDecoration(radius: 22),
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color:
                                        KhilonjiyaUI.primary.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Icon(
                                    Icons.currency_rupee_rounded,
                                    color: KhilonjiyaUI.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Expected salary",
                                        style: KhilonjiyaUI.caption,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _money(_expectedSalary),
                                        style: KhilonjiyaUI.body.copyWith(
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Icon(Icons.chevron_right_rounded),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // ----------------------------------------------------
                        // JOBS POSTED TODAY
                        // ----------------------------------------------------
                        Container(
                          decoration: KhilonjiyaUI.cardDecoration(radius: 22),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color:
                                      KhilonjiyaUI.primary.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Icon(
                                  Icons.today_rounded,
                                  color: KhilonjiyaUI.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Jobs posted today",
                                      style: KhilonjiyaUI.caption,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _jobsToday.toString(),
                                      style: KhilonjiyaUI.body.copyWith(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ----------------------------------------------------
                        // NOTE
                        // ----------------------------------------------------
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: KhilonjiyaUI.border),
                          ),
                          child: Text(
                            "Tip: Keep your expected salary updated. "
                            "We will show you jobs with salary equal to or higher than your expectation.",
                            style: KhilonjiyaUI.body.copyWith(
                              color: const Color(0xFF475569),
                              height: 1.5,
                            ),
                          ),
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