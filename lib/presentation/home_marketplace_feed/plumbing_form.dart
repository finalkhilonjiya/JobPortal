import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/construction_service.dart';

class PlumbingForm extends StatefulWidget {
  const PlumbingForm({Key? key}) : super(key: key);

  @override
  State<PlumbingForm> createState() => _PlumbingFormState();
}

class _PlumbingFormState extends State<PlumbingForm> {
  final _formKey = GlobalKey<FormState>();
  final SupabaseClient _db = Supabase.instance.client;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _additionalController = TextEditingController();

  List<String> _districts = [];
  String? _selectedDistrict;

  String _serviceType = 'New Installation';
  String _propertyType = 'Residential';
  String _bathroomCount = '1 Bathroom';
  String _budget = '5,000 - 15,000';
  String _timeline = 'Within 1 Week';

  bool _needsPipeInstallation = false;
  bool _needsWaterTankWork = false;
  bool _needsBathroomFitting = false;
  bool _needsKitchenPlumbing = false;
  bool _needsSewerageWork = false;
  bool _needsWaterHeaterInstallation = false;
  bool _needsLeakageRepair = false;
  bool _needsDrainageCleaning = false;

  bool _needsToiletInstallation = false;
  bool _needsBasinInstallation = false;
  bool _needsTapFittings = false;
  bool _needsShowerInstallation = false;

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
        title: const Text('Plumbing Services'),
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
                    _section("Work Details", _workDetails()),
                    _section("Services Required", _services()),
                    _section("Fixtures & Fittings", _fixtures()),
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
          "Professional Plumbing Solutions",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13.sp,
            color: const Color(0xFF0F172A),
          ),
        ),
        SizedBox(height: 1.5.h),
        const Text("• Pipe installation & leakage repair"),
        const Text("• Bathroom & kitchen plumbing"),
        const Text("• Drainage, sewerage & water heater work"),
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
              style: TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13.sp)),
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

  Widget _workDetails() {
    return Column(
      children: [
        _dropdown("Service Type", _serviceType,
            ['New Installation','Repair/Maintenance','Emergency Repair','Renovation'],
            (v) => setState(() => _serviceType = v!)),
        SizedBox(height: 3.w),
        _dropdown("Property Type", _propertyType,
            ['Residential','Commercial','Industrial','Office'],
            (v) => setState(() => _propertyType = v!)),
        SizedBox(height: 3.w),
        _dropdown("Number of Bathrooms", _bathroomCount,
            ['1 Bathroom','2 Bathrooms','3 Bathrooms','4+ Bathrooms','Commercial'],
            (v) => setState(() => _bathroomCount = v!)),
      ],
    );
  }

  Widget _services() {
    return Column(
      children: [
        _check("Pipe Installation", _needsPipeInstallation,
            (v) => setState(() => _needsPipeInstallation = v!)),
        _check("Water Tank Work", _needsWaterTankWork,
            (v) => setState(() => _needsWaterTankWork = v!)),
        _check("Bathroom Plumbing", _needsBathroomFitting,
            (v) => setState(() => _needsBathroomFitting = v!)),
        _check("Kitchen Plumbing", _needsKitchenPlumbing,
            (v) => setState(() => _needsKitchenPlumbing = v!)),
        _check("Sewerage Work", _needsSewerageWork,
            (v) => setState(() => _needsSewerageWork = v!)),
        _check("Water Heater Installation", _needsWaterHeaterInstallation,
            (v) => setState(() => _needsWaterHeaterInstallation = v!)),
        _check("Leakage Repair", _needsLeakageRepair,
            (v) => setState(() => _needsLeakageRepair = v!)),
        _check("Drainage Cleaning", _needsDrainageCleaning,
            (v) => setState(() => _needsDrainageCleaning = v!)),
      ],
    );
  }

  Widget _fixtures() {
    return Column(
      children: [
        _check("Toilet Installation", _needsToiletInstallation,
            (v) => setState(() => _needsToiletInstallation = v!)),
        _check("Basin Installation", _needsBasinInstallation,
            (v) => setState(() => _needsBasinInstallation = v!)),
        _check("Tap Fittings", _needsTapFittings,
            (v) => setState(() => _needsTapFittings = v!)),
        _check("Shower Installation", _needsShowerInstallation,
            (v) => setState(() => _needsShowerInstallation = v!)),
      ],
    );
  }

  Widget _budgetTimeline() {
    return Column(
      children: [
        _dropdown("Budget Range", _budget,
            ['2,000 - 5,000','5,000 - 15,000','15,000 - 30,000','30,000+'],
            (v) => setState(() => _budget = v!)),
        SizedBox(height: 3.w),
        _dropdown("Start Timeline", _timeline,
            ['Emergency','Within 2 Days','Within 1 Week','Flexible'],
            (v) => setState(() => _timeline = v!)),
      ],
    );
  }

  Widget _additional() {
    return _input(_additionalController,
        "Describe the plumbing issue",
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
    await ConstructionService().submitPlumbingRequest({
      'name': _nameController.text,
      'phone': _phoneController.text,
      'project_address': _selectedDistrict,
      'service_type_detail': _serviceType,
      'property_type': _propertyType,
      'bathroom_count': _bathroomCount,
      'budget_range': _budget,
      'timeline': _timeline,
      'needs_pipe_installation': _needsPipeInstallation,
      'needs_water_tank_work': _needsWaterTankWork,
      'needs_bathroom_fitting': _needsBathroomFitting,
      'needs_kitchen_plumbing': _needsKitchenPlumbing,
      'needs_sewerage_work': _needsSewerageWork,
      'needs_water_heater_installation': _needsWaterHeaterInstallation,
      'needs_leakage_repair': _needsLeakageRepair,
      'needs_drainage_cleaning': _needsDrainageCleaning,
      'needs_toilet_installation': _needsToiletInstallation,
      'needs_basin_installation': _needsBasinInstallation,
      'needs_tap_fittings': _needsTapFittings,
      'needs_shower_installation': _needsShowerInstallation,
      'additional_details': _additionalController.text,
    });

    if (!mounted) return;

    setState(() => _loading = false);

    // ✅ Show success dialog
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text("Request Submitted"),
        content: const Text(
          "Your plumbing request has been submitted successfully. Our team will contact you shortly.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );

    // After user presses OK
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
    _additionalController.dispose();
    super.dispose();
  }
}