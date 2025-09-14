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
  String _debugInfo = '';
  bool _showDebugInfo = false;
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

  void _addDebugInfo(String info) {
    setState(() {
      _debugInfo += '${DateTime.now().toString().substring(11, 19)}: $info\n';
    });
  }

  Future<void> _initializeAuthService() async {
    try {
      _addDebugInfo('Starting auth service initialization...');
      await _authService.initialize();
      _addDebugInfo('Auth service initialized successfully');
      
      if (_authService.isAuthenticated) {
        _addDebugInfo('Found stored session, checking validity...');
        final valid = await _authService.refreshSession();
        if (valid) {
          _addDebugInfo('Session valid, navigating to home');
          _navigateToHome();
          return;
        } else {
          _addDebugInfo('Session invalid, staying on login');
        }
      }
    } catch (e) {
      _addDebugInfo('Auth service init error: $e');
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
      _addDebugInfo('Sending OTP to: ${_mobileController.text}');
      await _authService.sendOtp(_mobileController.text);
      _addDebugInfo('OTP sent successfully');

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
      _addDebugInfo('Send OTP error: $e');
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
      _addDebugInfo('Starting OTP verification...');
      _addDebugInfo('OTP entered: $otp');
      _addDebugInfo('Phone: +91${_mobileController.text.replaceAll(RegExp(r'[^\d]'), '')}');
      
      final response = await _authService.verifyOtp(_mobileController.text, otp);
      _addDebugInfo('Verification response received successfully');

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
      _addDebugInfo('OTP verification error: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // Debug toggle button
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showDebugInfo = !_showDebugInfo;
                      });
                    },
                    child: Text(
                      _showDebugInfo ? 'Hide Debug' : 'Show Debug',
                      style: const TextStyle(color: Color(0xFF4285F4)),
                    ),
                  ),
                  if (_showDebugInfo)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _debugInfo = '';
                        });
                      },
                      child: const Text(
                        'Clear',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),

            // Debug info panel
            if (_showDebugInfo)
              Container(
                height: 200,
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _debugInfo.isEmpty ? 'Debug info will appear here...' : _debugInfo,
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),

            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom -
                        (_showDebugInfo ? 250 : 50),
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        // Step indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: _currentStep == 1 ? 24 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: const Color(0xFF4285F4),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: _currentStep == 2 ? 24 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _currentStep == 2 
                                    ? const Color(0xFF4285F4) 
                                    : const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),

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
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),

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
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'Khilonjiya India Private Limited 2025',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Welcome',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter your mobile number to continue',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),

        // Mobile input container
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                offset: const Offset(0, 4),
                blurRadius: 20,
              ),
            ],
            border: Border.all(
              color: _isMobileValid 
                  ? const Color(0xFF4285F4) 
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Indian flag + country code
                Container(
                  width: 24,
                  height: 18,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(color: const Color(0xFFFF9933)),
                        ),
                        Expanded(
                          child: Container(color: Colors.white),
                        ),
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
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 2,
                  height: 24,
                  color: const Color(0xFFF1F5F9),
                ),
                const SizedBox(width: 16),
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
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Enter mobile number',
                      hintStyle: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
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
              color: Colors.red,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],

        const SizedBox(height: 40),

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
                borderRadius: BorderRadius.circular(16),
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

        const SizedBox(height: 40),

        const Text(
          'By continuing, you agree to our Terms & Privacy Policy',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
          ),
          textAlign: TextAlign.center,
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

        // OTP input boxes
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
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _otpControllers[index].text.isNotEmpty
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFE2E8F0),
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF4285F4), width: 2),
                    ),
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
              color: Colors.red,
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
                borderRadius: BorderRadius.circular(16),
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