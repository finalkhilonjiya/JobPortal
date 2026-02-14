import 'package:flutter/material.dart';

import '../../core/ui/khilonjiya_ui.dart';
import '../../services/job_seeker_home_service.dart';

import 'profile_edit_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final JobSeekerHomeService _service = JobSeekerHomeService();

  bool _loading = true;
  bool _disposed = false;

  Map<String, dynamic> _profile = {};
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
      // NOTE:
      // We use getHomeProfileSummary for basic.
      // Then we fetch extra profile fields from Supabase directly inside service later if needed.
      // For now, we keep it stable and production-safe.

      final summary = await _service.getHomeProfileSummary();
      _expectedSalary = await _service.getExpectedSalaryPerMonth();

      _profile = {
        "full_name": summary["profileName"] ?? "Your Profile",
        "profile_completion_percentage": summary["profileCompletion"] ?? 0,
        "last_profile_update": summary["lastUpdatedText"] ?? "Updated recently",
      };
    } catch (_) {
      _profile = {};
      _expectedSalary = 0;
    }

    if (_disposed) return;
    setState(() => _loading = false);
  }

  String _salaryText(int v) {
    if (v <= 0) return "Not set";
    if (v >= 100000) return "₹${(v / 100000).toStringAsFixed(1)}L / month";
    if (v >= 1000) return "₹${(v / 1000).toStringAsFixed(0)}k / month";
    return "₹$v / month";
  }

  Future<void> _openEdit() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileEditPage()),
    );

    // refresh after edit
    await _load();
  }

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      decoration: KhilonjiyaUI.cardDecoration(radius: 18),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: KhilonjiyaUI.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: KhilonjiyaUI.border),
            ),
            child: Icon(icon, color: KhilonjiyaUI.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: KhilonjiyaUI.caption),
                const SizedBox(height: 4),
                Text(
                  value.trim().isEmpty ? "—" : value,
                  style: KhilonjiyaUI.body.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileHeader() {
    final name = (_profile["full_name"] ?? "Your Profile").toString();
    final completion =
        int.tryParse((_profile["profile_completion_percentage"] ?? 0).toString())
                ?.clamp(0, 100) ??
            0;

    final lastUpdate = (_profile["last_profile_update"] ?? "Updated recently")
        .toString();

    final value = completion / 100;

    return Container(
      decoration: KhilonjiyaUI.cardDecoration(radius: 22),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SizedBox(
            width: 62,
            height: 62,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CircularProgressIndicator(
                    value: value,
                    strokeWidth: 5,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      KhilonjiyaUI.primary,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    "$completion%",
                    style: KhilonjiyaUI.body.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: KhilonjiyaUI.hTitle.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 16.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  lastUpdate,
                  style: KhilonjiyaUI.sub.copyWith(
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: KhilonjiyaUI.border),
                  ),
                  child: Text(
                    completion >= 100
                        ? "Profile complete"
                        : "Complete your profile for better matches",
                    style: KhilonjiyaUI.sub.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.2,
                      color: completion >= 100
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _updateButton() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: KhilonjiyaUI.border)),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _openEdit,
            style: ElevatedButton.styleFrom(
              backgroundColor: KhilonjiyaUI.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: const Text(
              "Update Profile",
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body() {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          _profileHeader(),
          const SizedBox(height: 14),

          Text(
            "Quick details",
            style: KhilonjiyaUI.hTitle.copyWith(fontSize: 14.8),
          ),
          const SizedBox(height: 10),

          _infoTile(
            icon: Icons.currency_rupee_rounded,
            title: "Expected salary",
            value: _salaryText(_expectedSalary),
          ),

          const SizedBox(height: 12),

          _infoTile(
            icon: Icons.work_outline_rounded,
            title: "Job preferences",
            value: "Not set yet",
          ),

          const SizedBox(height: 12),

          _infoTile(
            icon: Icons.location_on_outlined,
            title: "Preferred location",
            value: "Not set yet",
          ),

          const SizedBox(height: 16),

          Container(
            decoration: KhilonjiyaUI.cardDecoration(radius: 22),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Profile tips", style: KhilonjiyaUI.hTitle),
                const SizedBox(height: 6),
                Text(
                  "A complete profile helps employers trust you and improves job recommendations.",
                  style: KhilonjiyaUI.sub,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: KhilonjiyaUI.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.verified_user_outlined,
                              color: Color(0xFF0F172A),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Add skills and experience",
                                style: KhilonjiyaUI.body.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),
        ],
      ),
    );
  }

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
                      "Profile",
                      style: KhilonjiyaUI.hTitle,
                    ),
                  ),
                  IconButton(
                    onPressed: _openEdit,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _body(),
            ),

            _updateButton(),
          ],
        ),
      ),
    );
  }
}