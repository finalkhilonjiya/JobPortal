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

  static const int _pageSize = 20;

  final CandidateDatabaseService _service = CandidateDatabaseService();
  final EmployerApplicantsService _applicantsService = EmployerApplicantsService();
  final EmployerSubscriptionService _subService = EmployerSubscriptionService();
  final TextEditingController _searchCtrl = TextEditingController();

  bool _loading = true;
  bool _loadingMore = false;
  bool _hasFullAccess = false;
  List<Map<String, dynamic>> _candidates = [];
  int _totalCount = 0;

  // Filters
  String? _state;
  String? _district;
  String? _qualification;

  List<String> _stateOptions = [];
  List<String> _districtOptions = [];
  List<String> _qualificationOptions = [];

  bool get _hasActiveFilters =>
      (_state ?? '').isNotEmpty ||
      (_district ?? '').isNotEmpty ||
      (_qualification ?? '').isNotEmpty;

  bool get _hasMore => _candidates.length < _totalCount;

  @override
  void initState() {
    super.initState();
    _loadFilterOptions();
    _load(reset: true);
  }

  Future<void> _loadFilterOptions() async {
    try {
      final opts = await _service.getFilterOptions();
      if (!mounted) return;
      setState(() {
        _stateOptions = opts.states;
        _districtOptions = opts.districts;
        _qualificationOptions = opts.qualifications;
      });
    } catch (_) {
      // Non-fatal — filter chips just won't have options if this fails.
    }
  }

  Future<void> _load({bool reset = false}) async {

    if (reset) {
      setState(() {
        _loading = true;
        _candidates = [];
        _totalCount = 0;
      });
    } else {
      setState(() => _loadingMore = true);
    }

    try {
      // Checked independently of the candidate list so the banner is
      // correct even when there are zero results for a search/filter.
      final active = await _subService.isPremiumActive();

      final result = await _service.getCandidates(
        search: _searchCtrl.text,
        state: _state,
        district: _district,
        qualification: _qualification,
        limit: _pageSize,
        offset: reset ? 0 : _candidates.length,
      );

      if (!mounted) return;

      setState(() {
        if (reset) {
          _candidates = result.candidates;
        } else {
          _candidates = [..._candidates, ...result.candidates];
        }
        _totalCount = result.totalCount;
        _hasFullAccess = active;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {

      if (!mounted) return;

      setState(() {
        _loading = false;
        _loadingMore = false;
      });

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
    ).then((_) => _load(reset: true));
  }

  // ------------------------------------------------------------
  // FILTER SHEET — State / District / Qualification
  // ------------------------------------------------------------
  Future<void> _openFilterSheet() async {

    String? state = _state;
    String? district = _district;
    String? qualification = _qualification;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Row(
                      children: [
                        const Text(
                          "Filter Candidates",
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setSheetState(() {
                              state = null;
                              district = null;
                              qualification = null;
                            });
                          },
                          child: const Text("Clear"),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    _filterDropdown(
                      label: "State",
                      value: state,
                      options: _stateOptions,
                      onChanged: (v) => setSheetState(() => state = v),
                    ),

                    const SizedBox(height: 12),

                    _filterDropdown(
                      label: "District",
                      value: district,
                      options: _districtOptions,
                      onChanged: (v) => setSheetState(() => district = v),
                    ),

                    const SizedBox(height: 12),

                    _filterDropdown(
                      label: "Qualification",
                      value: qualification,
                      options: _qualificationOptions,
                      onChanged: (v) => setSheetState(() => qualification = v),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          setState(() {
                            _state = state;
                            _district = district;
                            _qualification = qualification;
                          });
                          _load(reset: true);
                        },
                        child: const Text("Apply Filters"),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _filterDropdown({
    required String label,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: (value != null && options.contains(value)) ? value : null,
          hint: Text("Any $label"),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF7F8FA),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
          items: [
            DropdownMenuItem<String>(value: null, child: Text("Any $label")),
            ...options.map((o) => DropdownMenuItem<String>(value: o, child: Text(o))),
          ],
          onChanged: onChanged,
        ),
      ],
    );
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
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.filter_list),
                if (_hasActiveFilters)
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF16A34A),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _openFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [

          if (!_hasFullAccess) _lockedBanner(),

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
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
              onSubmitted: (_) => _load(reset: true),
            ),
          ),

          if (_hasActiveFilters) _activeFiltersRow(),

          if (!_loading)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Showing ${_candidates.length} of $_totalCount",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _candidates.isEmpty
                    ? const Center(child: Text("No candidates found"))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                        itemCount: _candidates.length + (_hasMore ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          if (i >= _candidates.length) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: _loadingMore
                                    ? const CircularProgressIndicator()
                                    : OutlinedButton(
                                        onPressed: () => _load(),
                                        child: const Text("Load More"),
                                      ),
                              ),
                            );
                          }
                          return _candidateCard(_candidates[i]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _activeFiltersRow() {
    final chips = <Widget>[];

    if ((_state ?? '').isNotEmpty) {
      chips.add(_filterChip("State: $_state", () {
        setState(() => _state = null);
        _load(reset: true);
      }));
    }
    if ((_district ?? '').isNotEmpty) {
      chips.add(_filterChip("District: $_district", () {
        setState(() => _district = null);
        _load(reset: true);
      }));
    }
    if ((_qualification ?? '').isNotEmpty) {
      chips.add(_filterChip("Qualification: $_qualification", () {
        setState(() => _qualification = null);
        _load(reset: true);
      }));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Wrap(spacing: 8, runSpacing: 8, children: chips),
    );
  }

  Widget _filterChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onRemove,
      backgroundColor: const Color(0xFFDCFCE7),
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
