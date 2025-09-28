import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/construction_service.dart';

class FalseCeilingForm extends StatefulWidget {
  const FalseCeilingForm({Key? key}) : super(key: key);

  @override
  State<FalseCeilingForm> createState() => _FalseCeilingFormState();
}

class _FalseCeilingFormState extends State<FalseCeilingForm> {
  final _formKey = GlobalKey<FormState>();

  // Form Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _areaController = TextEditingController();
  final _roomHeightController = TextEditingController();
  final _additionalDetailsController = TextEditingController();

  // Dropdown Values
  String _selectedDistrict = 'Kamrup Metropolitan';
  String _selectedCeilingType = 'POP (Plaster of Paris)';
  String _selectedRoomType = 'Living Room';
  String _selectedDesignComplexity = 'Simple/Plain';
  String _selectedLightingType = 'LED Lights';
  String _selectedTimeframe = 'Within 2 Weeks';
  String _selectedBudgetRange = '15,000 - 30,000';

  // Checkbox Values
  bool _needsLightingWork = false;
  bool _needsFanPoints = false;
  bool _needsACDucting = false;
  bool _needsPainting = false;
  bool _needsDesign = false;
  bool _hasExistingCeiling = false;
  bool _needsElectricalWork = false;
  bool _needsMaintenance = false;

