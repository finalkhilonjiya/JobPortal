// File: lib/presentation/common/widgets/pages/job_details_page.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';

import 'dart:math';

import 'package:flutter/material.dart';
import '../../../../routes/app_routes.dart';

import '../../../../core/ui/khilonjiya_ui.dart';
import '../../../../services/job_seeker_home_service.dart';

import '../job_application_form.dart';
import '../cards/job_card_widget.dart';

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
  final JobSeekerHomeService _homeService = JobSeekerHomeService();

  bool _isApplied = false;
  bool _checkingApplied = true;

  bool _descExpanded = false;

  bool _loadingExtras = true;
  bool _loadingCompany = true;
  bool _loadingReviews = true;
  String? _employerPhone;
bool _loadingContact = false;
bool _canViewContact = false;

  // Company
  Map<String, dynamic>? _company;
  bool _isCompanyFollowed = false;

  // Reviews
  List<Map<String, dynamic>> _reviews = [];

  // Similar jobs
  List<Map<String, dynamic>> _similarJobs = [];
  Set<String> _savedJobIds = {};

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  Future<void> _initAll() async {
    await Future.wait([
      _checkApplied(),
      _loadExtras(),
    ]);
  }

  // ------------------------------------------------------------
  // APPLY STATUS
  // ------------------------------------------------------------
  Future<void> _checkApplied() async {
    setState(() => _checkingApplied = true);

    try {
      final jobId = widget.job['id']?.toString();
      if (jobId == null || jobId.trim().isEmpty) {
        _isApplied = false;
      } else {
        final applied = await _homeService.hasAppliedToJob(jobId);
        _isApplied = applied;
      }
    } catch (_) {
      _isApplied = false;
    }

    if (!mounted) return;
    setState(() => _checkingApplied = false);
  }

  // ------------------------------------------------------------
  // LOAD REAL COMPANY + REVIEWS + SIMILAR JOBS + SAVED IDS
  // ------------------------------------------------------------

  
Future<void> _loadExtras() async {
  if (!mounted) return;

  setState(() => _loadingExtras = true);

  final jobId = widget.job['id']?.toString() ?? '';
  final companyObj = widget.job['companies'];

  String companyId = '';

  if (companyObj is Map && companyObj['id'] != null) {
    companyId = companyObj['id'].toString();
  } else if (widget.job['company_id'] != null) {
    companyId = widget.job['company_id'].toString();
  }

  _employerPhone = null;
  _canViewContact = false;
  _loadingContact = false;

  try {
    _savedJobIds = await _homeService.getUserSavedJobs();
  } catch (_) {
    _savedJobIds = {};
  }

  if (jobId.trim().isNotEmpty) {
    try {
      _similarJobs = await _homeService.fetchSimilarJobs(
        jobId: jobId,
        limit: 12,
      );
    } catch (_) {
      _similarJobs = [];
    }
  }

  if (companyId.trim().isNotEmpty) {
    if (mounted) {
      setState(() => _loadingCompany = true);
    }

    try {
      _company = await _homeService.fetchCompanyDetails(
        companyId,
      );
    } catch (_) {
      _company = null;
    }

    try {
      _isCompanyFollowed =
          await _homeService.isCompanyFollowed(
        companyId,
      );
    } catch (_) {
      _isCompanyFollowed = false;
    }

    if (mounted) {
      setState(() => _loadingCompany = false);
    }

    if (mounted) {
      setState(() => _loadingReviews = true);
    }

    try {
      _reviews = await _homeService.fetchCompanyReviews(
        companyId: companyId,
        limit: 10,
      );
    } catch (_) {
      _reviews = [];
    }

    if (mounted) {
      setState(() => _loadingReviews = false);
    }

    try {
      _loadingContact = true;

      final isPro =
          await _homeService.isUserProSubscribed();

      final isVerified =
          _company?['is_verified'] == true;

      if (isPro &&
          isVerified &&
          jobId.trim().isNotEmpty) {
        final phone =
            await _homeService.getEmployerContactForJob(
          jobId,
        );

        _employerPhone = phone;

        _canViewContact =
            phone != null &&
            phone.trim().isNotEmpty;
      } else {
        _employerPhone = null;
        _canViewContact = false;
      }
    } catch (_) {
      _employerPhone = null;
      _canViewContact = false;
    } finally {
      _loadingContact = false;
    }
  } else {
    _company = null;
    _reviews = [];
    _isCompanyFollowed = false;

    _employerPhone = null;
    _canViewContact = false;
    _loadingContact = false;

    if (mounted) {
      setState(() {
        _loadingCompany = false;
        _loadingReviews = false;
      });
    }
  }

  if (!mounted) return;

  setState(() => _loadingExtras = false);
}  
      
      // ------------------------------------------------------------
  Future<void> _applyNow() async {
  if (_checkingApplied || _isApplied) return;

  final jobId = widget.job['id']?.toString();
  if (jobId == null || jobId.trim().isEmpty) return;

  final isPro = await _homeService.isUserProSubscribed();

  if (!isPro) {
    if (!mounted) return;

    final res = await Navigator.pushNamed(
      context,
      AppRoutes.subscribe,
    );

    // retry after subscription
    if (res == true) {
      await _applyNow();
    }

    return;
  }

  final res = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => JobApplicationForm(jobId: jobId),
    ),
  );

  if (!mounted) return;

  if (res == true) {
    setState(() => _isApplied = true);
  } else {
    await _checkApplied();
  }
}
  // ------------------------------------------------------------
  // SAVE / UNSAVE
  // ------------------------------------------------------------
  Future<void> _toggleSaveJob(String jobId) async {
    try {
      final isSaved = await _homeService.toggleSaveJob(jobId);
      if (!mounted) return;

      setState(() {
        isSaved ? _savedJobIds.add(jobId) : _savedJobIds.remove(jobId);
      });
    } catch (_) {}
  }

  // ------------------------------------------------------------
  // FOLLOW COMPANY
  // ------------------------------------------------------------
  
  // ------------------------------------------------------------
  // OPEN ANOTHER JOB DETAILS (SIMILAR JOB)
  // ------------------------------------------------------------
  
  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------
  @override
