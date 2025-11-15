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
      begin: const Offset(0, 0.3),
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
          backgroundColor: const Color(0xFF22C55E),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    }
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Terms & Privacy Policy',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
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
                            color: Color(0xFF0F172A),
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
                            color: Color(0xFF0F172A),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFAFAFA), Color(0xFFEBF4FF)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  children: [
                    // ✅ Logo Section - FREE FORM with app_icon.png (NO FALLBACK K)
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          // ✅ ONLY app_icon.png - NO "K" fallback
                          Image.asset(
                            'assets/icons/app_icon.png',
                            width: 100,
                            height: 100,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              // If image fails, show nothing or a simple icon
                              return const SizedBox(
                                width: 100,
                                height: 100,
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Welcome to Khilonjiya',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _currentStep == 1 
                                ? 'Enter your mobile number to continue'
                                : 'Verify your number',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Main Card
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                offset: const Offset(0, 20),
                                blurRadius: 60,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(32),
                          child: _currentStep == 1 ? _buildMobileStep() : _buildOTPStep(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Footer
                    const Text(
                      '© Khilonjiya India Private Limited 2025',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mobile Number',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 12),

        // Mobile Input
        Container(
          decoration: BoxDecoration(
            color: _isMobileValid ? const Color(0xFFEBF4FF) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isMobileValid ? const Color(0xFF4285F4) : const Color(0xFFE2E8F0),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              // Prefix
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Row(
                  children: [
                    const Text('🇮🇳', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    const Text(
                      '+91',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 1,
                      height: 32,
                      color: const Color(0xFFE2E8F0),
                    ),
                  ],
                ),
              ),

              // Input
              Expanded(
                child: TextField(
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    letterSpacing: 1.5,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Enter 10 digit number',
                    hintStyle: TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 20),
                  ),
                ),
              ),

              // Check Icon
              if (_isMobileValid)
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFF22C55E),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 20),
                ),
            ],
          ),
        ),

        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Color(0xFFDC2626),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Continue Button
        SizedBox(
          width: double.infinity,
          height: 64,
          child: ElevatedButton(
            onPressed: _isMobileValid && !_isLoading ? _handleSendOTP : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isMobileValid && !_isLoading
                  ? const Color(0xFF4285F4)
                  : const Color(0xFFE2E8F0),
              foregroundColor: Colors.white,
              elevation: 0,
              shadowColor: const Color(0xFF4285F4).withOpacity(0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              disabledBackgroundColor: const Color(0xFFE2E8F0),
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
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _isMobileValid ? Colors.white : const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward,
                        size: 20,
                        color: _isMobileValid ? Colors.white : const Color(0xFF94A3B8),
                      ),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 24),

        // Terms
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'By continuing, you agree to our ',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              GestureDetector(
                onTap: _showTermsDialog,
                child: const Text(
                  'Terms & Privacy Policy',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF4285F4),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOTPStep() {
    return Column(
      children: [
        const Text(
          'Enter the 6-digit code sent to',
          style: TextStyle(fontSize: 15, color: Color(0xFF64748B)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '+91 ${MobileAuthService.formatMobileNumber(_mobileController.text)}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF4285F4),
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 40),

        // OTP Boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (index) {
            final hasValue = _otpControllers[index].text.isNotEmpty;
            return Container(
              width: 56,
              height: 64,
              decoration: BoxDecoration(
                color: hasValue ? const Color(0xFF4285F4) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hasValue ? const Color(0xFF4285F4) : const Color(0xFFE2E8F0),
                  width: 2,
                ),
                boxShadow: hasValue
                    ? [
                        BoxShadow(
                          color: const Color(0xFF4285F4).withOpacity(0.3),
                          offset: const Offset(0, 4),
                          blurRadius: 12,
                        ),
                      ]
                    : null,
              ),
              child: RawKeyboardListener(
                focusNode: FocusNode(),
                onKey: (event) => _handleOTPKeyPress(index, event),
                child: TextField(
                  controller: _otpControllers[index],
                  focusNode: _otpFocusNodes[index],
                  maxLength: 1,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: hasValue ? Colors.white : const Color(0xFFCBD5E1),
                  ),
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (value) => _handleOTPChange(index, value),
                ),
              ),
            );
          }),
        ),

        if (_errorMessage != null) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Color(0xFFDC2626),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 32),

        // Verify Button
        SizedBox(
          width: double.infinity,
          height: 64,
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
              backgroundColor: const Color(0xFF4285F4),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                      color: Colors.white,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 32),

        // Resend
        Column(
          children: [
            const Text(
              "Didn't receive the code?",
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            if (_canResend && _resendAttempts < 3)
              TextButton.icon(
                onPressed: _handleResendOTP,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text(
                  'Resend OTP',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF4285F4),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  backgroundColor: const Color(0xFFEBF4FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              )
            else
              Text(
                _resendAttempts >= 3
                    ? 'Maximum attempts reached'
                    : 'Resend in ${_resendTimer}s',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
