import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/construction_service.dart';

class AssamTypeForm extends StatefulWidget {
  const AssamTypeForm({Key? key}) : super(key: key);

  @override
  State<AssamTypeForm> createState() => _AssamTypeFormState();
}

class _AssamTypeFormState extends State<AssamTypeForm> {
  final _formKey = GlobalKey<FormState>();
  final SupabaseClient _db = Supabase.instance.client;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _plotSizeController = TextEditingController();
  final _additionalController = TextEditingController();

  List<String> _districts = [];
  String? _selectedDistrict;

  String _houseType = 'Traditional Assam House';
  String _floors = 'Single Story';
  String _roofType = 'Tin Roof';
  String _foundationType = 'Pillar Foundation';
  String _budget = '10-20 Lakhs';
  String _timeline = 'Within 3 Months';

  bool _needsDesign = false;
  bool _needsMaterial = false;
  bool _needsCarpentry = false;
  bool _needsModern = false;
  bool _needsElectrical = false;
  bool _needsPlumbing = false;
  bool _landReady = false;
  bool _needsPermits = false;

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
        title: const Text('Assam Type Construction'),
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
                    _section("House Specifications", _houseSpecs()),
                    _section("Services Required", _services()),
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

  // ===== Info Card =====
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
          "Traditional Assam Type House",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13.sp,
            color: const Color(0xFF0F172A),
          ),
        ),
        SizedBox(height: 1.5.h),
        const Text("• Elevated pillar foundation structure"),
        const Text("• Sloped roofing for heavy rainfall"),
        const Text("• Traditional wood craftsmanship"),
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

  Widget _houseSpecs() {
    return Column(
      children: [
        _dropdown("House Type", _houseType,
            ['Traditional Assam House','Modern Assam Style','Heritage Style','Fusion Style'],
            (v) => setState(() => _houseType = v!)),
        SizedBox(height: 3.w),
        _dropdown("Stories", _floors,
            ['Single Story','Double Story','Ground + First'],
            (v) => setState(() => _floors = v!)),
        SizedBox(height: 3.w),
        _dropdown("Roof Type", _roofType,
            ['Tin Roof','Tile Roof','Concrete Slab','Mixed'],
            (v) => setState(() => _roofType = v!)),
        SizedBox(height: 3.w),
        _dropdown("Foundation Type", _foundationType,
            ['Pillar Foundation','Concrete Foundation','Wooden Posts'],
            (v) => setState(() => _foundationType = v!)),
        SizedBox(height: 3.w),
        _input(_plotSizeController, "Plot Size (sq ft)",
            keyboardType: TextInputType.number),
      ],
    );
  }

  Widget _services() {
    return Column(
      children: [
        _check("Architectural Design", _needsDesign,
            (v) => setState(() => _needsDesign = v!)),
        _check("Material Supply", _needsMaterial,
            (v) => setState(() => _needsMaterial = v!)),
        _check("Traditional Carpentry", _needsCarpentry,
            (v) => setState(() => _needsCarpentry = v!)),
        _check("Modern Amenities", _needsModern,
            (v) => setState(() => _needsModern = v!)),
        _check("Electrical Work", _needsElectrical,
            (v) => setState(() => _needsElectrical = v!)),
        _check("Plumbing Work", _needsPlumbing,
            (v) => setState(() => _needsPlumbing = v!)),
        _check("Land Ready", _landReady,
            (v) => setState(() => _landReady = v!)),
        _check("Need Permits Help", _needsPermits,
            (v) => setState(() => _needsPermits = v!)),
      ],
    );
  }

  Widget _budgetTimeline() {
    return Column(
      children: [
        _dropdown("Budget Range", _budget,
            ['5-10 Lakhs','10-20 Lakhs','20-35 Lakhs','35-50 Lakhs','50 Lakhs+'],
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
        "Special Requirements",
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
    await ConstructionService().submitAssamTypeRequest({
      'name': _nameController.text,
      'phone': _phoneController.text,
      'project_address': _selectedDistrict,
      'house_type': _houseType,
      'number_of_floors': _floors,
      'roof_type': _roofType,
      'foundation_type': _foundationType,
      'plot_size': _plotSizeController.text,
      'budget_range': _budget,
      'timeline': _timeline,
      'needs_design': _needsDesign,
      'needs_material_supply': _needsMaterial,
      'needs_traditional_carpentry': _needsCarpentry,
      'needs_modern_amenities': _needsModern,
      'needs_electrical_work': _needsElectrical,
      'needs_plumbing_work': _needsPlumbing,
      'has_land_ready': _landReady,
      'needs_permits': _needsPermits,
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
          "Your Assam type construction request has been submitted successfully. Our team will contact you shortly.",
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