Widget build(BuildContext context) {
  final job = widget.job;

  final title = (job['job_title'] ?? '').toString();

  final companyObj = job['companies'];
  final companyName = (companyObj is Map
          ? (companyObj['name'] ?? '').toString()
          : (job['company_name'] ?? '').toString())
      .trim();

  final location = (job['district'] ?? '').toString();

  final salaryMin = job['salary_min'];
  final salaryMax = job['salary_max'];
  final salaryPeriod =
      (job['salary_period'] ?? 'Month').toString().trim();

  final description =
      (job['job_description'] ?? '').toString();

  final skills = _safeSkills(job['skills_required']);

  final postedAt = job['created_at']?.toString();

  final responsibilities =
      (job['responsibilities'] ?? '').toString().trim();

  // ✅ check if requirements exist
  final hasRequirements =
      (job['requirements'] ?? '').toString().trim().isNotEmpty ||
      (job['education_required'] ?? '').toString().trim().isNotEmpty ||
      (job['experience_required'] ?? '').toString().trim().isNotEmpty;

  return Scaffold(
    backgroundColor: KhilonjiyaUI.bg,
    bottomNavigationBar: _buildApplyBottomBar(),
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
                  // HERO
                  _jobHeroCard(
                    title: title,
                    company: companyName,
                    location: location,
                    salary: _salaryText(
                      salaryMin: salaryMin,
                      salaryMax: salaryMax,
                      salaryPeriod: salaryPeriod,
                    ),
                    postedText: _postedAgo(postedAt),
                  ),

                  const SizedBox(height: 14),

                  // QUICK INFO
                  _quickInfoChips(job),

                  const SizedBox(height: 16),

                  // DESCRIPTION
                  _sectionCard(
                    title: "Job Description",
                    child: _descriptionBlock(description),
                  ),

                  const SizedBox(height: 14),

                  // SKILLS
                  if (skills.isNotEmpty) ...[
                    _sectionCard(
                      title: "Key Skills",
                      child: _skillsWrap(skills),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // ✅ REQUIREMENTS (FIXED)
                  if (hasRequirements) ...[
                    _sectionCard(
                      title: "Requirements",
                      child: _requirementsBlock(job),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // RESPONSIBILITIES
                  _sectionCard(
                    title: "Roles & Responsibilities",
                    child: responsibilities.isEmpty
                        ? Text(
                            "No responsibilities provided for this job.",
                            style: KhilonjiyaUI.body.copyWith(
                              color: const Color(0xFF475569),
                              height: 1.55,
                            ),
                          )
                        : Text(
                            responsibilities,
                            style: KhilonjiyaUI.body.copyWith(
                              color: const Color(0xFF475569),
                              height: 1.55,
                            ),
                          ),
                  ),

                  const SizedBox(height: 14),

                  // COMPANY
                  _sectionCard(
                    title: "Company Overview",
                    child: _buildCompanyOverview(),
                  ),
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
  final companyMap =
      widget.job['companies'] as Map<String, dynamic>?;

  final isVerified =
      companyMap?['is_verified'] == true;

  String companyLogoUrl = '';

  final rawLogo = (
    companyMap?['logo_url'] ??
    _company?['logo_url'] ??
    ''
  ).toString().trim();

  if (rawLogo.isNotEmpty) {
    companyLogoUrl = Supabase
        .instance
        .client
        .storage
        .from('company-assets')
        .getPublicUrl(rawLogo);
  }

  return Container(
    decoration: KhilonjiyaUI.cardDecoration(radius: 20),
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _CompanyLogo(
              company: company,
              logoUrl: companyLogoUrl,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title.isEmpty
                        ? "Job Title"
                        : title,
                    style: KhilonjiyaUI.h1,
                  ),

                  const SizedBox(height: 4),

                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          company.isEmpty
                              ? "Company"
                              : company,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              KhilonjiyaUI.sub.copyWith(
                            fontSize: 13,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                      ),

                      if (isVerified) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.verified_rounded,
                          size: 16,
                          color:
                              KhilonjiyaUI.primary,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        _metaRow(
          Icons.location_on_outlined,
          location.isEmpty
              ? "Location not set"
              : location,
        ),

        const SizedBox(height: 8),

        _metaRow(
          Icons.currency_rupee_rounded,
          salary,
        ),

        const SizedBox(height: 8),

        _metaRow(
          Icons.access_time_rounded,
          postedText,
        ),

        const SizedBox(height: 12),

        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: KhilonjiyaUI.primary
                  .withOpacity(0.10),
              borderRadius:
                  BorderRadius.circular(999),
              border: Border.all(
                color: KhilonjiyaUI.primary
                    .withOpacity(0.18),
              ),
            ),
            child: Text(
              "Actively hiring",
              style:
                  KhilonjiyaUI.caption.copyWith(
                color:
                    KhilonjiyaUI.primary,
                fontWeight:
                    FontWeight.w800,
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
  // QUICK INFO CHIPS (REAL FIELDS)
  // ------------------------------------------------------------
  Widget _quickInfoChips(Map<String, dynamic> job) {
    final chips = [
      {
        "icon": Icons.work_outline_rounded,
        "label": "Job type",
        "value": (job['job_type'] ?? 'Not set').toString(),
      },
      {
        "icon": Icons.home_work_outlined,
        "label": "Work mode",
        "value": (job['work_mode'] ?? 'Not set').toString(),
      },
      {
        "icon": Icons.timeline_rounded,
        "label": "Experience",
        "value": (job['experience_required'] ?? 'Not set').toString(),
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
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEDD5), // ✅ LIGHT ORANGE
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: const Color(0xFFFCD34D),
          ),
        ),
        child: Text(
          s,
          style: KhilonjiyaUI.body.copyWith(
            fontSize: 12.5,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF9A3412), // ✅ DARK ORANGE TEXT
          ),
        ),
      );
    }).toList(),
  );
}

Widget _requirementsBlock(Map<String, dynamic> job) {
  final requirements =
      (job['requirements'] ?? '').toString().trim();

  final education =
      (job['education_required'] ?? '').toString().trim();

  final experience =
      (job['experience_required'] ?? '').toString().trim();

  final List<Map<String, String>> items = [];

  if (requirements.isNotEmpty) {
    items.add({
      "label": "Requirements",
      "value": requirements,
    });
  }

  if (education.isNotEmpty) {
    items.add({
      "label": "Education",
      "value": education,
    });
  }

  if (experience.isNotEmpty) {
    items.add({
      "label": "Experience",
      "value": experience,
    });
  }

  if (items.isEmpty) {
    return Text(
      "No requirements specified for this job.",
      style: KhilonjiyaUI.body.copyWith(
        color: const Color(0xFF475569),
        height: 1.55,
      ),
    );
  }

  return Column(
    children: items.map((item) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 18,
              color: Color(0xFF2563EB),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: KhilonjiyaUI.body.copyWith(
                    color: const Color(0xFF334155),
                    height: 1.5,
                  ),
                  children: [
                    TextSpan(
                      text: "${item['label']}: ",
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(text: item['value']),
                  ],
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
  // COMPANY OVERVIEW (REAL)
  // ------------------------------------------------------------
  Widget _buildCompanyOverview() {
  if (_loadingCompany) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  final company = _company;

  final name =
      (company?['name'] ?? '').toString().trim();

  final desc =
      (company?['description'] ?? '').toString().trim();

  final industry =
      (company?['industry'] ?? '').toString().trim();

  final size =
      (company?['company_size'] ?? '').toString().trim();

  final website =
      (company?['website'] ?? '').toString().trim();

  final verified =
      company?['is_verified'] == true;

  final ratingRaw = company?['rating'];

  final rating = ratingRaw == null
      ? null
      : double.tryParse(
          ratingRaw.toString(),
        );

  final totalReviews =
      _toInt(company?['total_reviews']);

  if (company == null) {
    return Text(
      "Company information not available.",
      style: KhilonjiyaUI.body.copyWith(
        color: const Color(0xFF475569),
        height: 1.55,
      ),
    );
  }

  return Column(
    crossAxisAlignment:
        CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Flexible(
            child: Text(
              name.isEmpty
                  ? "Company"
                  : name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  KhilonjiyaUI.body.copyWith(
                fontWeight:
                    FontWeight.w900,
                fontSize: 14.5,
              ),
            ),
          ),

          if (verified) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.verified_rounded,
              size: 18,
              color:
                  KhilonjiyaUI.primary,
            ),
          ],
        ],
      ),

      const SizedBox(height: 10),

      if (rating != null &&
          rating > 0) ...[
        Row(
          children: [
            const Icon(
              Icons.star_rounded,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              "${rating.toStringAsFixed(1)} ($totalReviews reviews)",
              style:
                  KhilonjiyaUI.body.copyWith(
                fontWeight:
                    FontWeight.w800,
                color:
                    const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
      ],

      if (industry.isNotEmpty ||
          size.isNotEmpty) ...[
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            if (industry.isNotEmpty)
              _miniChip(industry),

            if (size.isNotEmpty)
              _miniChip("Size: $size"),
          ],
        ),
        const SizedBox(height: 12),
      ],

      Text(
        desc.isEmpty
            ? "No company description available."
            : desc,
        style:
            KhilonjiyaUI.body.copyWith(
          color: const Color(0xFF475569),
          height: 1.55,
        ),
      ),

      if (verified) ...[
        const SizedBox(height: 16),

        if (verified) ...[
  const SizedBox(height: 16),

  if (_loadingContact)
    const Center(
      child: CircularProgressIndicator(),
    )
  else if (_canViewContact &&
      _employerPhone != null) ...[
    Text(
      "Contact Details",
      style: KhilonjiyaUI.body.copyWith(
        fontWeight: FontWeight.w900,
        fontSize: 15,
        color: const Color(0xFF0F172A),
      ),
    ),

    const SizedBox(height: 12),

    Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () async {
              final uri = Uri(
                scheme: 'tel',
                path: _employerPhone!,
              );

              await launchUrl(uri);
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: KhilonjiyaUI.primary,
                borderRadius:
                    BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.call_rounded,
                    color: Colors.white,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Call",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: InkWell(
            onTap: () async {
              final phone =
                  _employerPhone!
                      .replaceAll('+', '')
                      .replaceAll(' ', '');

              final uri = Uri.parse(
                'https://wa.me/$phone',
              );

              await launchUrl(
                uri,
                mode: LaunchMode
                    .externalApplication,
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color:
                    const Color(0xFF25D366),
                borderRadius:
                    BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_rounded,
                    color: Colors.white,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "WhatsApp",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  ]
  else
    Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: KhilonjiyaUI.border,
        ),
      ),
      child: Text(
        "Contact details are available only for Pro members on verified companies.",
        style: KhilonjiyaUI.body,
      ),
    ),
],

      const SizedBox(height: 14),

      if (website.isNotEmpty)
        OutlinedButton(
          onPressed: () {
            ScaffoldMessenger.of(
                    context)
                .showSnackBar(
              const SnackBar(
                content: Text(
                  "Website open coming next",
                ),
              ),
            );
          },
          style:
              OutlinedButton.styleFrom(
            foregroundColor:
                const Color(0xFF0F172A),
            side: BorderSide(
              color:
                  KhilonjiyaUI.border,
            ),
            padding:
                const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 14,
            ),
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                16,
              ),
            ),
          ),
          child: const Icon(
            Icons.language_rounded,
            size: 18,
          ),
        ),
    ],
  );
}

  Widget _miniChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: KhilonjiyaUI.border),
      ),
      child: Text(
        text,
        style: KhilonjiyaUI.body.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF0F172A),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // COMPANY REVIEWS (REAL)
  // ------------------------------------------------------------
  
  // ------------------------------------------------------------
  // SIMILAR JOBS (REAL)
  // ------------------------------------------------------------
  
  // ------------------------------------------------------------
  // BOTTOM BAR
  // ------------------------------------------------------------
  Widget _buildApplyBottomBar() {
  return SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: KhilonjiyaUI.border)),
      ),
      child: SizedBox(
        height: 40, // ✅ EXACT 40 HEIGHT
        width: double.infinity,
        child: ElevatedButton(
          onPressed: (_checkingApplied || _isApplied) ? null : _applyNow,
          style: ElevatedButton.styleFrom(
            backgroundColor: KhilonjiyaUI.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFE2E8F0),
            disabledForegroundColor: const Color(0xFF64748B),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            _checkingApplied
                ? "Checking..."
                : (_isApplied ? "Already Applied" : "Apply Now"),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14.5,
            ),
          ),
        ),
      ),
    ),
  );
}

  // ------------------------------------------------------------
  // UTILS
  // ------------------------------------------------------------
  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  int? _toIntOrNull(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString());
  }

  List<String> _safeSkills(dynamic raw) {
    if (raw == null) return [];

    if (raw is List) {
      return raw
          .map((e) => e.toString())
          .where((s) => s.trim().isNotEmpty)
          .toList();
    }

    if (raw is String) {
      final s = raw.trim();
      if (s.isEmpty) return [];

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

  String _salaryText({
    required dynamic salaryMin,
    required dynamic salaryMax,
    required String salaryPeriod,
  }) {
    final mn = _toIntOrNull(salaryMin);
    final mx = _toIntOrNull(salaryMax);

    String per = salaryPeriod.trim().toLowerCase();
    if (per.isEmpty) per = "month";

    // normalize common values
    if (per == "monthly") per = "month";
    if (per == "per month") per = "month";
    if (per == "month") per = "month";

    if (mn == null && mx == null) return "Salary not disclosed";

    if (mn != null && mx != null) {
      if (mn == mx) return "₹$mn / $per";
      return "₹$mn - ₹$mx / $per";
    }

    if (mn != null) return "₹$mn / $per";
    return "₹$mx / $per";
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

  String _formatDate(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return "Recently";

    final diff = DateTime.now().difference(d);

    if (diff.inMinutes < 60) return "${diff.inMinutes} min ago";
    if (diff.inHours < 24) return "${diff.inHours} hours ago";
    if (diff.inDays == 1) return "1 day ago";
    return "${diff.inDays} days ago";
  }
}

class _CompanyLogo extends StatelessWidget {
  final String company;
  final String logoUrl;

  const _CompanyLogo({
    required this.company,
    required this.logoUrl,
  });

  @override
  Widget build(BuildContext context) {
    if (logoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.network(
          logoUrl,
          width: 54,
          height: 54,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(),
        ),
      );
    }

    return _fallback();
  }

  Widget _fallback() {
    final initials = company.isNotEmpty
        ? company.trim().split(' ').map((e) => e[0]).take(2).join()
        : "C";

    return Container(
      width: 54,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: KhilonjiyaUI.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        initials.toUpperCase(),
        style: KhilonjiyaUI.body.copyWith(
          fontWeight: FontWeight.w800,
          color: KhilonjiyaUI.primary,
        ),
      ),
    );
  }
}
