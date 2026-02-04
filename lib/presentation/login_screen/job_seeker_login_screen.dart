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
  final mobileController = TextEditingController();
  final otpControllers = List.generate(6, (_) => TextEditingController());
  final otpFocus = List.generate(6, (_) => FocusNode());

  bool showOtp = false;
  int resend = 0;
  Timer? timer;

  void sendOtp() {
    setState(() {
      showOtp = true;
      resend = 30;
    });

    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (resend == 0) {
        t.cancel();
      } else {
        setState(() => resend--);
      }
    });

    HapticFeedback.lightImpact();
  }

  void verifyOtp() {
    final otp = otpControllers.map((e) => e.text).join();
    if (otp != '123456') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP')),
      );
      return;
    }

    Navigator.pushReplacementNamed(context, AppRoutes.homeJobsFeed);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 80),
              const Text(
                'Job Seeker Login',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(height: 40),

              TextField(
                controller: mobileController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: InputDecoration(
                  prefixText: '+91 ',
                  labelText: 'Mobile Number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              if (!showOtp)
                ElevatedButton(
                  onPressed: sendOtp,
                  child: const Text('Send OTP'),
                ),

              if (showOtp) ...[
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (i) {
                    return SizedBox(
                      width: 44,
                      child: TextField(
                        controller: otpControllers[i],
                        focusNode: otpFocus[i],
                        maxLength: 1,
                        textAlign: TextAlign.center,
                        decoration:
                            const InputDecoration(counterText: ''),
                        onChanged: (v) {
                          if (v.isNotEmpty && i < 5) {
                            otpFocus[i + 1].requestFocus();
                          }
                          if (otpControllers.every((c) => c.text.isNotEmpty)) {
                            verifyOtp();
                          }
                        },
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                Text(resend == 0
                    ? 'Resend OTP'
                    : 'Resend in $resend s'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}