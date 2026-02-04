import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateJobScreen extends StatefulWidget {
  const CreateJobScreen({Key? key}) : super(key: key);

  @override
  State<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final SupabaseClient _client = Supabase.instance.client;

  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _minSalaryCtrl = TextEditingController();
  final _maxSalaryCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController();
  final _vacancyCtrl = TextEditingController();
  final _skillsCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  String _jobType = 'Full-time';
  bool _loading = false;

  final List<String> _jobTypes = [
    'Full-time',
    'Part-time',
    'Internship',
    'Contract',
    'Walk-in',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    _minSalaryCtrl.dispose();
    _maxSalaryCtrl.dispose();
    _experienceCtrl.dispose();
    _vacancyCtrl.dispose();
    _skillsCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _client.auth.currentUser;
    if (user == null) return;

    setState(() => _loading = true);

    try {
      await _client.from('job_listings').insert({
        'employer_id': user.id,
        'job_title': _titleCtrl.text.trim(),
        'district': _locationCtrl.text.trim(),
        'salary_min': int.tryParse(_minSalaryCtrl.text),
        'salary_max': int.tryParse(_maxSalaryCtrl.text),
        'experience_required': _experienceCtrl.text.trim(),
        'vacancies': int.tryParse(_vacancyCtrl.text),
        'skills_required': _skillsCtrl.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        'job_description': _descriptionCtrl.text.trim(),
        'job_type': _jobType,
        'status': 'open',
      });

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create job')),
      );
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      appBar: AppBar(
        title: const Text(
          'Create Job',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _section('Job Information'),
              _field('Job Title', _titleCtrl),
              _field('Location / District', _locationCtrl),

              _dropdown(),

              _rowFields(
                _field('Min Salary', _minSalaryCtrl, number: true),
                _field('Max Salary', _maxSalaryCtrl, number: true),
              ),

              _rowFields(
                _field('Experience', _experienceCtrl),
                _field('Vacancies', _vacancyCtrl, number: true),
              ),

              _field(
                'Skills (comma separated)',
                _skillsCtrl,
                hint: 'Flutter, Firebase, Sales',
              ),

              _section('Job Description'),
              _multilineField('Description', _descriptionCtrl),

              SizedBox(height: 4.h),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Publish Job',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 6.h),
            ],
          ),
        ),
      ),
    );
  }

  /// ---------------- UI HELPERS ----------------

  Widget _section(String title) {
    return Padding(
      padding: EdgeInsets.only(top: 3.h, bottom: 1.h),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    bool number = false,
    String? hint,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.5.h),
      child: TextFormField(
        controller: controller,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'Required' : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ),
    );
  }

  Widget _multilineField(String label, TextEditingController controller) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: TextFormField(
        controller: controller,
        minLines: 4,
        maxLines: 8,
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'Required' : null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _rowFields(Widget left, Widget right) {
    return Row(
      children: [
        Expanded(child: left),
        SizedBox(width: 3.w),
        Expanded(child: right),
      ],
    );
  }

  Widget _dropdown() {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: DropdownButtonFormField<String>(
        value: _jobType,
        items: _jobTypes
            .map(
              (e) => DropdownMenuItem(
                value: e,
                child: Text(e),
              ),
            )
            .toList(),
        onChanged: (v) => setState(() => _jobType = v!),
        decoration: InputDecoration(
          labelText: 'Job Type',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}