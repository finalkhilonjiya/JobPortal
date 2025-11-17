// File: lib/presentation/home_marketplace_feed/job_application_form.dart
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../services/jobs_service.dart';

class JobApplicationForm extends StatefulWidget {
  const JobApplicationForm({Key? key}) : super(key: key);

  @override
  State<JobApplicationForm> createState() => _JobApplicationFormState();
}

class _JobApplicationFormState extends State<JobApplicationForm> {
  final _formKey = GlobalKey<FormState>();
  final JobsService _jobsService = JobsService();
  
  // Form Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _experienceController = TextEditingController();
  final _skillsController = TextEditingController();
  final _expectedSalaryController = TextEditingController();
  final _additionalInfoController = TextEditingController();
  
  // Dropdown Values
  String _selectedDistrict = 'Kamrup Metropolitan';
  String _selectedGender = 'Male';
  String _selectedEducation = 'Graduate';
  String _selectedExperience = '0-1 Years';
  String _selectedAvailability = 'Immediate';
  DateTime? _selectedDOB;
  
  // Job Categories
  List<String> _selectedJobCategories = [];
  
  // Files
  File? _resumeFile;
  String? _resumeFileName;
  File? _photoFile;
  String? _photoFileName;

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
  final Map<String, List<String>> jobCategories = {
    'Administrative & Office': [
      'Office Assistant', 'Receptionist', 'Data Entry Operator', 'Secretary', 
      'Administrative Assistant', 'Document Controller', 'Office Manager'
    ],
    'Sales & Marketing': [
      'Sales Executive', 'Marketing Executive', 'Sales Representative', 
      'Digital Marketing Executive', 'Business Development Executive', 'Sales Manager'
    ],
    'Customer Service': [
      'Customer Care Executive', 'Call Center Executive', 'Customer Support', 
      'Help Desk Executive', 'Telecaller', 'Customer Relationship Manager'
    ],
    'Hospitality & Food Service': [
      'Waiter/Waitress', 'Chef', 'Cook', 'Kitchen Helper', 'Bartender', 
      'Hotel Receptionist', 'Housekeeping Staff', 'Restaurant Manager'
    ],
    'Security & Safety': [
      'Security Guard', 'Security Supervisor', 'Watchman', 'Security Officer', 
      'Safety Officer', 'Bouncer', 'CCTV Operator'
    ],
    'Transportation & Delivery': [
      'Driver (Car)', 'Driver (Two Wheeler)', 'Driver (Heavy Vehicle)', 
      'Delivery Boy', 'Courier Executive', 'Logistics Executive'
    ],
    'Healthcare': [
      'Nurse', 'Medical Assistant', 'Pharmacist Assistant', 'Health Worker', 
      'Physiotherapy Assistant', 'Lab Technician', 'Ward Boy/Girl'
    ],
    'Education & Training': [
      'Teacher', 'Tutor', 'Training Executive', 'Education Counselor', 
      'Academic Coordinator', 'Subject Matter Expert'
    ],
    'Technical & IT': [
      'Computer Operator', 'IT Support Executive', 'Software Developer', 
      'Web Designer', 'Network Administrator', 'Technical Support'
    ],
    'Retail & Store': [
      'Store Keeper', 'Cashier', 'Shop Assistant', 'Store Manager', 
      'Inventory Executive', 'Billing Executive', 'Floor Manager'
    ],
    'Construction & Maintenance': [
      'Construction Worker', 'Electrician', 'Plumber', 'Carpenter', 
      'Maintenance Technician', 'Supervisor', 'Site Engineer'
    ],
    'Manufacturing & Production': [
      'Production Worker', 'Quality Control Executive', 'Machine Operator', 
      'Assembly Line Worker', 'Warehouse Executive', 'Production Supervisor'
    ],
    'Banking & Finance': [
      'Bank Clerk', 'Cashier', 'Loan Officer', 'Insurance Agent', 
      'Investment Advisor', 'Accounts Executive', 'Collection Executive'
    ],
    'Media & Creative': [
      'Graphic Designer', 'Content Writer', 'Video Editor', 'Photographer', 
      'Social Media Executive', 'Creative Designer', 'Copywriter'
    ],
    'General Labor': [
      'Helper', 'Cleaner', 'Peon', 'Gardener', 'Loader', 'Packer', 
      'General Worker', 'Maintenance Staff'
    ]
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Apply for Jobs'),
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
              
              _buildSectionHeader('Personal Information'),
              _buildPersonalInfoSection(),
              SizedBox(height: 4.w),
              
              _buildSectionHeader('Education & Experience'),
              _buildEducationSection(),
              SizedBox(height: 4.w),
              
              _buildSectionHeader('Job Preferences'),
              _buildJobPreferencesSection(),
              SizedBox(height: 4.w),
              
              _buildSectionHeader('Documents'),
              _buildDocumentsSection(),
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
          'assets/images/applyforjobsform.jpg',
          width: double.infinity,
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
                      Icon(Icons.work, size: 6.w, color: Colors.white),
                      SizedBox(width: 3.w),
                      Text(
                        'Job Application Form',
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
                    'Fill out this comprehensive form to apply for multiple job positions. You can select multiple job categories.',
                    style: TextStyle(fontSize: 12.sp, color: Colors.white70),
                  ),
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
          _buildTextFormField(_emailController, 'Email Address *', Icons.email, keyboardType: TextInputType.emailAddress),
          SizedBox(height: 3.w),
          _buildDropdownField(
            'District *',
            _selectedDistrict,
            assamDistricts,
            (value) => setState(() => _selectedDistrict = value!),
          ),
          SizedBox(height: 3.w),
          _buildTextFormField(_addressController, 'Full Address *', Icons.location_on, maxLines: 2),
          SizedBox(height: 3.w),
          Row(
            children: [
              Expanded(
                child: _buildDropdownField(
                  'Gender *',
                  _selectedGender,
                  ['Male', 'Female', 'Other'],
                  (value) => setState(() => _selectedGender = value!),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 3.5.w),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: Color(0xFF2563EB)),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Text(
                            _selectedDOB == null 
                                ? 'Date of Birth *' 
                                : '${_selectedDOB!.day}/${_selectedDOB!.month}/${_selectedDOB!.year}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: _selectedDOB == null ? Colors.grey : Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEducationSection() {
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
            'Highest Education *',
            _selectedEducation,
            ['10th Pass', '12th Pass', 'Diploma', 'Graduate', 'Post Graduate', 'Professional Degree', 'PhD', 'Other'],
            (value) => setState(() => _selectedEducation = value!),
          ),
          SizedBox(height: 3.w),
          _buildDropdownField(
            'Work Experience *',
            _selectedExperience,
            ['Fresher', '0-1 Years', '1-3 Years', '3-5 Years', '5-10 Years', '10+ Years'],
            (value) => setState(() => _selectedExperience = value!),
          ),
          SizedBox(height: 3.w),
          _buildTextFormField(
            _experienceController, 
            'Previous Work Experience Details', 
            Icons.work_history, 
            maxLines: 3,
            required: false,
          ),
          SizedBox(height: 3.w),
          _buildTextFormField(
            _skillsController, 
            'Key Skills & Qualifications *', 
            Icons.star, 
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildJobPreferencesSection() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Job Categories (Multiple selection allowed) *',
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 2.w),
          Container(
            height: 35.h,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              child: Column(
                children: jobCategories.entries.map((category) => 
                  ExpansionTile(
                    title: Text(
                      category.key,
                      style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500),
                    ),
                    children: category.value.map((job) => 
                      CheckboxListTile(
                        title: Text(job, style: TextStyle(fontSize: 11.sp)),
                        value: _selectedJobCategories.contains(job),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedJobCategories.add(job);
                            } else {
                              _selectedJobCategories.remove(job);
                            }
                          });
                        },
                        activeColor: Color(0xFF2563EB),
                        dense: true,
                      ),
                    ).toList(),
                  ),
                ).toList(),
              ),
            ),
          ),
          SizedBox(height: 3.w),
          _buildTextFormField(
            _expectedSalaryController, 
            'Expected Salary (per month)', 
            Icons.currency_rupee, 
            keyboardType: TextInputType.number,
            required: false,
          ),
          SizedBox(height: 3.w),
          _buildDropdownField(
            'Availability to Join *',
            _selectedAvailability,
            ['Immediate', 'Within 1 Week', 'Within 2 Weeks', 'Within 1 Month', 'After 1 Month'],
            (value) => setState(() => _selectedAvailability = value!),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
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
                  _resumeFileName ?? 'Upload Resume (PDF only) *',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: _resumeFileName != null ? Colors.green : Colors.grey,
                  ),
                ),
                SizedBox(height: 2.w),
                ElevatedButton(
                  onPressed: _pickResumeFile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Choose File'),
                ),
              ],
            ),
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
                Icon(Icons.photo_camera, size: 8.w, color: Color(0xFF2563EB)),
                SizedBox(height: 2.w),
                Text(
                  _photoFileName ?? 'Upload Photo (JPG/PNG only) *',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: _photoFileName != null ? Colors.green : Colors.grey,
                  ),
                ),
                SizedBox(height: 2.w),
                ElevatedButton(
                  onPressed: _pickPhotoFile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Choose Photo'),
                ),
              ],
            ),
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
        _additionalInfoController, 
        'Additional Information or Special Requirements', 
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
        onPressed: _submitApplication,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF2563EB),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
        child: Text(
          'Submit Job Application',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(Duration(days: 6570)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(Duration(days: 6570)),
    );
    if (picked != null && picked != _selectedDOB) {
      setState(() {
        _selectedDOB = picked;
      });
    }
  }

  Future<void> _pickResumeFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        _resumeFile = File(result.files.single.path!);
        _resumeFileName = result.files.single.name;
      });
    }
  }

  Future<void> _pickPhotoFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
    );

    if (result != null) {
      setState(() {
        _photoFile = File(result.files.single.path!);
        _photoFileName = result.files.single.name;
      });
    }
  }

  void _submitApplication() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDOB == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select your date of birth')),
        );
        return;
      }
      
      if (_selectedJobCategories.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select at least one job category')),
        );
        return;
      }
      
      if (_resumeFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please upload your resume')),
        );
        return;
      }
      
      if (_photoFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please upload your photo')),
        );
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      Map<String, dynamic> applicationData = {
        'name': _nameController.text,
        'phone': _phoneController.text,
        'email': _emailController.text,
        'district': _selectedDistrict,
        'address': _addressController.text,
        'gender': _selectedGender,
        'date_of_birth': _selectedDOB!.toIso8601String().split('T')[0],
        'education': _selectedEducation,
        'experience_level': _selectedExperience,
        'experience_details': _experienceController.text,
        'skills': _skillsController.text,
        'job_categories': _selectedJobCategories,
        'expected_salary': _expectedSalaryController.text,
        'availability': _selectedAvailability,
        'additional_info': _additionalInfoController.text,
        'resume_file_name': _resumeFileName,
        'photo_file_name': _photoFileName,
        'status': 'submitted',
      };

      try {
        await _jobsService.submitJobApplication(applicationData, _resumeFile, _photoFile);
        Navigator.pop(context);
        _showSuccessDialog();
      } catch (e) {
        Navigator.pop(context);
        _showErrorDialog('Failed to submit application: ${e.toString()}');
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Application Submitted!'),
        content: Text('Your job application has been submitted successfully. We will review your application and contact you soon.'),
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
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _experienceController.dispose();
    _skillsController.dispose();
    _expectedSalaryController.dispose();
    _additionalInfoController.dispose();
    super.dispose();
  }
}
