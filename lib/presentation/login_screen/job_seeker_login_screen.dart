import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../routes/app_routes.dart';

class JobSeekerLoginScreen extends StatefulWidget {
  const JobSeekerLoginScreen({Key? key}) : super(key: key);

  @override
  State<JobSeekerLoginScreen> createState() => _JobSeekerLoginScreenState();
}

class _JobSeekerLoginScreenState extends State<JobSeekerLoginScreen> {
  final TextEditingController _mobileController = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(6, (_) => FocusNode());

  bool _isMobileValid = false;
  bool _showOtp = false;
  int _resendSeconds = 0;

  Timer? _timer;

  @override
  void dispose() {
    _mobileController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _validateMobile() {
    final value = _mobileController.text.trim();
    setState(() {
      _isMobileValid = value.length == 10 && value[0] != '0';
    });
  }

  void _sendOtp() {
    if (!_isMobileValid) return;

    setState(() {
      _showOtp = true;
      _resendSeconds = 30;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendSeconds == 0) {
        t.cancel();
      } else {
        setState(() => _resendSeconds--);
      }
    });

    HapticFeedback.lightImpact();
  }

  void _verifyOtp() {
    final otp = _otpControllers.map((e) => e.text).join();
    if (otp != '123456') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid OTP'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.pushReplacementNamed(
      context,
      AppRoutes.homeJobsFeed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 72),

              const Text(
                'Job Seeker Login',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2563EB),
                ),
              ),

              const SizedBox(height: 12),
              const Text(
                'Find jobs near you instantly',
                style: TextStyle(color: Color(0xFF64748B)),
              ),

              const SizedBox(height: 48),

              TextField(
                controller: _mobileController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                onChanged: (_) => _validateMobile(),
                decoration: InputDecoration(
                  prefixText: '+91 ',
                  labelText: 'Mobile Number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              if (!_showOtp)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isMobileValid ? _sendOtp : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Send OTP',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              if (_showOtp) ...[
                const SizedBox(height: 32),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (i) {
                    return SizedBox(
                      width: 44,
                      child: TextField(
                        controller: _otpControllers[i],
                        focusNode: _otpFocusNodes[i],
                        maxLength: 1,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(counterText: ''),
                        onChanged: (v) {
                          if (v.isNotEmpty && i < 5) {
                            _otpFocusNodes[i + 1].requestFocus();
                          }
                          if (_otpControllers
                              .every((c) => c.text.isNotEmpty)) {
                            _verifyOtp();
                          }
                        },
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 24),

                TextButton(
                  onPressed: _resendSeconds == 0 ? _sendOtp : null,
                  child: Text(
                    _resendSeconds == 0
                        ? 'Resend OTP'
                        : 'Resend in $_resendSeconds s',
                  ),
                ),
              ],

              const Spacer(),

              const Text(
                '© Khilonjiya India Pvt. Ltd.',
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}