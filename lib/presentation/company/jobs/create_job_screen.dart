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
        "benefits":
            _benefitsCtrl.text.trim().isEmpty ? null : _benefitsCtrl.text.trim(),
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
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text(
          "Create Job",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0.6,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 12.h),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _pageIntro(),
                  SizedBox(height: 2.2.h),

                  _cardSection(
                    title: "Company Details",
                    subtitle: "Basic company information shown to candidates",
                    child: Column(
                      children: [
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
                      ],
                    ),
                  ),

                  SizedBox(height: 2.2.h),

                  _cardSection(
                    title: "Job Details",
                    subtitle: "Job title, category and working type",
                    child: Column(
                      children: [
                        _field("Job Title", _jobTitleCtrl),
                        _categoryDropdown(),
                        _dropdown("Job Type", _jobType, _jobTypes, (v) {
                          setState(() => _jobType = v);
                        }),
                        _dropdown(
                          "Employment Type",
                          _employmentType,
                          _employmentTypes,
                          (v) => setState(() => _employmentType = v),
                        ),
                        _dropdown("Work Mode", _workMode, _workModes, (v) {
                          setState(() => _workMode = v);
                        }),
                      ],
                    ),
                  ),

                  SizedBox(height: 2.2.h),

                  _cardSection(
                    title: "Salary",
                    subtitle: "Monthly / yearly salary range",
                    child: Column(
                      children: [
                        _rowFields(
                          _field("Min Salary", _salaryMinCtrl, number: true),
                          _field("Max Salary", _salaryMaxCtrl, number: true),
                        ),
                        _dropdown(
                          "Salary Period",
                          _salaryPeriod,
                          _salaryPeriods,
                          (v) => setState(() => _salaryPeriod = v),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 2.2.h),

                  _cardSection(
                    title: "Requirements",
                    subtitle: "Job description and candidate requirements",
                    child: Column(
                      children: [
                        _multilineField("Job Description", _jobDescriptionCtrl),
                        _multilineField("Requirements", _requirementsCtrl),
                        _field("Education Required", _educationCtrl),
                        _field("Experience Required", _experienceCtrl),
                        _field(
                          "Skills (comma separated)",
                          _skillsCtrl,
                          hint: "Flutter, Firebase, Sales",
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 2.2.h),

                  _cardSection(
                    title: "Location",
                    subtitle: "Where the candidate will work",
                    child: Column(
                      children: [
                        _field("District", _districtCtrl),
                        _multilineField("Full Job Address", _addressCtrl),
                      ],
                    ),
                  ),

                  SizedBox(height: 2.2.h),

                  _cardSection(
                    title: "Other",
                    subtitle: "Urgency, openings and optional details",
                    child: Column(
                      children: [
                        _dropdown(
                          "Hiring Urgency",
                          _hiringUrgency,
                          _urgencies,
                          (v) => setState(() => _hiringUrgency = v),
                        ),
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Sticky submit bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(4.w, 1.4.h, 4.w, 2.2.h),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.black.withOpacity(0.06)),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      disabledBackgroundColor: const Color(0xFFE2E8F0),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pageIntro() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7EAF0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDBEAFE)),
            ),
            child: const Icon(
              Icons.add_business_rounded,
              color: Color(0xFF2563EB),
              size: 24,
            ),
          ),
          SizedBox(width: 4.w),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Post a new job",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Fill details carefully. Candidates will see this exactly.",
                  style: TextStyle(
                    fontSize: 12.8,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // UI HELPERS (WORLD CLASS)
  // ------------------------------------------------------------
  Widget _cardSection({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(4.w, 2.2.h, 4.w, 2.2.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7EAF0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12.8,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          SizedBox(height: 2.h),
          child,
        ],
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
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Text(
            "Loading categories...",
            style: TextStyle(
              fontWeight: FontWeight.w800,
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
            color: const Color(0xFFFFF1F2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFECACA)),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  "No job categories found in DB",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF9F1239),
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
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF64748B),
          ),
          hintStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF94A3B8),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.4),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFFCA5A5)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
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
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: Color(0xFF0F172A),
          height: 1.35,
        ),
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF64748B),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.4),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFFCA5A5)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
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
                child: Text(
                  e,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
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
          fillColor: const Color(0xFFF8FAFC),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF64748B),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.4),
          ),
        ),
        icon: const Icon(Icons.keyboard_arrow_down_rounded),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}