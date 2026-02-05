import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // Required by schema
  final _companyNameCtrl = TextEditingController();
  final _contactPersonCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  final _jobTitleCtrl = TextEditingController();

  final _jobDescriptionCtrl = TextEditingController();
  final _requirementsCtrl = TextEditingController();

  final _educationCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController();

  final _salaryMinCtrl = TextEditingController();
  final _salaryMaxCtrl = TextEditingController();

  final _districtCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  final _openingsCtrl = TextEditingController(text: "1");

  final _skillsCtrl = TextEditingController();
  final _benefitsCtrl = TextEditingController();
  final _additionalInfoCtrl = TextEditingController();

  // Dropdowns (must match schema expectations)
  String _jobType = "Full-time";
  String _employmentType = "Permanent";
  String _workMode = "On-site";
  String _salaryPeriod = "Monthly";
  String _hiringUrgency = "Normal";

  // Category from master table
  bool _loadingCategories = true;
  List<String> _categories = [];
  String? _selectedCategory;

  bool _loading = false;

  final List<String> _jobTypes = const [
    "Full-time",
    "Part-time",
    "Internship",
    "Contract",
  ];

  final List<String> _employmentTypes = const [
    "Permanent",
    "Temporary",
    "Freelance",
    "Contract",
  ];

  final List<String> _workModes = const [
    "On-site",
    "Remote",
    "Hybrid",
  ];

  final List<String> _salaryPeriods = const [
    "Monthly",
    "Yearly",
    "Daily",
    "Hourly",
  ];

  final List<String> _urgencies = const [
    "Normal",
    "Urgent",
    "Immediate",
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _companyNameCtrl.dispose();
    _contactPersonCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();

    _jobTitleCtrl.dispose();

    _jobDescriptionCtrl.dispose();
    _requirementsCtrl.dispose();

    _educationCtrl.dispose();
    _experienceCtrl.dispose();

    _salaryMinCtrl.dispose();
    _salaryMaxCtrl.dispose();

    _districtCtrl.dispose();
    _addressCtrl.dispose();

    _openingsCtrl.dispose();

    _skillsCtrl.dispose();
    _benefitsCtrl.dispose();
    _additionalInfoCtrl.dispose();

    super.dispose();
  }

  // ------------------------------------------------------------
  // CATEGORIES
  // ------------------------------------------------------------
  Future<void> _loadCategories() async {
    try {
      final res = await _client
          .from("job_categories_master")
          .select("category_name")
          .eq("is_active", true)
          .order("category_name", ascending: true);

      final items = List<Map<String, dynamic>>.from(res)
          .map((e) => (e["category_name"] ?? "").toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();

      if (!mounted) return;

      setState(() {
        _categories = items;
        _selectedCategory = items.isNotEmpty ? items.first : null;
        _loadingCategories = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _categories = [];
        _selectedCategory = null;
        _loadingCategories = false;
      });
    }
  }

  // ------------------------------------------------------------
  // SUBMIT
  // ------------------------------------------------------------
  Future<void> _submit() async {
    if (_loading) return;

    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    if (_selectedCategory == null || _selectedCategory!.trim().isEmpty) {
      _showError("Please select a job category");
      return;
    }

    final user = _client.auth.currentUser;
    if (user == null) {
      _showError("Session expired. Please login again.");
      return;
    }

    final salaryMin = int.tryParse(_salaryMinCtrl.text.trim());
    final salaryMax = int.tryParse(_salaryMaxCtrl.text.trim());
    final openings = int.tryParse(_openingsCtrl.text.trim()) ?? 1;

    if (salaryMin == null || salaryMax == null) {
      _showError("Salary must be a valid number");
      return;
    }

    if (salaryMin > salaryMax) {
      _showError("Min salary cannot be greater than max salary");
      return;
    }

    if (openings <= 0) {
      _showError("Openings must be at least 1");
      return;
    }

    setState(() => _loading = true);

    try {
      final skills = _skillsCtrl.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      await _client.from("job_listings").insert({
        // owner
        "user_id": user.id,

        // company
        "company_name": _companyNameCtrl.text.trim(),
        "contact_person": _contactPersonCtrl.text.trim(),
        "phone": _phoneCtrl.text.trim(),
        "email": _emailCtrl.text.trim(),

        // job
        "job_title": _jobTitleCtrl.text.trim(),
        "job_category": _selectedCategory!,
        "job_type": _jobType,
        "employment_type": _employmentType,
        "work_mode": _workMode,

        // details
        "job_description": _jobDescriptionCtrl.text.trim(),
        "requirements": _requirementsCtrl.text.trim(),
        "education_required": _educationCtrl.text.trim(),
        "experience_required": _experienceCtrl.text.trim(),

        // salary
        "salary_min": salaryMin,
        "salary_max": salaryMax,
        "salary_period": _salaryPeriod,
        "salary_currency": "INR",

        // location
        "district": _districtCtrl.text.trim(),
        "job_address": _addressCtrl.text.trim(),

        // other
        "hiring_urgency": _hiringUrgency,
        "benefits": _benefitsCtrl.text.trim().isEmpty
            ? null
            : _benefitsCtrl.text.trim(),
        "additional_info": _additionalInfoCtrl.text.trim().isEmpty
            ? null
            : _additionalInfoCtrl.text.trim(),

        "skills_required": skills.isEmpty ? null : skills,
        "number_of_openings": openings,

        // status must match schema enum
        "status": "active",
      });

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      _showError("Failed to create job");
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  // ------------------------------------------------------------
  // VALIDATORS
  // ------------------------------------------------------------
  String? _requiredValidator(String? v) {
    final value = (v ?? "").trim();
    if (value.isEmpty) return "Required";
    return null;
  }

  String? _phoneValidator(String? v) {
    final value = (v ?? "").trim();
    if (value.isEmpty) return "Required";
    if (value.length != 10) return "Enter valid 10-digit number";
    return null;
  }

  String? _emailValidator(String? v) {
    final value = (v ?? "").trim();
    if (value.isEmpty) return "Required";
    final ok = RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$").hasMatch(value);
    if (!ok) return "Enter valid email";
    return null;
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
          "Create Job",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.white,
        elevation: 0.6,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _section("Company Details"),
              _field("Company Name", _companyNameCtrl),
              _field("Contact Person", _contactPersonCtrl),
              _field(
                "Phone",
                _phoneCtrl,
                validator: _phoneValidator,
                keyboard: TextInputType.phone,
                formatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
              ),
              _field(
                "Email",
                _emailCtrl,
                validator: _emailValidator,
                keyboard: TextInputType.emailAddress,
              ),

              _section("Job Details"),
              _field("Job Title", _jobTitleCtrl),

              _categoryDropdown(),

              _dropdown("Job Type", _jobType, _jobTypes, (v) {
                setState(() => _jobType = v);
              }),
              _dropdown("Employment Type", _employmentType, _employmentTypes,
                  (v) {
                setState(() => _employmentType = v);
              }),
              _dropdown("Work Mode", _workMode, _workModes, (v) {
                setState(() => _workMode = v);
              }),

              _section("Salary"),
              _rowFields(
                _field("Min Salary", _salaryMinCtrl, number: true),
                _field("Max Salary", _salaryMaxCtrl, number: true),
              ),
              _dropdown("Salary Period", _salaryPeriod, _salaryPeriods, (v) {
                setState(() => _salaryPeriod = v);
              }),

              _section("Requirements"),
              _multilineField("Job Description", _jobDescriptionCtrl),
              _multilineField("Requirements", _requirementsCtrl),
              _field("Education Required", _educationCtrl),
              _field("Experience Required", _experienceCtrl),
              _field(
                "Skills (comma separated)",
                _skillsCtrl,
                hint: "Flutter, Firebase, Sales",
              ),

              _section("Location"),
              _field("District", _districtCtrl),
              _multilineField("Full Job Address", _addressCtrl),

              _section("Other"),
              _dropdown("Hiring Urgency", _hiringUrgency, _urgencies, (v) {
                setState(() => _hiringUrgency = v);
              }),
              _field("Openings", _openingsCtrl, number: true),
              _multilineField(
                "Benefits (optional)",
                _benefitsCtrl,
                required: false,
              ),
              _multilineField(
                "Additional Info (optional)",
                _additionalInfoCtrl,
                required: false,
              ),

              SizedBox(height: 4.h),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.6,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          "Publish Job",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
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

  // ------------------------------------------------------------
  // UI HELPERS
  // ------------------------------------------------------------
  Widget _section(String title) {
    return Padding(
      padding: EdgeInsets.only(top: 3.h, bottom: 1.h),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF0F172A),
          ),
        ),
      ),
    );
  }

  Widget _categoryDropdown() {
    if (_loadingCategories) {
      return Padding(
        padding: EdgeInsets.only(bottom: 1.5.h),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Text(
            "Loading categories...",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
            ),
          ),
        ),
      );
    }

    if (_categories.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(bottom: 1.5.h),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  "No job categories found in DB",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ),
              TextButton(
                onPressed: _loadCategories,
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    return _dropdown(
      "Job Category",
      _selectedCategory!,
      _categories,
      (v) => setState(() => _selectedCategory = v),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    bool number = false,
    String? hint,
    TextInputType? keyboard,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.5.h),
      child: TextFormField(
        controller: controller,
        keyboardType:
            keyboard ?? (number ? TextInputType.number : TextInputType.text),
        inputFormatters: formatters,
        validator: validator ?? _requiredValidator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.4),
          ),
        ),
      ),
    );
  }

  Widget _multilineField(
    String label,
    TextEditingController controller, {
    bool required = true,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.5.h),
      child: TextFormField(
        controller: controller,
        minLines: 4,
        maxLines: 10,
        validator: (v) {
          final value = (v ?? "").trim();
          if (!required) return null;
          if (value.isEmpty) return "Required";
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.4),
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

  Widget _dropdown(
    String label,
    String value,
    List<String> items,
    void Function(String) onChanged,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.5.h),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items
            .map(
              (e) => DropdownMenuItem(
                value: e,
                child: Text(e),
              ),
            )
            .toList(),
        onChanged: (v) {
          if (v == null) return;
          onChanged(v);
        },
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}