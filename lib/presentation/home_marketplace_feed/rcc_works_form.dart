import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/construction_service.dart';

class RCCWorksForm extends StatefulWidget {
  const RCCWorksForm({Key? key}) : super(key: key);

  @override
  State<RCCWorksForm> createState() => _RCCWorksFormState();
}

class _RCCWorksFormState extends State<RCCWorksForm> {
  final _formKey = GlobalKey<FormState>();
  
  // Form Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _plotSizeController = TextEditingController();
  final _additionalDetailsController = TextEditingController();
  
  // Dropdown Values
  String _selectedDistrict = 'Kamrup Metropolitan';
  String _selectedProjectType = 'Residential Building';
  String _selectedFloors = '1 Floor (Ground)';
  String _selectedTimeframe = 'Within 1 Month';
  String _selectedBudgetRange = '5-10 Lakhs';
  
  // Checkbox Values
  bool _needsDesignPlanning = false;
  bool _needsMaterialSupply = false;
  bool _needsSoilTesting = false;
  bool _hasExistingPlans = false;
  bool _needsConstruction = false;
  bool _needsCompleteSolution = false;

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
        title: Text('RCC Works - Get Quote'),
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
              // Service Description Card
              _buildServiceDescriptionBanner(),
              SizedBox(height: 4.w),
              
              // Personal Information Section
              _buildSectionHeader('Personal Information'),
              _buildPersonalInfoSection(),
              SizedBox(height: 4.w),
              
              // Project Details Section
              _buildSectionHeader('Project Details'),
              _buildProjectDetailsSection(),
              SizedBox(height: 4.w),
              
              // Requirements Section
              _buildSectionHeader('Requirements & Services'),
              _buildRequirementsSection(),
              SizedBox(height: 4.w),
              
              // Budget & Timeline Section
              _buildSectionHeader('Budget & Timeline'),
              _buildBudgetTimelineSection(),
              SizedBox(height: 4.w),
              
              // Additional Information
              _buildSectionHeader('Additional Information'),
              _buildAdditionalInfoSection(),
              SizedBox(height: 6.w),
              
