import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/construction_service.dart';

class ElectricalWorksForm extends StatefulWidget {
  const ElectricalWorksForm({Key? key}) : super(key: key);

  @override
  State<ElectricalWorksForm> createState() => _ElectricalWorksFormState();
}

class _ElectricalWorksFormState extends State<ElectricalWorksForm> {
  final _formKey = GlobalKey<FormState>();

  // Form Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _areaController = TextEditingController();
  final _additionalDetailsController = TextEditingController();

  // Dropdown Values
  String _selectedDistrict = 'Kamrup Metropolitan';
  String _selectedWorkType = 'New Installation';
  String _selectedPropertyType = 'Residential';
  String _selectedLoadRequirement = '5 KW';
  String _selectedTimeframe = 'Within 1 Week';
  String _selectedBudgetRange = '10,000 - 25,000';

  // Checkbox Values
  bool _needsWiring = false;
  bool _needsSwitchBoard = false;
  bool _needsFanInstallation = false;
  bool _needsLightInstallation = false;
  bool _needsACPoints = false;
  bool _needsStabilizer = false;
  bool _needsEarthing = false;
  bool _needsMCB = false;

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
        title: Text('Electrical Works - Get Quote'),
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
              _buildSectionHeader('Electrical Work Details'),
              _buildProjectDetailsSection(),
              SizedBox(height: 4.w),

              // Services Required Section
              _buildSectionHeader('Services Required'),
              _buildServicesSection(),
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
    width: double.infinity, // Maintains full width alignment
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
    child: AspectRatio(
      aspectRatio: 1280 / 1063, // Exact ratio of your image (1280 x 1063)
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          'assets/images/electricalbanner.jpg',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to gradient container if image not found
            return Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE3F2FD), Color(0xFF90CAF9)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.electrical_services, size: 6.w, color: Colors.blue[700]),
                      SizedBox(width: 3.w),
                      Text(
                        'Electrical Works Services',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.w),
                  Text(
                    'Professional electrical installation and maintenance services:',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                  SizedBox(height: 2.w),
                  ...[
                    '• Complete home/office wiring',
                    '• Switch board installation',
                    '• Fan & light installation', 
                    '• AC point installation',
                    '• MCB & earthing work',
                    '• Electrical maintenance & repair',
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
            'Type of Work',
            _selectedWorkType,
            ['New Installation', 'Repair/Maintenance', 'Upgrade/Extension', 'Complete Rewiring'],
            (value) => setState(() => _selectedWorkType = value!),
          ),
          SizedBox(height: 3.w),
          _buildDropdownField(
            'Property Type',
            _selectedPropertyType,
            ['Residential', 'Commercial', 'Industrial', 'Office'],
            (value) => setState(() => _selectedPropertyType = value!),
          ),
          SizedBox(height: 3.w),
          _buildDropdownField(
            'Load Requirement',
            _selectedLoadRequirement,
            ['2 KW', '5 KW', '10 KW', '15 KW', '20 KW+', 'Not Sure'],
            (value) => setState(() => _selectedLoadRequirement = value!),
          ),
          SizedBox(height: 3.w),
          _buildTextFormField(_areaController, 'Area Size (sq ft)', Icons.straighten, keyboardType: TextInputType.number, required: false),
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
          _buildCheckboxTile('Wiring Work', _needsWiring, (value) => setState(() => _needsWiring = value!)),
          _buildCheckboxTile('Switch Board Installation', _needsSwitchBoard, (value) => setState(() => _needsSwitchBoard = value!)),
          _buildCheckboxTile('Fan Installation', _needsFanInstallation, (value) => setState(() => _needsFanInstallation = value!)),
          _buildCheckboxTile('Light Installation', _needsLightInstallation, (value) => setState(() => _needsLightInstallation = value!)),
          _buildCheckboxTile('AC Points', _needsACPoints, (value) => setState(() => _needsACPoints = value!)),
          _buildCheckboxTile('Stabilizer Installation', _needsStabilizer, (value) => setState(() => _needsStabilizer = value!)),
          _buildCheckboxTile('Earthing Work', _needsEarthing, (value) => setState(() => _needsEarthing = value!)),
          _buildCheckboxTile('MCB Installation', _needsMCB, (value) => setState(() => _needsMCB = value!)),
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
            ['5,000 - 10,000', '10,000 - 25,000', '25,000 - 50,000', '50,000 - 1,00,000', '1,00,000+', 'Will Discuss'],
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
        'service_type': 'Electrical Works',
        'name': _nameController.text,
        'phone': _phoneController.text,
        'project_address': _selectedDistrict,
        'work_type': _selectedWorkType,
        'property_type': _selectedPropertyType,
        'load_requirement': _selectedLoadRequirement,
        'area_size': _areaController.text,
        'budget_range': _selectedBudgetRange,
        'timeline': _selectedTimeframe,
        'needs_wiring': _needsWiring,
        'needs_switch_board': _needsSwitchBoard,
        'needs_fan_installation': _needsFanInstallation,
        'needs_light_installation': _needsLightInstallation,
        'needs_ac_points': _needsACPoints,
        'needs_stabilizer': _needsStabilizer,
        'needs_earthing': _needsEarthing,
        'needs_mcb': _needsMCB,
        'additional_details': _additionalDetailsController.text,
        'status': 'pending',
      };

      try {
        await ConstructionService().submitElectricalWorksRequest(formData);
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
        content: Text('Your electrical works request has been submitted successfully. Our team will contact you within 24 hours.'),
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
    _additionalDetailsController.dispose();
    super.dispose();
  }
}
