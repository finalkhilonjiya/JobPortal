// lib/presentation/company/jobs/job_applicants_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

import '../../../core/ui/khilonjiya_ui.dart';
import '../../../services/employer_applicants_service.dart';

class JobApplicantsScreen extends StatefulWidget {
  final String jobId;

  // Optional: can be passed from route
  // But we always resolve from job_listings for correctness.
  final String? companyId;

  const JobApplicantsScreen({
    Key? key,
    required this.jobId,
    this.companyId,
  }) : super(key: key);

  @override
  State<JobApplicantsScreen> createState() => _JobApplicantsScreenState();
}

class _JobApplicantsScreenState extends State<JobApplicantsScreen> {
  final EmployerApplicantsService _service = EmployerApplicantsService();

  bool _loading = true;
  bool _busy = false;

  List<Map<String, dynamic>> _rows = [];

  // Resolved from job
  String _resolvedCompanyId = '';
  String _jobTitle = '';

  // Filters
  String _filter = 'all';
  final TextEditingController _search = TextEditingController();

  // UI tokens
  static const Color _bg = Color(0xFFF7F8FA);
  static const Color _border = Color(0xFFE6E8EC);
  static const Color _text = Color(0xFF111827);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _primary = Color(0xFF16A34A);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Map<String, dynamic> _asMap(dynamic v) {
    if (v == null) return {};
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return {};
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      // FIXED: new access rule is organization membership, not employer_id
      final job = await _service.ensureCanAccessJobAndGetJob(widget.jobId);

      _resolvedCompanyId = (job['company_id'] ?? '').toString().trim();
      _jobTitle = (job['job_title'] ?? '').toString().trim();

      // fallback if passed
      if (_resolvedCompanyId.isEmpty && widget.companyId != null) {
        _resolvedCompanyId = widget.companyId!.trim();
      }

      _rows = await _service.fetchApplicantsForJob(widget.jobId);
    } catch (e) {
      _rows = [];
      _toast("Failed: ${e.toString()}");
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  // ------------------------------------------------------------
  // FILTERING
  // ------------------------------------------------------------
  List<Map<String, dynamic>> get _filtered {
    final q = _search.text.trim().toLowerCase();

    return _rows.where((r) {
      final status = (r['application_status'] ?? 'applied')
          .toString()
          .toLowerCase();

      if (_filter != 'all' && status != _filter) return false;

      if (q.isEmpty) return true;

      final app = _getApp(r['job_applications']);

      final name = (app['name'] ?? '').toString().toLowerCase();
      final phone = (app['phone'] ?? '').toString().toLowerCase();
      final email = (app['email'] ?? '').toString().toLowerCase();
      final skills = (app['skills'] ?? '').toString().toLowerCase();

      return name.contains(q) ||
          phone.contains(q) ||
          email.contains(q) ||
          skills.contains(q);
    }).toList();
  }

  // ------------------------------------------------------------
  // ACTIONS
  // ------------------------------------------------------------




Map<String, dynamic> _getApp(dynamic raw) {
  if (raw == null) return {};

  if (raw is List && raw.isNotEmpty) {
    final first = raw.first;
    if (first is Map<String, dynamic>) return first;
    if (first is Map) return Map<String, dynamic>.from(first);
  }

  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);

  return {};
}
  Future<void> _setStatus(Map<String, dynamic> row, String status) async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      await _service.updateApplicationStatus(
        listingRowId: (row['id'] ?? '').toString(),
        jobId: widget.jobId,
        status: status,
      );