              // Submit Button
              _buildSubmitButton(),
              SizedBox(height: 4.w),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceDescriptionBanner() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          'assets/images/rccbanner.jpg',
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to gradient container if image not found
            return Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE8F5E8), Color(0xFFC8E6C9)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.construction, size: 6.w, color: Colors.green[700]),
                      SizedBox(width: 3.w),
                      Text(
                        'RCC Works Services',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.w),
                  Text(
                    'We provide comprehensive RCC (Reinforced Cement Concrete) construction services including:',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                  SizedBox(height: 2.w),
                  ...[
                    '• Foundation work & footing',
                    '• Column construction',
                    '• Beam & slab work',
                    '• Staircase construction',
                    '• Retaining walls',
                    '• Quality concrete mixing & pouring',
                  ].map((service) => Padding(
                    padding: EdgeInsets.only(left: 3.w, bottom: 1.w),
                    child: Text(service, style: TextStyle(fontSize: 11.sp)),
                  )).toList(),
                ],
              ),
            );
          },
        ),
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

  Widget _buildProjectDetailsSection() {
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
            'Project Type',
            _selectedProjectType,
            ['Residential Building', 'Commercial Building', 'Industrial Structure', 'Renovation/Extension'],
            (value) => setState(() => _selectedProjectType = value!),
          ),
          SizedBox(height: 3.w),
          _buildDropdownField(
            'Number of Floors',
            _selectedFloors,
            ['1 Floor (Ground)', '2 Floors (Ground + 1)', '3 Floors (Ground + 2)', '4+ Floors', 'Basement + Floors'],
            (value) => setState(() => _selectedFloors = value!),
          ),
          SizedBox(height: 3.w),
          _buildTextFormField(_plotSizeController, 'Plot Size (sq ft)', Icons.straighten, keyboardType: TextInputType.number),
        ],
      ),
    );
  }

  Widget _buildRequirementsSection() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          _buildCheckboxTile('Complete Solution (Design + Construction)', _needsCompleteSolution, (value) => setState(() => _needsCompleteSolution = value!)),
          _buildCheckboxTile('Construction Work', _needsConstruction, (value) => setState(() => _needsConstruction = value!)),
          _buildCheckboxTile('Design & Planning Services', _needsDesignPlanning, (value) => setState(() => _needsDesignPlanning = value!)),
          _buildCheckboxTile('Material Supply', _needsMaterialSupply, (value) => setState(() => _needsMaterialSupply = value!)),
          _buildCheckboxTile('Soil Testing Required', _needsSoilTesting, (value) => setState(() => _needsSoilTesting = value!)),
          _buildCheckboxTile('I have existing architectural plans', _hasExistingPlans, (value) => setState(() => _hasExistingPlans = value!)),
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
            ['Below 5 Lakhs', '5-10 Lakhs', '10-20 Lakhs', '20-50 Lakhs', '50 Lakhs+', 'Will Discuss'],
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
        'Additional Details or Specific Requirements', 
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
        'service_type': 'RCC Works',
        'name': _nameController.text,
        'phone': _phoneController.text,
        'project_address': _selectedDistrict,
        'project_type': _selectedProjectType,
        'number_of_floors': _selectedFloors,
        'plot_size': _plotSizeController.text,
        'budget_range': _selectedBudgetRange,
        'timeframe': _selectedTimeframe,
        'needs_complete_solution': _needsCompleteSolution,
        'needs_construction': _needsConstruction,
        'needs_design_planning': _needsDesignPlanning,
        'needs_material_supply': _needsMaterialSupply,
        'needs_soil_testing': _needsSoilTesting,
        'has_existing_plans': _hasExistingPlans,
        'additional_details': _additionalDetailsController.text,
      };

      try {
        await ConstructionService().submitConstructionRequest(formData);
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
        content: Text('Your RCC works request has been submitted successfully. Our team will contact you within 24 hours.'),
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
    _plotSizeController.dispose();
    _additionalDetailsController.dispose();
    super.dispose();
  }
}import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/construction_service.dart';

class RCCWorksForm extends StatefulWidget {
  const RCCWorksForm({Key? key}) : super(key: key);

  @override
  State<RCCWorksForm> createState() => _RCCWorksFormState();
}

class _RCCWorksFormState extends State<RCCWorksForm> {
  final _formKey = GlobalKey<FormState>();
  
  // Form Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _plotSizeController = TextEditingController();
  final _additionalDetailsController = TextEditingController();
  
  // Dropdown Values
  String _selectedDistrict = 'Kamrup Metropolitan';
  String _selectedProjectType = 'Residential Building';
  String _selectedFloors = '1 Floor (Ground)';
  String _selectedTimeframe = 'Within 1 Month';
  String _selectedBudgetRange = '5-10 Lakhs';
  
  // Checkbox Values
  bool _needsDesignPlanning = false;
  bool _needsMaterialSupply = false;
  bool _needsSoilTesting = false;
  bool _hasExistingPlans = false;
  bool _needsConstruction = false;
  bool _needsCompleteSolution = false;

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
        title: Text('RCC Works - Get Quote'),
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
              // Service Description Card
              _buildServiceDescriptionBanner(),
              SizedBox(height: 4.w),
              
              // Personal Information Section
              _buildSectionHeader('Personal Information'),
              _buildPersonalInfoSection(),
              SizedBox(height: 4.w),
              
              // Project Details Section
              _buildSectionHeader('Project Details'),
              _buildProjectDetailsSection(),
              SizedBox(height: 4.w),
              
              // Requirements Section
              _buildSectionHeader('Requirements & Services'),
              _buildRequirementsSection(),
              SizedBox(height: 4.w),
              
              // Budget & Timeline Section
              _buildSectionHeader('Budget & Timeline'),
              _buildBudgetTimelineSection(),
              SizedBox(height: 4.w),
              
              // Additional Information
              _buildSectionHeader('Additional Information'),
              _buildAdditionalInfoSection(),
              SizedBox(height: 6.w),
              
