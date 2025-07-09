import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:lottie/lottie.dart';

import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../utils/auth_service.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/otp_verification_widget.dart';
import './widgets/password_strength_indicator_widget.dart';
import './widgets/profile_photo_upload_widget.dart';
import './widgets/terms_privacy_widget.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  // Enhanced auth service with proper provider integration
  AuthService? _authService;

  // Enhanced state management
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLocationEnabled = false;
  bool _acceptTerms = false;
  bool _isEmailValid = false;
  bool _isPhoneValid = false;
  bool _isNameValid = false;
  bool _isPasswordValid = false;
  bool _isConfirmPasswordValid = false;
  bool _showOtpVerification = false;
  bool _isLoading = false;
  String _errorMessage = '';

  String _selectedContactMethod = 'email'; // 'email' or 'phone'
  int _currentStep = 1;
  final int _totalSteps = 3;

  // Enhanced password strength levels (0-5 for better granularity)
  int _passwordStrength = 0;

  // Profile photo
  String? _profilePhotoPath;

  // Animation controllers for enhanced UX
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    _initializeAuthService();
    _setupAnimations();
    _setupValidationListeners();
    _setupFocusListeners();
  }

  void _initializeAuthService() {
    // Get AuthService from Provider context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _authService = Provider.of<AuthService>(context, listen: false);
      }
    });
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
    
    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  void _setupFocusListeners() {
    // Enhanced focus listeners with haptic feedback
    _nameFocusNode.addListener(() {
      if (_nameFocusNode.hasFocus) {
        HapticFeedback.lightImpact();
      }
      setState(() {});
    });
    
    _emailFocusNode.addListener(() {
      if (_emailFocusNode.hasFocus) {
        HapticFeedback.lightImpact();
      }
      setState(() {});
    });
    
    _phoneFocusNode.addListener(() {
      if (_phoneFocusNode.hasFocus) {
        HapticFeedback.lightImpact();
      }
      setState(() {});
    });
    
    _passwordFocusNode.addListener(() {
      if (_passwordFocusNode.hasFocus) {
        HapticFeedback.lightImpact();
      }
      setState(() {});
    });
    
    _confirmPasswordFocusNode.addListener(() {
      if (_confirmPasswordFocusNode.hasFocus) {
        HapticFeedback.lightImpact();
      }
      setState(() {});
    });
  }

  void _setupValidationListeners() {
    // Enhanced name validation with real-time feedback
    _nameController.addListener(() {
      final name = _nameController.text.trim();
      setState(() {
        _isNameValid = name.length >= 2 && RegExp(r'^[a-zA-Z\s]+$').hasMatch(name);
      });
    });

    // Enhanced email validation
    _emailController.addListener(() {
      setState(() {
        _isEmailValid = _validateEmail(_emailController.text);
      });
    });

    // Enhanced phone validation with formatting
    _phoneController.addListener(() {
      final phone = _phoneController.text;
      setState(() {
        _isPhoneValid = _validatePhone(phone);
      });
      
      // Auto-format phone number
      _formatPhoneNumber();
    });

    // Enhanced password validation
    _passwordController.addListener(() {
      final password = _passwordController.text;
      setState(() {
        _passwordStrength = _calculatePasswordStrength(password);
        _isPasswordValid = _passwordStrength >= 3; // Require medium strength
        _isConfirmPasswordValid = _confirmPasswordController.text == password;
      });
    });

    // Enhanced confirm password validation
    _confirmPasswordController.addListener(() {
      setState(() {
        _isConfirmPasswordValid = _confirmPasswordController.text == _passwordController.text;
      });
    });
  }

  void _formatPhoneNumber() {
    String phone = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
    
    // Add +91 prefix for Indian numbers if not present
    if (phone.length == 10 && !phone.startsWith('91')) {
      phone = '91$phone';
    }
    
    // Format as +91 XXXXX XXXXX
    if (phone.length == 12 && phone.startsWith('91')) {
      final formatted = '+91 ${phone.substring(2, 7)} ${phone.substring(7)}';
      if (_phoneController.text != formatted) {
        _phoneController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    }
  }

  // Enhanced email validation with comprehensive patterns
  // Enhanced email validation with comprehensive patterns
  bool _validateEmail(String email) {
    if (email.isEmpty) return false;
    
    // Fixed comprehensive email regex
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$'
    );
    
    return emailRegex.hasMatch(email.trim()) && 
           email.length <= 254 && // RFC 5321 limit
           !email.contains('..') && // No consecutive dots
           !email.startsWith('.') && 
           !email.endsWith('.');
  }

  // Enhanced phone validation for Indian numbers
  bool _validatePhone(String phone) {
    if (phone.isEmpty) return false;
    
    // Remove all non-digit characters for validation
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // Indian phone validation patterns
    if (cleanPhone.length == 10) {
      // 10-digit Indian mobile: starts with 6,7,8,9
      return RegExp(r'^[6-9]\d{9}$').hasMatch(cleanPhone);
    } else if (cleanPhone.length == 12 && cleanPhone.startsWith('91')) {
      // 12-digit with country code: +91 followed by valid 10-digit mobile
      final mobileNumber = cleanPhone.substring(2);
      return RegExp(r'^[6-9]\d{9}$').hasMatch(mobileNumber);
    }
    
    return false;
  }

  // Enhanced password strength calculation (0-5 levels)
  int _calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0;
    
    int strength = 0;
    
    // Length criteria
    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;
    
    // Character type criteria
    if (password.contains(RegExp(r'[A-Z]'))) strength++; // Uppercase
    if (password.contains(RegExp(r'[a-z]'))) strength++; // Lowercase
    if (password.contains(RegExp(r'[0-9]'))) strength++; // Numbers
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++; // Special chars
    
    // Bonus for variety and length
    if (password.length >= 16 && strength >= 4) strength = 5;
    
    return strength > 5 ? 5 : strength;
  }

  // Enhanced form validation
  bool get _isFormValid {
    return _isNameValid &&
           (_selectedContactMethod == 'email' ? _isEmailValid : _isPhoneValid) &&
           _isPasswordValid &&
           _isConfirmPasswordValid &&
           _acceptTerms &&
           _errorMessage.isEmpty;
  }

  // Get password strength text and color
  String _getPasswordStrengthText() {
    switch (_passwordStrength) {
      case 0:
      case 1:
        return 'Very Weak';
      case 2:
        return 'Weak';
      case 3:
        return 'Medium';
      case 4:
        return 'Strong';
      case 5:
        return 'Very Strong';
      default:
        return 'Very Weak';
    }
  }

  Color _getPasswordStrengthColor() {
    switch (_passwordStrength) {
      case 0:
      case 1:
        return Colors.red.shade400;
      case 2:
        return Colors.orange.shade400;
      case 3:
        return Colors.yellow.shade600;
      case 4:
        return Colors.lightGreen.shade500;
      case 5:
        return Colors.green.shade600;
      default:
        return Colors.red.shade400;
    }
  }

  // Enhanced error message handling
  void _clearErrorMessage() {
    if (_errorMessage.isNotEmpty) {
      setState(() {
        _errorMessage = '';
      });
    }
  }

  // Validate individual fields with specific error messages
  String? _validateNameField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your full name';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
      return 'Name can only contain letters and spaces';
    }
    if (value.trim().length > 50) {
      return 'Name cannot exceed 50 characters';
    }
    return null;
  }

  String? _validateEmailField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email address';
    }
    if (!_validateEmail(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePhoneField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your phone number';
    }
    if (!_validatePhone(value)) {
      return 'Please enter a valid Indian mobile number';
    }
    return null;
  }

  String? _validatePasswordField(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (_passwordStrength < 3) {
      return 'Please create a stronger password';
    }
    return null;
  }

  String? _validateConfirmPasswordField(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }


void _onProfilePhotoSelected(String? photoPath) {
    setState(() {
      _profilePhotoPath = photoPath;
    });
    
    // Provide haptic feedback
    HapticFeedback.lightImpact();
    
    // Show success message if photo selected
    if (photoPath != null) {
      _showSuccessSnackBar('Profile photo uploaded successfully');
    }
  }

  void _showTermsBottomSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TermsPrivacyWidget(),
    );
  }

  void _toggleLocationServices() {
    setState(() {
      _isLocationEnabled = !_isLocationEnabled;
    });
    
    HapticFeedback.lightImpact();
    
    // Show informative message
    final message = _isLocationEnabled 
        ? 'Location services enabled - Find nearby listings!' 
        : 'Location services disabled';
    _showInfoSnackBar(message);
  }

  void _toggleContactMethod() {
    setState(() {
      _selectedContactMethod = _selectedContactMethod == 'email' ? 'phone' : 'email';
      // Clear the inactive field
      if (_selectedContactMethod == 'email') {
        _phoneController.clear();
      } else {
        _emailController.clear();
      }
      _clearErrorMessage();
    });
    
    HapticFeedback.lightImpact();
  }

  Future<void> _handleRegistration() async {
    // Clear any existing errors
    _clearErrorMessage();
    
    // Validate form
    if (!_formKey.currentState!.validate()) {
      _showErrorSnackBar('Please fix the errors above');
      return;
    }

    if (!_isFormValid) {
      _showErrorSnackBar('Please complete all required fields');
      return;
    }

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      // Ensure auth service is available
      if (_authService == null) {
        _authService = Provider.of<AuthService>(context, listen: false);
      }

      final email = _selectedContactMethod == 'email'
          ? _emailController.text.trim()
          : '${_phoneController.text.replaceAll(RegExp(r'[^\d]'), '')}@khilonjiya.temp'; // Temporary email for phone signup
      
      final password = _passwordController.text;
      final fullName = _nameController.text.trim();

      // Enhanced registration with additional metadata
      final response = await _authService!.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phone: _selectedContactMethod == 'phone' ? _phoneController.text.trim() : null,
        profilePhotoPath: _profilePhotoPath,
        locationEnabled: _isLocationEnabled,
      );

      if (response.user != null) {
        setState(() {
          _showOtpVerification = true;
          _currentStep = 2;
        });

        // Provide haptic feedback for success
        HapticFeedback.notificationFeedback();
        
        _showSuccessSnackBar('Verification code sent to your ${_selectedContactMethod}');

        // Simulate OTP verification process
        await _simulateOtpProcess();
      } else {
        throw Exception('Registration failed - no user returned');
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });

      // Enhanced error handling with specific messages
      String errorMessage = _getEnhancedErrorMessage(error.toString());
      setState(() {
        _errorMessage = errorMessage;
      });
      
      _showErrorSnackBar(errorMessage);
      HapticFeedback.heavyImpact(); // Error feedback
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getEnhancedErrorMessage(String error) {
    if (error.toLowerCase().contains('user already registered') || 
        error.toLowerCase().contains('already exists')) {
      return 'This ${_selectedContactMethod} is already registered. Please sign in instead.';
    } else if (error.toLowerCase().contains('weak password') || 
               error.toLowerCase().contains('password')) {
      return 'Password is too weak. Please create a stronger password.';
    } else if (error.toLowerCase().contains('invalid email') || 
               error.toLowerCase().contains('email')) {
      return 'Please enter a valid email address.';
    } else if (error.toLowerCase().contains('network') || 
               error.toLowerCase().contains('connection')) {
      return 'Network error. Please check your connection and try again.';
    } else if (error.toLowerCase().contains('timeout')) {
      return 'Request timed out. Please try again.';
    } else {
      return 'Registration failed. Please try again or contact support.';
    }
  }

  Future<void> _simulateOtpProcess() async {
    // Simulate OTP sending delay
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      // Auto-verify for demo (in production, wait for user input)
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        _handleOtpVerified();
      }
    }
  }

  void _handleOtpVerified() {
    setState(() {
      _currentStep = 3;
    });

    // Provide success haptic feedback
    HapticFeedback.notificationFeedback();
    
    // Show success dialog
    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success animation
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 40,
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'স্বাগতম khilonjiya.com ত!', // Welcome to khilonjiya.com in Assamese
              style: AppTheme.lightTheme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text(
              'Your account has been created successfully. Start exploring amazing local deals!',
              style: AppTheme.lightTheme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.homeMarketplaceFeed,
                    (route) => false,
                  );
                },
                child: const Text('Explore Marketplace'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExitConfirmation() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Registration?'),
        content: const Text('Your progress will be lost. Are you sure you want to go back?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.lightTheme.colorScheme.error,
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  // Enhanced snackbar methods
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 20),
              SizedBox(width: 2.w),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(4.w),
          duration: const Duration(seconds: 4),
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
              Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              SizedBox(width: 2.w),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(4.w),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showInfoSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white, size: 20),
              SizedBox(width: 2.w),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: AppTheme.lightTheme.colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(4.w),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }



@override
  void dispose() {
    // Dispose animation controllers
    _fadeController.dispose();
    _slideController.dispose();
    
    // Dispose text controllers
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    
    // Dispose focus nodes
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Enhanced back button handling
        if (_isLoading) return false; // Prevent going back while loading
        
        if (_nameController.text.isNotEmpty ||
            _emailController.text.isNotEmpty ||
            _phoneController.text.isNotEmpty ||
            _passwordController.text.isNotEmpty) {
          _showExitConfirmation();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  _buildEnhancedHeader(),
                  _buildEnhancedProgressIndicator(),
                  if (_errorMessage.isNotEmpty) _buildErrorBanner(),
                  Expanded(
                    child: _showOtpVerification
                        ? _buildOtpVerificationStep()
                        : _buildEnhancedRegistrationForm(),
                  ),
                  _buildEnhancedBottomButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (_isLoading) return; // Prevent navigation while loading
              
              if (_nameController.text.isNotEmpty ||
                  _emailController.text.isNotEmpty ||
                  _phoneController.text.isNotEmpty ||
                  _passwordController.text.isNotEmpty) {
                _showExitConfirmation();
              } else {
                Navigator.of(context).pop();
              }
            },
            child: Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.lightTheme.colorScheme.outline,
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios,
                color: AppTheme.lightTheme.colorScheme.onSurface,
                size: 20,
              ),
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _showOtpVerification 
                      ? 'Verify Your Account' 
                      : 'Join khilonjiya.com',
                  style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _showOtpVerification
                      ? 'Enter the verification code sent to your ${_selectedContactMethod}'
                      : 'আমাৰ সংস্কৃতি, আমাৰ গৌৰৱ - Join our marketplace',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Loading indicator in header
          if (_isLoading)
            SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.lightTheme.colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEnhancedProgressIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        children: [
          Row(
            children: List.generate(_totalSteps, (index) {
              final isActive = index < _currentStep;
              final isCurrent = index == _currentStep - 1;

              return Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 1.w),
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.lightTheme.colorScheme.primary
                        : AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: isCurrent && _isLoading
                      ? LinearProgressIndicator(
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.lightTheme.colorScheme.primary,
                          ),
                        )
                      : null,
                ),
              );
            }),
          ),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Details',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: _currentStep >= 1 
                      ? AppTheme.lightTheme.colorScheme.primary 
                      : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  fontWeight: _currentStep == 1 ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              Text(
                'Verify',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: _currentStep >= 2 
                      ? AppTheme.lightTheme.colorScheme.primary 
                      : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  fontWeight: _currentStep == 2 ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              Text(
                'Complete',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: _currentStep >= 3 
                      ? AppTheme.lightTheme.colorScheme.primary 
                      : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  fontWeight: _currentStep == 3 ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.all(3.w),
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: AppTheme.lightTheme.colorScheme.error,
            size: 20,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              _errorMessage,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.error,
              ),
            ),
          ),
          GestureDetector(
            onTap: _clearErrorMessage,
            child: Icon(
              Icons.close,
              color: AppTheme.lightTheme.colorScheme.error,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }



Widget _buildOtpVerificationStep() {
    return OtpVerificationWidget(
      contactMethod: _selectedContactMethod,
      contactValue: _selectedContactMethod == 'email'
          ? _emailController.text
          : _phoneController.text,
      onVerified: _handleOtpVerified,
      onResend: () {
        _showInfoSnackBar('Verification code resent to your ${_selectedContactMethod}');
      },
    );
  }

  Widget _buildEnhancedRegistrationForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      physics: const BouncingScrollPhysics(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 2.h),

            // Enhanced Profile Photo Upload
            ProfilePhotoUploadWidget(
              onPhotoSelected: _onProfilePhotoSelected,
              currentPhotoPath: _profilePhotoPath,
            ),

            SizedBox(height: 3.h),

            // Enhanced Name Field
            _buildEnhancedInputField(
              controller: _nameController,
              focusNode: _nameFocusNode,
              label: 'Full Name',
              hint: 'Enter your full name',
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.next,
              isValid: _isNameValid,
              prefixIcon: Icons.person_outline,
              validator: _validateNameField,
              onFieldSubmitted: (_) {
                FocusScope.of(context).requestFocus(
                    _selectedContactMethod == 'email'
                        ? _emailFocusNode
                        : _phoneFocusNode);
              },
            ),

            SizedBox(height: 2.h),

            // Enhanced Contact Method Toggle
            _buildEnhancedContactMethodToggle(),

            SizedBox(height: 2.h),

            // Enhanced Email or Phone Field
            _selectedContactMethod == 'email'
                ? _buildEnhancedInputField(
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    label: 'Email Address',
                    hint: 'your.email@example.com',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    isValid: _isEmailValid,
                    prefixIcon: Icons.email_outlined,
                    validator: _validateEmailField,
                    onFieldSubmitted: (_) {
                      FocusScope.of(context).requestFocus(_passwordFocusNode);
                    },
                  )
                : _buildEnhancedInputField(
                    controller: _phoneController,
                    focusNode: _phoneFocusNode,
                    label: 'Phone Number',
                    hint: '+91 XXXXX XXXXX',
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    isValid: _isPhoneValid,
                    prefixIcon: Icons.phone_outlined,
                    validator: _validatePhoneField,
                    onFieldSubmitted: (_) {
                      FocusScope.of(context).requestFocus(_passwordFocusNode);
                    },
                  ),

            SizedBox(height: 2.h),

            // Enhanced Password Field
            _buildEnhancedInputField(
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              label: 'Password',
              hint: 'Create a strong password',
              obscureText: !_isPasswordVisible,
              textInputAction: TextInputAction.next,
              isValid: _isPasswordValid,
              prefixIcon: Icons.lock_outline,
              suffixIcon: GestureDetector(
                onTap: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                  HapticFeedback.lightImpact();
                },
                child: Icon(
                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
              validator: _validatePasswordField,
              onFieldSubmitted: (_) {
                FocusScope.of(context).requestFocus(_confirmPasswordFocusNode);
              },
            ),

            // Enhanced Password Strength Indicator
            if (_passwordController.text.isNotEmpty) ...[
              SizedBox(height: 1.h),
              PasswordStrengthIndicatorWidget(
                password: _passwordController.text,
                strength: _passwordStrength,
              ),
              SizedBox(height: 0.5.h),
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: _getPasswordStrengthColor(),
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    'Password strength: ${_getPasswordStrengthText()}',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: _getPasswordStrengthColor(),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],

            SizedBox(height: 2.h),

            // Enhanced Confirm Password Field
            _buildEnhancedInputField(
              controller: _confirmPasswordController,
              focusNode: _confirmPasswordFocusNode,
              label: 'Confirm Password',
              hint: 'Re-enter your password',
              obscureText: !_isConfirmPasswordVisible,
              textInputAction: TextInputAction.done,
              isValid: _isConfirmPasswordValid,
              prefixIcon: Icons.lock_outline,
              suffixIcon: GestureDetector(
                onTap: () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                  HapticFeedback.lightImpact();
                },
                child: Icon(
                  _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
              validator: _validateConfirmPasswordField,
            ),

            // Password match indicator
            if (_confirmPasswordController.text.isNotEmpty) ...[
              SizedBox(height: 0.5.h),
              Row(
                children: [
                  Icon(
                    _isConfirmPasswordValid ? Icons.check_circle : Icons.cancel,
                    size: 14,
                    color: _isConfirmPasswordValid 
                        ? Colors.green.shade600 
                        : Colors.red.shade400,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    _isConfirmPasswordValid ? 'Passwords match' : 'Passwords do not match',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: _isConfirmPasswordValid 
                          ? Colors.green.shade600 
                          : Colors.red.shade400,
                    ),
                  ),
                ],
              ),
            ],

            SizedBox(height: 3.h),

            // Enhanced Location Services Toggle
            _buildEnhancedLocationToggle(),

            SizedBox(height: 3.h),

            // Enhanced Terms and Privacy
            _buildEnhancedTermsCheckbox(),

            SizedBox(height: 10.h), // Space for bottom button
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    bool obscureText = false,
    bool isValid = false,
    IconData? prefixIcon,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    void Function(String)? onFieldSubmitted,
  }) {
    final bool hasError = controller.text.isNotEmpty && !isValid;
    final bool hasFocus = focusNode.hasFocus;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 0.5.h),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: hasFocus
                ? [
                    BoxShadow(
                      color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            obscureText: obscureText,
            validator: validator,
            onFieldSubmitted: onFieldSubmitted,
            style: AppTheme.lightTheme.textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              prefixIcon: prefixIcon != null
                  ? Icon(
                      prefixIcon,
                      color: hasFocus
                          ? AppTheme.lightTheme.colorScheme.primary
                          : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      size: 20,
                    )
                  : null,
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (controller.text.isNotEmpty && isValid)
                    Icon(
                      Icons.check_circle,
                      color: Colors.green.shade600,
                      size: 20,
                    ),
                  if (controller.text.isNotEmpty && hasError)
                    Icon(
                      Icons.error,
                      color: Colors.red.shade400,
                      size: 20,
                    ),
                  if (suffixIcon != null) ...[
                    SizedBox(width: 2.w),
                    suffixIcon,
                  ],
                  SizedBox(width: 3.w),
                ],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.lightTheme.colorScheme.outline,
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: hasError
                      ? Colors.red.shade400
                      : AppTheme.lightTheme.colorScheme.outline,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: hasError
                      ? Colors.red.shade400
                      : AppTheme.lightTheme.colorScheme.primary,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.red.shade400,
                  width: 1,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.red.shade400,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: hasFocus
                  ? AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.05)
                  : AppTheme.lightTheme.colorScheme.surface,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 4.w,
                vertical: 3.w,
              ),
            ),
            onTap: () {
              if (!focusNode.hasFocus) {
                FocusScope.of(context).requestFocus(focusNode);
              }
            },
            onChanged: (value) {
              // Clear error message when user starts typing
              if (_errorMessage.isNotEmpty) {
                _clearErrorMessage();
              }
            },
          ),
        ),
      ],
    );
  }



Widget _buildEnhancedContactMethodToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preferred Contact Method',
          style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          'Choose how you\'d like to receive notifications',
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 1.h),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.lightTheme.colorScheme.outline,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (_selectedContactMethod != 'email') {
                      setState(() {
                        _selectedContactMethod = 'email';
                        _phoneController.clear();
                        _clearErrorMessage();
                      });
                      HapticFeedback.lightImpact();
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(vertical: 3.w),
                    decoration: BoxDecoration(
                      color: _selectedContactMethod == 'email'
                          ? AppTheme.lightTheme.colorScheme.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _selectedContactMethod == 'email'
                          ? [
                              BoxShadow(
                                color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.email_outlined,
                          color: _selectedContactMethod == 'email'
                              ? Colors.white
                              : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                          size: 18,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          'Email',
                          style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                            color: _selectedContactMethod == 'email'
                                ? Colors.white
                                : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                            fontWeight: _selectedContactMethod == 'email'
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (_selectedContactMethod != 'phone') {
                      setState(() {
                        _selectedContactMethod = 'phone';
                        _emailController.clear();
                        _clearErrorMessage();
                      });
                      HapticFeedback.lightImpact();
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(vertical: 3.w),
                    decoration: BoxDecoration(
                      color: _selectedContactMethod == 'phone'
                          ? AppTheme.lightTheme.colorScheme.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _selectedContactMethod == 'phone'
                          ? [
                              BoxShadow(
                                color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          color: _selectedContactMethod == 'phone'
                              ? Colors.white
                              : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                          size: 18,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          'Phone',
                          style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                            color: _selectedContactMethod == 'phone'
                                ? Colors.white
                                : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                            fontWeight: _selectedContactMethod == 'phone'
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedLocationToggle() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isLocationEnabled
              ? AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.3)
              : AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: _isLocationEnabled
                  ? AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1)
                  : AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _isLocationEnabled ? Icons.location_on : Icons.location_off,
              color: _isLocationEnabled
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enable Location Services',
                  style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  _isLocationEnabled
                      ? 'Great! You\'ll see nearby listings and local deals'
                      : 'Find local listings and sellers near you',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: _isLocationEnabled
                        ? AppTheme.lightTheme.colorScheme.primary
                        : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (_isLocationEnabled) ...[
                  SizedBox(height: 0.5.h),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 14,
                        color: AppTheme.lightTheme.colorScheme.primary,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        'Location access enabled',
                        style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Switch(
              value: _isLocationEnabled,
              onChanged: (value) => _toggleLocationServices(),
              activeColor: AppTheme.lightTheme.colorScheme.primary,
              activeTrackColor: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.3),
              inactiveThumbColor: AppTheme.lightTheme.colorScheme.outline,
              inactiveTrackColor: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedTermsCheckbox() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: _acceptTerms
            ? AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.05)
            : AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _acceptTerms
              ? AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.3)
              : AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Checkbox(
              value: _acceptTerms,
              onChanged: (value) {
                setState(() {
                  _acceptTerms = value ?? false;
                });
                HapticFeedback.lightImpact();
              },
              activeColor: AppTheme.lightTheme.colorScheme.primary,
              checkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _acceptTerms = !_acceptTerms;
                });
                HapticFeedback.lightImpact();
              },
              child: Padding(
                padding: EdgeInsets.only(top: 3.w, left: 2.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: AppTheme.lightTheme.textTheme.bodyMedium,
                        children: [
                          const TextSpan(text: 'I agree to the '),
                          WidgetSpan(
                            child: GestureDetector(
                              onTap: () {
                                _showTermsBottomSheet();
                                HapticFeedback.lightImpact();
                              },
                              child: Text(
                                'Terms of Service',
                                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.lightTheme.colorScheme.primary,
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const TextSpan(text: ' and '),
                          WidgetSpan(
                            child: GestureDetector(
                              onTap: () {
                                _showTermsBottomSheet();
                                HapticFeedback.lightImpact();
                              },
                              child: Text(
                                'Privacy Policy',
                                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.lightTheme.colorScheme.primary,
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Row(
                      children: [
                        Icon(
                          Icons.security,
                          size: 14,
                          color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                        SizedBox(width: 1.w),
                        Expanded(
                          child: Text(
                            'Your data is secure and protected with us',
                            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }



Widget _buildEnhancedBottomButton() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Form completion indicator
          if (!_showOtpVerification) ...[
            Row(
              children: [
                Icon(
                  Icons.checklist,
                  size: 16,
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Form ${_getCompletionPercentage()}% complete',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                if (_isFormValid)
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Colors.green.shade600,
                  ),
              ],
            ),
            SizedBox(height: 2.h),
          ],

          // Main action button
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _showOtpVerification
                  ? null
                  : (_isFormValid && !_isLoading ? _handleRegistration : null),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isFormValid && !_isLoading
                    ? AppTheme.lightTheme.colorScheme.primary
                    : AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
                foregroundColor: _isFormValid && !_isLoading
                    ? Colors.white
                    : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                elevation: _isFormValid && !_isLoading ? 4 : 0,
                shadowColor: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Text(
                          'Creating Account...',
                          style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_add,
                          size: 20,
                          color: _isFormValid ? Colors.white : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          'Create Account',
                          style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          SizedBox(height: 2.h),

          // Alternative sign-in option
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: AppTheme.lightTheme.textTheme.bodyMedium,
              ),
              GestureDetector(
                onTap: _isLoading
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        Navigator.pushReplacementNamed(context, AppRoutes.loginScreen);
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: _isLoading
                        ? Colors.transparent
                        : AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
                  ),
                  child: Text(
                    'Sign In',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: _isLoading
                          ? AppTheme.lightTheme.colorScheme.onSurfaceVariant
                          : AppTheme.lightTheme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Cultural touch and app branding
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_mall,
                size: 16,
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
              SizedBox(width: 1.w),
              Text(
                'khilonjiya.com',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                ' - আমাৰ সংস্কৃতি, আমাৰ গৌৰৱ',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper method to calculate form completion percentage
  int _getCompletionPercentage() {
    int completed = 0;
    int total = 5; // name, email/phone, password, confirm password, terms

    if (_isNameValid) completed++;
    if (_selectedContactMethod == 'email' ? _isEmailValid : _isPhoneValid) completed++;
    if (_isPasswordValid) completed++;
    if (_isConfirmPasswordValid) completed++;
    if (_acceptTerms) completed++;

    return ((completed / total) * 100).round();
  }

  // Enhanced social login buttons (if needed for future implementation)
  Widget _buildSocialLoginSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                'Or continue with',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(child: Divider()),
          ],
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : () {
                  // Handle Google sign-up
                  HapticFeedback.lightImpact();
                },
                icon: Icon(Icons.g_mobiledata, size: 24),
                label: Text('Google'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 3.w),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : () {
                  // Handle Facebook sign-up
                  HapticFeedback.lightImpact();
                },
                icon: Icon(Icons.facebook, size: 24),
                label: Text('Facebook'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 3.w),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Extension for enhanced auth service integration
extension RegistrationScreenAuthExtension on AuthService {
  Future<dynamic> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String? profilePhotoPath,
    bool locationEnabled = false,
  }) async {
    try {
      // Call the existing signUp method with additional metadata
      final response = await signUpWithEmail(email, password);
      
      if (response.user != null) {
        // Update user profile with additional information
        await updateUserProfile(
          userId: response.user!.id,
          fullName: fullName,
          phone: phone,
          profilePhotoPath: profilePhotoPath,
          locationEnabled: locationEnabled,
        );
      }
      
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUserProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? profilePhotoPath,
    bool locationEnabled = false,
  }) async {
    try {
      // Implementation would depend on your UserProfileService
      // This is a placeholder for the actual implementation
      final profileService = UserProfileService();
      await profileService.updateProfile(
        userId: userId,
        fullName: fullName,
        phone: phone,
        profilePhotoPath: profilePhotoPath,
        locationEnabled: locationEnabled,
      );
    } catch (e) {
      // Log error but don't throw to avoid breaking registration flow
      print('Failed to update user profile: $e');
    }
  }
}