      row['application_status'] = status;
      if (mounted) setState(() {});
    } catch (e) {
      _toast("Failed: ${e.toString()}");
    }

    if (!mounted) return;
    setState(() => _busy = false);
  }

  Future<void> _scheduleInterview(Map<String, dynamic> row) async {
    if (_resolvedCompanyId.trim().isEmpty) {
      _toast("Organization not linked to job. Please contact support.");
      return;
    }

    final picked = await _pickDateTime();
    if (picked == null) return;

    if (_busy) return;
    setState(() => _busy = true);

    try {
      await _service.scheduleInterview(
        listingRowId: (row['id'] ?? '').toString(),
        jobId: widget.jobId,
        companyId: _resolvedCompanyId,
        scheduledAt: picked,
        durationMinutes: 30,
        interviewType: 'video',
      );

      row['application_status'] = 'interview_scheduled';
      row['interview_date'] = picked.toIso8601String();

      if (mounted) setState(() {});
      _toast("Interview scheduled");
    } catch (e) {
      _toast("Failed: ${e.toString()}");
    }

    if (!mounted) return;
    setState(() => _busy = false);
  }

  Future<DateTime?> _pickDateTime() async {
    final now = DateTime.now();

    final d = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: now.add(const Duration(days: 1)),
    );
    if (d == null) return null;

    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: now.hour, minute: now.minute),
    );
    if (t == null) return null;

    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  // ------------------------------------------------------------
  // MARK VIEWED
  // ------------------------------------------------------------
  Future<void> _markViewedIfNeeded(Map<String, dynamic> row) async {
    final status =
        (row['application_status'] ?? 'applied').toString().toLowerCase();

    if (status != 'applied') return;

    try {
      await _service.markViewed(
        listingRowId: (row['id'] ?? '').toString(),
        jobId: widget.jobId,
      );
      row['application_status'] = 'viewed';
      if (mounted) setState(() {});
    } catch (_) {}
  }

  // ------------------------------------------------------------
  // NOTES (REAL)
  // ------------------------------------------------------------
  Future<void> _editNotes(Map<String, dynamic> row) async {
    final listingRowId = (row['id'] ?? '').toString();
    final existing = (row['employer_notes'] ?? '').toString();

    final c = TextEditingController(text: existing);

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Employer Notes"),
          content: TextField(
            controller: c,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: "Write private notes for your team...",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
              ),
              child: const Text("Save"),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    try {
      await _service.updateEmployerNotes(
        listingRowId: listingRowId,
        jobId: widget.jobId,
        notes: c.text.trim(),
      );

      row['employer_notes'] = c.text.trim();
      if (mounted) setState(() {});
      _toast("Saved");
    } catch (e) {
      _toast("Failed: ${e.toString()}");
    }
  }

  // ------------------------------------------------------------
  // OPEN RESUME (REAL)
  // ------------------------------------------------------------
  Future<void> _openResume(Map<String, dynamic> row) async {
  final app = _getApp(row['job_applications']);
  final rawPath = (app['resume_file_url'] ?? '').toString().trim();

  if (rawPath.isEmpty) {
    _toast("Resume not uploaded");
    return;
  }

  try {
    final url = await _service.getPublicOrSignedUrl(rawPath);

    if (url == null || url.isEmpty) {
      _toast("Invalid resume");
      return;
    }

    final isPdf = Uri.parse(url).path.toLowerCase().endsWith('.pdf');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return FutureBuilder<String?>(
          future: isPdf ? _downloadPdf(url) : Future.value(null),
          builder: (context, snap) {
            final loading = snap.connectionState == ConnectionState.waiting;
            final localPath = snap.data;

            return SafeArea(
              child: Column(
                children: [
                  // HEADER
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

                  // CONTENT
                  Expanded(
                    child: loading
                        ? const Center(child: CircularProgressIndicator())
                        : isPdf
                            ? PDFView(
                                filePath: localPath!,
                                enableSwipe: true,
                                swipeHorizontal: false,
                                autoSpacing: true,
                                pageFling: true,
                                pageSnap: true,
                                fitPolicy: FitPolicy.BOTH,
                              )
                            : InteractiveViewer(
                                minScale: 1,
                                maxScale: 5,
                                child: Image.network(
                                  url,
                                  fit: BoxFit.contain,
                                ),
                              ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  } catch (e) {
    _toast("Resume failed");
  }
}
  // ------------------------------------------------------------
  // DETAILS SHEET
  // ------------------------------------------------------------
  void _openApplicant(Map<String, dynamic> row) async {
  await _markViewedIfNeeded(row);

  final app = _getApp(row['job_applications']);

  final name = (app['name'] ?? 'Candidate').toString();
  final photo = (app['photo_file_url'] ?? '').toString();
  final skills = (app['skills'] ?? '').toString();
  final notes = (row['employer_notes'] ?? '').toString();

  final fields = {
    "Phone": app['phone'],
    "Email": app['email'],
    "District": app['district'],
    "Education": app['education'],
    "Experience": app['experience_level'],
    "Salary": app['expected_salary'],
    "Availability": app['availability'],
  };

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.6,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // HEADER
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE6E8EC)),
                    ),
                  ),
                  child: Row(
                    children: [
                      _avatar(name, photoUrl: photo),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                ),

                // CONTENT
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      ...fields.entries
                          .where((e) =>
                              (e.value ?? '').toString().trim().isNotEmpty)
                          .map((e) => _kvStack(e.key, e.value.toString())),

                      if (skills.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text("Skills",
                            style: TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 14)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: skills.split(',').map((s) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                s.trim(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700),
                              ),
                            );
                          }).toList(),
                        ),
                      ],

                      if (notes.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text("Notes",
                            style: TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 14)),
                        const SizedBox(height: 6),
                        Text(notes),
                      ],

                      const SizedBox(height: 80),
                    ],
                  ),
                ),

                // ACTION BAR (CRITICAL FIX)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFFE6E8EC)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            await _setStatus(row, 'shortlisted');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Shortlist"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            await _setStatus(row, 'rejected');
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _muted,
                            side: const BorderSide(color: _border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Reject"),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Resume icon
                      _iconBtn(Icons.description_outlined, () async {
                        Navigator.pop(context);
                        await _openResume(row);
                      }),

                      const SizedBox(width: 8),

                      // Schedule icon
                      _iconBtn(Icons.calendar_today_outlined, () async {
                        Navigator.pop(context);
                        await _scheduleInterview(row);
                      }),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}


