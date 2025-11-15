import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import '../../core/app_export.dart';
import 'mobile_auth_service.dart';

class MobileLoginScreen extends StatefulWidget {
  const MobileLoginScreen({Key? key}) : super(key: key);

  @override
  State<MobileLoginScreen> createState() => _MobileLoginScreenState();
}

class _MobileLoginScreenState extends State<MobileLoginScreen>
    with TickerProviderStateMixin {
  final _mobileController = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(6, (index) => FocusNode());

  bool _isLoading = false;
  bool _isMobileValid = false;
  String? _errorMessage;
  int _currentStep = 1;
  int _resendTimer = 0;
  bool _canResend = false;
  int _resendAttempts = 0;
  Timer? _timer;

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final _authService = MobileAuthService();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _mobileController.addListener(_validateMobile);
    _initializeAuthService();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  Future<void> _initializeAuthService() async {
    try {
      await _authService.initialize();

      if (_authService.isAuthenticated) {
        final valid = await _authService.refreshSession();
        if (valid) {
          _navigateToHome();
          return;
        }
      }
    } catch (e) {
      debugPrint('Auth service initialization error: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _mobileController.dispose();
    _timer?.cancel();

    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }

    super.dispose();
  }

  void _validateMobile() {
    setState(() {
      _isMobileValid =
          MobileAuthService.isValidMobileNumber(_mobileController.text);
      if (_errorMessage != null) _errorMessage = null;
    });
  }

  Future<void> _handleSendOTP() async {
    if (!_isMobileValid || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.sendOtp(_mobileController.text);

      setState(() {
        _currentStep = 2;
        _isLoading = false;
        _resendAttempts++;
      });

      _startResendTimer();
      _animationController.reset();
      _animationController.forward();

      HapticFeedback.lightImpact();
      _showSuccessMessage('OTP sent! Use 123456 to continue.');
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e is MobileAuthException 
            ? e.message 
            : 'Failed to send OTP. Please try again.';
      });
    }
  }

  void _startResendTimer() {
    setState(() {
      _resendTimer = 30;
      _canResend = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_resendTimer > 0) {
            _resendTimer--;
          } else {
            _canResend = true;
            timer.cancel();
          }
        });
      }
    });
  }

  Future<void> _handleResendOTP() async {
    if (!_canResend || _resendAttempts >= 3) return;

    for (var controller in _otpControllers) {
      controller.clear();
    }
    setState(() {
      _errorMessage = null;
    });

    await _handleSendOTP();
  }

  Future<void> _handleVerifyOTP() async {
    final otp = _otpControllers.map((c) => c.text).join();

    if (otp.length != 6) {
      setState(() {
        _errorMessage = 'Please enter all 6 digits';
      });
      return;
    }

    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _authService.verifyOtp(_mobileController.text, otp);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        HapticFeedback.lightImpact();
        _showSuccessMessage('Login successful! Welcome to Khilonjiya.');

        await Future.delayed(const Duration(milliseconds: 1500));
        _navigateToHome();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e is MobileAuthException
              ? e.message
              : 'Verification failed. Please try again.';
        });

        for (var controller in _otpControllers) {
          controller.clear();
        }
        _otpFocusNodes[0].requestFocus();
      }
    }
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.homeMarketplaceFeed);
    }
  }

  void _handleOTPChange(int index, String value) {
    if (value.length > 1) {
      if (value.length == 6 && index == 0) {
        for (int i = 0; i < 6; i++) {
          if (i < value.length) {
            setState(() {
              _otpControllers[i].text = value[i];
            });
          }
        }
        _otpFocusNodes[5].requestFocus();
        Future.delayed(const Duration(milliseconds: 300), _handleVerifyOTP);
        return;
      } else {
        value = value[0];
      }
    }

    setState(() {
      _otpControllers[index].text = value;
      _errorMessage = null;
    });

    if (value.isNotEmpty && index < 5) {
      _otpFocusNodes[index + 1].requestFocus();
    }

    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length == 6) {
      Future.delayed(const Duration(milliseconds: 300), _handleVerifyOTP);
    }
  }

  void _handleOTPKeyPress(int index, RawKeyEvent event) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_otpControllers[index].text.isEmpty && index > 0) {
        _otpFocusNodes[index - 1].requestFocus();
        setState(() {
          _otpControllers[index - 1].text = '';
        });
      }
    }
  }

  void _showSuccessMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Terms & Privacy Policy',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Terms of Service',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'This is a demo Terms of Service document. The actual terms will be updated by the company.\n\n'
                          'By using our services, you agree to be bound by these terms and conditions. Please read them carefully before proceeding.\n\n'
                          '1. Acceptance of Terms\n'
                          '2. User Responsibilities\n'
                          '3. Service Usage\n'
                          '4. Limitations of Liability\n'
                          '5. Modifications to Terms',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Privacy Policy',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'This is a demo Privacy Policy document. The actual policy will be updated by the company.\n\n'
                          'We respect your privacy and are committed to protecting your personal data. This privacy policy will inform you about how we handle your personal information.\n\n'
                          '1. Information We Collect\n'
                          '2. How We Use Your Information\n'
                          '3. Data Security\n'
                          '4. Your Rights\n'
                          '5. Contact Us',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
          child: Column(
            children: [
              // Logo section
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4285F4),
                        shape: BoxShape.circle,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: Image.asset(
                          'assets/images/company_logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Text(
                              'K',
                              style: TextStyle(
                                fontSize: 36,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Khilonjiya.com',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF4285F4),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 80),

              // Main content
              Expanded(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _currentStep == 1 ? _buildMobileStep() : _buildOTPStep(),
                  ),
                ),
              ),

              // Footer
              const Text(
                '© Khilonjiya India Private Limited 2025',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Mobile input with subtle border
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                // Indian flag with proper colors and Ashok Chakra
                Container(
                  width: 28,
                  height: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        offset: const Offset(0, 1),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: Column(
                      children: [
                        // Saffron
                        Expanded(
                          child: Container(color: const Color(0xFFFF9933)),
                        ),
                        // White with Ashok Chakra
                        Expanded(
                          child: Container(
                            color: Colors.white,
                            child: Center(
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFF000080),
                                    width: 0.8,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: CustomPaint(
                                  painter: AshokChakraPainter(),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Green
                        Expanded(
                          child: Container(color: const Color(0xFF138808)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  '+91',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: TextField(
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1E293B),
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Mobile number',
                      hintStyle: TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: const TextStyle(
              color: Color(0xFFEF4444),
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],

        const SizedBox(height: 50),

        // Continue button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isMobileValid && !_isLoading ? _handleSendOTP : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isMobileValid && !_isLoading
                  ? const Color(0xFF4285F4)
                  : const Color(0xFFE2E8F0),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 50),

        // Terms and Privacy Policy
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text(
              'By continuing, you agree to our ',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            GestureDetector(
              onTap: _showTermsDialog,
              child: const Text(
                'Terms & Privacy Policy',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF4285F4),
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOTPStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Enter verification code',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
            ),
            children: [
              const TextSpan(text: 'We sent a 6-digit code to\n'),
              TextSpan(
                text: '+91 ${MobileAuthService.formatMobileNumber(_mobileController.text)}',
                style: const TextStyle(
                  color: Color(0xFF4285F4),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),

        // OTP input boxes with subtle borders
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 48,
              height: 56,
              child: RawKeyboardListener(
                focusNode: FocusNode(),
                onKey: (event) => _handleOTPKeyPress(index, event),
                child: TextField(
                  controller: _otpControllers[index],
                  focusNode: _otpFocusNodes[index],
                  maxLength: 1,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _otpControllers[index].text.isNotEmpty
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    fillColor: _otpControllers[index].text.isNotEmpty
                        ? const Color(0xFF22C55E).withOpacity(0.05)
                        : Colors.white,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onChanged: (value) => _handleOTPChange(index, value),
                ),
              ),
            );
          }),
        ),

        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: const TextStyle(
              color: Color(0xFFEF4444),
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],

        const SizedBox(height: 40),

        // Verify button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: !_isLoading ? () {
              final otp = _otpControllers.map((c) => c.text).join();
              if (otp.length == 6) {
                _handleVerifyOTP();
              } else {
                setState(() {
                  _errorMessage = 'Please enter all 6 digits';
                });
              }
            } : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: !_isLoading
                  ? const Color(0xFF4285F4)
                  : const Color(0xFFE2E8F0),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Verify & Continue',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 24),

        // Resend section
        const Text(
          "Didn't receive code?",
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _canResend && _resendAttempts < 3 ? _handleResendOTP : null,
          child: Text(
            _canResend && _resendAttempts < 3
                ? 'Resend OTP'
                : _resendAttempts >= 3
                    ? 'Max attempts reached'
                    : 'Resend in ${_resendTimer}s',
            style: TextStyle(
              color: _canResend && _resendAttempts < 3
                  ? const Color(0xFF4285F4)
                  : const Color(0xFF94A3B8),
              fontWeight: FontWeight.w600,
              decoration: _canResend && _resendAttempts < 3
                  ? TextDecoration.underline
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

// Custom painter for Ashok Chakra
class AshokChakraPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF000080)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);

    // Draw vertical and horizontal lines
    canvas.drawLine(
      Offset(center.dx, 0),
      Offset(center.dx, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, center.dy),
      Offset(size.width, center.dy),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
