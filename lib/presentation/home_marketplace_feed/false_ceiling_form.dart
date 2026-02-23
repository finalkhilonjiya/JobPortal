import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/construction_service.dart';

class FalseCeilingForm extends StatefulWidget {
  const FalseCeilingForm({Key? key}) : super(key: key);

  @override
  State<FalseCeilingForm> createState() => _FalseCeilingFormState();
}

class _FalseCeilingFormState extends State<FalseCeilingForm> {
  final _formKey = GlobalKey<FormState>();
  final SupabaseClient _db = Supabase.instance.client;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _areaController = TextEditingController();
  final _heightController = TextEditingController();
  final _additionalController = TextEditingController();

  List<String> _districts = [];
  String? _selectedDistrict;

  String _ceilingType = 'POP (Plaster of Paris)';
  String _roomType = 'Living Room';
  String _designComplexity = 'Simple/Plain';
  String _lightingType = 'LED Lights';
  String _budget = '15,000 - 30,000';
  String _timeline = 'Within 2 Weeks';

  bool _needsLightingWork = false;
  bool _needsFanPoints = false;
  bool _needsACDucting = false;
  bool _needsPainting = false;
  bool _needsDesign = false;
  bool _needsElectricalWork = false;
  bool _hasExistingCeiling = false;
  bool _needsMaintenance = false;

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
      _districts = List<Map<String, dynamic>>.from(response)
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
        title: const Text('False Ceiling'),
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
                    _infoCard(),
                    SizedBox(height: 4.w),
                    _section("Personal Details", _personal()),
                    _section("Ceiling Specifications", _specs()),
                    _section("Additional Services", _services()),
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

  Widget _infoCard() {
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
          "Professional False Ceiling Solutions",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13.sp,
            color: const Color(0xFF0F172A),
          ),
        ),
        SizedBox(height: 1.5.h),
        const Text("• POP, Gypsum & PVC ceiling installation"),
        const Text("• Custom lighting & cove integration"),
        const Text("• AC duct concealment & modern finishes"),
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

  Widget _specs() {
    return Column(
      children: [
        _dropdown("Ceiling Material", _ceilingType,
            ['POP (Plaster of Paris)','Gypsum Board','PVC Panels','Wooden Panels','Metal Ceiling'],
            (v) => setState(() => _ceilingType = v!)),
        SizedBox(height: 3.w),
        _dropdown("Room Type", _roomType,
            ['Living Room','Bedroom','Kitchen','Office','Hall'],
            (v) => setState(() => _roomType = v!)),
        SizedBox(height: 3.w),
        _dropdown("Design Complexity", _designComplexity,
            ['Simple/Plain','Step/Tray Ceiling','Cove Lighting','Decorative','Custom'],
            (v) => setState(() => _designComplexity = v!)),
        SizedBox(height: 3.w),
        _dropdown("Lighting Type", _lightingType,
            ['LED Lights','Spot Lights','Cove Lighting','Chandelier','Mixed'],
            (v) => setState(() => _lightingType = v!)),
        SizedBox(height: 3.w),
        _input(_areaController, "Room Area (sq ft)",
            keyboardType: TextInputType.number),
        SizedBox(height: 3.w),
        _input(_heightController, "Room Height (ft)",
            keyboardType: TextInputType.number,
            required: false),
      ],
    );
  }

  Widget _services() {
    return Column(
      children: [
        _check("Lighting Installation", _needsLightingWork,
            (v) => setState(() => _needsLightingWork = v!)),
        _check("Fan Mounting Points", _needsFanPoints,
            (v) => setState(() => _needsFanPoints = v!)),
        _check("AC Duct Concealment", _needsACDucting,
            (v) => setState(() => _needsACDucting = v!)),
        _check("Painting/Finishing Work", _needsPainting,
            (v) => setState(() => _needsPainting = v!)),
        _check("Custom Design Service", _needsDesign,
            (v) => setState(() => _needsDesign = v!)),
        _check("Electrical Work Required", _needsElectricalWork,
            (v) => setState(() => _needsElectricalWork = v!)),
        _check("Existing Ceiling Repair", _hasExistingCeiling,
            (v) => setState(() => _hasExistingCeiling = v!)),
        _check("Maintenance Service", _needsMaintenance,
            (v) => setState(() => _needsMaintenance = v!)),
      ],
    );
  }

  Widget _budgetTimeline() {
    return Column(
      children: [
        _dropdown("Budget Range", _budget,
            ['10,000 - 15,000','15,000 - 30,000','30,000 - 50,000','50,000+'],
            (v) => setState(() => _budget = v!)),
        SizedBox(height: 3.w),
        _dropdown("Start Timeline", _timeline,
            ['Immediately','Within 1 Week','Within 2 Weeks','Within 1 Month','Flexible'],
            (v) => setState(() => _timeline = v!)),
      ],
    );
  }

  Widget _additional() {
    return _input(_additionalController,
        "Specific Design Requirements",
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
        foregroundColor: Colors.white, // ✅ Force white text
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
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              "Request Quote",
              style: TextStyle(
                color: Colors.white, // ✅ Explicit white text
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
    await ConstructionService().submitFalseCeilingRequest({
      'name': _nameController.text,
      'phone': _phoneController.text,
      'project_address': _selectedDistrict,
      'ceiling_type': _ceilingType,
      'room_type': _roomType,
      'design_complexity': _designComplexity,
      'lighting_type': _lightingType,
      'area_size': _areaController.text,
      'room_height': _heightController.text,
      'budget_range': _budget,
      'timeline': _timeline,
      'needs_lighting_work': _needsLightingWork,
      'needs_fan_points': _needsFanPoints,
      'needs_ac_ducting': _needsACDucting,
      'needs_painting': _needsPainting,
      'needs_design': _needsDesign,
      'needs_electrical_work': _needsElectricalWork,
      'has_existing_ceiling': _hasExistingCeiling,
      'needs_maintenance': _needsMaintenance,
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
          "Your false ceiling request has been submitted successfully. Our team will contact you shortly.",
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
    _areaController.dispose();
    _heightController.dispose();
    _additionalController.dispose();
    super.dispose();
  }
}