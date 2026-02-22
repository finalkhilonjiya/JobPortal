import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/construction_service.dart';

class ElectricalWorksForm extends StatefulWidget {
  const ElectricalWorksForm({Key? key}) : super(key: key);

  @override
  State<ElectricalWorksForm> createState() => _ElectricalWorksFormState();
}

class _ElectricalWorksFormState extends State<ElectricalWorksForm> {
  final _formKey = GlobalKey<FormState>();
  final SupabaseClient _db = Supabase.instance.client;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _areaController = TextEditingController();
  final _additionalController = TextEditingController();

  List<String> _districts = [];
  String? _selectedDistrict;

  String _workType = 'New Installation';
  String _propertyType = 'Residential';
  String _loadRequirement = '5 KW';
  String _budget = '10,000 - 25,000';
  String _timeline = 'Within 1 Week';

  bool _needsWiring = false;
  bool _needsSwitchBoard = false;
  bool _needsFanInstallation = false;
  bool _needsLightInstallation = false;
  bool _needsACPoints = false;
  bool _needsStabilizer = false;
  bool _needsEarthing = false;
  bool _needsMCB = false;

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
        title: const Text('Electrical Works'),
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
                    _section("Electrical Work Details", _project()),
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
          "Professional Electrical Services",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13.sp,
            color: const Color(0xFF0F172A),
          ),
        ),
        SizedBox(height: 1.5.h),
        const Text("• Complete home & office wiring"),
        const Text("• MCB panel & load setup"),
        const Text("• Safe earthing & compliance work"),
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
        _dropdown("Type of Work", _workType,
            ['New Installation','Repair/Maintenance','Upgrade','Complete Rewiring'],
            (v) => setState(() => _workType = v!)),
        SizedBox(height: 3.w),
        _dropdown("Property Type", _propertyType,
            ['Residential','Commercial','Industrial','Office'],
            (v) => setState(() => _propertyType = v!)),
        SizedBox(height: 3.w),
        _dropdown("Load Requirement", _loadRequirement,
            ['2 KW','5 KW','10 KW','15 KW','20 KW+','Not Sure'],
            (v) => setState(() => _loadRequirement = v!)),
        SizedBox(height: 3.w),
        _input(_areaController, "Area Size (sq ft)",
            keyboardType: TextInputType.number,
            required: false),
      ],
    );
  }

  Widget _services() {
    return Column(
      children: [
        _check("Wiring Work", _needsWiring,
            (v) => setState(() => _needsWiring = v!)),
        _check("Switch Board Installation", _needsSwitchBoard,
            (v) => setState(() => _needsSwitchBoard = v!)),
        _check("Fan Installation", _needsFanInstallation,
            (v) => setState(() => _needsFanInstallation = v!)),
        _check("Light Installation", _needsLightInstallation,
            (v) => setState(() => _needsLightInstallation = v!)),
        _check("AC Points", _needsACPoints,
            (v) => setState(() => _needsACPoints = v!)),
        _check("Stabilizer Installation", _needsStabilizer,
            (v) => setState(() => _needsStabilizer = v!)),
        _check("Earthing Work", _needsEarthing,
            (v) => setState(() => _needsEarthing = v!)),
        _check("MCB Installation", _needsMCB,
            (v) => setState(() => _needsMCB = v!)),
      ],
    );
  }

  Widget _budgetTimeline() {
    return Column(
      children: [
        _dropdown("Budget Range", _budget,
            ['5,000 - 10,000','10,000 - 25,000','25,000 - 50,000','50,000 - 1,00,000','1,00,000+'],
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
    await ConstructionService().submitElectricalWorksRequest({
      'name': _nameController.text,
      'phone': _phoneController.text,
      'project_address': _selectedDistrict,
      'work_type': _workType,
      'property_type': _propertyType,
      'load_requirement': _loadRequirement,
      'area_size': _areaController.text,
      'budget_range': _budget,
      'timeline': _timeline,
      'needs_wiring': _needsWiring,
      'needs_switch_board': _needsSwitchBoard,
      'needs_fan_installation': _needsFanInstallation,
      'needs_light_installation': _needsLightInstallation,
      'needs_ac_points': _needsACPoints,
      'needs_stabilizer': _needsStabilizer,
      'needs_earthing': _needsEarthing,
      'needs_mcb': _needsMCB,
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
          "Your electrical work request has been submitted successfully. Our team will contact you shortly.",
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
    _additionalController.dispose();
    super.dispose();
  }
}