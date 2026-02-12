import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/ui/khilonjiya_ui.dart';
import '../../../services/job_service.dart';

// FIX: correct import path for your project
import '../../job_application_form.dart';

class JobDetailsPage extends StatefulWidget {
  final Map<String, dynamic> job;
  final bool isSaved;
  final VoidCallback onSaveToggle;

  const JobDetailsPage({
    Key? key,
    required this.job,
    required this.isSaved,
    required this.onSaveToggle,
  }) : super(key: key);

  @override
  State<JobDetailsPage> createState() => _JobDetailsPageState();
}

class _JobDetailsPageState extends State<JobDetailsPage> {
  final JobService _jobService = JobService();

  bool _isApplied = false;
  bool _checking = true;

  bool _descExpanded = false;

  @override
  void initState() {
    super.initState();
    _checkApplied();
  }

  Future<void> _checkApplied() async {
    try {
      final apps = await _jobService.getUserAppliedJobs();
      final jobId = widget.job['id']?.toString();

      _isApplied = apps.any((row) {
        final listingId = row['listing_id']?.toString();
        return listingId == jobId;
      });
    } catch (_) {
      _isApplied = false;
    }

    if (!mounted) return;
    setState(() => _checking = false);
  }

  // ------------------------------------------------------------
  // APPLY
  // ------------------------------------------------------------
  Future<void> _applyNow() async {
    if (_checking || _isApplied) return;

    final jobId = widget.job['id']?.toString();
    if (jobId == null || jobId.trim().isEmpty) return;

    final res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JobApplicationForm(jobId: jobId),
      ),
    );

    if (res == true) {
      if (!mounted) return;
      setState(() => _isApplied = true);
    } else {
      await _checkApplied();
    }
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final job = widget.job;

    final title = (job['job_title'] ?? '').toString();
    final company = (job['company_name'] ?? '').toString();
    final location = (job['district'] ?? '').toString();

    final salaryMin = job['salary_min'];
    final salaryMax = job['salary_max'];

    final description = (job['job_description'] ?? '').toString();

    // FIX: skills_required may be List OR String OR null
    final skills = _safeSkills(job['skills_required']);

    final postedAt = job['created_at']?.toString();
    final companyDesc = (job['company_description'] ??
            'Company information not available.')
        .toString();

    return Scaffold(
      backgroundColor: KhilonjiyaUI.bg,

      // Bottom bar
      bottomNavigationBar: _buildApplyBottomBar(
        salaryText: _salary(salaryMin, salaryMax),
      ),

      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildTopBar()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _jobHeroCard(
                      title: title,
                      company: company,
                      location: location,
                      salary: _salary(salaryMin, salaryMax),
                      postedText: _postedAgo(postedAt),
                    ),
                    const SizedBox(height: 14),

                    _quickInfoChips(job),

                    const SizedBox(height: 16),

                    _sectionCard(
                      title: "Job Description",
                      child: _descriptionBlock(description),
                    ),

                    const SizedBox(height: 14),

                    if (skills.isNotEmpty)
                      _sectionCard(
                        title: "Key Skills",
                        child: _skillsWrap(skills),
                      ),

                    if (skills.isNotEmpty) const SizedBox(height: 14),

                    _sectionCard(
                      title: "Roles & Responsibilities",
                      child: _bulletList([
                        "Build and maintain high-quality mobile applications",
                        "Collaborate with design and backend teams",
                        "Ensure clean UI and good performance",
                        "Write maintainable code and follow best practices",
                      ]),
                    ),

                    const SizedBox(height: 14),

                    _sectionCard(
                      title: "Company Overview",
                      child: _companyOverview(
                        company: company,
                        companyDesc: companyDesc,
                      ),
                    ),

                    const SizedBox(height: 18),

                    Text(
                      "Similar jobs",
                      style: KhilonjiyaUI.hTitle,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 145,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: 6,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 12),
                        itemBuilder: (_, i) => _similarJobCard(),
                      ),
                    ),

                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // TOP BAR
  // ------------------------------------------------------------
  Widget _buildTopBar() {
    return Container(
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
              "Job Details",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: KhilonjiyaUI.hTitle,
            ),
          ),
          IconButton(
            onPressed: widget.onSaveToggle,
            icon: Icon(
              widget.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border,
              color: widget.isSaved ? KhilonjiyaUI.primary : KhilonjiyaUI.text,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // HERO CARD
  // ------------------------------------------------------------
  Widget _jobHeroCard({
    required String title,
    required String company,
    required String location,
    required String salary,
    required String postedText,
  }) {
    return Container(
      decoration: KhilonjiyaUI.cardDecoration(radius: 20),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CompanyLogo(company: company),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.isEmpty ? "Job Title" : title,
                      style: KhilonjiyaUI.h1,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      company.isEmpty ? "Company" : company,
                      style: KhilonjiyaUI.sub.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _metaRow(
            Icons.location_on_outlined,
            location.isEmpty ? "Location not set" : location,
          ),
          const SizedBox(height: 8),
          _metaRow(Icons.currency_rupee_rounded, salary),
          const SizedBox(height: 8),
          _metaRow(Icons.access_time_rounded, postedText),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: KhilonjiyaUI.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: KhilonjiyaUI.primary.withOpacity(0.18),
                ),
              ),
              child: Text(
                "Actively hiring",
                style: KhilonjiyaUI.caption.copyWith(
                  color: KhilonjiyaUI.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: KhilonjiyaUI.body.copyWith(
              color: const Color(0xFF334155),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // QUICK INFO CHIPS
  // ------------------------------------------------------------
  Widget _quickInfoChips(Map<String, dynamic> job) {
    final chips = [
      {
        "icon": Icons.work_outline_rounded,
        "label": "Job type",
        "value": (job['job_type'] ?? 'Full-time').toString(),
      },
      {
        "icon": Icons.home_work_outlined,
        "label": "Work mode",
        "value": (job['work_mode'] ?? 'Onsite').toString(),
      },
      {
        "icon": Icons.timeline_rounded,
        "label": "Experience",
        "value": (job['experience'] ?? 'Any').toString(),
      },
    ];

    return Row(
      children: chips.map((c) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: c == chips.last ? 0 : 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: KhilonjiyaUI.border),
            ),
            child: Row(
              children: [
                Icon(
                  c["icon"] as IconData,
                  size: 18,
                  color: KhilonjiyaUI.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (c["label"] ?? '').toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: KhilonjiyaUI.caption.copyWith(fontSize: 10.8),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        (c["value"] ?? '').toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: KhilonjiyaUI.body.copyWith(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ------------------------------------------------------------
  // SECTION CARD
  // ------------------------------------------------------------
  Widget _sectionCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: KhilonjiyaUI.cardDecoration(radius: 20),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: KhilonjiyaUI.hTitle),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // DESCRIPTION
  // ------------------------------------------------------------
  Widget _descriptionBlock(String description) {
    final d = description.trim().isEmpty
        ? "No description provided for this job."
        : description.trim();

    final short = d.length > 280 ? d.substring(0, 280) : d;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _descExpanded ? d : (short + (d.length > 280 ? "..." : "")),
          style: KhilonjiyaUI.body.copyWith(
            color: const Color(0xFF475569),
            height: 1.6,
          ),
        ),
        if (d.length > 280) ...[
          const SizedBox(height: 10),
          InkWell(
            onTap: () => setState(() => _descExpanded = !_descExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                _descExpanded ? "Read less" : "Read more",
                style: KhilonjiyaUI.link,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ------------------------------------------------------------
  // SKILLS
  // ------------------------------------------------------------
  Widget _skillsWrap(List<String> skills) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: skills.map((s) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: KhilonjiyaUI.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: KhilonjiyaUI.primary.withOpacity(0.12)),
          ),
          child: Text(
            s,
            style: KhilonjiyaUI.body.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              color: KhilonjiyaUI.primary,
            ),
          ),
        );
      }).toList(),
    );
  }

  // ------------------------------------------------------------
  // BULLET LIST
  // ------------------------------------------------------------
  Widget _bulletList(List<String> items) {
    return Column(
      children: items.map((t) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(top: 7),
                decoration: BoxDecoration(
                  color: KhilonjiyaUI.primary,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  t,
                  style: KhilonjiyaUI.body.copyWith(
                    color: const Color(0xFF475569),
                    height: 1.55,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ------------------------------------------------------------
  // COMPANY OVERVIEW
  // ------------------------------------------------------------
  Widget _companyOverview({
    required String company,
    required String companyDesc,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                company.isEmpty ? "Company" : company,
                style: KhilonjiyaUI.body.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 14.5,
                ),
              ),
            ),
            const Icon(
              Icons.verified_rounded,
              size: 18,
              color: KhilonjiyaUI.primary,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          companyDesc,
          style: KhilonjiyaUI.body.copyWith(
            color: const Color(0xFF475569),
            height: 1.55,
          ),
        ),
        const SizedBox(height: 14),
        OutlinedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Company profile coming soon")),
            );
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF0F172A),
            side: BorderSide(color: KhilonjiyaUI.border),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "View Company Profile",
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, size: 18),
            ],
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // SIMILAR JOB CARD (UI only)
  // ------------------------------------------------------------
  Widget _similarJobCard() {
    return Container(
      width: 280,
      decoration: KhilonjiyaUI.cardDecoration(radius: 20),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Flutter Developer",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: KhilonjiyaUI.body.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            "Khilonjiya Verified",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: KhilonjiyaUI.sub,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  "Guwahati • Hybrid",
                  style: KhilonjiyaUI.sub.copyWith(
                    color: const Color(0xFF475569),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "₹4L - ₹7L",
            style: KhilonjiyaUI.body.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // BOTTOM BAR
  // ------------------------------------------------------------
  Widget _buildApplyBottomBar({required String salaryText}) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: KhilonjiyaUI.border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              salaryText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: KhilonjiyaUI.sub.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_checking || _isApplied) ? null : _applyNow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: KhilonjiyaUI.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE2E8F0),
                  disabledForegroundColor: const Color(0xFF64748B),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  _checking
                      ? "Checking..."
                      : (_isApplied ? "Already Applied" : "Apply Now"),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // UTILS
  // ------------------------------------------------------------
  List<String> _safeSkills(dynamic raw) {
    if (raw == null) return [];

    if (raw is List) {
      return raw.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList();
    }

    // Sometimes Supabase returns a comma separated string
    if (raw is String) {
      final s = raw.trim();
      if (s.isEmpty) return [];

      // If it looks like "['a','b']" handle roughly
      if (s.startsWith('[') && s.endsWith(']')) {
        final inner = s.substring(1, s.length - 1);
        return inner
            .split(',')
            .map((e) => e.replaceAll("'", "").replaceAll('"', '').trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }

      return s
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return [];
  }

  String _salary(dynamic min, dynamic max) {
    int? toInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    final mn = toInt(min);
    final mx = toInt(max);

    String f(int v) => '${(v / 100000).toStringAsFixed(1)} Lacs PA';

    if (mn != null && mx != null) return '${f(mn)} - ${f(mx)}';
    if (mn != null) return f(mn);
    return 'Not disclosed';
  }

  String _postedAgo(String? date) {
    if (date == null) return 'Recently';

    final d = DateTime.tryParse(date);
    if (d == null) return 'Recently';

    final diff = DateTime.now().difference(d);

    if (diff.inHours < 24) return 'Posted today';
    if (diff.inDays == 1) return 'Posted 1 day ago';
    return 'Posted ${diff.inDays} days ago';
  }
}

class _CompanyLogo extends StatelessWidget {
  final String company;
  const _CompanyLogo({required this.company});

  @override
  Widget build(BuildContext context) {
    final letter = company.isNotEmpty ? company[0].toUpperCase() : 'C';
    final color = Colors.primaries[
        Random(company.hashCode).nextInt(Colors.primaries.length)];

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: KhilonjiyaUI.border),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}