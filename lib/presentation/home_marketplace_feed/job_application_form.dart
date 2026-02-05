import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class JobApplicationForm extends StatefulWidget {
  final String jobId;

  const JobApplicationForm({
    Key? key,
    required this.jobId,
  }) : super(key: key);

  @override
  State<JobApplicationForm> createState() => _JobApplicationFormState();
}

class _JobApplicationFormState extends State<JobApplicationForm> {
  final _formKey = GlobalKey<FormState>();
  final SupabaseClient _supabase = Supabase.instance.client;

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _skills = TextEditingController();

  PlatformFile? _resumeFile;
  PlatformFile? _photoFile;

  bool _loading = true;
  bool _submitting = false;

  // Your bucket
  static const String _bucket = "job-files";

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _skills.dispose();
    super.dispose();
  }

  Future<void> _prefill() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() => _loading = false);
        return;
      }

      final profile = await _supabase
          .from('user_profiles')
          .select('full_name, email, mobile_number, skills')
          .eq('id', user.id)
          .maybeSingle();

      if (profile != null) {
        _name.text = (profile['full_name'] ?? '').toString();
        _email.text = (profile['email'] ?? '').toString();
        _phone.text = (profile['mobile_number'] ?? '').toString();

        final skills = profile['skills'];
        if (skills is List) {
          _skills.text = skills.map((e) => e.toString()).join(', ');
        }
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() => _loading = false);
  }

  // ------------------------------------------------------------
  // PICKERS (NO CRASH)
  // ------------------------------------------------------------
  Future<void> _pickResume() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );

    if (res == null) return;

    final file = res.files.single;

    if (file.bytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Resume could not be read. Please pick again."),
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _resumeFile = file);
  }

  Future<void> _pickPhoto() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (res == null) return;

    final file = res.files.single;

    if (file.bytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Photo could not be read. Please pick again."),
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _photoFile = file);
  }

  // ------------------------------------------------------------
  // APPLY
  // ------------------------------------------------------------
  Future<void> _apply() async {
    if (_submitting) return;

    if (!_formKey.currentState!.validate()) return;

    if (_resumeFile == null || _photoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resume and photo are required')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception("Not logged in");

      final userId = user.id;

      // 1) Prevent duplicate apply (correct)
      final existing = await _supabase
          .from('job_applications_listings')
          .select('id')
          .eq('user_id', userId)
          .eq('listing_id', widget.jobId)
          .maybeSingle();

      if (existing != null) {
        throw Exception("You already applied for this job");
      }

      // 2) Upload resume + photo
      final resumeUrl = await _uploadToJobFiles(
        folder: "resumes/$userId",
        bytes: _resumeFile!.bytes!,
        fileName: _safeFileName(_resumeFile!.name, defaultExt: "pdf"),
      );

      final photoUrl = await _uploadToJobFiles(
        folder: "photos/$userId",
        bytes: _photoFile!.bytes!,
        fileName: _safeFileName(_photoFile!.name, defaultExt: "jpg"),
      );

      // 3) Insert job_applications row (NEW ROW PER APPLY)
      final createdApp = await _supabase
          .from('job_applications')
          .insert({
            'user_id': userId,
            'name': _name.text.trim(),
            'email': _email.text.trim(),
            'phone': _phone.text.trim(),
            'skills': _skills.text
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList(),
            'resume_file_url': resumeUrl,
            'photo_file_url': photoUrl,
            'status': 'submitted',
            'created_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();

      final applicationId = createdApp['id'].toString();

      // 4) Insert job_applications_listings row
      await _supabase.from('job_applications_listings').insert({
        'application_id': applicationId,
        'listing_id': widget.jobId,
        'user_id': userId,
        'applied_at': DateTime.now().toIso8601String(),
        'application_status': 'applied',
      });

      // 5) Increment job count safely
      // (No need to read old value. Just +1 using RPC would be best,
      // but for now we keep it safe.)
      try {
        final job = await _supabase
            .from('job_listings')
            .select('applications_count')
            .eq('id', widget.jobId)
            .maybeSingle();

        final current = (job?['applications_count'] ?? 0) as int;

        await _supabase
            .from('job_listings')
            .update({'applications_count': current + 1}).eq('id', widget.jobId);
      } catch (_) {}

      if (!mounted) return;

      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application submitted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ------------------------------------------------------------
  // STORAGE
  // ------------------------------------------------------------
  Future<String> _uploadToJobFiles({
    required String folder,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final path =
        '$folder/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    await _supabase.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );

    return _supabase.storage.from(_bucket).getPublicUrl(path);
  }

  String _safeFileName(String original, {required String defaultExt}) {
    final cleaned = original.trim().replaceAll(' ', '_');
    if (cleaned.contains('.')) return cleaned;
    return '$cleaned.$defaultExt';
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Apply for Job'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0.6,
      ),
      body: Padding(
        padding: EdgeInsets.all(4.w),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _field(_name, 'Full name'),
              _field(_email, 'Email'),
              _field(_phone, 'Phone'),
              _field(_skills, 'Skills (comma separated)'),
              SizedBox(height: 1.h),
              _fileTile(
                title: 'Resume (PDF)',
                fileName: _resumeFile?.name,
                onPick: _pickResume,
              ),
              _fileTile(
                title: 'Photo',
                fileName: _photoFile?.name,
                onPick: _pickPhoto,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _apply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.6,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit Application',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _fileTile({
    required String title,
    required String? fileName,
    required VoidCallback onPick,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 1.2.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          fileName == null ? 'Not selected' : fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: TextButton(
          onPressed: onPick,
          child: const Text('Choose'),
        ),
      ),
    );
  }
}