import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class JobApplicantsScreen extends StatefulWidget {
  final String jobId;

  const JobApplicantsScreen({
    Key? key,
    required this.jobId,
  }) : super(key: key);

  @override
  State<JobApplicantsScreen> createState() => _JobApplicantsScreenState();
}

class _JobApplicantsScreenState extends State<JobApplicantsScreen> {
  final SupabaseClient _client = Supabase.instance.client;

  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _rows = [];

  // ------------------------------------------------------------
  // FLUENT LIGHT PALETTE
  // ------------------------------------------------------------
  static const _bg = Color(0xFFF6F7FB);
  static const _card = Colors.white;
  static const _text = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);
  static const _line = Color(0xFFE6EAF2);
  static const _primary = Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    _loadApplicants();
  }

  // ------------------------------------------------------------
  // LOAD
  // ------------------------------------------------------------
  Future<void> _loadApplicants() async {
    try {
      if (!mounted) return;
      setState(() {
        _loading = true;
        _error = null;
      });

      final user = _client.auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = "Session expired. Please login again.";
        });
        return;
      }

      /// IMPORTANT:
      /// We select BOTH old and new schema column names
      /// so app works even if DB differs.
      final res = await _client
          .from('job_applications_listings')
          .select('''
            id,
            listing_id,
            application_id,
            applied_at,
            application_status,
            employer_notes,
            interview_date,
            user_id,

            job_applications (
              id,
              user_id,
              created_at,

              -- NEW schema
              full_name,
              mobile_number,
              resume_file_url,
              photo_file_url,

              -- OLD schema
              name,
              phone,
              resume_url,
              photo_url,

              email,
              district,
              address,

              gender,
              date_of_birth,

              education,
              experience_years,
              skills,
              expected_salary
            )
          ''')
          .eq('listing_id', widget.jobId)
          .order('applied_at', ascending: false);

      if (!mounted) return;

      setState(() {
        _rows = List<Map<String, dynamic>>.from(res);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = "Failed to load applicants";
      });
    }
  }

  // ------------------------------------------------------------
  // UPDATE STATUS
  // ------------------------------------------------------------
  Future<void> _updateStatus(String listingRowId, String status) async {
    try {
      await _client
          .from('job_applications_listings')
          .update({'application_status': status})
          .eq('id', listingRowId);

      await _loadApplicants();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update status")),
      );
    }
  }

  // ------------------------------------------------------------
  // ACTIONS
  // ------------------------------------------------------------
  Future<void> _call(String phone) async {
    final p = phone.trim();
    if (p.isEmpty) return;

    final uri = Uri.parse("tel:$p");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _email(String email) async {
    final e = email.trim();
    if (e.isEmpty) return;

    final uri = Uri.parse("mailto:$e");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openUrl(String url) async {
    final u = url.trim();
    if (u.isEmpty) return;

    final uri = Uri.tryParse(u);
    if (uri == null) return;

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        surfaceTintColor: _bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _text),
        titleSpacing: 4.w,
        title: const Text(
          'Applicants',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: _text,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadApplicants,
            tooltip: "Refresh",
            icon: const Icon(Icons.refresh_rounded),
          ),
          SizedBox(width: 2.w),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _errorState()
              : _rows.isEmpty
                  ? _emptyState()
                  : RefreshIndicator(
                      onRefresh: _loadApplicants,
                      child: ListView.builder(
                        padding: EdgeInsets.fromLTRB(4.w, 1.h, 4.w, 4.h),
                        itemCount: _rows.length,
                        itemBuilder: (context, index) {
                          final row = _rows[index];

                          final app = (row['job_applications'] ?? {})
                              as Map<String, dynamic>;

                          // ✅ support both old + new schema
                          final name = _pickString(app, ['full_name', 'name'])
                              .ifEmpty("Candidate");

                          final phone =
                              _pickString(app, ['mobile_number', 'phone']);

                          final email = _pickString(app, ['email']);

                          final district = _pickString(app, ['district']);
                          final education = _pickString(app, ['education']);
                          final expectedSalary =
                              _pickString(app, ['expected_salary']);

                          final resumeUrl = _pickString(
                            app,
                            ['resume_file_url', 'resume_url'],
                          );

                          final skillsText = _skillsToText(app['skills']);

                          return _applicantCard(
                            listingRowId: row['id'].toString(),
                            status: (row['application_status'] ?? 'applied')
                                .toString(),
                            appliedAt: row['applied_at'],
                            name: name,
                            mobile: phone,
                            email: email,
                            district: district,
                            education: education,
                            experienceYears:
                                _toIntOrNull(app['experience_years']),
                            skills: skillsText,
                            expectedSalary: expectedSalary,
                            resumeUrl: resumeUrl,
                          );
                        },
                      ),
                    ),
    );
  }

  // ------------------------------------------------------------
  // CARD
  // ------------------------------------------------------------
  Widget _applicantCard({
    required String listingRowId,
    required String status,
    required dynamic appliedAt,
    required String name,
    required String mobile,
    required String email,
    required String district,
    required String education,
    required int? experienceYears,
    required String skills,
    required String expectedSalary,
    required String resumeUrl,
  }) {
    final statusUi = _statusUi(status);

    return Container(
      margin: EdgeInsets.only(bottom: 1.6.h),
      padding: EdgeInsets.fromLTRB(4.w, 2.1.h, 4.w, 2.1.h),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _line),
                ),
                child: const Icon(Icons.person_rounded, color: _text),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.6,
                        fontWeight: FontWeight.w800,
                        color: _text,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _appliedAgo(appliedAt),
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: _muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _statusChip(statusUi.label, statusUi.bg, statusUi.fg),
            ],
          ),

          SizedBox(height: 1.6.h),

          // Contact buttons row
          Row(
            children: [
              Expanded(
                child: _miniAction(
                  icon: Icons.call_rounded,
                  label: "Call",
                  onTap: mobile.trim().isEmpty ? null : () => _call(mobile),
                ),
              ),
              SizedBox(width: 2.5.w),
              Expanded(
                child: _miniAction(
                  icon: Icons.mail_rounded,
                  label: "Email",
                  onTap: email.trim().isEmpty ? null : () => _email(email),
                ),
              ),
              SizedBox(width: 2.5.w),
              Expanded(
                child: _miniAction(
                  icon: Icons.picture_as_pdf_rounded,
                  label: "Resume",
                  onTap: resumeUrl.trim().isEmpty
                      ? null
                      : () => _openUrl(resumeUrl),
                ),
              ),
            ],
          ),

          SizedBox(height: 1.6.h),
          Divider(color: Colors.black.withOpacity(0.06), height: 1),
          SizedBox(height: 1.6.h),

          // Summary pills
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill(
                icon: Icons.location_on_rounded,
                text: district.isEmpty ? "District not set" : district,
              ),
              _pill(
                icon: Icons.school_rounded,
                text: education.isEmpty ? "Education not set" : education,
              ),
              _pill(
                icon: Icons.work_rounded,
                text: experienceYears == null
                    ? "Experience not set"
                    : "$experienceYears yrs",
              ),
              _pill(
                icon: Icons.currency_rupee_rounded,
                text: expectedSalary.isEmpty
                    ? "Salary not set"
                    : "₹$expectedSalary",
              ),
            ],
          ),

          if (mobile.trim().isNotEmpty || email.trim().isNotEmpty) ...[
            SizedBox(height: 1.4.h),
            _keyValueRow("Phone", mobile.isEmpty ? "Not provided" : mobile),
            if (email.trim().isNotEmpty)
              _keyValueRow("Email", email.trim()),
          ],

          if (skills.trim().isNotEmpty) ...[
            SizedBox(height: 1.6.h),
            const Text(
              "Skills",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: _text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              skills,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ],

          SizedBox(height: 2.h),

          // Status actions
          if (status == 'applied') ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _updateStatus(listingRowId, 'shortlisted'),
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: const Text(
                      "Shortlist",
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _updateStatus(listingRowId, 'rejected'),
                    icon: const Icon(Icons.cancel_rounded, size: 18),
                    label: const Text(
                      "Reject",
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF9F1239),
                      side: const BorderSide(color: Color(0xFFFECACA)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _updateStatus(listingRowId, 'viewed'),
                    icon: const Icon(Icons.remove_red_eye_rounded, size: 18),
                    label: const Text(
                      "Mark Viewed",
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _text,
                      side: const BorderSide(color: _line),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // SMALL UI PIECES
  // ------------------------------------------------------------
  Widget _miniAction({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    final bool disabled = onTap == null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: disabled ? const Color(0xFFF1F5F9) : const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: disabled ? _line : const Color(0xFFDBEAFE),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: disabled ? const Color(0xFF94A3B8) : _primary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: disabled ? const Color(0xFF94A3B8) : _primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF334155)),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  Widget _keyValueRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 74,
            child: Text(
              k,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: _muted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: _text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // HELPERS
  // ------------------------------------------------------------
  String _skillsToText(dynamic skills) {
    if (skills == null) return '';

    if (skills is List) {
      final items = skills
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
      return items.join(', ');
    }

    final s = skills.toString().trim();
    return s;
  }

  int? _toIntOrNull(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString());
  }

  String _pickString(Map<String, dynamic> map, List<String> keys) {
    for (final k in keys) {
      final v = map[k];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return "";
  }

  _StatusUI _statusUi(String status) {
    final s = status.toLowerCase();

    if (s == 'shortlisted') {
      return _StatusUI(
        label: "Shortlisted",
        bg: const Color(0xFFECFDF5),
        fg: const Color(0xFF14532D),
      );
    }
    if (s == 'rejected') {
      return _StatusUI(
        label: "Rejected",
        bg: const Color(0xFFFFF1F2),
        fg: const Color(0xFF9F1239),
      );
    }
    if (s == 'viewed') {
      return _StatusUI(
        label: "Viewed",
        bg: const Color(0xFFF1F5F9),
        fg: const Color(0xFF334155),
      );
    }

    return _StatusUI(
      label: "Applied",
      bg: const Color(0xFFEFF6FF),
      fg: const Color(0xFF1D4ED8),
    );
  }

  String _appliedAgo(dynamic date) {
    if (date == null) return "Applied recently";

    final d = DateTime.tryParse(date.toString());
    if (d == null) return "Applied recently";

    final diff = DateTime.now().difference(d);

    if (diff.inMinutes < 2) return "Applied just now";
    if (diff.inMinutes < 60) return "Applied ${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "Applied ${diff.inHours}h ago";
    if (diff.inDays == 1) return "Applied 1 day ago";
    return "Applied ${diff.inDays} days ago";
  }

  // ------------------------------------------------------------
  // STATES
  // ------------------------------------------------------------
  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(7.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _line),
              ),
              child: const Icon(
                Icons.people_alt_outlined,
                size: 34,
                color: Color(0xFF334155),
              ),
            ),
            SizedBox(height: 2.4.h),
            const Text(
              'No applicants yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _text,
                letterSpacing: -0.2,
              ),
            ),
            SizedBox(height: 1.h),
            const Text(
              'Candidates will appear here once they apply for this job.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _muted,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            SizedBox(height: 2.6.h),
            OutlinedButton.icon(
              onPressed: _loadApplicants,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(
                "Refresh",
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _text,
                side: const BorderSide(color: _line),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(7.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 34,
                color: Color(0xFF9F1239),
              ),
            ),
            SizedBox(height: 2.4.h),
            Text(
              _error ?? "Something went wrong",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _text,
              ),
            ),
            SizedBox(height: 1.8.h),
            OutlinedButton.icon(
              onPressed: _loadApplicants,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(
                "Try Again",
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _text,
                side: const BorderSide(color: _line),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusUI {
  final String label;
  final Color bg;
  final Color fg;

  _StatusUI({
    required this.label,
    required this.bg,
    required this.fg,
  });
}

extension _StringExt on String {
  String ifEmpty(String fallback) => trim().isEmpty ? fallback : this;
}