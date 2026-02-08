// File: lib/presentation/jobs/job_application_form.dart
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';

import '../../services/jobs_service.dart';

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
  final JobsService _jobsService = JobsService();

  // ------------------------------------------------------------
  // CONTROLLERS
  // ------------------------------------------------------------
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _district = TextEditingController();
  final _address = TextEditingController();
  final _education = TextEditingController();
  final _experienceLevel = TextEditingController();
  final _experienceDetails = TextEditingController();
  final _skills = TextEditingController();
  final _expectedSalary = TextEditingController();
  final _availability = TextEditingController();
  final _additionalInfo = TextEditingController();

  String? _gender;

  PlatformFile? _resumeFile;

  /// Photo picked via image_picker (Android 10 safe)
  XFile? _photoXFile;
  Uint8List? _photoBytes;

  bool _submitting = false;

  // ------------------------------------------------------------
  // PALETTE (Fluent Light)
  // ------------------------------------------------------------
  static const _bg = Color(0xFFF6F7FB);

  /// FIX: this was `_card` but that conflicts with Widget _card(...)
  static const _cardColor = Colors.white;

  static const _text = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);
  static const _line = Color(0xFFE6EAF2);
  static const _primary = Color(0xFF2563EB);

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _district.dispose();
    _address.dispose();
    _education.dispose();
    _experienceLevel.dispose();
    _experienceDetails.dispose();
    _skills.dispose();
    _expectedSalary.dispose();
    _availability.dispose();
    _additionalInfo.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // PICK RESUME (PDF) -> file_picker
  // ------------------------------------------------------------
  Future<void> _pickResume() async {
    try {
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Resume pick failed: $e")),
      );
    }
  }

  // ------------------------------------------------------------
  // PICK PHOTO -> image_picker (Android 10 SAFE)
  // ------------------------------------------------------------
  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();

      final XFile? xfile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (xfile == null) return;

      final bytes = await xfile.readAsBytes();

      if (!mounted) return;
      setState(() {
        _photoXFile = xfile;
        _photoBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Photo pick failed: $e")),
      );
    }
  }

  // ------------------------------------------------------------
  // APPLY
  // ------------------------------------------------------------
  Future<void> _apply() async {
    if (_submitting) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (_resumeFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resume (PDF) is required')),
      );
      return;
    }

    if (_photoBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo is required')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      await _jobsService.applyForJob(
        jobId: widget.jobId,
        resumeFile: _resumeFile!,
        photoBytes: _photoBytes!,
        photoFileName: _photoXFile?.name ?? "photo.jpg",
        applicationData: {
          'name': _name.text.trim(),
          'email': _email.text.trim(),
          'phone': _phone.text.trim(),
          'district': _district.text.trim(),
          'address': _address.text.trim(),
          'gender': _gender,
          'education': _education.text.trim(),
          'experience_level': _experienceLevel.text.trim(),
          'experience_details': _experienceDetails.text.trim(),

          // IMPORTANT: schema expects TEXT NOT NULL
          'skills': _skills.text.trim(),

          'expected_salary': _expectedSalary.text.trim(),
          'availability': _availability.text.trim(),
          'additional_info': _additionalInfo.text.trim(),
        },
      );

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
  // UI
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        elevation: 0.6,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: _text,
        title: const Text(
          'Apply for Job',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 4.h),
            children: [
              _sectionHeader(
                title: "Candidate Details",
                subtitle: "Fill accurate details to increase chances",
                icon: Icons.person_outline_rounded,
              ),
              SizedBox(height: 1.2.h),
              _card(
                child: Column(
                  children: [
                    _field(
                      controller: _name,
                      label: "Full name",
                      hint: "Eg: Pankaj Doley",
                      requiredField: true,
                      keyboardType: TextInputType.name,
                    ),
                    SizedBox(height: 1.2.h),
                    _field(
                      controller: _phone,
                      label: "Phone",
                      hint: "10 digit mobile number",
                      requiredField: true,
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: 1.2.h),
                    _field(
                      controller: _email,
                      label: "Email",
                      hint: "Eg: you@gmail.com",
                      requiredField: true,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: 1.2.h),
                    _dropdownGender(),
                  ],
                ),
              ),
              SizedBox(height: 2.2.h),
              _sectionHeader(
                title: "Location",
                subtitle: "Optional but recommended",
                icon: Icons.location_on_outlined,
              ),
              SizedBox(height: 1.2.h),
              _card(
                child: Column(
                  children: [
                    _field(
                      controller: _district,
                      label: "District",
                      hint: "Eg: Dibrugarh",
                    ),
                    SizedBox(height: 1.2.h),
                    _field(
                      controller: _address,
                      label: "Address",
                      hint: "Village / Town / Landmark",
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 2.2.h),
              _sectionHeader(
                title: "Profile",
                subtitle: "Education, experience and skills",
                icon: Icons.badge_outlined,
              ),
              SizedBox(height: 1.2.h),
              _card(
                child: Column(
                  children: [
                    _field(
                      controller: _education,
                      label: "Education",
                      hint: "Eg: B.Tech, Diploma, HS",
                    ),
                    SizedBox(height: 1.2.h),
                    _field(
                      controller: _experienceLevel,
                      label: "Experience level",
                      hint: "Eg: Fresher / 1-2 years / 5+ years",
                    ),
                    SizedBox(height: 1.2.h),
                    _field(
                      controller: _experienceDetails,
                      label: "Experience details",
                      hint: "Describe your work experience",
                      maxLines: 3,
                    ),
                    SizedBox(height: 1.2.h),
                    _field(
                      controller: _skills,
                      label: "Skills (comma separated)",
                      hint: "Eg: MS Excel, Tally, Driving",
                      requiredField: true,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 2.2.h),
              _sectionHeader(
                title: "Documents",
                subtitle: "Resume and photo are required",
                icon: Icons.upload_file_outlined,
              ),
              SizedBox(height: 1.2.h),
              _card(
                child: Column(
                  children: [
                    _fileTile(
                      title: 'Resume (PDF)',
                      subtitle: "Upload your resume in PDF format",
                      fileName: _resumeFile?.name,
                      onPick: _pickResume,
                      icon: Icons.picture_as_pdf_outlined,
                    ),
                    Divider(height: 1, color: Colors.black.withOpacity(0.06)),
                    _fileTile(
                      title: 'Photo',
                      subtitle: "Upload a clear photo",
                      fileName: _photoXFile?.name,
                      onPick: _pickPhoto,
                      icon: Icons.image_outlined,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 2.2.h),
              _sectionHeader(
                title: "Optional",
                subtitle: "Expected salary and availability",
                icon: Icons.tune_rounded,
              ),
              SizedBox(height: 1.2.h),
              _card(
                child: Column(
                  children: [
                    _field(
                      controller: _expectedSalary,
                      label: "Expected salary",
                      hint: "Eg: 15000 / month",
                    ),
                    SizedBox(height: 1.2.h),
                    _field(
                      controller: _availability,
                      label: "Availability",
                      hint: "Eg: Immediate / 7 days / 30 days",
                    ),
                    SizedBox(height: 1.2.h),
                    _field(
                      controller: _additionalInfo,
                      label: "Additional information",
                      hint: "Anything you want to add",
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 2.8.h),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _apply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.6,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit Application',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.2,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 1.4.h),
              Text(
                "By submitting, you confirm your details are correct.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: _muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // UI PARTS
  // ------------------------------------------------------------
  Widget _sectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDBEAFE)),
          ),
          child: Icon(icon, color: _primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w900,
                  color: _text,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: _cardColor,
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
      child: child,
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool requiredField = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: (v) {
        if (!requiredField) return null;
        if (v == null || v.trim().isEmpty) return "Required";
        return null;
      },
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        color: _text,
      ),
      decoration: InputDecoration(
        labelText: requiredField ? "$label *" : label,
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        labelStyle: const TextStyle(
          color: _muted,
          fontWeight: FontWeight.w800,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF94A3B8),
          fontWeight: FontWeight.w700,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _primary, width: 1.3),
        ),
      ),
    );
  }

  Widget _dropdownGender() {
    return DropdownButtonFormField<String>(
      value: _gender,
      items: const [
        DropdownMenuItem(value: 'Male', child: Text("Male")),
        DropdownMenuItem(value: 'Female', child: Text("Female")),
        DropdownMenuItem(value: 'Other', child: Text("Other")),
      ],
      onChanged: (v) => setState(() => _gender = v),
      decoration: InputDecoration(
        labelText: "Gender (optional)",
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        labelStyle: const TextStyle(
          color: _muted,
          fontWeight: FontWeight.w800,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _primary, width: 1.3),
        ),
      ),
    );
  }

  Widget _fileTile({
    required String title,
    required String subtitle,
    required String? fileName,
    required VoidCallback onPick,
    required IconData icon,
  }) {
    final hasFile = fileName != null && fileName.trim().isNotEmpty;

    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.6.h),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _line),
        ),
        child: Icon(icon, color: _text),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          color: _text,
          letterSpacing: -0.2,
        ),
      ),
      subtitle: Text(
        hasFile ? fileName! : subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: hasFile ? _text : _muted,
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: TextButton(
        onPressed: onPick,
        child: Text(
          hasFile ? "Change" : "Choose",
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}