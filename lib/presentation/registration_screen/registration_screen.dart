import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController(); // Added for full name

  final _emailFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  final _fullNameFocusNode = FocusNode(); // Added for full name

  final _authService = AuthService();

  // State variables
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _acceptTerms = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupValidationListeners();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
    
    _fadeController.forward();
    _slideController.forward();
  }

  void _setupValidationListeners() {
    _emailController.addListener(_validateForm);
    _phoneController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
    _confirmPasswordController.addListener(_validateForm);
    _fullNameController.addListener(_validateForm);
  }

  void _validateForm() {
    setState(() {
      _errorMessage = '';
    });
  }

  bool _isFormValid() {
    return _emailController.text.trim().isNotEmpty &&
           _fullNameController.text.trim().isNotEmpty &&
           _phoneController.text.trim().isNotEmpty &&
           _passwordController.text.isNotEmpty &&
           _confirmPasswordController.text.isNotEmpty &&
           _passwordController.text == _confirmPasswordController.text &&
           _acceptTerms;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validateFullName(String? value) {
    if (value == null || value.isEmpty) return 'Full name is required';
    if (value.length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Phone number is required';
    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.length < 10) return 'Please enter a valid phone number';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _handleRegistration() async {
    if (!_isFormValid()) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final email = _emailController.text.trim();
      final fullName = _fullNameController.text.trim();
      final password = _passwordController.text;
      final phone = _phoneController.text.trim();

      debugPrint('📤 Attempting registration with email: $email');

      // Use email, full name, and phone for Supabase
      final response = await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );

      if (response.user != null) {
        // Upload profile image if selected
        // (Profile picture upload temporarily disabled)
        // if (_profileImage != null) {
        //   try {
        //     await UserProfileService().uploadProfilePicture(_profileImage!);
        //   } catch (e) {
        //     debugPrint('Profile picture upload failed: $e');
        //     // Continue registration even if profile picture upload fails
        //   }
        // }

        HapticFeedback.lightImpact();
        
        // Check if email verification is required
        if (response.session == null) {
          _showSuccessSnackBar('Registration successful! Please check your email to verify your account.');
        } else {
          _showSuccessSnackBar('Registration successful!');
        }
        
        if (mounted) {
          await Future.delayed(Duration(seconds: 2));
          Navigator.pushReplacementNamed(context, AppRoutes.loginScreen);
        }
      }
    } on AppAuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
      _showErrorSnackBar(e.message);
    } catch (error) {
      setState(() {
        _errorMessage = 'Registration failed. Please try again.';
      });
      debugPrint('❌ Registration error: $error');
      _showErrorSnackBar('Registration failed. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(4.w),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: Duration(milliseconds: 1500),
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(4.w),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: Duration(milliseconds: 1500),
        ),
      );
    }
  }

  // --- Added for build error fix: UI-only, no backend logic changed ---
  Widget _buildProfileImagePicker() {
    // Reuse the profile photo section for design
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            // This method is no longer used for image picking
          },
          child: Container(
            width: 25.w,
            height: 25.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[100],
              border: Border.all(
                color: Colors.grey[300]!,
                width: 2,
              ),
            ),
            child: Icon(
              Icons.add_a_photo,
              color: Colors.grey[400],
              size: 32,
            ),
          ),
        ),
        SizedBox(height: 1.h),
        GestureDetector(
          onTap: () {
            // This method is no longer used for image picking
          },
          child: Text(
            'Add Profile Photo',
            style: TextStyle(
              fontSize: 3.5.w,
              color: AppTheme.lightTheme.colorScheme.primary,
            ),
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          'Optional - helps build trust',
          style: TextStyle(
            fontSize: 3.w,
            color: Colors.grey[500],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Add a method to calculate password strength
  int _calculatePasswordStrength(String password) {
    int strength = 0;
    if (password.length >= 8) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[a-z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) strength++;
    return strength;
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildFullNameField(),
          SizedBox(height: 2.h),
          _buildEmailField(),
          SizedBox(height: 2.h),
          _buildPhoneField(),
          SizedBox(height: 2.h),
          _buildPasswordField(),
          PasswordStrengthIndicatorWidget(
            password: _passwordController.text,
            strength: _calculatePasswordStrength(_passwordController.text),
          ),
          SizedBox(height: 2.h),
          _buildConfirmPasswordField(),
        ],
      ),
    );
  }

  Widget _buildTermsAndConditions() {
    // Reuse the terms checkbox for design
    return Row(
      children: [
        Checkbox(
          value: _acceptTerms,
          onChanged: (value) => setState(() => _acceptTerms = value ?? false),
          activeColor: AppTheme.lightTheme.colorScheme.primary,
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _acceptTerms = !_acceptTerms),
            child: Text(
              'I agree to the Terms of Service and Privacy Policy',
              style: TextStyle(
                fontSize: 3.5.w,
                color: Colors.grey[700],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _fullNameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF10B981).withOpacity(0.08), Color(0xFF6366F1).withOpacity(0.04)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981),
                            fontFamily: 'Poppins',
                          ),
                        ),
                        SizedBox(height: 2.h),
                        _buildForm(),
                        SizedBox(height: 2.h),
                        _buildTermsAndConditions(),
                        SizedBox(height: 2.h),
                        _buildRegisterButton(),
                        if (_errorMessage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Text(
                              _errorMessage,
                              style: TextStyle(color: Colors.red, fontSize: 12.sp),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'Create Account',
          style: TextStyle(
            fontSize: 7.w,
            fontWeight: FontWeight.bold,
            color: AppTheme.lightTheme.colorScheme.primary,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'Join our marketplace community',
          style: TextStyle(
            fontSize: 4.w,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildFullNameField() {
    return TextFormField(
      controller: _fullNameController,
      focusNode: _fullNameFocusNode,
      keyboardType: TextInputType.name,
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: 'Full Name',
        hintText: 'Enter your full name',
        prefixIcon: Icon(Icons.person_outline),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.lightTheme.colorScheme.primary, width: 2),
        ),
      ),
      validator: _validateFullName,
      onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_emailFocusNode),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      focusNode: _emailFocusNode,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      decoration: InputDecoration(
        labelText: 'Email Address',
        hintText: 'Enter your email address',
        prefixIcon: Icon(Icons.email_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.lightTheme.colorScheme.primary, width: 2),
        ),
      ),
      validator: _validateEmail,
      onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_phoneFocusNode),
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      focusNode: _phoneFocusNode,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: 'Phone Number',
        hintText: 'Enter your phone number',
        prefixIcon: Icon(Icons.phone_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.lightTheme.colorScheme.primary, width: 2),
        ),
      ),
      validator: _validatePhone,
      onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_passwordFocusNode),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      focusNode: _passwordFocusNode,
      obscureText: !_isPasswordVisible,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: 'Enter your password',
        prefixIcon: Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.lightTheme.colorScheme.primary, width: 2),
        ),
      ),
      validator: _validatePassword,
      onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_confirmPasswordFocusNode),
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      focusNode: _confirmPasswordFocusNode,
      obscureText: !_isConfirmPasswordVisible,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: 'Confirm Password',
        hintText: 'Confirm your password',
        prefixIcon: Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(_isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.lightTheme.colorScheme.primary, width: 2),
        ),
      ),
      validator: _validateConfirmPassword,
      onFieldSubmitted: (_) {
        if (_isFormValid()) {
          _handleRegistration();
        }
      },
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _acceptTerms,
          onChanged: (value) => setState(() => _acceptTerms = value ?? false),
          activeColor: AppTheme.lightTheme.colorScheme.primary,
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _acceptTerms = !_acceptTerms),
            child: Text(
              'I agree to the Terms of Service and Privacy Policy',
              style: TextStyle(
                fontSize: 3.5.w,
                color: Colors.grey[700],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 20),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              _errorMessage,
              style: TextStyle(
                fontSize: 3.w,
                color: Colors.red[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isFormValid() && !_isLoading ? _handleRegistration : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF2563EB), // Blue
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
        child: _isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2.5,
                ),
              )
            : Text('Register', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: TextStyle(
            fontSize: 3.5.w,
            color: Colors.grey[600],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.loginScreen),
          child: Text(
            'Sign In',
            style: TextStyle(
              fontSize: 3.5.w,
              color: AppTheme.lightTheme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}