              // Submit Button
              _buildSubmitButton(),
              SizedBox(height: 4.w),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceDescriptionBanner() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          'assets/images/rccbanner.jpg',
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to gradient container if image not found
            return Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE8F5E8), Color(0xFFC8E6C9)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.construction, size: 6.w, color: Colors.green[700]),
                      SizedBox(width: 3.w),
                      Text(
                        'RCC Works Services',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.w),
                  Text(
                    'We provide comprehensive RCC (Reinforced Cement Concrete) construction services including:',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                  SizedBox(height: 2.w),
                  ...[
                    '• Foundation work & footing',
                    '• Column construction',
                    '• Beam & slab work',
                    '• Staircase construction',
                    '• Retaining walls',
                    '• Quality concrete mixing & pouring',
                  ].map((service) => Padding(
                    padding: EdgeInsets.only(left: 3.w, bottom: 1.w),
                    child: Text(service, style: TextStyle(fontSize: 11.sp)),
                  )).toList(),
                ],
              ),
            );
          },
        ),
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

  Widget _buildProjectDetailsSection() {
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
            'Project Type',
            _selectedProjectType,
            ['Residential Building', 'Commercial Building', 'Industrial Structure', 'Renovation/Extension'],
            (value) => setState(() => _selectedProjectType = value!),
          ),
          SizedBox(height: 3.w),
          _buildDropdownField(
            'Number of Floors',
            _selectedFloors,
            ['1 Floor (Ground)', '2 Floors (Ground + 1)', '3 Floors (Ground + 2)', '4+ Floors', 'Basement + Floors'],
            (value) => setState(() => _selectedFloors = value!),
          ),
          SizedBox(height: 3.w),
          _buildTextFormField(_plotSizeController, 'Plot Size (sq ft)', Icons.straighten, keyboardType: TextInputType.number),
        ],
      ),
    );
  }

  Widget _buildRequirementsSection() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          _buildCheckboxTile('Complete Solution (Design + Construction)', _needsCompleteSolution, (value) => setState(() => _needsCompleteSolution = value!)),
          _buildCheckboxTile('Construction Work', _needsConstruction, (value) => setState(() => _needsConstruction = value!)),
          _buildCheckboxTile('Design & Planning Services', _needsDesignPlanning, (value) => setState(() => _needsDesignPlanning = value!)),
          _buildCheckboxTile('Material Supply', _needsMaterialSupply, (value) => setState(() => _needsMaterialSupply = value!)),
          _buildCheckboxTile('Soil Testing Required', _needsSoilTesting, (value) => setState(() => _needsSoilTesting = value!)),
          _buildCheckboxTile('I have existing architectural plans', _hasExistingPlans, (value) => setState(() => _hasExistingPlans = value!)),
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
            ['Below 5 Lakhs', '5-10 Lakhs', '10-20 Lakhs', '20-50 Lakhs', '50 Lakhs+', 'Will Discuss'],
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
        'Additional Details or Specific Requirements', 
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
        'service_type': 'RCC Works',
        'name': _nameController.text,
        'phone': _phoneController.text,
        'project_address': _selectedDistrict,
        'project_type': _selectedProjectType,
        'number_of_floors': _selectedFloors,
        'plot_size': _plotSizeController.text,
        'budget_range': _selectedBudgetRange,
        'timeframe': _selectedTimeframe,
        'needs_complete_solution': _needsCompleteSolution,
        'needs_construction': _needsConstruction,
        'needs_design_planning': _needsDesignPlanning,
        'needs_material_supply': _needsMaterialSupply,
        'needs_soil_testing': _needsSoilTesting,
        'has_existing_plans': _hasExistingPlans,
        'additional_details': _additionalDetailsController.text,
      };

      try {
        await ConstructionService().submitConstructionRequest(formData);
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
        content: Text('Your RCC works request has been submitted successfully. Our team will contact you within 24 hours.'),
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
    _plotSizeController.dispose();
    _additionalDetailsController.dispose();
    super.dispose();
  }
}
