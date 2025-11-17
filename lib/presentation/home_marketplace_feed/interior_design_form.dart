import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/construction_service.dart';

class InteriorDesignForm extends StatefulWidget {
  const InteriorDesignForm({Key? key}) : super(key: key);

  @override
  State<InteriorDesignForm> createState() => _InteriorDesignFormState();
}

class _InteriorDesignFormState extends State<InteriorDesignForm> {
  final _formKey = GlobalKey<FormState>();

  // Form Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _areaSizeController = TextEditingController();
  final _additionalDetailsController = TextEditingController();

  // Dropdown Values
  String _selectedDistrict = 'Kamrup Metropolitan';
  String _selectedProjectType = 'Complete Interior';
  String _selectedPropertyType = 'Residential Apartment';
  String _selectedDesignStyle = 'Modern Contemporary';
  String _selectedRoomCount = '2 BHK';
  String _selectedTimeframe = '2-3 Months';
  String _selectedBudgetRange = '2-5 Lakhs';

  // Checkbox Values - Rooms
  bool _needsLivingRoomDesign = false;
  bool _needsBedroomDesign = false;
  bool _needsKitchenDesign = false;
  bool _needsBathroomDesign = false;
  bool _needsDiningRoomDesign = false;
  bool _needsStudyRoomDesign = false;
  bool _needsKidsRoomDesign = false;
  bool _needsBalconyDesign = false;

  // Checkbox Values - Services
  bool _needsFurnitureDesign = false;
  bool _needsLightingDesign = false;
  bool _needsColorConsultation = false;
  bool _needsSpacePlanning = false;
  bool _needs3DVisualization = false;
  bool _needsImplementation = false;

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
        title: Text('Interior Design - Get Quote'),
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
              _buildServiceDescriptionBanner(),
              SizedBox(height: 4.w),

              _buildSectionHeader('Personal Information'),
              _buildPersonalInfoSection(),
              SizedBox(height: 4.w),

              _buildSectionHeader('Project Details'),
              _buildProjectDetailsSection(),
              SizedBox(height: 4.w),

              _buildSectionHeader('Rooms to Design'),
              _buildRoomsSection(),
              SizedBox(height: 4.w),

