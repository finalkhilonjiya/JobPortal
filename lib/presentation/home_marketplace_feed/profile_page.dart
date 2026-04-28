import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/ui/khilonjiya_ui.dart';
import '../../services/job_seeker_home_service.dart';
import 'profile_edit_page.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

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
      _profile = await _service.fetchMyProfile();
    } catch (_) {
      _profile = {};
    }

    if (_disposed) return;
    setState(() => _loading = false);
  }

  String _s(dynamic v) => (v ?? '').toString().trim();

  int _i(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  bool _b(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    final s = v.toString().toLowerCase();
    return s == 'true' || s == '1';
  }

  String _salaryText(int v) {
    if (v <= 0) return "";
    if (v >= 100000) return "₹${(v / 100000).toStringAsFixed(1)}L / month";
    if (v >= 1000) return "₹${(v / 1000).toStringAsFixed(0)}k / month";
    return "₹$v / month";
  }

  String _salaryRange() {
    final min = _i(_profile['expected_salary_min']);
    final max = _i(_profile['expected_salary_max']);

    if (min <= 0 && max <= 0) return "";
    if (min > 0 && max <= 0) return _salaryText(min);
    if (min <= 0 && max > 0) return "Up to ${_salaryText(max)}";
    return "${_salaryText(min)} - ${_salaryText(max)}";
  }

  String _experienceText(int years) {
    if (years <= 0) return "";
    if (years == 1) return "1 year";
    return "$years years";
  }

  String _skillsText(dynamic skills) {
    if (skills is List && skills.isNotEmpty) {
      return skills.join(", ");
    }
    return "";
  }

  String _locationText() {
    final city = _s(_profile['current_city']);
    final state = _s(_profile['current_state']);

    if (city.isNotEmpty && state.isNotEmpty) return "$city, $state";
    if (city.isNotEmpty) return city;
    if (state.isNotEmpty) return state;
    return "";
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openEdit() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileEditPage()),
    );
    await _load();
  }

  Widget _infoTile({
  required String title,
  required String value,
  IconData? icon,
  VoidCallback? onTap,
}) {
  if (value.isEmpty) return const SizedBox();

  final isResume = title.toLowerCase() == "resume";

  return InkWell(
    onTap: isResume ? () => _openResumeViewer(value) : onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: KhilonjiyaUI.cardDecoration(radius: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: KhilonjiyaUI.primary),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: KhilonjiyaUI.caption.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isResume ? "View Resume" : value,
                  style: KhilonjiyaUI.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isResume
                        ? KhilonjiyaUI.primary
                        : null,
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

  Widget _profileHeader() {
    final fullName = _s(_profile["full_name"]);
    final completion =
        _i(_profile["profile_completion_percentage"]).clamp(0, 100);
    final avatarUrl = _s(_profile['avatar_url']);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: KhilonjiyaUI.cardDecoration(radius: 18),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 54,
              height: 54,
              color: const Color(0xFFF1F5F9),
              child: avatarUrl.isEmpty
                  ? const Icon(Icons.person_outline)
                  : Image.network(avatarUrl, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName, // ✅ no placeholder
                  style: KhilonjiyaUI.hTitle.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$completion% profile completed",
                  style: KhilonjiyaUI.sub,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


Future<void> _openResumeViewer(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || url.isEmpty) return;

  final isPdf = uri.path.toLowerCase().endsWith('.pdf');

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) {
      return SafeArea(
        child: Column(
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Text(
                    "Resume",
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () async {
                      await launchUrl(
                        Uri.parse(url),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // CONTENT
            Expanded(
              child: isPdf
                  ? SfPdfViewer.network(url) // ✅ PDF viewer
                  : InteractiveViewer(
                      minScale: 1,
                      maxScale: 5,
                      child: Image.network(url),
                    ),
            ),
          ],
        ),
      );
    },
  );
}

  Widget _body() {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          _profileHeader(),
          const SizedBox(height: 14),

          _infoTile(
            title: "Full Name",
            value: _s(_profile['full_name']),
            icon: Icons.person_outline,
          ),
          _infoTile(
            title: "Mobile Number",
            value: _s(_profile['phone']),
            icon: Icons.phone_outlined,
          ),
          _infoTile(
            title: "Email Address",
            value: _s(_profile['actual_email']),
            icon: Icons.email_outlined,
          ),
          _infoTile(
            title: "Expected Salary",
            value: _salaryRange(),
            icon: Icons.currency_rupee,
          ),
          _infoTile(
            title: "Total Experience",
            value: _experienceText(_i(_profile['total_experience_years'])),
            icon: Icons.work_outline,
          ),
          _infoTile(
            title: "Highest Education",
            value: _s(_profile['highest_education']),
            icon: Icons.school_outlined,
          ),
          _infoTile(
            title: "Skills",
            value: _skillsText(_profile['skills']),
            icon: Icons.psychology_alt_outlined,
          ),
          _infoTile(
            title: "Bio",
            value: _s(_profile['bio']),
            icon: Icons.info_outline,
          ),
          _infoTile(
            title: "Current Location",
            value: _locationText(),
            icon: Icons.location_on_outlined,
          ),
          _infoTile(
            title: "Preferred Job Type",
            value: _s(_profile['preferred_job_type']),
            icon: Icons.badge_outlined,
          ),
          _infoTile(
            title: "Notice Period (days)",
            value: _i(_profile['notice_period_days']) > 0
                ? "${_profile['notice_period_days']} days"
                : "",
            icon: Icons.timer_outlined,
          ),
          _infoTile(
            title: "Open to Work",
            value: _b(_profile['is_open_to_work']) ? "Yes" : "No",
            icon: Icons.flag_outlined,
          ),
          _infoTile(
  title: "Resume",
  value: _s(_profile['resume_url']),
  icon: Icons.description_outlined,
),
            onTap: _s(_profile['resume_url']).isEmpty
                ? null
                : () => _openUrl(_profile['resume_url']),
          ),
        ],
      ),
    );
  }

  Widget _updateButton() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
        color: Colors.white,
        child: SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: _openEdit,
            style: ElevatedButton.styleFrom(
              backgroundColor: KhilonjiyaUI.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              "Edit Profile",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
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
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: KhilonjiyaUI.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Profile",
                      style: KhilonjiyaUI.hTitle.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
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