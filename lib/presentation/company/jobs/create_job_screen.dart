import 'package:flutter/material.dart';

class CreateJobScreen extends StatefulWidget {
  const CreateJobScreen({Key? key}) : super(key: key);

  @override
  State<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController();
  final _salaryCtrl = TextEditingController();
  final _skillsCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  String _jobType = 'Full-time';

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    _experienceCtrl.dispose();
    _salaryCtrl.dispose();
    _skillsCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    /// NEXT STEP:
    /// - Save to Supabase
    /// - Attach employer_id
    /// - Redirect to employer job list

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Job posted (mock)')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text(
          'Post a Job',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(
              label: 'Job Title',
              controller: _titleCtrl,
              hint: 'e.g. Flutter Developer',
            ),
            _field(
              label: 'Location',
              controller: _locationCtrl,
              hint: 'e.g. Bangalore',
            ),
            _field(
              label: 'Experience Required',
              controller: _experienceCtrl,
              hint: 'e.g. 2-4 years',
            ),
            _field(
              label: 'Salary Range',
              controller: _salaryCtrl,
              hint: 'e.g. ₹6–10 LPA',
            ),

            const SizedBox(height: 16),
            const Text(
              'Job Type',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _jobType,
              items: const [
                DropdownMenuItem(value: 'Full-time', child: Text('Full-time')),
                DropdownMenuItem(value: 'Part-time', child: Text('Part-time')),
                DropdownMenuItem(value: 'Internship', child: Text('Internship')),
                DropdownMenuItem(value: 'Contract', child: Text('Contract')),
              ],
              onChanged: (v) => setState(() => _jobType = v!),
              decoration: _inputDecoration(),
            ),

            const SizedBox(height: 16),
            _field(
              label: 'Skills',
              controller: _skillsCtrl,
              hint: 'Flutter, Dart, Firebase',
            ),
            _field(
              label: 'Job Description',
              controller: _descriptionCtrl,
              maxLines: 5,
              hint: 'Describe role & responsibilities',
            ),

            const SizedBox(height: 32),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Post Job',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            decoration: _inputDecoration(hint),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration([String? hint]) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
    );
  }
}