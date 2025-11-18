// File: lib/presentation/home_marketplace_feed/job_listing_form.dart
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../services/jobs_service.dart';

class JobListingForm extends StatefulWidget {
  const JobListingForm({Key? key}) : super(key: key);

  @override
  State<JobListingForm> createState() => _JobListingFormState();
}

class _JobListingFormState extends State<JobListingForm> {
  final _formKey = GlobalKey<FormState>();
  final JobsService _jobsService = JobsService();
  
  // Form Controllers
  final _companyNameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _jobDescriptionController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _salaryMinController = TextEditingController();
  final _salaryMaxController = TextEditingController();
  final _benefitsController = TextEditingController();
  final _addressController = TextEditingController();
  final _additionalInfoController = TextEditingController();
  
  // Dropdown Values
  String _selectedDistrict = 'Kamrup Metropolitan';
  String _selectedJobCategory = 'Administrative & Office';
  String _selectedJobType = 'Full Time';
  String _selectedExperienceRequired = 'Fresher';
  String _selectedEducationRequired = '10th Pass';
  String _selectedUrgency = 'Normal Hiring';
  String _selectedEmploymentType = 'Permanent';
  
  // File upload
  File? _jobDescriptionFile;
  String? _jobDescriptionFileName;

  // Assam Districts
  final List<String> assamDistricts = [
    'Baksa', 'Barpeta', 'Biswanath', 'Bongaigaon', 'Cachar', 'Charaideo',
    'Chirang', 'Darrang', 'Dhemaji', 'Dhubri', 'Dibrugarh', 'Dima Hasao',
    'Goalpara', 'Golaghat', 'Hailakandi', 'Hojai', 'Jorhat', 'Kamrup',
    'Kamrup Metropolitan', 'Karbi Anglong', 'Karimganj', 'Kokrajhar',
    'Lakhimpur', 'Majuli', 'Morigaon', 'Nagaon', 'Nalbari', 'Sivasagar',
    'Sonitpur', 'South Salmara-Mankachar', 'Tinsukia', 'Udalguri',
    'West Karbi Anglong'
  ];

