import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/employer_job_service.dart';

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
  final EmployerJobService _service = EmployerJobService();

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
      final res = await _service.fetchApplicantsForJob(widget.jobId);

      if (!mounted) return;
      setState(() {
        _rows = res;
        _loading = false;
      });
    } catch (e) {
      _service.logError(e);

      if (!mounted) return;
      setState(() {
        _rows = [];
        _loading = false;
      });
    }
  }

  Future<void> _updateStatus({
    required String rowId,
    required String status,
    String? notes,
    DateTime? interviewDate,
  }) async {
    try {
      await _service.updateApplicantStatus(
        jobApplicationListingId: rowId,
        status: status,
        employerNotes: notes,
        interviewDate: interviewDate,
      );

      await _loadApplicants();
    } catch (e) {
      _service.logError(e);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update status")),
      );
    }
  }

  // ------------------------------------------------------------
  // NOTES DIALOG
  // ------------------------------------------------------------
  Future<void> _openNotesDialog({
    required String rowId,
    required String currentStatus,
    String? existingNotes,
  }) async {
    final ctrl = TextEditingController(text: existingNotes ?? "");

    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Employer Notes"),
        content: TextField(
          controller: ctrl,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: "Write notes about this candidate...",
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
            child: const Text("Save"),
          ),
        ],
      ),
    );

    if (saved == true) {
      await _updateStatus(
        rowId: rowId,
        status: currentStatus, // keep same status
        notes: ctrl.text.trim(),
      );
    }
  }

  // ------------------------------------------------------------
  // INTERVIEW DATE PICKER
  // ------------------------------------------------------------
  Future<void> _pickInterviewDate({
    required String rowId,
    required String currentStatus,
    String? existingNotes,
  }) async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 0)),
      lastDate: now.add(const Duration(days: 365)),
      initialDate: now.add(const Duration(days: 1)),
    );

    if (picked == null) return;

    await _updateStatus(
      rowId: rowId,
      status: "interviewed",
      notes: existingNotes,
      interviewDate: picked,
    );
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------
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

                    final rowId = (row['id'] ?? '').toString();
                    final status =
                        (row['application_status'] ?? 'applied').toString();

                    final appliedAt = row['applied_at']?.toString();
                    final notes = row['employer_notes']?.toString();
                    final interviewDate = row['interview_date']?.toString();

                    final app =
                        row['job_applications'] as Map<String, dynamic>?;

                    final name = (app?['name'] ?? 'Candidate').toString();
                    final phone = (app?['phone'] ?? '').toString();
                    final email = (app?['email'] ?? '').toString();
                    final education = (app?['education'] ?? '').toString();
                    final expLevel =
                        (app?['experience_level'] ?? '').toString();
                    final expectedSalary =
                        (app?['expected_salary'] ?? '').toString();

                    return _applicantCard(
                      rowId: rowId,
                      status: status,
                      appliedAt: appliedAt,
                      name: name,
                      phone: phone,
                      email: email,
                      education: education,
                      expLevel: expLevel,
                      expectedSalary: expectedSalary,
                      notes: notes,
                      interviewDate: interviewDate,
                    );
                  },
                ),
    );
  }

  Widget _applicantCard({
    required String rowId,
    required String status,
    required String? appliedAt,
    required String name,
    required String phone,
    required String email,
    required String education,
    required String expLevel,
    required String expectedSalary,
    required String? notes,
    required String? interviewDate,
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

          if (interviewDate != null && interviewDate.trim().isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 0.6.h),
              child: Text(
                "Interview: ${_formatDate(interviewDate)}",
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w700,
                ),
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
          if (expLevel.isNotEmpty) _metaLine(Icons.work_outline, expLevel),
          if (expectedSalary.isNotEmpty)
            _metaLine(Icons.currency_rupee, expectedSalary),

          if (notes != null && notes.trim().isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 1.2.h),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  "Notes: $notes",
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
            ),

          SizedBox(height: 1.8.h),
          const Divider(height: 1),
          SizedBox(height: 1.2.h),

          // ------------------------------------------------------------
          // ACTIONS
          // ------------------------------------------------------------
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _smallButton(
                label: "Add Notes",
                icon: Icons.note_add_outlined,
                onTap: () => _openNotesDialog(
                  rowId: rowId,
                  currentStatus: s,
                  existingNotes: notes,
                ),
              ),

              if (s == "applied" || s == "viewed")
                _smallButton(
                  label: "Shortlist",
                  icon: Icons.check_circle_outline,
                  color: const Color(0xFF16A34A),
                  onTap: () =>
                      _updateStatus(rowId: rowId, status: "shortlisted"),
                ),

              if (s == "shortlisted")
                _smallButton(
                  label: "Schedule Interview",
                  icon: Icons.event_available_outlined,
                  color: const Color(0xFF2563EB),
                  onTap: () => _pickInterviewDate(
                    rowId: rowId,
                    currentStatus: s,
                    existingNotes: notes,
                  ),
                ),

              if (s == "interviewed" || s == "shortlisted")
                _smallButton(
                  label: "Select",
                  icon: Icons.verified_outlined,
                  color: const Color(0xFF7C3AED),
                  onTap: () => _updateStatus(rowId: rowId, status: "selected"),
                ),

              if (s != "rejected" && s != "selected")
                _smallButton(
                  label: "Reject",
                  icon: Icons.cancel_outlined,
                  color: const Color(0xFFEF4444),
                  onTap: () => _updateStatus(rowId: rowId, status: "rejected"),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _smallButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: color),
      label: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.w900, color: color),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color ?? const Color(0xFFE2E8F0)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
      case 'viewed':
        bg = const Color(0xFFFFEDD5);
        fg = const Color(0xFF9A3412);
        label = 'Viewed';
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

  String _formatDate(String date) {
    final d = DateTime.tryParse(date);
    if (d == null) return date;

    return "${d.day.toString().padLeft(2, '0')}-"
        "${d.month.toString().padLeft(2, '0')}-"
        "${d.year}";
  }
}