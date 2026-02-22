import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/construction_service.dart';

class RCCWorksForm extends StatefulWidget {
  const RCCWorksForm({Key? key}) : super(key: key);

  @override
  State<RCCWorksForm> createState() => _RCCWorksFormState();
}

class _RCCWorksFormState extends State<RCCWorksForm> {
  final _formKey = GlobalKey<FormState>();
  final SupabaseClient _db = Supabase.instance.client;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _plotSizeController = TextEditingController();
  final _additionalController = TextEditingController();

  List<String> _districts = [];
  String? _selectedDistrict;

  String _projectType = 'Residential';
  String _floors = '1';
  String _budget = '5-10 Lakhs';
  String _timeline = 'Within 1 Month';

  bool _needsDesign = false;
  bool _needsMaterial = false;
  bool _needsSoilTest = false;
  bool _hasPlans = false;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadDistricts();
  }

  Future<void> _loadDistricts() async {
    final response = await _db
        .from('assam_districts_master')
        .select('district_name')
        .order('district_name');

    setState(() {
      _districts =
          List<Map<String, dynamic>>.from(response)
              .map((e) => e['district_name'] as String)
              .toList();
      if (_districts.isNotEmpty) {
        _selectedDistrict = _districts.first;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('RCC Construction'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: _selectedDistrict == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _banner(),
                    SizedBox(height: 4.w),
                    _section("Personal Details", _personal()),
                    _section("Project Details", _project()),
                    _section("Requirements", _requirements()),
                    _section("Budget & Timeline", _budgetTimeline()),
                    _section("Additional Details", _additional()),
                    SizedBox(height: 6.w),
                    _submitButton(),
                    SizedBox(height: 4.w),
                  ],
                ),
              ),
            ),
    );
  }

  // ===== Banner (Boost Style) =====
  Widget _banner() {
  return Container(
    width: double.infinity,
    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.w),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [
          Color(0xFFE0F2FE),
          Color(0xFFBAE6FD),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Professional RCC Construction",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13.sp,
            color: const Color(0xFF0F172A),
          ),
        ),
        SizedBox(height: 1.5.h),
        const Text("• Foundation, column & slab execution"),
        const Text("• High-strength structural construction"),
        const Text("• Supervised quality material usage"),
      ],
    ),
  );
}

  Widget _section(String title, Widget child) {
    return Container(
      margin: EdgeInsets.only(bottom: 4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp)),
          SizedBox(height: 3.w),
          child,
        ],
      ),
    );
  }

  Widget _personal() {
    return Column(
      children: [
        _input(_nameController, "Full Name"),
        SizedBox(height: 3.w),
        _phoneInput(),
        SizedBox(height: 3.w),
        DropdownButtonFormField<String>(
          value: _selectedDistrict,
          decoration: _dec("District"),
          items: _districts
              .map((e) =>
                  DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) => setState(() => _selectedDistrict = v),
        ),
      ],
    );
  }

  Widget _phoneInput() {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.number,
      maxLength: 10,
      validator: (v) {
        if (v == null || v.isEmpty) return "Required";
        if (v.length != 10) return "Enter valid 10 digit number";
        return null;
      },
      onChanged: (value) {
        final clean = value.replaceAll(RegExp(r'[^0-9]'), '');
        if (value != clean) {
          _phoneController.value = TextEditingValue(
              text: clean,
              selection:
                  TextSelection.collapsed(offset: clean.length));
        }
      },
      decoration: _dec("Phone Number"),
    );
  }

  Widget _project() {
    return Column(
      children: [
        _dropdown("Project Type", _projectType,
            ['Residential', 'Commercial', 'Industrial'],
            (v) => setState(() => _projectType = v!)),
        SizedBox(height: 3.w),
        _dropdown("Number of Floors", _floors,
            ['1', '2', '3', '4+'],
            (v) => setState(() => _floors = v!)),
        SizedBox(height: 3.w),
        _input(_plotSizeController, "Plot Size (sq ft)",
            keyboardType: TextInputType.number),
      ],
    );
  }

  Widget _requirements() {
    return Column(
      children: [
        _check("Design & Planning", _needsDesign,
            (v) => setState(() => _needsDesign = v!)),
        _check("Material Supply", _needsMaterial,
            (v) => setState(() => _needsMaterial = v!)),
        _check("Soil Testing", _needsSoilTest,
            (v) => setState(() => _needsSoilTest = v!)),
        _check("Have Existing Plans", _hasPlans,
            (v) => setState(() => _hasPlans = v!)),
      ],
    );
  }

  Widget _budgetTimeline() {
    return Column(
      children: [
        _dropdown("Budget Range", _budget,
            ['Below 5 Lakhs','5-10 Lakhs','10-20 Lakhs','20-50 Lakhs','50 Lakhs+'],
            (v) => setState(() => _budget = v!)),
        SizedBox(height: 3.w),
        _dropdown("Start Timeline", _timeline,
            ['Immediately','Within 1 Month','Within 3 Months','Planning'],
            (v) => setState(() => _timeline = v!)),
      ],
    );
  }

  Widget _additional() {
    return _input(_additionalController,
        "Additional Requirements",
        maxLines: 4,
        required: false);
  }

  Widget _submitButton() {
  return SizedBox(
    width: double.infinity,
    height: 5.5.h,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2563EB),
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: _loading ? null : _submit,
      child: _loading
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(
              "Request Quote",
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
    ),
  );
}

  Future<void> _submit() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _loading = true);

  try {
    await ConstructionService().submitRCCWorksRequest({
      'name': _nameController.text,
      'phone': _phoneController.text,
      'project_address': _selectedDistrict,
      'project_type': _projectType,
      'number_of_floors': _floors,
      'plot_size': _plotSizeController.text,
      'budget_range': _budget,
      'timeline': _timeline,
      'needs_design_planning': _needsDesign,
      'needs_material_supply': _needsMaterial,
      'needs_soil_testing': _needsSoilTest,
      'has_existing_plans': _hasPlans,
      'additional_details': _additionalController.text,
    });

    if (!mounted) return;

    setState(() => _loading = false);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text("Request Submitted"),
        content: const Text(
          "Your RCC construction request has been submitted successfully. Our team will contact you shortly.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );

    if (!mounted) return;
    Navigator.pop(context);

  } catch (e) {
    if (!mounted) return;
    setState(() => _loading = false);

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(e.toString())));
  }
}

  Widget _input(TextEditingController c, String label,
      {TextInputType keyboardType = TextInputType.text,
      int maxLines = 1,
      bool required = true}) {
    return TextFormField(
      controller: c,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator:
          required ? (v) => v == null || v.isEmpty ? "Required" : null : null,
      decoration: _dec(label),
    );
  }

  Widget _dropdown(String label, String value, List<String> options,
      Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: _dec(label),
      items: options
          .map((e) =>
              DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _check(String title, bool value, Function(bool?) onChanged) {
    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      title: Text(title),
    );
  }

  InputDecoration _dec(String label) {
    return InputDecoration(
      labelText: label,
      border:
          OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _plotSizeController.dispose();
    _additionalController.dispose();
    super.dispose();
  }
}