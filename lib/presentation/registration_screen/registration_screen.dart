import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import 'widgets/password_strength_indicator_widget.dart';

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
  final _fullNameController = TextEditingController();

  final _emailFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  final _fullNameFocusNode = FocusNode();

  final _authService = AuthService();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _acceptTerms = false;

  String _errorMessage = '';

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _fadeController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _slideController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  bool _isFormValid() {
    return _emailController.text.isNotEmpty &&
        _fullNameController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        _passwordController.text == _confirmPasswordController.text &&
        _acceptTerms;
  }

  Future<void> _handleRegistration() async {
    if (!_isFormValid()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      if (response.user != null) {
        HapticFeedback.lightImpact();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful'),
            backgroundColor: Colors.green,
          ),
        );

        await Future.delayed(const Duration(seconds: 1));

        if (!mounted) return;

        /// ✅ FIX: go to Job Seeker Login
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.jobSeekerLogin,
        );
      }
    } on AppAuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Registration failed. Try again.');
    } finally {
      setState(() => _isLoading = false);
    }
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
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: EdgeInsets.all(6.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                      SizedBox(height: 3.h),
                      _buildForm(),
                      SizedBox(height: 2.h),
                      _buildTerms(),
                      SizedBox(height: 2.h),
                      _buildRegisterButton(),
                      if (_errorMessage.isNotEmpty) ...[
                        SizedBox(height: 1.h),
                        Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                      SizedBox(height: 2.h),
                      _buildLoginLink(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _textField(_fullNameController, 'Full Name', Icons.person),
          _textField(_emailController, 'Email', Icons.email),
          _textField(_phoneController, 'Phone', Icons.phone),
          _passwordField(),
          PasswordStrengthIndicatorWidget(password: _passwordController.text),
          _confirmPasswordField(),
        ],
      ),
    );
  }

  Widget _textField(
      TextEditingController c, String label, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: TextFormField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _passwordField() {
    return _secureField(
      _passwordController,
      'Password',
      _isPasswordVisible,
      () => setState(() => _isPasswordVisible = !_isPasswordVisible),
    );
  }

  Widget _confirmPasswordField() {
    return _secureField(
      _confirmPasswordController,
      'Confirm Password',
      _isConfirmPasswordVisible,
      () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
    );
  }

  Widget _secureField(
    TextEditingController c,
    String label,
    bool visible,
    VoidCallback toggle,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: TextFormField(
        controller: c,
        obscureText: !visible,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.lock),
          suffixIcon: IconButton(
            icon: Icon(visible ? Icons.visibility_off : Icons.visibility),
            onPressed: toggle,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildTerms() {
    return Row(
      children: [
        Checkbox(
          value: _acceptTerms,
          onChanged: (v) => setState(() => _acceptTerms = v ?? false),
        ),
        const Expanded(
          child: Text('I accept the Terms & Privacy Policy'),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isFormValid() && !_isLoading ? _handleRegistration : null,
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('Register'),
      ),
    );
  }

  Widget _buildLoginLink() {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.jobSeekerLogin, // ✅ FIXED
        );
      },
      child: const Text(
        'Already have an account? Sign In',
        style: TextStyle(color: Color(0xFF2563EB)),
      ),
    );
  }
}