import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  // Each item = job_applications_listings row + nested job_applications
  List<Map<String, dynamic>> _rows = [];

  @override
  void initState() {
    super.initState();
    _loadApplicants();
  }

  Future<void> _loadApplicants() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final user = _client.auth.currentUser;
      if (user == null) {
        setState(() {
          _loading = false;
          _error = "Session expired. Please login again.";
        });
        return;
      }

      // ✅ Correct query based on schema:
      // job_applications_listings.listing_id -> job_listings.id
      // job_applications_listings.application_id -> job_applications.id
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
              name,
              phone,
              email,
              district,
              address,
              gender,
              date_of_birth,
              education,
              experience_level,
              experience_details,
              skills,
              expected_salary,
              availability,
              additional_info,
              resume_file_url,
              photo_file_url,
              created_at,
              updated_at
            )
          ''')
          .eq('listing_id', widget.jobId)
          .order('applied_at', ascending: false);

      if (!mounted) return;

      setState(() {
        _rows = List<Map<String, dynamic>>.from(res);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = "Failed to load applicants";
      });
    }
  }

  Future<void> _updateStatus(String listingRowId, String status) async {
    try {
      await _client
          .from('job_applications_listings')
          .update({'application_status': status})
          .eq('id', listingRowId);

      await _loadApplicants();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update status")),
      );
    }
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text(
          'Applicants',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
            letterSpacing: -0.2,
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0.6,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
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
                        padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 4.h),
                        itemCount: _rows.length,
                        itemBuilder: (context, index) {
                          final row = _rows[index];
                          final app =
                              (row['job_applications'] ?? {}) as Map<String, dynamic>;

                          return _applicantCard(
                            listingRowId: row['id'].toString(),
                            status: (row['application_status'] ?? 'applied')
                                .toString(),
                            appliedAt: row['applied_at'],
                            name: (app['name'] ?? 'Candidate').toString(),
                            mobile: (app['phone'] ?? '').toString(),
                            email: (app['email'] ?? '').toString(),
                            district: (app['district'] ?? '').toString(),
                            education: (app['education'] ?? '').toString(),
                            expLevel:
                                (app['experience_level'] ?? '').toString(),
                            expDetails:
                                (app['experience_details'] ?? '').toString(),
                            skills: (app['skills'] ?? '').toString(),
                            expectedSalary:
                                (app['expected_salary'] ?? '').toString(),
                          );
                        },
                      ),
                    ),
    );
  }

  // ------------------------------------------------------------
  // CARD UI (WORLD CLASS)
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
    required String expLevel,
    required String expDetails,
    required String skills,
    required String expectedSalary,
  }) {
    final statusUi = _statusUi(status);

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7EAF0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Color(0xFF0F172A),
                ),
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
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _appliedAgo(appliedAt),
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _statusChip(statusUi.label, statusUi.bg, statusUi.fg),
            ],
          ),

          SizedBox(height: 1.6.h),

          // Contact
          _infoRow(Icons.call_rounded, mobile.isEmpty ? "No phone" : mobile),
          if (email.trim().isNotEmpty) ...[
            SizedBox(height: 0.8.h),
            _infoRow(Icons.mail_rounded, email),
          ],

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
                text: expLevel.isEmpty ? "Experience not set" : expLevel,
              ),
              _pill(
                icon: Icons.currency_rupee_rounded,
                text: expectedSalary.isEmpty
                    ? "Salary not set"
                    : expectedSalary,
              ),
            ],
          ),

          if (skills.trim().isNotEmpty) ...[
            SizedBox(height: 1.6.h),
            _sectionTitle("Skills"),
            const SizedBox(height: 6),
            Text(
              skills,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ],

          if (expDetails.trim().isNotEmpty) ...[
            SizedBox(height: 1.6.h),
            _sectionTitle("Experience Details"),
            const SizedBox(height: 6),
            Text(
              expDetails,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ],

          SizedBox(height: 2.h),

          // Actions
          if (status == 'applied') ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _updateStatus(listingRowId, 'shortlisted'),
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: const Text(
                      "Shortlist",
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
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
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF991B1B),
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
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
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F172A),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
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
  Widget _sectionTitle(String t) {
    return Text(
      t,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w900,
        color: Color(0xFF0F172A),
      ),
    );
  }

  Widget _pill({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF334155)),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF475569)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13.2,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
      ],
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
          fontWeight: FontWeight.w900,
          color: fg,
        ),
      ),
    );
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

    if (diff.inMinutes < 60) return "Applied just now";
    if (diff.inHours < 24) return "Applied today";
    if (diff.inDays == 1) return "Applied 1 day ago";
    return "Applied ${diff.inDays} days ago";
  }

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
                border: Border.all(color: const Color(0xFFE2E8F0)),
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
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
            ),
            SizedBox(height: 1.h),
            const Text(
              'Candidates will appear here once they apply for this job.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            SizedBox(height: 2.6.h),
            OutlinedButton.icon(
              onPressed: _loadApplicants,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(
                "Refresh",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F172A),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
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
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 1.8.h),
            OutlinedButton.icon(
              onPressed: _loadApplicants,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(
                "Try Again",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F172A),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
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