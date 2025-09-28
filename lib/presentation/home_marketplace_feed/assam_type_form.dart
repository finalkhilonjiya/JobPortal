import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/construction_service.dart';

class AssamTypeForm extends StatefulWidget {
  const AssamTypeForm({Key? key}) : super(key: key);

  @override
  State<AssamTypeForm> createState() => _AssamTypeFormState();
}

class _AssamTypeFormState extends State<AssamTypeForm> {
  final _formKey = GlobalKey<FormState>();

  // Form Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _plotSizeController = TextEditingController();
  final _additionalDetailsController = TextEditingController();

  // Dropdown Values
  String _selectedDistrict = 'Kamrup Metropolitan';
  String _selectedHouseType = 'Traditional Assam House';
  String _selectedFloors = 'Single Story';
  String _selectedRoofType = 'Tin Roof';
  String _selectedFoundationType = 'Pillar Foundation';
  String _selectedTimeframe = 'Within 3 Months';
  String _selectedBudgetRange = '10-20 Lakhs';

  // Checkbox Values
  bool _needsDesign = false;
  bool _needsMaterialSupply = false;
  bool _needsTraditionalCarpentry = false;
  bool _needsModernAmenities = false;
  bool _needsElectricalWork = false;
  bool _needsPlumbingWork = false;
  bool _hasLandReady = false;
  bool _needsPermits = false;

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
        title: Text('Assam Type House - Get Quote'),
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

              _buildSectionHeader('House Specifications'),
              _buildHouseSpecsSection(),
              SizedBox(height: 4.w),

              _buildSectionHeader('Services Required'),
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
          colors: [Color(0xFFFFF3E0), Color(0xFFFFCC02)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.home, size: 6.w, color: Colors.orange[800]),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  'Traditional Assam Type House',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.w),
          Text(
            'Authentic Assamese architecture with modern comfort:',
            style: TextStyle(fontSize: 12.sp),
          ),
          SizedBox(height: 2.w),
          ...[
            '• Traditional wooden structure',
            '• Raised foundation with pillars',
            '• Sloped tin or tile roofing',
            '• Spacious verandas (dol)',
            '• Natural ventilation design',
            '• Modern amenities integration',
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

  Widget _buildHouseSpecsSection() {
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
            'House Type',
            _selectedHouseType,
            ['Traditional Assam House', 'Modern Assam Style', 'Heritage Style', 'Contemporary Fusion'],
            (value) => setState(() => _selectedHouseType = value!),
          ),
          SizedBox(height: 3.w),
          _buildDropdownField(
            'Number of Stories',
            _selectedFloors,
            ['Single Story', 'Double Story', 'Ground + First Floor'],
            (value) => setState(() => _selectedFloors = value!),
          ),
          SizedBox(height: 3.w),
          _buildDropdownField(
            'Roof Type',
            _selectedRoofType,
            ['Tin Roof', 'Tile Roof', 'Concrete Slab', 'Mixed (Tin + Concrete)'],
            (value) => setState(() => _selectedRoofType = value!),
          ),
          SizedBox(height: 3.w),
          _buildDropdownField(
            'Foundation Type',
            _selectedFoundationType,
            ['Pillar Foundation', 'Combined Foundation', 'Concrete Foundation', 'Traditional Wooden Posts'],
            (value) => setState(() => _selectedFoundationType = value!),
          ),
          SizedBox(height: 3.w),
          _buildTextFormField(_plotSizeController, 'Plot Size (sq ft)', Icons.straighten, keyboardType: TextInputType.number),
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
          _buildCheckboxTile('Architectural Design & Planning', _needsDesign, (value) => setState(() => _needsDesign = value!)),
          _buildCheckboxTile('Material Supply (Wood, Tin, etc.)', _needsMaterialSupply, (value) => setState(() => _needsMaterialSupply = value!)),
          _buildCheckboxTile('Traditional Carpentry Work', _needsTraditionalCarpentry, (value) => setState(() => _needsTraditionalCarpentry = value!)),
          _buildCheckboxTile('Modern Amenities Integration', _needsModernAmenities, (value) => setState(() => _needsModernAmenities = value!)),
          _buildCheckboxTile('Electrical Work', _needsElectricalWork, (value) => setState(() => _needsElectricalWork = value!)),
          _buildCheckboxTile('Plumbing Work', _needsPlumbingWork, (value) => setState(() => _needsPlumbingWork = value!)),
          _buildCheckboxTile('Land is ready for construction', _hasLandReady, (value) => setState(() => _hasLandReady = value!)),
          _buildCheckboxTile('Need help with permits/approvals', _needsPermits, (value) => setState(() => _needsPermits = value!)),
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
            ['5-10 Lakhs', '10-20 Lakhs', '20-35 Lakhs', '35-50 Lakhs', '50 Lakhs+', 'Will Discuss'],
            (value) => setState(() => _selectedBudgetRange = value!),
          ),
          SizedBox(height: 3.w),
          _buildDropdownField(
            'When do you want to start?',
            _selectedTimeframe,
            ['Immediately', 'Within 1 Month', 'Within 3 Months', '3-6 Months', 'Just Planning'],
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
        'Special Requirements or Traditional Features Needed', 
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
        'service_type': 'Assam Type',
        'name': _nameController.text,
        'phone': _phoneController.text,
        'project_address': _selectedDistrict,
        'house_type': _selectedHouseType,
        'number_of_floors': _selectedFloors,
        'roof_type': _selectedRoofType,
        'foundation_type': _selectedFoundationType,
        'plot_size': _plotSizeController.text,
        'budget_range': _selectedBudgetRange,
        'timeline': _selectedTimeframe,
        'needs_design': _needsDesign,
        'needs_material_supply': _needsMaterialSupply,
        'needs_traditional_carpentry': _needsTraditionalCarpentry,
        'needs_modern_amenities': _needsModernAmenities,
        'needs_electrical_work': _needsElectricalWork,
        'needs_plumbing_work': _needsPlumbingWork,
        'has_land_ready': _hasLandReady,
        'needs_permits': _needsPermits,
        'additional_details': _additionalDetailsController.text,
        'status': 'pending',
      };

      try {
        await ConstructionService().submitAssamTypeRequest(formData);
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
        content: Text('Your Assam Type house request has been submitted successfully. Our traditional construction experts will contact you within 24 hours.'),
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
    _addressController.dispose();
    _plotSizeController.dispose();
    _additionalDetailsController.dispose();
    super.dispose();
  }
}