  // Job Categories
  final List<String> jobCategories = [
    'Administrative & Office',
    'Sales & Marketing',
    'Customer Service',
    'Hospitality & Food Service',
    'Security & Safety',
    'Transportation & Delivery',
    'Healthcare',
    'Education & Training',
    'Technical & IT',
    'Retail & Store',
    'Construction & Maintenance',
    'Manufacturing & Production',
    'Banking & Finance',
    'Media & Creative',
    'General Labor'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Post a Job'),
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
              _buildWelcomeBanner(),
              SizedBox(height: 4.w),
              
              _buildSectionHeader('Company Information'),
              _buildCompanyInfoSection(),
              SizedBox(height: 4.w),
              
              _buildSectionHeader('Job Details'),
              _buildJobDetailsSection(),
              SizedBox(height: 4.w),
              
              _buildSectionHeader('Requirements & Qualifications'),
              _buildRequirementsSection(),
              SizedBox(height: 4.w),
              
              _buildSectionHeader('Salary & Benefits'),
              _buildSalaryBenefitsSection(),
              SizedBox(height: 4.w),
              
              _buildSectionHeader('Job Location'),
              _buildLocationSection(),
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
Widget _buildWelcomeBanner() {
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
      aspectRatio: 1280 / 444, // Exact ratio of your image (1280 x 444)
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          'assets/images/listjobsform.jpg',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to gradient container if image not found
            return Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.post_add, size: 6.w, color: Colors.white),
                      SizedBox(width: 3.w),
                      Text(
                        'Job Listing Form',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.w),
                  Text(
                    'Post your job opening and find the right candidates. Fill out all details to attract qualified applicants.',
                    style: TextStyle(fontSize: 12.sp, color: Colors.white70),
                  ),
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

  Widget _buildCompanyInfoSection() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          _buildTextFormField(_companyNameController, 'Company/Organization Name *', Icons.business),
          SizedBox(height: 3.w),
          _buildTextFormField(_contactPersonController, 'Contact Person Name *', Icons.person),
          SizedBox(height: 3.w),
          _buildTextFormField(_phoneController, 'Contact Phone Number *', Icons.phone, keyboardType: TextInputType.phone),
          SizedBox(height: 3.w),
          _buildTextFormField(_emailController, 'Contact Email Address *', Icons.email, keyboardType: TextInputType.emailAddress),
        ],
      ),
    );
  }

  Widget _buildJobDetailsSection() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          _buildTextFormField(_jobTitleController, 'Job Title/Position *', Icons.work),
          SizedBox(height: 3.w),
          _buildDropdownField(
            'Job Category *',
            _selectedJobCategory,
            jobCategories,
            (value) => setState(() => _selectedJobCategory = value!),
          ),
          SizedBox(height: 3.w),
          Row(
            children: [
              Expanded(
                child: _buildDropdownField(
                  'Job Type *',
                  _selectedJobType,
                  ['Full Time', 'Part Time', 'Contract', 'Temporary', 'Internship'],
                  (value) => setState(() => _selectedJobType = value!),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildDropdownField(
                  'Employment Type *',
                  _selectedEmploymentType,
                  ['Permanent', 'Temporary', 'Contract', 'Freelance', 'Probation'],
                  (value) => setState(() => _selectedEmploymentType = value!),
                ),
              ),
            ],
          ),
          SizedBox(height: 3.w),
          _buildTextFormField(
            _jobDescriptionController, 
            'Job Description & Responsibilities *', 
            Icons.description, 
            maxLines: 5,
          ),
          SizedBox(height: 3.w),
          _buildDropdownField(
            'Hiring Urgency *',
            _selectedUrgency,
            ['Urgent (Within 1 Week)', 'Priority (Within 2 Weeks)', 'Normal Hiring', 'Flexible Timeline'],
            (value) => setState(() => _selectedUrgency = value!),
          ),
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
          _buildDropdownField(
            'Minimum Education Required *',
            _selectedEducationRequired,
            ['10th Pass', '12th Pass', 'Diploma', 'Graduate', 'Post Graduate', 'Professional Degree', 'PhD', 'Any'],
            (value) => setState(() => _selectedEducationRequired = value!),
          ),
          SizedBox(height: 3.w),
          _buildDropdownField(
            'Experience Required *',
            _selectedExperienceRequired,
            ['Fresher', '0-1 Years', '1-3 Years', '3-5 Years', '5-10 Years', '10+ Years', 'Any'],
            (value) => setState(() => _selectedExperienceRequired = value!),
          ),
          SizedBox(height: 3.w),
          _buildTextFormField(
            _requirementsController, 
            'Specific Skills & Requirements *', 
            Icons.checklist, 
            maxLines: 4,
          ),
          SizedBox(height: 3.w),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Icon(Icons.cloud_upload, size: 8.w, color: Color(0xFF2563EB)),
                SizedBox(height: 2.w),
                Text(
                  _jobDescriptionFileName ?? 'Upload Detailed Job Description (PDF - Optional)',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: _jobDescriptionFileName != null ? Colors.green : Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 2.w),
                ElevatedButton(
                  onPressed: _pickJobDescriptionFile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Choose File'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalaryBenefitsSection() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTextFormField(
                  _salaryMinController, 
                  'Minimum Salary (₹) *', 
                  Icons.currency_rupee, 
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildTextFormField(
                  _salaryMaxController, 
                  'Maximum Salary (₹) *', 
                  Icons.currency_rupee, 
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.w),
          _buildTextFormField(
            _benefitsController, 
            'Benefits & Perks', 
            Icons.card_giftcard, 
            maxLines: 3,
            required: false,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
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
            'District *',
            _selectedDistrict,
            assamDistricts,
            (value) => setState(() => _selectedDistrict = value!),
          ),
          SizedBox(height: 3.w),
          _buildTextFormField(_addressController, 'Complete Job Location Address *', Icons.location_on, maxLines: 2),
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
        _additionalInfoController, 
        'Additional Information or Special Instructions', 
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

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 7.h,
      child: ElevatedButton(
        onPressed: _submitJobListing,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF2563EB),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
        child: Text(
          'Post Job Listing',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Future<void> _pickJobDescriptionFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        _jobDescriptionFile = File(result.files.single.path!);
        _jobDescriptionFileName = result.files.single.name;
      });
    }
  }

  void _submitJobListing() async {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      Map<String, dynamic> jobListingData = {
        'company_name': _companyNameController.text,
        'contact_person': _contactPersonController.text,
        'phone': _phoneController.text,
        'email': _emailController.text,
        'job_title': _jobTitleController.text,
        'job_category': _selectedJobCategory,
        'job_type': _selectedJobType,
        'employment_type': _selectedEmploymentType,
        'job_description': _jobDescriptionController.text,
        'requirements': _requirementsController.text,
        'education_required': _selectedEducationRequired,
        'experience_required': _selectedExperienceRequired,
        'salary_min': int.parse(_salaryMinController.text),
        'salary_max': int.parse(_salaryMaxController.text),
        'benefits': _benefitsController.text,
        'district': _selectedDistrict,
        'job_address': _addressController.text,
        'hiring_urgency': _selectedUrgency,
        'additional_info': _additionalInfoController.text,
        'job_description_file': _jobDescriptionFileName,
        'status': 'active',
      };

      try {
        await _jobsService.submitJobListing(jobListingData, _jobDescriptionFile);
        Navigator.pop(context);
        _showSuccessDialog();
      } catch (e) {
        Navigator.pop(context);
        _showErrorDialog('Failed to post job listing: ${e.toString()}');
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Job Posted Successfully!'),
        content: Text('Your job listing has been posted successfully. Candidates can now view and apply for this position.'),
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
    _companyNameController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _jobTitleController.dispose();
    _jobDescriptionController.dispose();
    _requirementsController.dispose();
    _salaryMinController.dispose();
    _salaryMaxController.dispose();
    _benefitsController.dispose();
    _addressController.dispose();
    _additionalInfoController.dispose();
    super.dispose();
  }
}
