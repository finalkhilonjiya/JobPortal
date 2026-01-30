import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/jobs_service.dart';

class JobApplicationForm extends StatefulWidget {
  final String jobId;
  const JobApplicationForm({Key? key, required this.jobId}) : super(key: key);

  @override
  State<JobApplicationForm> createState() => _JobApplicationFormState();
}

class _JobApplicationFormState extends State<JobApplicationForm> {
  final _formKey = GlobalKey<FormState>();
  final _jobsService = JobsService();
  final _supabase = Supabase.instance.client;

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _skills = TextEditingController();

  File? _resume;
  File? _photo;

  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  Future<void> _prefill() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final profile = await _supabase
        .from('user_profiles')
        .select()
        .eq('id', user.id)
        .single();

    _name.text = profile['full_name'] ?? '';
    _email.text = profile['email'] ?? '';
    _phone.text = profile['mobile_number'] ?? '';
    _skills.text = (profile['skills'] as List?)?.join(', ') ?? '';

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply Job'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
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
              _field(_skills, 'Skills'),

              _filePicker('Resume (PDF)', _resume, () async {
                final f = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
                if (f != null) setState(() => _resume = File(f.files.single.path!));
              }),

              _filePicker('Photo', _photo, () async {
                final f = await FilePicker.platform.pickFiles(type: FileType.image);
                if (f != null) setState(() => _photo = File(f.files.single.path!));
              }),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _apply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _submitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Apply', style: TextStyle(fontWeight: FontWeight.w600)),
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
        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _filePicker(String title, File? file, VoidCallback onPick) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(file == null ? 'Not uploaded' : 'Attached'),
      trailing: TextButton(onPressed: onPick, child: const Text('Upload')),
    );
  }

  Future<void> _apply() async {
    if (!_formKey.currentState!.validate()) return;
    if (_resume == null || _photo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resume and photo required')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      await _jobsService.applyForJob(
        jobId: widget.jobId,
        resumeFile: _resume,
        photoFile: _photo,
        applicationData: {
          'name': _name.text,
          'email': _email.text,
          'phone': _phone.text,
          'skills': _skills.text,
          'resume_file_name': _resume!.path.split('/').last,
          'photo_file_name': _photo!.path.split('/').last,
        },
      );

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application submitted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _submitting = false);
    }
  }
}
