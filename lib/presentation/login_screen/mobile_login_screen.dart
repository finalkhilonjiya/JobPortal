import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_export.dart';
import '../../core/auth/user_role.dart';
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
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(6, (_) => FocusNode());

  final _authService = MobileAuthService();

  UserRole _selectedRole = UserRole.jobSeeker;

  bool _isMobileValid = false;
  bool _isLoading = false;
  bool _canResend = false;

  int _step = 1;
  int _resendTimer = 0;
  int _resendAttempts = 0;

  String? _error;

  Timer? _timer;

  late final AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 500))
          ..forward();

    _mobileController.addListener(_validateMobile);
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    await _authService.initialize();
    if (_authService.isAuthenticated) {
      _navigateToHome();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _mobileController.dispose();
    _timer?.cancel();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _validateMobile() {
    setState(() {
      _isMobileValid =
          MobileAuthService.isValidMobileNumber(_mobileController.text);
      _error = null;
    });
  }

  Future<void> _sendOtp() async {
    if (!_isMobileValid || _isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _authService.sendOtp(_mobileController.text);

      setState(() {
        _step = 2;
        _isLoading = false;
        _resendAttempts++;
      });

      _startResendTimer();
      HapticFeedback.lightImpact();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e is MobileAuthException
            ? e.message
            : 'Failed to send OTP';
      });
    }
  }

  void _startResendTimer() {
    _resendTimer = 30;
    _canResend = false;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_resendTimer > 0) {
          _resendTimer--;
        } else {
          _canResend = true;
          t.cancel();
        }
      });
    });
  }

  Future<void> _verifyOtp() async {
    final otp = _otpControllers.map((e) => e.text).join();
    if (otp.length != 6) {
      setState(() => _error = 'Enter complete OTP');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.verifyOtp(_mobileController.text, otp);

      // 🔒 role already selected → later stored in user_profiles
      _navigateToHome();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e is MobileAuthException ? e.message : 'Invalid OTP';
      });
      _otpControllers.forEach((c) => c.clear());
      _otpFocusNodes.first.requestFocus();
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacementNamed(context, AppRoutes.homeJobsFeed);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeController,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 60),

                /// LOGO
                const Text(
                  'Khilonjiya',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2563EB),
                  ),
                ),

                const SizedBox(height: 8),
                const Text(
                  'India’s local job platform',
                  style: TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 48),

                Expanded(
                  child: _step == 1 ? _buildMobileStep() : _buildOtpStep(),
                ),

                const SizedBox(height: 24),
                const Text(
                  '© Khilonjiya India Pvt. Ltd.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ---------------- STEP 1 ----------------

  Widget _buildMobileStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _roleSelector(),
        const SizedBox(height: 24),

        const Text(
          'Mobile number',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),

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
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),

        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Colors.red)),
        ],

        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isMobileValid && !_isLoading ? _sendOtp : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'Send OTP',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }

  /// ---------------- STEP 2 ----------------

  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enter OTP',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          '+91 ${_mobileController.text}',
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) {
            return SizedBox(
              width: 44,
              child: TextField(
                controller: _otpControllers[i],
                focusNode: _otpFocusNodes[i],
                textAlign: TextAlign.center,
                maxLength: 1,
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  if (v.isNotEmpty && i < 5) {
                    _otpFocusNodes[i + 1].requestFocus();
                  }
                  if (_otpControllers.every((c) => c.text.isNotEmpty)) {
                    _verifyOtp();
                  }
                },
                decoration: const InputDecoration(counterText: ''),
              ),
            );
          }),
        ),

        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Colors.red)),
        ],

        const SizedBox(height: 24),

        TextButton(
          onPressed: _canResend && _resendAttempts < 3 ? _sendOtp : null,
          child: Text(
            _canResend
                ? 'Resend OTP'
                : 'Resend in $_resendTimer s',
          ),
        ),
      ],
    );
  }

  /// ---------------- ROLE SELECTOR ----------------

  Widget _roleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Continue as',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _roleTile(UserRole.jobSeeker, 'Job Seeker'),
            const SizedBox(width: 12),
            _roleTile(UserRole.employer, 'Employer'),
          ],
        ),
      ],
    );
  }

  Widget _roleTile(UserRole role, String label) {
    final selected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? const Color(0xFF2563EB) : Colors.grey.shade300,
            ),
            color: selected ? const Color(0xFFEFF6FF) : Colors.white,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected ? const Color(0xFF2563EB) : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}