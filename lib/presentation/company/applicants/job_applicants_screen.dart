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
              created_at,

              user_profiles (
                id,
                full_name,
                mobile_number,
                email,
                district,
                address,
                education,
                experience_years,
                skills,
                expected_salary
              )
            )
          ''')
          .eq('listing_id', widget.jobId)
          .order('applied_at', ascending: false);

      _rows = List<Map<String, dynamic>>.from(res);
    } catch (_) {
      _rows = [];
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _updateStatus(String rowId, String status) async {
    await _client
        .from('job_applications_listings')
        .update({
          'application_status': status,
        })
        .eq('id', rowId);

    await _loadApplicants();
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

                    final profile = jobApp?['user_profiles']
                        as Map<String, dynamic>?;

                    final name =
                        (profile?['full_name'] ?? 'Candidate').toString();
                    final phone =
                        (profile?['mobile_number'] ?? '').toString();
                    final email = (profile?['email'] ?? '').toString();

                    final expYears = profile?['experience_years'];
                    final expectedSalary = profile?['expected_salary'];

                    final education =
                        (profile?['education'] ?? '').toString();

                    return _applicantCard(
                      rowId: row['id'].toString(),
                      status:
                          (row['application_status'] ?? 'applied').toString(),
                      appliedAt: row['applied_at']?.toString(),
                      name: name,
                      phone: phone,
                      email: email,
                      education: education,
                      expText: expYears == null ? '' : '$expYears yrs',
                      expectedSalaryText: expectedSalary == null
                          ? ''
                          : expectedSalary.toString(),
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
    required String education,
    required String expText,
    required String expectedSalaryText,
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
          // Name + Status
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

          // Contact
          if (phone.isNotEmpty) _metaLine(Icons.phone_outlined, phone),
          if (email.isNotEmpty) _metaLine(Icons.email_outlined, email),

          SizedBox(height: 1.2.h),

          // Education + Experience
          if (education.isNotEmpty)
            _metaLine(Icons.school_outlined, education),

          if (expText.isNotEmpty) _metaLine(Icons.work_outline, expText),

          if (expectedSalaryText.isNotEmpty)
            _metaLine(Icons.currency_rupee, expectedSalaryText),

          SizedBox(height: 1.8.h),
          const Divider(height: 1),
          SizedBox(height: 1.2.h),

          // Actions
          if (s == 'applied')
            Row(
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
            ),

          if (s == 'shortlisted')
            SizedBox(
              width: double.infinity,
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
                  'Reject Candidate',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _metaLine(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 0.6.h),
      child: Row(
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