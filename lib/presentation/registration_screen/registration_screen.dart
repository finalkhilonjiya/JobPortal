import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
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

  // Add auth service
  final _authService = AuthService();

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

  String _selectedContactMethod = 'email'; // 'email' or 'phone'
  int _currentStep = 1;
  final int _totalSteps = 3;

  // Password strength levels
  int _passwordStrength = 0; // 0-4 (weak to very strong)

  // Profile photo
  String? _profilePhotoPath;

  @override
  void initState() {
    super.initState();
    _setupValidationListeners();
    _setupFocusListeners();
  }

  void _setupFocusListeners() {
    // Add focus listeners to handle keyboard behavior properly
    _nameFocusNode.addListener(() {
      setState(() {}); // Rebuild to update UI based on focus
    });
    _emailFocusNode.addListener(() {
      setState(() {}); // Rebuild to update UI based on focus
    });
    _phoneFocusNode.addListener(() {
      setState(() {}); // Rebuild to update UI based on focus
    });
    _passwordFocusNode.addListener(() {
      setState(() {}); // Rebuild to update UI based on focus
    });
    _confirmPasswordFocusNode.addListener(() {
      setState(() {}); // Rebuild to update UI based on focus
    });
  }

  void _setupValidationListeners() {
    _nameController.addListener(() {
      setState(() {
        _isNameValid = _nameController.text.trim().length >= 2;
      });
    });

    _emailController.addListener(() {
      setState(() {
        _isEmailValid = _validateEmail(_emailController.text);
      });
    });

    _phoneController.addListener(() {
      setState(() {
        _isPhoneValid = _validatePhone(_phoneController.text);
      });
    });

    _passwordController.addListener(() {
      setState(() {
        _passwordStrength =
            _calculatePasswordStrength(_passwordController.text);
        _isPasswordValid = _passwordStrength >= 2;
        _isConfirmPasswordValid =
            _confirmPasswordController.text == _passwordController.text;
      });
    });

    _confirmPasswordController.addListener(() {
      setState(() {
        _isConfirmPasswordValid =
            _confirmPasswordController.text == _passwordController.text;
      });
    });
  }

  bool _validateEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _validatePhone(String phone) {
    return RegExp(r'^\+?[\d\s\-\(\)]{10,}$').hasMatch(phone);
  }

  int _calculatePasswordStrength(String password) {
    int strength = 0;
    if (password.length >= 8) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[a-z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;
    return strength;
  }

  bool get _isFormValid {
    return _isNameValid &&
        (_selectedContactMethod == 'email' ? _isEmailValid : _isPhoneValid) &&
        _isPasswordValid &&
        _isConfirmPasswordValid &&
        _acceptTerms;
  }

  void _onProfilePhotoSelected(String? photoPath) {
    setState(() {
      _profilePhotoPath = photoPath;
    });
  }

  void _showTermsBottomSheet() {
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
  }

  Future<void> _handleRegistration() async {
    if (!_isFormValid) return;

    // Dismiss keyboard before starting registration
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _selectedContactMethod == 'email'
          ? _emailController.text.trim()
          : '${_phoneController.text.trim()}@placeholder.com'; // Temporary email for phone signup
      final password = _passwordController.text;
      final fullName = _nameController.text.trim();

      final response = await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
        role: 'buyer',
      );

      if (response.user != null) {
        setState(() {
          _isLoading = false;
          _showOtpVerification = true;
          _currentStep = 2;
        });

        // For now, simulate OTP verification
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            _handleOtpVerified();
          }
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Registration failed. Please try again.');
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });

      String errorMessage = 'Registration failed. Please try again.';
      if (error.toString().contains('User already registered')) {
        errorMessage = 'This email is already registered. Please sign in.';
      } else if (error
          .toString()
          .contains('Password should be at least 6 characters')) {
        errorMessage = 'Password must be at least 6 characters long.';
      }

      _showErrorSnackBar(errorMessage);
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(4.w),
        ),
      );
    }
  }

  void _handleOtpVerified() {
    setState(() {
      _currentStep = 3;
    });

    // Show success message and navigate
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
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primary
                    .withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: CustomIconWidget(
                iconName: 'check_circle',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 40,
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'Welcome to MarketPlace Pro!',
              style: AppTheme.lightTheme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text(
              'Your account has been created successfully. Start exploring amazing deals!',
              style: AppTheme.lightTheme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacementNamed(
                      context, '/onboarding-tutorial');
                },
                child: const Text('Get Started'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Registration?'),
        content: const Text(
            'Your progress will be lost. Are you sure you want to go back?'),
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
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
        if (_nameController.text.isNotEmpty ||
            _emailController.text.isNotEmpty ||
            _phoneController.text.isNotEmpty) {
          _showExitConfirmation();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildProgressIndicator(),
              Expanded(
                child: _showOtpVerification
                    ? _buildOtpVerificationStep()
                    : _buildRegistrationForm(),
              ),
              _buildBottomButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (_nameController.text.isNotEmpty ||
                  _emailController.text.isNotEmpty ||
                  _phoneController.text.isNotEmpty) {
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
              child: CustomIconWidget(
                iconName: 'arrow_back_ios',
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
                  _showOtpVerification ? 'Verify Account' : 'Create Account',
                  style: AppTheme.lightTheme.textTheme.headlineSmall,
                ),
                Text(
                  _showOtpVerification
                      ? 'Enter the verification code sent to your ${_selectedContactMethod}'
                      : 'Join thousands of users buying and selling',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isActive = index < _currentStep;
          final isCurrent = index == _currentStep - 1;

          return Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 1.w),
              height: 4,
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.lightTheme.colorScheme.primary
                    : AppTheme.lightTheme.colorScheme.outline
                        .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildRegistrationForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 2.h),

            // Profile Photo Upload
            ProfilePhotoUploadWidget(
              onPhotoSelected: _onProfilePhotoSelected,
              currentPhotoPath: _profilePhotoPath,
            ),

            SizedBox(height: 3.h),

            // Name Field
            _buildInputField(
              controller: _nameController,
              focusNode: _nameFocusNode,
              label: 'Full Name',
              hint: 'Enter your full name',
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.next,
              isValid: _isNameValid,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your full name';
                }
                if (value.trim().length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
              onFieldSubmitted: (_) {
                FocusScope.of(context).requestFocus(
                    _selectedContactMethod == 'email'
                        ? _emailFocusNode
                        : _phoneFocusNode);
              },
            ),

            SizedBox(height: 2.h),

            // Contact Method Toggle
            _buildContactMethodToggle(),

            SizedBox(height: 2.h),

            // Email or Phone Field
            _selectedContactMethod == 'email'
                ? _buildInputField(
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    label: 'Email Address',
                    hint: 'Enter your email address',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    isValid: _isEmailValid,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email address';
                      }
                      if (!_validateEmail(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) {
                      FocusScope.of(context).requestFocus(_passwordFocusNode);
                    },
                  )
                : _buildInputField(
                    controller: _phoneController,
                    focusNode: _phoneFocusNode,
                    label: 'Phone Number',
                    hint: 'Enter your phone number',
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    isValid: _isPhoneValid,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your phone number';
                      }
                      if (!_validatePhone(value)) {
                        return 'Please enter a valid phone number';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) {
                      FocusScope.of(context).requestFocus(_passwordFocusNode);
                    },
                  ),

            SizedBox(height: 2.h),

            // Password Field
            _buildInputField(
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              label: 'Password',
              hint: 'Create a strong password',
              obscureText: !_isPasswordVisible,
              textInputAction: TextInputAction.next,
              isValid: _isPasswordValid,
              suffixIcon: GestureDetector(
                onTap: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
                child: CustomIconWidget(
                  iconName:
                      _isPasswordVisible ? 'visibility_off' : 'visibility',
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a password';
                }
                if (value.length < 8) {
                  return 'Password must be at least 8 characters';
                }
                return null;
              },
              onFieldSubmitted: (_) {
                FocusScope.of(context).requestFocus(_confirmPasswordFocusNode);
              },
            ),

            // Password Strength Indicator
            if (_passwordController.text.isNotEmpty) ...[
              SizedBox(height: 1.h),
              PasswordStrengthIndicatorWidget(
                password: _passwordController.text,
                strength: _passwordStrength,
              ),
            ],

            SizedBox(height: 2.h),

            // Confirm Password Field
            _buildInputField(
              controller: _confirmPasswordController,
              focusNode: _confirmPasswordFocusNode,
              label: 'Confirm Password',
              hint: 'Re-enter your password',
              obscureText: !_isConfirmPasswordVisible,
              textInputAction: TextInputAction.done,
              isValid: _isConfirmPasswordValid,
              suffixIcon: GestureDetector(
                onTap: () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                },
                child: CustomIconWidget(
                  iconName: _isConfirmPasswordVisible
                      ? 'visibility_off'
                      : 'visibility',
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),

            SizedBox(height: 3.h),

            // Location Services Toggle
            _buildLocationToggle(),

            SizedBox(height: 3.h),

            // Terms and Privacy
            _buildTermsCheckbox(),

            SizedBox(height: 10.h), // Space for bottom button
          ],
        ),
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
        // Handle resend OTP
      },
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    bool obscureText = false,
    bool isValid = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    void Function(String)? onFieldSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.labelLarge,
        ),
        SizedBox(height: 0.5.h),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          validator: validator,
          onFieldSubmitted: onFieldSubmitted,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (controller.text.isNotEmpty && isValid)
                  CustomIconWidget(
                    iconName: 'check_circle',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 20,
                  ),
                if (suffixIcon != null) ...[
                  SizedBox(width: 2.w),
                  suffixIcon,
                ],
                SizedBox(width: 3.w),
              ],
            ),
          ),
          onTap: () {
            // Ensure focus is properly managed when field is tapped
            if (!focusNode.hasFocus) {
              FocusScope.of(context).requestFocus(focusNode);
            }
          },
        ),
      ],
    );
  }

  Widget _buildContactMethodToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contact Method',
          style: AppTheme.lightTheme.textTheme.labelLarge,
        ),
        SizedBox(height: 1.h),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.lightTheme.colorScheme.outline,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedContactMethod = 'email';
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 3.w),
                    decoration: BoxDecoration(
                      color: _selectedContactMethod == 'email'
                          ? AppTheme.lightTheme.colorScheme.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomIconWidget(
                          iconName: 'email',
                          color: _selectedContactMethod == 'email'
                              ? Colors.white
                              : AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                          size: 18,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          'Email',
                          style: AppTheme.lightTheme.textTheme.labelLarge
                              ?.copyWith(
                            color: _selectedContactMethod == 'email'
                                ? Colors.white
                                : AppTheme
                                    .lightTheme.colorScheme.onSurfaceVariant,
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
                    setState(() {
                      _selectedContactMethod = 'phone';
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 3.w),
                    decoration: BoxDecoration(
                      color: _selectedContactMethod == 'phone'
                          ? AppTheme.lightTheme.colorScheme.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomIconWidget(
                          iconName: 'phone',
                          color: _selectedContactMethod == 'phone'
                              ? Colors.white
                              : AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                          size: 18,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          'Phone',
                          style: AppTheme.lightTheme.textTheme.labelLarge
                              ?.copyWith(
                            color: _selectedContactMethod == 'phone'
                                ? Colors.white
                                : AppTheme
                                    .lightTheme.colorScheme.onSurfaceVariant,
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

  Widget _buildLocationToggle() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primary
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomIconWidget(
              iconName: 'location_on',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 20,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enable Location Services',
                  style: AppTheme.lightTheme.textTheme.labelLarge,
                ),
                Text(
                  'Find nearby listings and improve your experience',
                  style: AppTheme.lightTheme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Switch(
            value: _isLocationEnabled,
            onChanged: (value) => _toggleLocationServices(),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _acceptTerms,
          onChanged: (value) {
            setState(() {
              _acceptTerms = value ?? false;
            });
          },
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _acceptTerms = !_acceptTerms;
              });
            },
            child: Padding(
              padding: EdgeInsets.only(top: 3.w),
              child: RichText(
                text: TextSpan(
                  style: AppTheme.lightTheme.textTheme.bodySmall,
                  children: [
                    const TextSpan(text: 'I agree to the '),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: _showTermsBottomSheet,
                        child: Text(
                          'Terms of Service',
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                    const TextSpan(text: ' and '),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: _showTermsBottomSheet,
                        child: Text(
                          'Privacy Policy',
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.colorScheme.shadow,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _showOtpVerification
                  ? null
                  : (_isFormValid ? _handleRegistration : null),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isFormValid
                    ? AppTheme.lightTheme.colorScheme.primary
                    : AppTheme.lightTheme.colorScheme.outline
                        .withValues(alpha: 0.3),
                foregroundColor: _isFormValid
                    ? Colors.white
                    : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              child: _isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Create Account'),
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: AppTheme.lightTheme.textTheme.bodyMedium,
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/login-screen');
                },
                child: Text(
                  'Sign In',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
