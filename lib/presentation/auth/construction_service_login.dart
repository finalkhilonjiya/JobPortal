import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../routes/app_routes.dart';
import '../../core/auth/user_role.dart';
import '../../services/mobile_auth_service.dart';
import 'package:sms_autofill/sms_autofill.dart';

class ConstructionServiceLogin extends StatefulWidget {
  const ConstructionServiceLogin({Key? key}) : super(key: key);

  @override
  State<ConstructionServiceLogin> createState() =>
      _ConstructionServiceLoginState();
}

class _ConstructionServiceLoginState
    extends State<ConstructionServiceLogin>
    with SingleTickerProviderStateMixin, CodeAutoFill {
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

  static const Color _primary = Color(0xFFF59E0B); // 🔶 ORANGE

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..forward();

    _mobileController.addListener(_validateMobile);
    listenForCode();
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

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _auth.sendOtp(
        mobile: _mobileController.text.trim(),
        role: UserRole.construction,
      );

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
        role: UserRole.construction,
      );

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        AppRoutes.constructionHome,
      );
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
        Future.delayed(const Duration(milliseconds: 250), _handleVerifyOtp);
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

  void _goBack() {
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
                    onPressed: _goBack,
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                ),

                const SizedBox(height: 26),

                const Text(
                  'Construction Login',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: _primary,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Access construction services and manage projects',
                  style: TextStyle(
                    fontSize: 14.5,
                    color: Color(0xFF64748B),
                  ),
                ),

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

  Widget _mobileStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mobile number',
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
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
          Text(_error!, style: const TextStyle(color: Colors.red)),
        ],

        const SizedBox(height: 26),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isMobileValid ? _handleSendOtp : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
            ),
            child: const Text('Send OTP'),
          ),
        ),
      ],
    );
  }

  Widget _otpStep() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) {
            return SizedBox(
              width: 46,
              height: 56,
              child: RawKeyboardListener(
                focusNode: FocusNode(),
                onKey: (e) => _handleOtpBackspace(i, e),
                child: TextField(
                  controller: _otpControllers[i],
                  focusNode: _otpFocusNodes[i],
                  maxLength: 1,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _handleOtpChange(i, v),
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 22),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _handleVerifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
            ),
            child: const Text('Verify & Continue'),
          ),
        ),
      ],
    );
  }
}