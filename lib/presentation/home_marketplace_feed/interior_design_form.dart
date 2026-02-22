import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/construction_service.dart';

class InteriorDesignForm extends StatefulWidget {
  const InteriorDesignForm({Key? key}) : super(key: key);

  @override
  State<InteriorDesignForm> createState() => _InteriorDesignFormState();
}

class _InteriorDesignFormState extends State<InteriorDesignForm> {
  final _formKey = GlobalKey<FormState>();
  final SupabaseClient _db = Supabase.instance.client;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _areaController = TextEditingController();
  final _additionalController = TextEditingController();

  List<String> _districts = [];
  String? _selectedDistrict;

  String _projectType = 'Complete Interior';
  String _propertyType = 'Residential Apartment';
  String _designStyle = 'Modern Contemporary';
  String _roomCount = '2 BHK';
  String _budget = '2-5 Lakhs';
  String _timeline = '2-3 Months';

  bool _needsLivingRoom = false;
  bool _needsBedroom = false;
  bool _needsKitchen = false;
  bool _needsBathroom = false;
  bool _needsDining = false;
  bool _needsStudy = false;
  bool _needsKidsRoom = false;
  bool _needsBalcony = false;

  bool _needsFurniture = false;
  bool _needsLighting = false;
  bool _needsColorConsultation = false;
  bool _needsSpacePlanning = false;
  bool _needs3D = false;
  bool _needsImplementation = false;

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
        title: const Text('Interior Design'),
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
                    _section("Project Details", _projectDetails()),
                    _section("Rooms to Design", _rooms()),
                    _section("Design Services", _services()),
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
          "Professional Interior Design Solutions",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13.sp,
            color: const Color(0xFF0F172A),
          ),
        ),
        SizedBox(height: 1.5.h),
        const Text("• Space planning & layout optimization"),
        const Text("• Custom furniture & lighting design"),
        const Text("• 3D visualization & project execution"),
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

  Widget _projectDetails() {
    return Column(
      children: [
        _dropdown("Project Type", _projectType,
            ['Complete Interior','Partial Interior','Single Room','Renovation'],
            (v) => setState(() => _projectType = v!)),
        SizedBox(height: 3.w),
        _dropdown("Property Type", _propertyType,
            ['Residential Apartment','Independent House','Villa','Office','Commercial'],
            (v) => setState(() => _propertyType = v!)),
        SizedBox(height: 3.w),
        _dropdown("Design Style", _designStyle,
            ['Modern','Traditional','Minimalist','Industrial','Scandinavian','Fusion'],
            (v) => setState(() => _designStyle = v!)),
        SizedBox(height: 3.w),
        _dropdown("Property Configuration", _roomCount,
            ['1 BHK','2 BHK','3 BHK','4+ BHK','Studio','Duplex'],
            (v) => setState(() => _roomCount = v!)),
        SizedBox(height: 3.w),
        _input(_areaController, "Total Area (sq ft)",
            keyboardType: TextInputType.number,
            required: false),
      ],
    );
  }

  Widget _rooms() {
    return Column(
      children: [
        _check("Living Room", _needsLivingRoom,
            (v) => setState(() => _needsLivingRoom = v!)),
        _check("Bedroom", _needsBedroom,
            (v) => setState(() => _needsBedroom = v!)),
        _check("Kitchen", _needsKitchen,
            (v) => setState(() => _needsKitchen = v!)),
        _check("Bathroom", _needsBathroom,
            (v) => setState(() => _needsBathroom = v!)),
        _check("Dining Room", _needsDining,
            (v) => setState(() => _needsDining = v!)),
        _check("Study/Home Office", _needsStudy,
            (v) => setState(() => _needsStudy = v!)),
        _check("Kids Room", _needsKidsRoom,
            (v) => setState(() => _needsKidsRoom = v!)),
        _check("Balcony/Terrace", _needsBalcony,
            (v) => setState(() => _needsBalcony = v!)),
      ],
    );
  }

  Widget _services() {
    return Column(
      children: [
        _check("Custom Furniture Design", _needsFurniture,
            (v) => setState(() => _needsFurniture = v!)),
        _check("Lighting Design", _needsLighting,
            (v) => setState(() => _needsLighting = v!)),
        _check("Color Consultation", _needsColorConsultation,
            (v) => setState(() => _needsColorConsultation = v!)),
        _check("Space Planning", _needsSpacePlanning,
            (v) => setState(() => _needsSpacePlanning = v!)),
        _check("3D Visualization", _needs3D,
            (v) => setState(() => _needs3D = v!)),
        _check("Full Implementation", _needsImplementation,
            (v) => setState(() => _needsImplementation = v!)),
      ],
    );
  }

  Widget _budgetTimeline() {
    return Column(
      children: [
        _dropdown("Budget Range", _budget,
            ['1-2 Lakhs','2-5 Lakhs','5-10 Lakhs','10-20 Lakhs','20+ Lakhs'],
            (v) => setState(() => _budget = v!)),
        SizedBox(height: 3.w),
        _dropdown("Start Timeline", _timeline,
            ['Immediately','1 Month','2-3 Months','3-6 Months','Planning Stage'],
            (v) => setState(() => _timeline = v!)),
      ],
    );
  }

  Widget _additional() {
    return _input(_additionalController,
        "Design preferences or requirements",
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
    await ConstructionService().submitInteriorDesignRequest({
      'name': _nameController.text,
      'phone': _phoneController.text,
      'project_address': _selectedDistrict,
      'project_type': _projectType,
      'property_type': _propertyType,
      'design_style': _designStyle,
      'room_count': _roomCount,
      'area_size': _areaController.text,
      'budget_range': _budget,
      'timeline': _timeline,
      'needs_living_room_design': _needsLivingRoom,
      'needs_bedroom_design': _needsBedroom,
      'needs_kitchen_design': _needsKitchen,
      'needs_bathroom_design': _needsBathroom,
      'needs_dining_room_design': _needsDining,
      'needs_study_room_design': _needsStudy,
      'needs_kids_room_design': _needsKidsRoom,
      'needs_balcony_design': _needsBalcony,
      'needs_furniture_design': _needsFurniture,
      'needs_lighting_design': _needsLighting,
      'needs_color_consultation': _needsColorConsultation,
      'needs_space_planning': _needsSpacePlanning,
      'needs_3d_visualization': _needs3D,
      'needs_implementation': _needsImplementation,
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
          "Your interior design request has been submitted successfully. Our team will contact you shortly.",
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