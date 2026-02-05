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

  /// Each row will be:
  /// {
  ///   id,
  ///   applied_at,
  ///   application_status,
  ///   job_applications: {...},
  ///   user_profiles: {...}   // manually attached by us
  /// }
  List<Map<String, dynamic>> _rows = [];

  @override
  void initState() {
    super.initState();
    _loadApplicants();
  }

  Future<void> _loadApplicants() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      // 1) fetch bridge rows + job_applications
      final res = await _client
          .from('job_applications_listings')
          .select('''
            id,
            applied_at,
            application_status,
            employer_notes,
            interview_date,

            job_applications (
              id,
              user_id,
              name,
              phone,
              email,
              district,
              address,
              education,
              experience_level,
              experience_details,
              skills,
              expected_salary,
              availability,
              resume_file_url,
              photo_file_url,
              created_at
            )
          ''')
          .eq('listing_id', widget.jobId)
          .order('applied_at', ascending: false);

      final rows = List<Map<String, dynamic>>.from(res);

      // 2) collect user_ids
      final userIds = <String>{};

      for (final r in rows) {
        final app = r['job_applications'] as Map<String, dynamic>?;
        final uid = app?['user_id']?.toString();
        if (uid != null && uid.isNotEmpty) userIds.add(uid);
      }

      // 3) fetch profiles in one query (safe)
      Map<String, Map<String, dynamic>> profilesById = {};

      if (userIds.isNotEmpty) {
        final profilesRes = await _client
            .from('user_profiles')
            .select(
              'id, full_name, mobile_number, email, district, address, education, experience_years, skills, expected_salary',
            )
            .inFilter('id', userIds.toList());

        final profiles = List<Map<String, dynamic>>.from(profilesRes);

        profilesById = {
          for (final p in profiles) p['id'].toString(): p,
        };
      }

      // 4) attach profile to each row
      for (final r in rows) {
        final app = r['job_applications'] as Map<String, dynamic>?;
        final uid = app?['user_id']?.toString();
        r['user_profiles'] = uid == null ? null : profilesById[uid];
      }

      _rows = rows;
    } catch (_) {
      _rows = [];
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _updateStatus(String rowId, String status) async {
    await _client
        .from('job_applications_listings')
        .update({'application_status': status}).eq('id', rowId);

    await _loadApplicants();
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open file")),
      );
    }
  }

  void _openPhotoViewer(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PhotoViewer(url: url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Applicants',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        elevation: 0.6,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadApplicants,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _rows.isEmpty
              ? _emptyState()
              : ListView.builder(
                  padding: EdgeInsets.all(4.w),
                  itemCount: _rows.length,
                  itemBuilder: (context, index) {
                    final row = _rows[index];

                    final jobApp =
                        row['job_applications'] as Map<String, dynamic>?;

                    final profile =
                        row['user_profiles'] as Map<String, dynamic>?;

                    // Prefer profile values if present, else fallback to job_applications
                    final name = (profile?['full_name'] ??
                            jobApp?['name'] ??
                            'Candidate')
                        .toString();

                    final phone = (profile?['mobile_number'] ??
                            jobApp?['phone'] ??
                            '')
                        .toString();

                    final email =
                        (profile?['email'] ?? jobApp?['email'] ?? '').toString();

                    final district = (profile?['district'] ??
                            jobApp?['district'] ??
                            '')
                        .toString();

                    final address =
                        (profile?['address'] ?? jobApp?['address'] ?? '')
                            .toString();

                    final education =
                        (profile?['education'] ?? jobApp?['education'] ?? '')
                            .toString();

                    final expYears = profile?['experience_years'];
                    final expectedSalary = profile?['expected_salary'];

                    final skillsRaw = profile?['skills'] ?? jobApp?['skills'];
                    final skills = skillsRaw is List
                        ? skillsRaw.map((e) => e.toString()).toList()
                        : <String>[];

                    final resumeUrl =
                        (jobApp?['resume_file_url'] ?? '').toString();
                    final photoUrl =
                        (jobApp?['photo_file_url'] ?? '').toString();

                    return _applicantCard(
                      rowId: row['id'].toString(),
                      status:
                          (row['application_status'] ?? 'applied').toString(),
                      appliedAt: row['applied_at']?.toString(),
                      name: name,
                      phone: phone,
                      email: email,
                      district: district,
                      address: address,
                      education: education,
                      expText: expYears == null ? '' : '$expYears yrs',
                      expectedSalaryText: expectedSalary == null
                          ? ''
                          : expectedSalary.toString(),
                      skillsText: skills.isEmpty ? '' : skills.join(', '),
                      resumeUrl: resumeUrl,
                      photoUrl: photoUrl,
                    );
                  },
                ),
    );
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------
  Widget _applicantCard({
    required String rowId,
    required String status,
    required String? appliedAt,
    required String name,
    required String phone,
    required String email,
    required String district,
    required String address,
    required String education,
    required String expText,
    required String expectedSalaryText,
    required String skillsText,
    required String resumeUrl,
    required String photoUrl,
  }) {
    final s = status.toLowerCase();

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 14.5.sp,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
              _statusChip(s),
            ],
          ),
          SizedBox(height: 0.8.h),
          if (appliedAt != null)
            Text(
              "Applied ${_postedAgo(appliedAt)}",
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          SizedBox(height: 1.4.h),

          if (phone.isNotEmpty) _metaLine(Icons.phone_outlined, phone),
          if (email.isNotEmpty) _metaLine(Icons.email_outlined, email),

          if (district.isNotEmpty)
            _metaLine(Icons.location_on_outlined, district),
          if (address.isNotEmpty) _metaLine(Icons.home_outlined, address),

          SizedBox(height: 1.2.h),

          if (education.isNotEmpty)
            _metaLine(Icons.school_outlined, education),

          if (expText.isNotEmpty) _metaLine(Icons.work_outline, expText),

          if (expectedSalaryText.isNotEmpty)
            _metaLine(Icons.currency_rupee, expectedSalaryText),

          if (skillsText.isNotEmpty) _metaLine(Icons.star_outline, skillsText),

          SizedBox(height: 1.6.h),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: resumeUrl.trim().isEmpty
                      ? null
                      : () => _openUrl(resumeUrl),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  label: const Text(
                    "Resume",
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: photoUrl.trim().isEmpty
                      ? null
                      : () => _openPhotoViewer(photoUrl),
                  icon: const Icon(Icons.image_outlined, size: 18),
                  label: const Text(
                    "Photo",
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 1.8.h),
          const Divider(height: 1),
          SizedBox(height: 1.2.h),

          _actions(rowId, s),
        ],
      ),
    );
  }

  Widget _actions(String rowId, String status) {
    if (status == 'applied') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateStatus(rowId, 'shortlisted'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                'Shortlist',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: OutlinedButton(
              onPressed: () => _updateStatus(rowId, 'rejected'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFEF4444)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                'Reject',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      );
    }

    if (status == 'shortlisted') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateStatus(rowId, 'selected'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                'Select',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: OutlinedButton(
              onPressed: () => _updateStatus(rowId, 'rejected'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFEF4444)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                'Reject',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: status == 'rejected'
            ? null
            : () => _updateStatus(rowId, 'rejected'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFEF4444),
          side: const BorderSide(color: Color(0xFFEF4444)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: const Text(
          'Reject Candidate',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _metaLine(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 0.6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF475569)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'shortlisted':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF166534);
        label = 'Shortlisted';
        break;
      case 'rejected':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFF991B1B);
        label = 'Rejected';
        break;
      case 'interviewed':
        bg = const Color(0xFFE0F2FE);
        fg = const Color(0xFF075985);
        label = 'Interviewed';
        break;
      case 'selected':
        bg = const Color(0xFFEDE9FE);
        fg = const Color(0xFF5B21B6);
        label = 'Selected';
        break;
      default:
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF1D4ED8);
        label = 'Applied';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w900,
          color: fg,
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
            SizedBox(height: 2.h),
            const Text(
              'No applicants yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 1.h),
            const Text(
              'Candidates will appear here once they apply.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _postedAgo(String date) {
    final d = DateTime.tryParse(date);
    if (d == null) return 'recently';

    final diff = DateTime.now().difference(d);

    if (diff.inMinutes < 60) return 'today';
    if (diff.inHours < 24) return 'today';
    if (diff.inDays == 1) return '1 day ago';
    return '${diff.inDays} days ago';
  }
}

// ------------------------------------------------------------
// PHOTO VIEWER
// ------------------------------------------------------------
class _PhotoViewer extends StatelessWidget {
  final String url;

  const _PhotoViewer({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        title: const Text(
          "Photo",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Text(
              "Could not load image",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}