  // Assam Districts List
  final List<String> assamDistricts = [
    'Baksa', 'Barpeta', 'Biswanath', 'Bongaigaon', 'Cachar', 'Charaideo',
    'Chirang', 'Darrang', 'Dhemaji', 'Dhubri', 'Dibrugarh', 'Dima Hasao',
    'Goalpara', 'Golaghat', 'Hailakandi', 'Hojai', 'Jorhat', 'Kamrup',
    'Kamrup Metropolitan', 'Karbi Anglong', 'Karimganj', 'Kokrajhar',
    'Lakhimpur', 'Majuli', 'Morigaon', 'Nagaon', 'Nalbari', 'Sivasagar',
    'Sonitpur', 'South Salmara-Mankachar', 'Tinsukia', 'Udalguri',
    'West Karbi Anglong'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('False Ceiling - Get Quote'),
        backgroundColor: Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildServiceDescriptionCard(),
              SizedBox(height: 4.w),

              _buildSectionHeader('Personal Information'),
              _buildPersonalInfoSection(),
              SizedBox(height: 4.w),

              _buildSectionHeader('False Ceiling Specifications'),
              _buildSpecsSection(),
              SizedBox(height: 4.w),

              _buildSectionHeader('Additional Services'),
              _buildServicesSection(),
              SizedBox(height: 4.w),

              _buildSectionHeader('Budget & Timeline'),
              _buildBudgetTimelineSection(),
              SizedBox(height: 4.w),

              _buildSectionHeader('Additional Information'),
              _buildAdditionalInfoSection(),
              SizedBox(height: 6.w),

              _buildSubmitButton(),
              SizedBox(height: 4.w),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceDescriptionCard() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF3E5F5), Color(0xFFCE93D8)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.architecture, size: 6.w, color: Colors.purple[700]),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  'False Ceiling Services',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[700],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.w),
          Text(
            'Professional false ceiling installation & design:',
            style: TextStyle(fontSize: 12.sp),
          ),
          SizedBox(height: 2.w),
          ...[
            '• POP, Gypsum, PVC ceiling work',
            '• Custom lighting integration',
            '• AC duct concealment',
            '• Decorative designs & patterns',
            '• Fan mounting & electrical work',
            '• Maintenance & repair services',
          ].map((service) => Padding(
            padding: EdgeInsets.only(left: 3.w, bottom: 1.w),
            child: Text(service, style: TextStyle(fontSize: 11.sp)),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 3.w),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          _buildTextFormField(_nameController, 'Full Name *', Icons.person),
          SizedBox(height: 3.w),
          _buildTextFormField(_phoneController, 'Phone Number *', Icons.phone, keyboardType: TextInputType.phone),
          SizedBox(height: 3.w),
          _buildDropdownField(
            'District *',
            _selectedDistrict,
            assamDistricts,
            (value) => setState(() => _selectedDistrict = value!),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecsSection() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          _buildDropdownField(
            'Ceiling Material Type',
            _selectedCeilingType,
            ['POP (Plaster of Paris)', 'Gypsum Board', 'PVC Panels', 'Wooden Panels', 'Metal Ceiling', 'Fiber Cement'],
            (value) => setState(() => _selectedCeilingType = value!),
          ),
          SizedBox(height: 3.w),
          _buildDropdownField(
            'Room Type',
            _selectedRoomType,
            ['Living Room', 'Bedroom', 'Kitchen', 'Bathroom', 'Office', 'Shop/Commercial', 'Hall/Reception', 'Dining Room'],
            (value) => setState(() => _selectedRoomType = value!),
          ),
          SizedBox(height: 3.w),
          _buildDropdownField(
            'Design Complexity',
            _selectedDesignComplexity,
            ['Simple/Plain', 'Step/Tray Ceiling', 'Cove Lighting', 'Decorative Patterns', 'Custom Design', 'Curved/Artistic'],
            (value) => setState(() => _selectedDesignComplexity = value!),
          ),
          SizedBox(height: 3.w),
          _buildDropdownField(
            'Lighting Type',
            _selectedLightingType,
            ['LED Lights', 'Tube Lights', 'Cove Lighting', 'Spot Lights', 'Chandelier Points', 'No Lighting', 'Mixed Lighting'],
            (value) => setState(() => _selectedLightingType = value!),
          ),
          SizedBox(height: 3.w),
          _buildTextFormField(_areaController, 'Room Area (sq ft) *', Icons.straighten, keyboardType: TextInputType.number),
          SizedBox(height: 3.w),
          _buildTextFormField(_roomHeightController, 'Current Room Height (ft)', Icons.height, keyboardType: TextInputType.number, required: false),
        ],
      ),
    );
  }

  Widget _buildServicesSection() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          _buildCheckboxTile('Lighting Installation', _needsLightingWork, (value) => setState(() => _needsLightingWork = value!)),
          _buildCheckboxTile('Fan Mounting Points', _needsFanPoints, (value) => setState(() => _needsFanPoints = value!)),
          _buildCheckboxTile('AC Duct Concealment', _needsACDucting, (value) => setState(() => _needsACDucting = value!)),
          _buildCheckboxTile('Painting/Finishing Work', _needsPainting, (value) => setState(() => _needsPainting = value!)),
          _buildCheckboxTile('Custom Design Service', _needsDesign, (value) => setState(() => _needsDesign = value!)),
          _buildCheckboxTile('Electrical Work Required', _needsElectricalWork, (value) => setState(() => _needsElectricalWork = value!)),
          _buildCheckboxTile('Existing False Ceiling (Repair/Modify)', _hasExistingCeiling, (value) => setState(() => _hasExistingCeiling = value!)),
          _buildCheckboxTile('Maintenance Service Required', _needsMaintenance, (value) => setState(() => _needsMaintenance = value!)),
        ],
      ),
    );
  }

  Widget _buildBudgetTimelineSection() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          _buildDropdownField(
            'Budget Range (per sq ft)',
            _selectedBudgetRange,
            ['10,000 - 15,000', '15,000 - 30,000', '30,000 - 50,000', '50,000 - 1,00,000', '1,00,000+', 'Will Discuss'],
            (value) => setState(() => _selectedBudgetRange = value!),
          ),
          SizedBox(height: 3.w),
          _buildDropdownField(
            'When do you want to start?',
            _selectedTimeframe,
            ['Immediately', 'Within 1 Week', 'Within 2 Weeks', 'Within 1 Month', 'Flexible'],
            (value) => setState(() => _selectedTimeframe = value!),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoSection() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: _buildTextFormField(
        _additionalDetailsController, 
        'Specific Design Requirements or Additional Details', 
        Icons.notes, 
        maxLines: 4,
        required: false,
      ),
    );
  }

  Widget _buildTextFormField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool required = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: required ? (value) => value?.isEmpty ?? true ? 'This field is required' : null : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Color(0xFF2563EB)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color(0xFF2563EB), width: 2),
        ),
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    String value,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color(0xFF2563EB), width: 2),
        ),
      ),
      items: options.map((option) => DropdownMenuItem(value: option, child: Text(option))).toList(),
    );
  }

  Widget _buildCheckboxTile(String title, bool value, Function(bool?) onChanged) {
    return CheckboxListTile(
      title: Text(title, style: TextStyle(fontSize: 12.sp)),
      value: value,
      onChanged: onChanged,
      activeColor: Color(0xFF2563EB),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 7.h,
      child: ElevatedButton(
        onPressed: _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF2563EB),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
        child: Text(
          'Request for Quote',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      Map<String, dynamic> formData = {
        'service_type': 'False Ceiling',
        'name': _nameController.text,
        'phone': _phoneController.text,
        'project_address': _selectedDistrict,
        'ceiling_type': _selectedCeilingType,
        'room_type': _selectedRoomType,
        'design_complexity': _selectedDesignComplexity,
        'lighting_type': _selectedLightingType,
        'area_size': _areaController.text,
        'room_height': _roomHeightController.text,
        'budget_range': _selectedBudgetRange,
        'timeline': _selectedTimeframe,
        'needs_lighting_work': _needsLightingWork,
        'needs_fan_points': _needsFanPoints,
        'needs_ac_ducting': _needsACDucting,
        'needs_painting': _needsPainting,
        'needs_design': _needsDesign,
        'needs_electrical_work': _needsElectricalWork,
        'has_existing_ceiling': _hasExistingCeiling,
        'needs_maintenance': _needsMaintenance,
        'additional_details': _additionalDetailsController.text,
        'status': 'pending',
      };

      try {
        await ConstructionService().submitFalseCeilingRequest(formData);
        Navigator.pop(context); // Close loading
        _showSuccessDialog();
      } catch (e) {
        Navigator.pop(context); // Close loading
        _showErrorDialog('Failed to submit request: ${e.toString()}');
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Request Submitted!'),
        content: Text('Your false ceiling request has been submitted successfully. Our design team will contact you within 24 hours.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to construction services
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _areaController.dispose();
    _roomHeightController.dispose();
    _additionalDetailsController.dispose();
    super.dispose();
  }
}