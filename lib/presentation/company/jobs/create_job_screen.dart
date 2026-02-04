import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/employer_job_service.dart';

class CreateJobScreen extends StatefulWidget {
  const CreateJobScreen({Key? key}) : super(key: key);

  @override
  State<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = EmployerJobService();

  final _title = TextEditingController();
  final _company = TextEditingController();
  final _location = TextEditingController();
  final _experience = TextEditingController();
  final _salaryMin = TextEditingController();
  final _salaryMax = TextEditingController();
  final _skills = TextEditingController();
  final _description = TextEditingController();

  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post a Job'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Padding(
        padding: EdgeInsets.all(4.w),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _field(_title, 'Job title'),
              _field(_company, 'Company name'),
              _field(_location, 'Location / District'),
              _field(_experience, 'Experience required'),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      _salaryMin,
                      'Min salary',
                      type: TextInputType.number,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: _field(
                      _salaryMax,
                      'Max salary',
                      type: TextInputType.number,
                    ),
                  ),
                ],
              ),
              _field(_skills, 'Skills (comma separated)', maxLines: 2),
              _field(_description, 'Job description', maxLines: 4),

              SizedBox(height: 4.h),

              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _submitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Publish Job',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    int maxLines = 1,
    TextInputType type = TextInputType.text,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: type,
        maxLines: maxLines,
        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    await _service.createJob({
      'job_title': _title.text,
      'company_name': _company.text,
      'district': _location.text,
      'experience_required': _experience.text,
      'salary_min': int.tryParse(_salaryMin.text),
      'salary_max': int.tryParse(_salaryMax.text),
      'skills_required':
          _skills.text.split(',').map((e) => e.trim()).toList(),
      'job_description': _description.text,
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    });

    Navigator.pop(context);
  }
}