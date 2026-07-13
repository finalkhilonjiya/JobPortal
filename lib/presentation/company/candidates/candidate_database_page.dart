// File: lib/presentation/company/candidates/candidate_database_page.dart

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/candidate_database_service.dart';
import '../../../services/employer_applicants_service.dart';
import '../../../services/employer_subscription_service.dart';
import '../subscription/employer_subscription_page.dart';

class CandidateDatabasePage extends StatefulWidget {

  final String companyId;

  const CandidateDatabasePage({
    Key? key,
    required this.companyId,
  }) : super(key: key);

  @override
  State<CandidateDatabasePage> createState() => _CandidateDatabasePageState();
}

class _CandidateDatabasePageState extends State<CandidateDatabasePage> {

  final CandidateDatabaseService _service = CandidateDatabaseService();
  final EmployerApplicantsService _applicantsService = EmployerApplicantsService();
  final EmployerSubscriptionService _subService = EmployerSubscriptionService();
  final TextEditingController _searchCtrl = TextEditingController();

  bool _loading = true;
  bool _hasFullAccess = false;
  List<Map<String, dynamic>> _candidates = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({String? search}) async {

    setState(() => _loading = true);

    try {
      // Checked independently of the candidate list so the banner is
      // correct even when there are zero results for a search.
      final active = await _subService.isPremiumActive();

      final rows = await _service.getCandidates(search: search);

      if (!mounted) return;

      setState(() {
        _candidates = rows;
        _hasFullAccess = active;
        _loading = false;
      });
    } catch (e) {

      if (!mounted) return;

      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load candidates: $e")),
      );
    }
  }

  void _goToSubscription() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EmployerSubscriptionPage(companyId: widget.companyId),
      ),
    ).then((_) => _load(search: _searchCtrl.text));
  }

  // ------------------------------------------------------------
  // OPEN RESUME — same viewer employers already use for applicants
  // ------------------------------------------------------------
  Future<void> _openResume(Map<String, dynamic> c) async {

    final rawPath = (c['resume_url'] ?? '').toString().trim();

    if (rawPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("This candidate hasn't uploaded a resume")),
      );
      return;
    }

    try {
      final url = await _applicantsService.getPublicOrSignedUrl(rawPath);

      if (url == null || url.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid resume")),
        );
        return;
      }

      final isPdf = Uri.parse(url).path.toLowerCase().endsWith('.pdf');

      if (!mounted) return;

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
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Text("Resume",
                          style: TextStyle(fontWeight: FontWeight.w900)),
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
                Expanded(
                  child: isPdf
                      ? SfPdfViewer.network(url)
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Resume failed to load")),
      );
    }
  }

  // ------------------------------------------------------------
  // CONTACT SHEET — call / email the candidate directly
  // ------------------------------------------------------------
  void _contactCandidate(Map<String, dynamic> c) {

    final phone = (c['mobile_number'] ?? '').toString().trim();
    final email = (c['actual_email'] ?? '').toString().trim();

    if (phone.isEmpty && email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No contact details on file for this candidate")),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (phone.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.call, color: Color(0xFF16A34A)),
                  title: Text(phone),
                  subtitle: const Text("Call candidate"),
                  onTap: () async {
                    Navigator.pop(context);
                    await launchUrl(Uri.parse("tel:$phone"));
                  },
                ),
              if (phone.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.message, color: Color(0xFF16A34A)),
                  title: Text(phone),
                  subtitle: const Text("Message on WhatsApp"),
                  onTap: () async {
                    Navigator.pop(context);
                    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
                    await launchUrl(
                      Uri.parse("https://wa.me/$digits"),
                      mode: LaunchMode.externalApplication,
                    );
                  },
                ),
              if (email.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.email, color: Color(0xFF16A34A)),
                  title: Text(email),
                  subtitle: const Text("Send email"),
                  onTap: () async {
                    Navigator.pop(context);
                    await launchUrl(Uri.parse("mailto:$email"));
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text(
          "Candidate Database",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [

          if (!_hasFullAccess) _lockedBanner(),

          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: "Search by name, title, or skill",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (v) => _load(search: v),
            ),
          ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _candidates.isEmpty
                    ? const Center(child: Text("No candidates found"))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _candidates.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) =>
                            _candidateCard(_candidates[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _lockedBanner() {

    return Container(
      width: double.infinity,
      color: const Color(0xFFFFF7ED),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(Icons.lock, color: Color(0xFFEA580C), size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              "You're browsing in preview mode. Get Khilonjiya Premium to view resumes and contact details.",
              style: TextStyle(fontSize: 12.5),
            ),
          ),
          TextButton(
            onPressed: _goToSubscription,
            child: const Text("Unlock"),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // Small pill button used for View Resume / Contact — sized to
  // always fit on one line regardless of locked/unlocked label.
  // ------------------------------------------------------------
  Widget _actionButton({
    required IconData icon,
    required String label,
    required bool locked,
    required VoidCallback onTap,
    required bool filled,
  }) {

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        ),
        if (locked) ...[
          const SizedBox(width: 3),
          const Icon(Icons.lock, size: 12),
        ],
      ],
    );

    if (filled) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF16A34A),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: onTap,
        child: child,
      );
    }

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: onTap,
      child: child,
    );
  }

  Widget _candidateCard(Map<String, dynamic> c) {

    final name = (c['full_name'] ?? 'Candidate').toString();
    final title = (c['current_job_title'] ?? '').toString();
    final company = (c['current_company'] ?? '').toString();
    final city = (c['current_city'] ?? '').toString();
    final state = (c['current_state'] ?? '').toString();
    final exp = c['total_experience_years'];
    final skills = (c['skills'] is List)
        ? List<String>.from(c['skills'])
        : <String>[];
    final hasAccess = c['has_full_access'] == true;
    final boosted = c['is_boost_enabled'] == true;
    final avatar = (c['avatar_url'] ?? '').toString();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openCandidateDetail(c),
        child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: boosted
            ? Border.all(color: const Color(0xFF16A34A), width: 1.2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFE2E8F0),
                backgroundImage:
                    avatar.isNotEmpty ? NetworkImage(avatar) : null,
                child: avatar.isEmpty
                    ? Text(name.isNotEmpty ? name[0].toUpperCase() : "?")
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (boosted) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              "Boosted",
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF16A34A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (title.isNotEmpty || company.isNotEmpty)
                      Text(
                        [title, company].where((e) => e.isNotEmpty).join(" at "),
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    if (city.isNotEmpty || state.isNotEmpty)
                      Text(
                        [city, state].where((e) => e.isNotEmpty).join(", "),
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                  ],
                ),
              ),
            ],
          ),

          if (exp != null) ...[
            const SizedBox(height: 8),
            Text("$exp years experience",
                style: const TextStyle(fontSize: 12.5)),
          ],

          if (skills.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: skills.take(6).map((s) {
                return Chip(
                  label: Text(s, style: const TextStyle(fontSize: 11)),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _actionButton(
                  icon: Icons.description_outlined,
                  label: "View Resume",
                  locked: !hasAccess,
                  filled: false,
                  onTap: () {
                    if (!hasAccess) {
                      _goToSubscription();
                      return;
                    }
                    _openResume(c);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _actionButton(
                  icon: Icons.call,
                  label: "Contact",
                  locked: !hasAccess,
                  filled: true,
                  onTap: () {
                    if (!hasAccess) {
                      _goToSubscription();
                      return;
                    }
                    _contactCandidate(c);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // CANDIDATE DETAIL — full profile, photo, resume, contact.
  // Opened when a card in the database is tapped.
  // ------------------------------------------------------------
  void _openCandidateDetail(Map<String, dynamic> c) {

    final name = (c['full_name'] ?? 'Candidate').toString();
    final title = (c['current_job_title'] ?? '').toString();
    final company = (c['current_company'] ?? '').toString();
    final city = (c['current_city'] ?? '').toString();
    final state = (c['current_state'] ?? '').toString();
    final exp = c['total_experience_years'];
    final bio = (c['bio'] ?? '').toString();
    final resumeHeadline = (c['resume_headline'] ?? '').toString();
    final education = (c['highest_education'] ?? '').toString();
    final notice = c['notice_period_days'];
    final salaryMin = c['expected_salary_min'];
    final salaryMax = c['expected_salary_max'];
    final skills = (c['skills'] is List)
        ? List<String>.from(c['skills'])
        : <String>[];
    final hasAccess = c['has_full_access'] == true;
    final avatar = (c['avatar_url'] ?? '').toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SafeArea(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                children: [

                  Center(
                    child: CircleAvatar(
                      radius: 44,
                      backgroundColor: const Color(0xFFE2E8F0),
                      backgroundImage:
                          avatar.isNotEmpty ? NetworkImage(avatar) : null,
                      child: avatar.isEmpty
                          ? Text(
                              name.isNotEmpty ? name[0].toUpperCase() : "?",
                              style: const TextStyle(fontSize: 28),
                            )
                          : null,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Center(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),

                  if (title.isNotEmpty || company.isNotEmpty)
                    Center(
                      child: Text(
                        [title, company].where((e) => e.isNotEmpty).join(" at "),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),

                  if (city.isNotEmpty || state.isNotEmpty)
                    Center(
                      child: Text(
                        [city, state].where((e) => e.isNotEmpty).join(", "),
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ),

                  const SizedBox(height: 20),

                  if (resumeHeadline.isNotEmpty) ...[
                    _detailSection("Headline", resumeHeadline),
                  ],

                  if (bio.isNotEmpty) ...[
                    _detailSection("About", bio),
                  ],

                  Row(
                    children: [
                      if (exp != null)
                        Expanded(
                          child: _statTile("Experience", "$exp yrs"),
                        ),
                      if (salaryMin != null && salaryMax != null)
                        Expanded(
                          child: _statTile(
                            "Expected Salary",
                            "₹$salaryMin - ₹$salaryMax",
                          ),
                        ),
                    ],
                  ),

                  Row(
                    children: [
                      if (education.isNotEmpty)
                        Expanded(
                          child: _statTile("Education", education),
                        ),
                      if (notice != null)
                        Expanded(
                          child: _statTile("Notice Period", "$notice days"),
                        ),
                    ],
                  ),

                  if (skills.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      "Skills",
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: skills
                          .map((s) => Chip(label: Text(s)))
                          .toList(),
                    ),
                  ],

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: _actionButton(
                          icon: Icons.description_outlined,
                          label: "View Resume",
                          locked: !hasAccess,
                          filled: false,
                          onTap: () {
                            if (!hasAccess) {
                              Navigator.pop(context);
                              _goToSubscription();
                              return;
                            }
                            _openResume(c);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _actionButton(
                          icon: Icons.call,
                          label: "Contact",
                          locked: !hasAccess,
                          filled: true,
                          onTap: () {
                            if (!hasAccess) {
                              Navigator.pop(context);
                              _goToSubscription();
                              return;
                            }
                            _contactCandidate(c);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailSection(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _statTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
