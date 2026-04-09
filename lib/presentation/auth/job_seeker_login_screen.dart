// File: lib/presentation/auth/job_seeker_login_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sms_autofill/sms_autofill.dart';

import '../../routes/app_routes.dart';
import '../../core/auth/user_role.dart';
import '../../services/mobile_auth_service.dart';
import '../../services/location_service.dart';

class JobSeekerLoginScreen extends StatefulWidget {
  const JobSeekerLoginScreen({Key? key}) : super(key: key);

  @override
  State<JobSeekerLoginScreen> createState() =>
      _JobSeekerLoginScreenState();
}

class _JobSeekerLoginScreenState extends State<JobSeekerLoginScreen>
    with SingleTickerProviderStateMixin, CodeAutoFill {

  final _mobileController = TextEditingController();

  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(6, (_) => FocusNode());

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

    listenForCode();

    // ✅ APP HASH PRINT
    _printAppHash();
  }

  Future<void> _printAppHash() async {
    final signature = await SmsAutoFill().getAppSignature;
    debugPrint("APP HASH: $signature");
  }

  @override
  void dispose() {
    SmsAutoFill().unregisterListener();
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

  @override
  void codeUpdated() {
    if (code == null) return;

    final otp = code!.replaceAll(RegExp(r'[^0-9]'), '');

    if (otp.length == 6) {
      for (int i = 0; i < 6; i++) {
        _otpControllers[i].text = otp[i];
      }

      Future.delayed(const Duration(milliseconds: 200), () {
        _handleVerifyOtp();
      });
    }
  }

  void _validateMobile() {
    final value = _mobileController.text.trim();
    final valid = MobileAuthService.isValidMobileNumber(value);

    setState(() {
      _isMobileValid = valid;
      _error = null;
    });
  }

  Future<void> _handleSendOtp() async {
    if (!_isMobileValid || _isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _auth.sendOtp(
        mobile: _mobileController.text.trim(),
        role: UserRole.jobSeeker,
      );

      setState(() {
        _showOtpStep = true;
        _isLoading = false;
      });

      _startResendTimer();
      _clearOtp();
      _otpFocusNodes.first.requestFocus();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to send OTP';
      });
    }
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _resendSeconds = 30);

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
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

    if (otp.length != 6) return;

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

      await LocationService.collectAndSaveLocation();

      if (!mounted) return;

      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Invalid OTP';
      });

      _clearOtp();
    }
  }

  void _handleOtpChange(int index, String value) {
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length == 6) {
        for (int i = 0; i < 6; i++) {
          _otpControllers[i].text = digits[i];
        }
        Future.delayed(const Duration(milliseconds: 200), _handleVerifyOtp);
      }
      return;
    }

    if (value.isNotEmpty && index < 5) {
      _otpFocusNodes[index + 1].requestFocus();
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
                const SizedBox(height: 12),

                // BACK BUTTON DISABLED
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                ),

                const SizedBox(height: 26),

                _header(),

                const SizedBox(height: 38),

                Expanded(
                  child: _showOtpStep ? _otpStep() : _mobileStep(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= HEADER =================
  Widget _header() {
    return const Column(
      children: [
        Text(
          'Khilonjiya Login',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // ================= MOBILE =================
  Widget _mobileStep() {
    return Column(
      children: [
        TextField(
          controller: _mobileController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(hintText: 'Enter mobile'),
        ),
        ElevatedButton(
          onPressed: _handleSendOtp,
          child: const Text('Send OTP'),
        ),
      ],
    );
  }

  // ================= OTP =================
  Widget _otpStep() {
    return Column(
      children: [
        Row(
          children: List.generate(6, (i) {
            return Expanded(
              child: TextField(
                controller: _otpControllers[i],
                focusNode: _otpFocusNodes[i],
                maxLength: 1,
                textAlign: TextAlign.center,
                autofillHints: const [AutofillHints.oneTimeCode],
                onChanged: (v) => _handleOtpChange(i, v),
              ),
            );
          }),
        ),
        ElevatedButton(
          onPressed: _handleVerifyOtp,
          child: const Text('Verify'),
        ),
      ],
    );
  }
}