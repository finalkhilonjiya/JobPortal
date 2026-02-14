import 'package:flutter/material.dart';

import '../../core/ui/khilonjiya_ui.dart';
import '../../services/job_seeker_home_service.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({Key? key}) : super(key: key);

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final JobSeekerHomeService _service = JobSeekerHomeService();

  bool _loading = true;
  bool _saving = false;
  bool _disposed = false;

  Map<String, dynamic> _profile = {};

  // Controllers
  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  final _skillsCtrl = TextEditingController();
  final List<String> _skills = [];

  final _educationCtrl = TextEditingController();
  final _experienceYearsCtrl = TextEditingController();

  final _expectedSalaryCtrl = TextEditingController();
  final _noticeDaysCtrl = TextEditingController();

  // Dropdowns
  String _jobType = 'Any';
  String _employmentType = 'Any';

  final _jobTypeOptions = const [
    'Any',
    'Full-time',
    'Part-time',
    'Internship',
    'Contract',
    'Walk-in',
  ];

  final _employmentTypeOptions = const [
    'Any',
    'On-site',
    'Hybrid',
    'Remote',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _disposed = true;

    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _locationCtrl.dispose();
    _bioCtrl.dispose();
    _skillsCtrl.dispose();
    _educationCtrl.dispose();
    _experienceYearsCtrl.dispose();
    _expectedSalaryCtrl.dispose();
    _noticeDaysCtrl.dispose();

    super.dispose();
  }

  Future<void> _load() async {
    if (!_disposed) setState(() => _loading = true);

    try {
      _profile = await _service.fetchMyProfile();

      _fullNameCtrl.text = (_profile['full_name'] ?? '').toString();
      _phoneCtrl.text = (_profile['phone'] ?? '').toString();
      _cityCtrl.text = (_profile['current_city'] ?? '').toString();
      _stateCtrl.text = (_profile['current_state'] ?? '').toString();
      _locationCtrl.text = (_profile['location_text'] ?? '').toString();
      _bioCtrl.text = (_profile['bio'] ?? '').toString();

      _educationCtrl.text = (_profile['highest_education'] ?? '').toString();
      _experienceYearsCtrl.text =
          (_profile['total_experience_years'] ?? '').toString();

      final expSal = _profile['expected_salary_min'];
      _expectedSalaryCtrl.text = (expSal ?? '').toString();

      _noticeDaysCtrl.text = (_profile['notice_period_days'] ?? '').toString();

      // skills
      _skills.clear();
      final rawSkills = _profile['skills'] ?? _profile['skills_required'];
      if (rawSkills is List) {
        for (final s in rawSkills) {
          final v = s.toString().trim();
          if (v.isNotEmpty) _skills.add(v);
        }
      } else if (rawSkills is String) {
        // if stored as comma separated
        final parts = rawSkills.split(',');
        for (final p in parts) {
          final v = p.trim();
          if (v.isNotEmpty) _skills.add(v);
        }
      }

      // dropdowns
      _jobType = (_profile['preferred_job_type'] ?? 'Any').toString();
      if (!_jobTypeOptions.contains(_jobType)) _jobType = 'Any';

      _employmentType = (_profile['preferred_employment_type'] ?? 'Any')
          .toString();
      if (!_employmentTypeOptions.contains(_employmentType)) {
        _employmentType = 'Any';
      }
    } catch (_) {
      _profile = {};
    }

    if (_disposed) return;
    setState(() => _loading = false);
  }

  // ------------------------------------------------------------
  // UI HELPERS
  // ------------------------------------------------------------
  InputDecoration _dec(String hint, {IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: KhilonjiyaUI.sub,
      prefixIcon: icon == null ? null : Icon(icon),
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
    );
  }

  Widget _sectionTitle(String title, {String? sub}) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: KhilonjiyaUI.hTitle.copyWith(fontSize: 15.5),
          ),
          if (sub != null) ...[
            const SizedBox(height: 4),
            Text(sub, style: KhilonjiyaUI.sub),
          ],
        ],
      ),
    );
  }

  void _addSkill() {
    final raw = _skillsCtrl.text.trim();
    if (raw.isEmpty) return;

    final parts = raw.split(',');
    bool added = false;

    for (final p in parts) {
      final v = p.trim();
      if (v.isEmpty) continue;
      if (_skills.any((e) => e.toLowerCase() == v.toLowerCase())) continue;
      _skills.add(v);
      added = true;
    }

    if (added) {
      _skillsCtrl.clear();
      setState(() {});
    }
  }

  Future<void> _save() async {
    if (_saving) return;

    final fullName = _fullNameCtrl.text.trim();
    if (fullName.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your full name")),
      );
      return;
    }

    int toInt(String s) => int.tryParse(s.trim()) ?? 0;

    final expYears = toInt(_experienceYearsCtrl.text);
    final expectedSalary = toInt(_expectedSalaryCtrl.text);
    final noticeDays = toInt(_noticeDaysCtrl.text);

    final payload = <String, dynamic>{
      'full_name': fullName,
      'phone': _phoneCtrl.text.trim(),
      'current_city': _cityCtrl.text.trim(),
      'current_state': _stateCtrl.text.trim(),
      'location_text': _locationCtrl.text.trim(),
      'bio': _bioCtrl.text.trim(),
      'skills': _skills,
      'highest_education': _educationCtrl.text.trim(),
      'total_experience_years': expYears,
      'expected_salary_min': expectedSalary < 0 ? 0 : expectedSalary,
      'expected_salary_max': (expectedSalary < 0 ? 0 : expectedSalary) + 5000,
      'notice_period_days': noticeDays < 0 ? 0 : noticeDays,
      'preferred_job_type': _jobType,
      'preferred_employment_type': _employmentType,
    };

    setState(() => _saving = true);

    try {
      await _service.updateMyProfile(payload);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully")),
      );

      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update profile")),
      );
    }

    if (!mounted) return;
    setState(() => _saving = false);
  }

  Widget _skillsBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: KhilonjiyaUI.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _skills.map((s) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: KhilonjiyaUI.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      s,
                      style: KhilonjiyaUI.body.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        _skills.remove(s);
                        setState(() {});
                      },
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _skillsCtrl,
                  decoration: _dec("Add skills (comma separated)"),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 52,
                width: 52,
                child: ElevatedButton(
                  onPressed: _addSkill,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KhilonjiyaUI.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Icon(Icons.add),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _body() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        Container(
          decoration: KhilonjiyaUI.cardDecoration(radius: 22),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: KhilonjiyaUI.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: KhilonjiyaUI.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Edit your profile", style: KhilonjiyaUI.hTitle),
                    const SizedBox(height: 4),
                    Text(
                      "Keep your details updated to get better jobs.",
                      style: KhilonjiyaUI.sub,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        _sectionTitle("Basic details"),
        TextField(
          controller: _fullNameCtrl,
          decoration: _dec("Full name", icon: Icons.badge_outlined),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: _dec("Mobile number", icon: Icons.phone_outlined),
        ),

        _sectionTitle("Location"),
        TextField(
          controller: _cityCtrl,
          decoration: _dec("Current city", icon: Icons.location_city_outlined),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _stateCtrl,
          decoration: _dec("Current state", icon: Icons.map_outlined),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _locationCtrl,
          decoration: _dec("Full location (optional)", icon: Icons.place),
        ),

        _sectionTitle("Career"),
        TextField(
          controller: _educationCtrl,
          decoration: _dec("Highest education", icon: Icons.school_outlined),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _experienceYearsCtrl,
          keyboardType: TextInputType.number,
          decoration:
              _dec("Total experience (years)", icon: Icons.work_outline),
        ),
        const SizedBox(height: 12),

        // Expected Salary
        TextField(
          controller: _expectedSalaryCtrl,
          keyboardType: TextInputType.number,
          decoration: _dec(
            "Expected salary per month",
            icon: Icons.currency_rupee_rounded,
          ),
        ),
        const SizedBox(height: 12),

        TextField(
          controller: _noticeDaysCtrl,
          keyboardType: TextInputType.number,
          decoration:
              _dec("Notice period (days)", icon: Icons.calendar_today_outlined),
        ),

        _sectionTitle("Preferences"),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: KhilonjiyaUI.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _jobType,
              isExpanded: true,
              items: _jobTypeOptions
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(
                        e,
                        style: KhilonjiyaUI.body.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() => _jobType = v);
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: KhilonjiyaUI.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _employmentType,
              isExpanded: true,
              items: _employmentTypeOptions
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(
                        e,
                        style: KhilonjiyaUI.body.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() => _employmentType = v);
              },
            ),
          ),
        ),

        _sectionTitle("Skills", sub: "These help us recommend better jobs."),
        _skillsBox(),

        _sectionTitle("About you"),
        TextField(
          controller: _bioCtrl,
          maxLines: 5,
          decoration: _dec("Short bio", icon: Icons.subject_rounded),
        ),
      ],
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
                      "Edit profile",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KhilonjiyaUI.hTitle,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _body(),
            ),
          ],
        ),
      ),

      // Bottom Update Button (world class UX)
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: KhilonjiyaUI.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: KhilonjiyaUI.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.6,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      "Update Profile",
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}