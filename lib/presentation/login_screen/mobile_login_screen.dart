import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
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
  bool _isSupabaseConnected = false;

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

  /// ✅ Refactored for Option 2
  Future<void> _initializeAuthService() async {
    try {
      await _authService.initialize(); // loads cached auth + fingerprint

      setState(() {
        _isSupabaseConnected = true;
      });

      if (_authService.isAuthenticated) {
        final sessionValid = await _authService.refreshSession();
        if (sessionValid) {
          _navigateToHome();
          return;
        }
      }

      _showSuccessMessage('Ready for login');
    } catch (e) {
      setState(() {
        _isSupabaseConnected = false;
      });
      _showErrorMessage('Auth service error: ${e.toString()}');
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
      _errorMessage = null;
    });
  }

  Future<void> _handleSendOTP() async {
    if (!_isMobileValid || _isLoading) return;

    if (!_isSupabaseConnected) {
      _showErrorMessage(
          'Not connected to authentication service. Please check your connection.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('Sending OTP to: ${_mobileController.text}');
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
      _showSuccessMessage('OTP sent! Check Supabase function logs for the code.');
    } catch (e) {
      debugPrint('OTP Send Error: $e');
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
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
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
    debugPrint('Attempting to verify OTP: $otp (${otp.length} characters)');

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
        _showSuccessMessage('Login successful! Redirecting...');

        await Future.delayed(Duration(milliseconds: 1000));
        _navigateToHome();
      }
    } catch (e) {
      debugPrint('OTP Verification Error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e is MobileAuthException
              ? e.message
              : 'Invalid OTP. Please check the code.';
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
        Future.delayed(Duration(milliseconds: 300), _handleVerifyOTP);
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
      Future.delayed(Duration(milliseconds: 300), _handleVerifyOTP);
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
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(
                  child:
                      Text(message, style: TextStyle(color: Colors.white))),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(
                  child:
                      Text(message, style: TextStyle(color: Colors.white))),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          child: Column(
            children: [
              SizedBox(height: 40),
              // Connection status
              Container(
                margin: EdgeInsets.symmetric(horizontal: 24),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _isSupabaseConnected
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isSupabaseConnected
                        ? Colors.green.withOpacity(0.3)
                        : Colors.red.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _isSupabaseConnected ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      _isSupabaseConnected ? 'Connected' : 'Not Connected',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _isSupabaseConnected
                            ? Colors.green[700]
                            : Colors.red[700],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  height: 180,
                  child: Center(child: _buildLogo()),
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _currentStep == 1
                          ? _buildMobileStep()
                          : _buildOTPStep(),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 85,
          height: 85,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(42.5),
            child: Image.asset(
              'assets/images/company_logo.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Center(
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
        SizedBox(height: 20),
        Text(
          'khilonjiya.com',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _mobileController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: 'Enter your mobile number',
              prefixIcon: Container(
                padding: EdgeInsets.only(left: 20, right: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.phone_outlined, size: 22),
                    SizedBox(width: 10),
                    Text(
                      '+91',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(vertical: 22, horizontal: 20),
            ),
          ),
        ),
        if (_errorMessage != null) ...[
          SizedBox(height: 16),
          Text(_errorMessage!,
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
        ],
        SizedBox(height: 40),
        Container(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: _isMobileValid && !_isLoading && _isSupabaseConnected
                ? _handleSendOTP
                : null,
            child: _isLoading
                ? CircularProgressIndicator(strokeWidth: 3)
                : Text('Continue'),
          ),
        ),
      ],
    );
  }

  Widget _buildOTPStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Enter verification code'),
        SizedBox(height: 16),
        Text('We sent a code to ${_mobileController.text}'),
        SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (index) {
            return Flexible(
              child: TextField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                maxLength: 1,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                onChanged: (val) => _handleOTPChange(index, val),
                decoration: InputDecoration(counterText: ''),
              ),
            );
          }),
        ),
        SizedBox(height: 40),
        Container(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: () {
              final otp = _otpControllers.map((c) => c.text).join();
              if (otp.length == 6 && !_isLoading) {
                _handleVerifyOTP();
              } else {
                setState(() {
                  _errorMessage = 'Please enter all 6 digits';
                });
              }
            },
            child: _isLoading
                ? CircularProgressIndicator(strokeWidth: 3)
                : Text('Verify'),
          ),
        ),
      ],
    );
  }
}