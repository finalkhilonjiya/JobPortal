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
  bool _validateEmail(String email) {
    if (email.isEmpty) return false;
    
    // Comprehensive email regex
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$'
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
          backgroundColor: AppThem