              _buildSectionHeader('Design Services'),
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
          'assets/images/interior.jpg',
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to gradient container if image not found
            return Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFCE4EC), Color(0xFFF48FB1)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.design_services, size: 6.w, color: Colors.pink[700]),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Text(
                          'Custom Interior Design Solutions',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.pink[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.w),
                  Text(
                    'Transform your space with professional interior design:',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                  SizedBox(height: 2.w),
                  ...[
                    '• Complete space planning & design',
                    '• Custom furniture & decor',
                    '• Lighting design & consultation',
                    '• Color schemes & material selection',
                    '• 3D visualization & renderings',
                    '• Project management & implementation',
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
            ['Complete Interior', 'Partial Interior', 'Single Room', 'Renovation', 'Consultation Only'],
            (value) => setState(() => _selectedProjectType = value!),
          ),
          SizedBox(height: 3.w),
          _buildDropdownField(
            'Property Type',
            _selectedPropertyType,
            ['Residential Apartment', 'Independent House', 'Villa', 'Office Space', 'Commercial Shop', 'Restaurant/Cafe'],
            (value) => setState(() => _selectedPropertyType = value!),
          ),
          SizedBox(height: 3.w),
          _buildDropdownField(
            'Design Style Preference',
            _selectedDesignStyle,
            ['Modern Contemporary', 'Traditional/Classic', 'Minimalist', 'Industrial', 'Scandinavian', 'Bohemian', 'Art Deco', 'Mixed/Fusion'],
            (value) => setState(() => _selectedDesignStyle = value!),
          ),
          SizedBox(height: 3.w),
          _buildDropdownField(
            'Property Configuration',
            _selectedRoomCount,
            ['1 BHK', '2 BHK', '3 BHK', '4+ BHK', 'Studio Apartment', 'Duplex/Penthouse', 'Independent House'],
            (value) => setState(() => _selectedRoomCount = value!),
          ),
          SizedBox(height: 3.w),
          _buildTextFormField(_areaSizeController, 'Total Area (sq ft)', Icons.straighten, keyboardType: TextInputType.number, required: false),
        ],
      ),
    );
  }

  Widget _buildRoomsSection() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          _buildCheckboxTile('Living Room', _needsLivingRoomDesign, (value) => setState(() => _needsLivingRoomDesign = value!)),
          _buildCheckboxTile('Master Bedroom', _needsBedroomDesign, (value) => setState(() => _needsBedroomDesign = value!)),
          _buildCheckboxTile('Kitchen', _needsKitchenDesign, (value) => setState(() => _needsKitchenDesign = value!)),
          _buildCheckboxTile('Bathrooms', _needsBathroomDesign, (value) => setState(() => _needsBathroomDesign = value!)),
          _buildCheckboxTile('Dining Room', _needsDiningRoomDesign, (value) => setState(() => _needsDiningRoomDesign = value!)),
          _buildCheckboxTile('Study/Home Office', _needsStudyRoomDesign, (value) => setState(() => _needsStudyRoomDesign = value!)),
          _buildCheckboxTile('Kids Room', _needsKidsRoomDesign, (value) => setState(() => _needsKidsRoomDesign = value!)),
          _buildCheckboxTile('Balcony/Terrace', _needsBalconyDesign, (value) => setState(() => _needsBalconyDesign = value!)),
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
          _buildCheckboxTile('Custom Furniture Design', _needsFurnitureDesign, (value) => setState(() => _needsFurnitureDesign = value!)),
          _buildCheckboxTile('Lighting Design & Planning', _needsLightingDesign, (value) => setState(() => _needsLightingDesign = value!)),
          _buildCheckboxTile('Color & Material Consultation', _needsColorConsultation, (value) => setState(() => _needsColorConsultation = value!)),
          _buildCheckboxTile('Space Planning & Layout', _needsSpacePlanning, (value) => setState(() => _needsSpacePlanning = value!)),
          _buildCheckboxTile('3D Visualization & Renderings', _needs3DVisualization, (value) => setState(() => _needs3DVisualization = value!)),
          _buildCheckboxTile('Complete Implementation Management', _needsImplementation, (value) => setState(() => _needsImplementation = value!)),
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
            ['1-2 Lakhs', '2-5 Lakhs', '5-10 Lakhs', '10-20 Lakhs', '20-50 Lakhs', '50 Lakhs+', 'Will Discuss'],
            (value) => setState(() => _selectedBudgetRange = value!),
          ),
          SizedBox(height: 3.w),
          _buildDropdownField(
            'When do you want to start?',
            _selectedTimeframe,
            ['Immediately', '1 Month', '2-3 Months', '3-6 Months', '6-12 Months', 'Just Planning'],
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
        'Design preferences, style ideas, or specific requirements', 
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
        'service_type': 'Interior Design',
        'name': _nameController.text,
        'phone': _phoneController.text,
        'project_address': _selectedDistrict,
        'project_type': _selectedProjectType,
        'property_type': _selectedPropertyType,
        'design_style': _selectedDesignStyle,
        'room_count': _selectedRoomCount,
        'area_size': _areaSizeController.text,
        'budget_range': _selectedBudgetRange,
        'timeline': _selectedTimeframe,
        'needs_living_room_design': _needsLivingRoomDesign,
        'needs_bedroom_design': _needsBedroomDesign,
        'needs_kitchen_design': _needsKitchenDesign,
        'needs_bathroom_design': _needsBathroomDesign,
        'needs_dining_room_design': _needsDiningRoomDesign,
        'needs_study_room_design': _needsStudyRoomDesign,
        'needs_kids_room_design': _needsKidsRoomDesign,
        'needs_balcony_design': _needsBalconyDesign,
        'needs_furniture_design': _needsFurnitureDesign,
        'needs_lighting_design': _needsLightingDesign,
        'needs_color_consultation': _needsColorConsultation,
        'needs_space_planning': _needsSpacePlanning,
        'needs_3d_visualization': _needs3DVisualization,
        'needs_implementation': _needsImplementation,
        'additional_details': _additionalDetailsController.text,
        'status': 'pending',
      };

      try {
        await ConstructionService().submitInteriorDesignRequest(formData);
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
        content: Text('Your interior design request has been submitted successfully. Our design consultants will contact you within 24 hours to discuss your project.'),
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
    _areaSizeController.dispose();
    _additionalDetailsController.dispose();
    super.dispose();
  }
}
