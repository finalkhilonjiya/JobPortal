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
      duration: const Duration(milliseconds: 600),
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
        final sessionValid = await _authService.refreshSession();
        if (sessionValid) {
          _navigateToHome();
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
      _isMobileValid = MobileAuthService.isValidMobileNumber(_mobileController.text);
      _errorMessage = null;
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
      _showSuccessMessage('OTP sent successfully!');
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e is AuthException ? e.message : 'Failed to send OTP';
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
      setState(() {
        if (_resendTimer > 0) {
          _resendTimer--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
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
    if (otp.length != 6 || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _authService.verifyOtp(_mobileController.text, otp);
      
      setState(() {
        _isLoading = false;
      });
      
      HapticFeedback.lightImpact();
      _showSuccessMessage('Login successful!');
      
      await Future.delayed(Duration(milliseconds: 500));
      _navigateToHome();
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e is AuthException ? e.message : 'Invalid OTP';
      });
    }
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.homeMarketplaceFeed);
    }
  }

  void _handleOTPChange(int index, String value) {
    if (value.length > 1) return;
    
    _otpControllers[index].text = value;
    
    if (value.isNotEmpty && index < 5) {
      _otpFocusNodes[index + 1].requestFocus();
    }
    
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length == 6) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  void _handleOTPKeyDown(int index, RawKeyEvent key) {
    if (key is RawKeyDownEvent && key.logicalKey == LogicalKeyboardKey.backspace) {
      if (_otpControllers[index].text.isEmpty && index > 0) {
        _otpFocusNodes[index - 1].requestFocus();
        _otpControllers[index - 1].clear();
      }
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Expanded(child: Text(message, style: TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(4.w),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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
                colors: [
                  Color(0xFF10B981).withOpacity(0.08),
                  Color(0xFF6366F1).withOpacity(0.04)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildLogo(),
                            SizedBox(height: 4.h),
                            if (_currentStep == 1) 
                              _buildMobileStep()
                            else 
                              _buildOTPStep(),
                          ],
                        ),
                      ),
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

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[300]!, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: Image.asset(
              'assets/images/company_logo.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Center(
                child: Text(
                  'Your Logo',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          'khilonjiya.com',
          style: TextStyle(
            fontSize: 6.w,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2563EB),
            letterSpacing: 1.2,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildMobileStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _mobileController,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          decoration: InputDecoration(
            hintText: 'Enter your mobile number',
            prefixIcon: Padding(
              padding: EdgeInsets.all(3.w),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.phone_outlined, color: Colors.grey[600], size: 5.w),
                  SizedBox(width: 2.w),
                  Text('+91', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF2563EB), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red, width: 1),
            ),
            contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          ),
          style: TextStyle(fontSize: 4.5.w),
          onFieldSubmitted: (value) {
            if (_isMobileValid) _handleSendOTP();
          },
        ),
        
        if (_errorMessage != null) ...[
          SizedBox(height: 1.h),
          Padding(
            padding: EdgeInsets.only(left: 3.w),
            child: Text(_errorMessage!, style: TextStyle(fontSize: 3.w, color: Colors.red)),
          ),
        ],
        
        SizedBox(height: 4.h),
        
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isMobileValid && !_isLoading ? _handleSendOTP : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
            child: _isLoading
                ? SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2.5,
                    ),
                  )
                : Text('Continue', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildOTPStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (index) {
            return Container(
              width: 12.w,
              child: RawKeyboardListener(
                focusNode: FocusNode(),
                onKey: (event) => _handleOTPKeyDown(index, event),
                child: TextFormField(
                  controller: _otpControllers[index],
                  focusNode: _otpFocusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFF2563EB), width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red, width: 1),
                    ),
                  ),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  onChanged: (value) => _handleOTPChange(index, value),
                  onTap: () => _otpControllers[index].clear(),
                ),
              ),
            );
          }),
        ),
        
        if (_errorMessage != null) ...[
          SizedBox(height: 2.h),
          Text(_errorMessage!, style: TextStyle(fontSize: 3.w, color: Colors.red), textAlign: TextAlign.center),
        ],
        
        SizedBox(height: 4.h),
        
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _otpControllers.every((c) => c.text.isNotEmpty) && !_isLoading 
                ? _handleVerifyOTP 
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
            child: _isLoading
                ? SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2.5,
                    ),
                  )
                : Text('Verify OTP', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
          ),
        ),
        
        SizedBox(height: 2.h),
        
        if (!_canResend && _resendTimer > 0)
          Text('Resend OTP in ${_resendTimer}s',
            style: TextStyle(fontSize: 3.5.w, color: Colors.grey[600]),
            textAlign: TextAlign.center)
        else if (_canResend && _resendAttempts < 3)
          TextButton(
            onPressed: _handleResendOTP,
            child: Text('Resend OTP',
              style: TextStyle(fontSize: 3.5.w, color: Color(0xFF2563EB), fontWeight: FontWeight.w600)),
          )
        else if (_resendAttempts >= 3)
          Text('Maximum resend attempts reached',
            style: TextStyle(fontSize: 3.w, color: Colors.red),
            textAlign: TextAlign.center),
        
        SizedBox(height: 1.h),
        
        TextButton(
          onPressed: () {
            setState(() {
              _currentStep = 1;
              _errorMessage = null;
            });
            for (var controller in _otpControllers) {
              controller.clear();
            }
            _timer?.cancel();
            _animationController.reset();
            _animationController.forward();
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back, size: 4.w, color: Colors.grey[600]),
              SizedBox(width: 1.w),
              Text('Edit mobile number',
                style: TextStyle(fontSize: 3.5.w, color: Colors.grey[600])),
            ],
          ),
        ),
      ],
    );
  }
}