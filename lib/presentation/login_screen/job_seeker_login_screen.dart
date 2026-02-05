import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../routes/app_routes.dart';
import '../../core/auth/user_role.dart';
import 'mobile_auth_service.dart';

class JobSeekerLoginScreen extends StatefulWidget {
  const JobSeekerLoginScreen({Key? key}) : super(key: key);

  @override
  State<JobSeekerLoginScreen> createState() => _JobSeekerLoginScreenState();
}

class _JobSeekerLoginScreenState extends State<JobSeekerLoginScreen>
    with SingleTickerProviderStateMixin {
  final _mobileController = TextEditingController();

  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  final _auth = MobileAuthService();

  bool _isMobileValid = false;
  bool _showOtpStep = false;
  bool _isLoading = false;

  int _resendSeconds = 0;
  Timer? _timer;

  String? _error;

  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..forward();

    _mobileController.addListener(_validateMobile);
  }

  @override
  void dispose() {
    _animController.dispose();
    _timer?.cancel();
    _mobileController.dispose();

    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _validateMobile() {
    final value = _mobileController.text.trim();
    final valid = MobileAuthService.isValidMobileNumber(value);
    if (valid == _isMobileValid && _error == null) return;

    setState(() {
      _isMobileValid = valid;
      _error = null;
    });
  }

  Future<void> _handleSendOtp() async {
    if (!_isMobileValid || _isLoading) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _auth.sendOtp(_mobileController.text.trim());

      setState(() {
        _showOtpStep = true;
        _isLoading = false;
      });

      _startResendTimer();
      _clearOtp();
      _otpFocusNodes.first.requestFocus();

      HapticFeedback.lightImpact();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e is MobileAuthException ? e.message : 'Failed to send OTP';
      });
    }
  }

  void _startResendTimer() {
    _timer?.cancel();

    setState(() {
      _resendSeconds = 30;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_resendSeconds <= 0) {
        t.cancel();
        return;
      }
      setState(() => _resendSeconds--);
    });
  }

  void _clearOtp() {
    for (final c in _otpControllers) {
      c.clear();
    }
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();

    if (otp.length != 6) {
      setState(() => _error = 'Please enter the full 6-digit OTP');
      return;
    }

    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _auth.verifyOtp(
        mobile: _mobileController.text.trim(),
        otp: otp,
        role: UserRole.jobSeeker,
      );

      if (!mounted) return;

      // ✅ ALWAYS GO TO ROLE BASED HOME ROUTER
      Navigator.pushReplacementNamed(context, AppRoutes.homeJobsFeed);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e is MobileAuthException ? e.message : 'Invalid OTP';
      });

      _clearOtp();
      _otpFocusNodes.first.requestFocus();
    }
  }

  void _handleOtpChange(int index, String value) {
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length == 6) {
        for (int i = 0; i < 6; i++) {
          _otpControllers[i].text = digits[i];
        }
        _otpFocusNodes.last.requestFocus();
        Future.delayed(const Duration(milliseconds: 250), _handleVerifyOtp);
      } else {
        _otpControllers[index].text = digits.isNotEmpty ? digits[0] : '';
      }
      return;
    }

    if (value.isNotEmpty && index < 5) {
      _otpFocusNodes[index + 1].requestFocus();
    }

    final fullOtp = _otpControllers.map((c) => c.text).join();
    if (fullOtp.length == 6) {
      Future.delayed(const Duration(milliseconds: 250), _handleVerifyOtp);
    }
  }

  void _handleOtpBackspace(int index, RawKeyEvent event) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_otpControllers[index].text.isEmpty && index > 0) {
        _otpControllers[index - 1].clear();
        _otpFocusNodes[index - 1].requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: FadeTransition(
          opacity: _animController,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 64),

                _header(),

                const SizedBox(height: 38),

                Expanded(
                  child: _showOtpStep ? _otpStep() : _mobileStep(),
                ),

                const SizedBox(height: 18),
                const Text(
                  '© Khilonjiya India Pvt. Ltd.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Column(
      children: const [
        Text(
          'Job Seeker Login',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2563EB),
            letterSpacing: -0.4,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Find nearby jobs and apply instantly',
          style: TextStyle(
            fontSize: 14.5,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _mobileStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mobile number',
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _mobileController,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          decoration: InputDecoration(
            prefixText: '+91 ',
            hintText: 'Enter mobile number',
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.4),
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          Text(
            _error!,
            style: const TextStyle(
              color: Color(0xFFEF4444),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 26),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isMobileValid && !_isLoading ? _handleSendOtp : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              disabledBackgroundColor: const Color(0xFFE2E8F0),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Send OTP',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFDBEAFE)),
          ),
          child: Row(
            children: const [
              Icon(Icons.info_outline, size: 18, color: Color(0xFF2563EB)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Demo OTP is 123456 (Edge Function)',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF1E3A8A),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _otpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enter OTP',
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '+91 ${_mobileController.text.trim()}',
          style: const TextStyle(
            fontSize: 13.5,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) {
            return SizedBox(
              width: 46,
              height: 56,
              child: RawKeyboardListener(
                focusNode: FocusNode(),
                onKey: (event) => _handleOtpBackspace(i, event),
                child: TextField(
                  controller: _otpControllers[i],
                  focusNode: _otpFocusNodes[i],
                  maxLength: 1,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF2563EB),
                        width: 1.4,
                      ),
                    ),
                  ),
                  onChanged: (v) => _handleOtpChange(i, v),
                ),
              ),
            );
          }),
        ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          Text(
            _error!,
            style: const TextStyle(
              color: Color(0xFFEF4444),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleVerifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              disabledBackgroundColor: const Color(0xFFE2E8F0),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Verify & Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed:
              (_resendSeconds == 0 && !_isLoading) ? _handleSendOtp : null,
          child: Text(
            _resendSeconds == 0
                ? 'Resend OTP'
                : 'Resend in $_resendSeconds s',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: _resendSeconds == 0
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF94A3B8),
            ),
          ),
        ),
        const SizedBox(height: 6),
        TextButton(
          onPressed: _isLoading
              ? null
              : () {
                  setState(() {
                    _showOtpStep = false;
                    _error = null;
                  });
                },
          child: const Text(
            'Change mobile number',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }
}