Future<String> _downloadPdf(String url) async {
  final dir = await getTemporaryDirectory();
  final file = File("${dir.path}/${DateTime.now().millisecondsSinceEpoch}.pdf");

  final res = await http.get(Uri.parse(url));
  await file.writeAsBytes(res.bodyBytes);

  return file.path;
}

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------
  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: _bg,
    appBar: AppBar(
      backgroundColor: _bg,
      elevation: 0,
      surfaceTintColor: _bg,
      title: const Text(
        "Applicants",
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: _text,
        ),
      ),
      actions: [
        IconButton(
          onPressed: _busy ? null : _load,
          icon: const Icon(Icons.refresh_rounded),
          color: _primary,
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(28),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _jobTitle.isEmpty ? "Job Applicants" : _jobTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: _muted,
              ),
            ),
          ),
        ),
      ),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              _topFilters(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _load,
                  child: _filtered.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.all(16),
                          children: [_emptyCard()],
                        )
                      : ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(16, 12, 16, 20),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) =>
                              _applicantTile(_filtered[i]),
                        ),
                ),
              ),
            ],
          ),
  );
}
  // ------------------------------------------------------------
  // UI: FILTERS
  // ------------------------------------------------------------



Widget _kvStack(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: _muted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: _text,
          ),
        ),
      ],
    ),
  );
}


