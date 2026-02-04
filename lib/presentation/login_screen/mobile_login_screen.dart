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

class _MobileLoginScreenState extends State<MobileLoginScreen> {
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();

  final _auth = MobileAuthService();

  UserRole _role = UserRole.jobSeeker;
  bool _otpSent = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _mobileController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!MobileAuthService.isValidMobileNumber(_mobileController.text)) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_user_role', _role.name);

    try {
      await _auth.sendOtp(_mobileController.text);
      setState(() => _otpSent = true);
    } catch (_) {
      _error = 'Failed to send OTP';
    }

    setState(() => _loading = false);
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _auth.verifyOtp(_mobileController.text, _otpController.text);
      Navigator.pushReplacementNamed(context, AppRoutes.homeJobsFeed);
    } catch (e) {
      _error = 'Invalid OTP';
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Khilonjiya', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),

            if (!_otpSent) ...[
              Row(
                children: [
                  _roleButton(UserRole.jobSeeker, 'Job Seeker'),
                  const SizedBox(width: 12),
                  _roleButton(UserRole.employer, 'Employer'),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Mobile Number'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loading ? null : _sendOtp,
                child: const Text('Send OTP'),
              ),
            ] else ...[
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Enter OTP'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loading ? null : _verifyOtp,
                child: const Text('Verify OTP'),
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ]
          ],
        ),
      ),
    );
  }

  Widget _roleButton(UserRole role, String label) {
    final selected = _role == role;
    return Expanded(
      child: OutlinedButton(
        onPressed: () => setState(() => _role = role),
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? Colors.blue.shade50 : null,
        ),
        child: Text(label),
      ),
    );
  }
}