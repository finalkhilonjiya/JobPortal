import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class PlumbingForm extends StatefulWidget {
  const PlumbingForm({Key? key}) : super(key: key);

  @override
  State<PlumbingForm> createState() => _PlumbingFormState();
}

class _PlumbingFormState extends State<PlumbingForm> {
  final _formKey = GlobalKey<FormState>();
  
  // Form Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _additionalDetailsController = TextEditingController();
  
  // Dropdown Values
  String _selectedServiceType = 'New Installation';
  String _selectedPropertyType = 'Residential';
  String _selectedUrgency = 'Within 1 Week';
  String _selectedBudgetRange = '5,000 - 15,000';
  String _selectedBathroomCount = '1 Bathroom';
  
  // Checkbox Values - Plumbing Services
  bool _needsPipeInstallation = false;
  bool _needsWaterTankWork = false;
  bool _needsBathroomFitting = false;
  bool _needsKitchenPlumbing = false;
  bool _needsSewerageWork = false;
  bool _needsWaterHeaterInstallation = false;
  bool _needsLeakageRepair = false;
  bool _needsDrainageCleaning = false;
  
  // Checkbox Values - Fixtures
  bool _needsToiletInstallation = false;
  bool _needsBasinInstallation = false;
  bool _needsTapFittings = false;
  bool _needsShowerInstallation = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Plumbing Services - Get Quote'),
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
              
              _buildSectionHeader('Plumbing Work Details'),
              _buildWorkDetailsSection(),
              SizedBox(height: 4.w),
              
              _buildSectionHeader('Services Required'),
              _buildServicesSection(),
              SizedBox(height: 4.w),
              
              _buildSectionHeader('Fixtures & Fittings'),
              _buildFixturesSection(),
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
          colors: [Color(0xFFFFF8E1), Color(0xFFFFCC02)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.plumbing, size: 6.w, color: Colors.orange[800]),
              SizedBox(width: 3.w),
              Text(
                'Complete Plumbing Solutions',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.w),
          Text(
            'Professional plumbing installation & repair services:',
            style: TextStyle(fontSize: 12.sp),
          ),
          SizedBox(height: 2.w),
          ...[
            '• Water supply line installation',
            '• Bathroom & kitchen plumbing',
            '• Sewerage & drainage work',
            '• Water heater installation',
            '• Leak detection & repair',
            '• Pipe fitting & maintenance',
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
          _buildTextFormField(_emailController, 'Email Address', Icons.email, keyboardType: TextInputType.emailAddress, required: false),
          SizedBox(height: 3.w),
          _buildTextFormField(_addressController, 'Service Address *', Icons.location_on, maxLines: 2),
        ],
      ),
    );
  }

  Widget _buildWorkDetailsSection() {
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
            'Service Type',
            _selectedServiceType,
            ['New Installation', 'Repair/Maintenance', 'Emergency Repair', 'Renovation/Upgrade', 'Complete Overhaul'],
            (value) => setState(() => _selectedServiceType = value!),
          ),
          SizedBox(height: 3.w),
          _buildDropdownField(
            'Property Type',
            _selectedPropertyType,
            ['Residential', 'Commercial', 'Industrial', 'Office Building'],
            (value) => setState(() => _selectedPropertyType = value!),
          ),
          SizedBox(height: 3.w),
          _buildDropdownField(
            'Number of Bathrooms',
            _selectedBathroomCount,
            ['1 Bathroom', '2 Bathrooms', '3 Bathrooms', '4+ Bathrooms', 'Commercial Toilets'],
            (value) => setState(() => _selectedBathroomCount = value!),
          ),
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
          _buildCheckboxTile('Water Supply Pipe Installation', _needsPipeInstallation, (value) => setState(() => _needsPipeInstallation = value!)),
          _buildCheckboxTile('Water Tank Installation/Repair', _needsWaterTankWork, (value) => setState(() => _needsWaterTankWork = value!)),
          _buildCheckboxTile('Bathroom Plumbing Work', _needsBathroomFitting, (value) => setState(() => _needsBathroomFitting = value!)),
          _buildCheckboxTile('Kitchen Plumbing', _needsKitchenPlumbing, (value) => setState(() => _needsKitchenPlumbing = value!)),
          _buildCheckboxTile('Sewerage & Drainage Work', _needsSewerageWork, (value) => setState(() => _needsSewerageWork = value!)),
          _buildCheckboxTile('Water Heater Installation', _needsWaterHeaterInstallation, (value) => setState(() => _needsWaterHeaterInstallation = value!)),
          _buildCheckboxTile('Leak Detection & Repair', _needsLeakageRepair, (value) => setState(() => _needsLeakageRepair = value!)),
          _buildCheckboxTile('Drainage Cleaning/Unclogging', _needsDrainageCleaning, (value) => setState(() => _needsDrainageCleaning = value!)),
        ],
      ),
    );
  }

  Widget _buildFixturesSection() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          _buildCheckboxTile('Toilet Installation', _needsToiletInstallation, (value) => setState(() => _needsToiletInstallation = value!)),
          _buildCheckboxTile('Wash Basin Installation', _needsBasinInstallation, (value) => setState(() => _needsBasinInstallation = value!)),
          _buildCheckboxTile('Tap/Faucet Fittings', _needsTapFittings, (value) => setState(() => _needsTapFittings = value!)),
          _buildCheckboxTile('Shower Installation', _needsShowerInstallation, (value) => setState(() => _needsShowerInstallation = value!)),
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
            'Budget Range',
            _selectedBudgetRange,
            ['2,000 - 5,000', '5,000 - 15,000', '15,000 - 30,000', '30,000 - 50,000', '50,000+', 'Will Discuss'],
            (value) => setState(() => _selectedBudgetRange = value!),
          ),
          SizedBox(height: 3.w),
          _buildDropdownField(
            'Service Timeline',
            _selectedUrgency,
            ['Emergency (Same Day)', 'Within 2 Days', 'Within 1 Week', 'Within 2 Weeks', 'Flexible'],
            (value) => setState(() => _selectedUrgency = value!),
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
        'Describe the plumbing issue or specific requirements', 
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
      height: 12.h,
      child: ElevatedButton(
        onPressed: _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF2563EB),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
        child: Text(
          'Submit Request for Quote',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      Map<String, dynamic> formData = {
        'service_type': 'Plumbing',
        'name': _nameController.text,
        'phone': _phoneController.text,
        'email': _emailController.text.isEmpty ? null : _emailController.text,
        'project_address': _addressController.text,
        'service_type_detail': _selectedServiceType,
        'property_type': _selectedPropertyType,
        'bathroom_count': _selectedBathroomCount,
        'budget_range': _selectedBudgetRange,
        'timeline': _selectedUrgency,
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
        'additional_details': _additionalDetailsController.text,
        'created_at': DateTime.now().toIso8601String(),
        'status': 'pending',
      };

      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Request Submitted!'),
        content: Text('Your plumbing service request has been submitted successfully. Our plumbing experts will contact you within 24 hours.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
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
    _emailController.dispose();
    _addressController.dispose();
    _additionalDetailsController.dispose();
    super.dispose();
  }
}