Widget _iconBtn(IconData icon, VoidCallback onTap) {
  return Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      border: Border.all(color: _border),
      borderRadius: BorderRadius.circular(12),
    ),
    child: IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 20, color: _muted),
    ),
  );
}
  Widget _topFilters() {
  return Container(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: _border)),
    ),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: _muted),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: "Search candidates...",
                    border: InputBorder.none,
                  ),
                ),
              ),
              if (_search.text.isNotEmpty)
                IconButton(
                  onPressed: () {
                    _search.clear();
                    setState(() {});
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _filterChip("All", "all"),
              _filterChip("Applied", "applied"),
              _filterChip("Viewed", "viewed"),
              _filterChip("Shortlisted", "shortlisted"),
              _filterChip("Interview", "interview_scheduled"),
              _filterChip("Selected", "selected"),
              _filterChip("Rejected", "rejected"),
            ],
          ),
        ),
      ],
    ),
  );
}


  Widget _filterChip(String label, String key) {
  final active = _filter == key;

  return Padding(
    padding: const EdgeInsets.only(right: 8),
    child: GestureDetector(
      onTap: () => setState(() => _filter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFDCFCE7) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? const Color(0xFFBBF7D0) : _border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: active ? _primary : _text,
            fontSize: 12,
          ),
        ),
      ),
    ),
  );
}

  // ------------------------------------------------------------
  // UI: LIST ITEM
  // ------------------------------------------------------------
  Widget _applicantTile(Map<String, dynamic> row) {
  final app = _getApp(row['job_applications']);

  final name = (app['name'] ?? 'Candidate').toString();
  final district = (app['district'] ?? '').toString();
  final exp = (app['experience_level'] ?? '').toString();
  final salary = (app['expected_salary'] ?? '').toString();
  final photo = (app['photo_file_url'] ?? '').toString();

  final status =
      (row['application_status'] ?? 'applied').toString().toLowerCase();

  final appliedAt = row['applied_at'];

  return InkWell(
    onTap: () => _openApplicant(row),
    borderRadius: BorderRadius.circular(16),
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _avatar(name, photoUrl: photo),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // NAME + STATUS
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: _text,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _statusChip(status),
                  ],
                ),

                const SizedBox(height: 4),

                // APPLIED TIME
                Text(
                  appliedAt == null
                      ? "Recently applied"
                      : "Applied ${_timeAgo(appliedAt)}",
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 6),

                // LOCATION + EXPERIENCE
                Text(
                  district.isEmpty && exp.isEmpty
                      ? "-"
                      : "$district${district.isNotEmpty && exp.isNotEmpty ? " • " : ""}${exp.isEmpty ? "" : exp}",
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 6),

                // SALARY
                Text(
                  salary.isEmpty ? "Expected salary -" : salary,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: _text,
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


  Widget _mini(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: _muted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusChip(String status) {
    final s = status.toLowerCase();

    Color bg = const Color(0xFFEFF6FF);
    Color fg = const Color(0xFF1D4ED8);
    String label = 'Applied';

    if (s == 'viewed') {
      bg = const Color(0xFFF1F5F9);
      fg = const Color(0xFF334155);
      label = 'Viewed';
    } else if (s == 'shortlisted') {
      bg = const Color(0xFFECFDF5);
      fg = const Color(0xFF166534);
      label = 'Shortlisted';
    } else if (s == 'interview_scheduled') {
      bg = const Color(0xFFFFFBEB);
      fg = const Color(0xFF7C2D12);
      label = 'Interview';
    } else if (s == 'interviewed') {
      bg = const Color(0xFFFFFBEB);
      fg = const Color(0xFF7C2D12);
      label = 'Interviewed';
    } else if (s == 'selected') {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF14532D);
      label = 'Selected';
    } else if (s == 'rejected') {
      bg = const Color(0xFFFFF1F2);
      fg = const Color(0xFF9F1239);
      label = 'Rejected';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withOpacity(0.12)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
          color: fg,
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              k,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: _muted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: _text,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar(String name, {String? photoUrl}) {
  final letter = name.isNotEmpty ? name[0].toUpperCase() : "C";

  if (photoUrl == null || photoUrl.trim().isEmpty) {
    return _fallbackAvatar(letter);
  }

  return FutureBuilder<String?>(
    future: _service.getPublicOrSignedUrl(photoUrl),
    builder: (context, snap) {
      final url = snap.data;

      if (url != null && url.isNotEmpty) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Image.network(
            url,
            width: 44,
            height: 44,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallbackAvatar(letter),
          ),
        );
      }

      return _fallbackAvatar(letter);
    },
  );
}


Widget _fallbackAvatar(String letter) {
  return Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      color: const Color(0xFFDCFCE7),
      borderRadius: BorderRadius.circular(999),
    ),
    alignment: Alignment.center,
    child: Text(
      letter,
      style: const TextStyle(
        fontWeight: FontWeight.w900,
        color: _primary,
      ),
    ),
  );
}

  Widget _emptyCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: const Icon(Icons.people_outline, color: _text),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "No applicants found",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: _text,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "When candidates apply, they will appear here.",
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: _muted,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(dynamic date) {
    if (date == null) return 'recent';

    final d = DateTime.tryParse(date.toString());
    if (d == null) return 'recent';

    final diff = DateTime.now().difference(d);

    if (diff.inMinutes < 2) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return '1d ago';
    return '${diff.inDays}d ago';
  }

  String _formatDateTime(dynamic date) {
    final d = DateTime.tryParse(date.toString());
    if (d == null) return '';
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = d.year.toString();
    final hh = d.hour.toString().padLeft(2, '0');
    final mi = d.minute.toString().padLeft(2, '0');
    return "$dd/$mm/$yy $hh:$mi";
  }
}