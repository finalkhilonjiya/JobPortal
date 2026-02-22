import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../routes/app_routes.dart';
import '../../core/auth/user_role.dart';
import '../../services/mobile_auth_service.dart';
import '../../services/location_service.dart'; // ✅ Added

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

      // ✅ Collect GPS after successful login
      await LocationService.ensureFreshLocation();

      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e is MobileAuthException ? e.message : 'Invalid OTP';
      });

      _clearOtp();
      _otpFocusNodes.first.requestFocus();
    }
  }

  void _goBackToRoleSelection() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.roleSelection,
      (_) => false,
    );
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
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: _goBackToRoleSelection,
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: const Color(0xFF0F172A),
                    splashRadius: 22,
                  ),
                ),
                const SizedBox(height: 26),
                _header(),
                const SizedBox(height: 38),
                Expanded(
                  child: _showOtpStep ? _otpStep() : _mobileStep(),
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
    return const Column(
      children: [
        Text(
          'Khilonjiya Login', // ✅ Renamed
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2563EB),
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
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
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
          height: 40, // ✅ Changed height to 40
          child: ElevatedButton(
            onPressed: _isMobileValid && !_isLoading ? _handleSendOtp : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Send OTP',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _otpStep() {
    return Column(
      children: [
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 40, // ✅ Changed height to 40
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleVerifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Verify & Continue',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}