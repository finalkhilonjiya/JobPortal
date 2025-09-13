import 'package:flutter/material.dart';
import 'mobile_auth_service.dart';

class MobileLoginScreen extends StatefulWidget {
  @override
  _MobileLoginScreenState createState() => _MobileLoginScreenState();
}

class _MobileLoginScreenState extends State<MobileLoginScreen> {
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final MobileAuthService _authService = MobileAuthService();

  bool _otpSent = false;
  bool _isMobileValid = false;

  Future<void> _sendOtp() async {
    final connected = await _authService.checkConnection();
    if (!connected) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("No connection")));
      return;
    }

    final success = await _authService.sendOtp(_mobileController.text);
    if (success) {
      setState(() => _otpSent = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to send OTP")));
    }
  }

  Future<void> _verifyOtp() async {
    final valid = await _authService.refreshSession();
    if (!valid) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Session invalid")));
      return;
    }

    final success = await _authService.verifyOtp(_mobileController.text, _otpController.text);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Login successful")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Invalid OTP")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Mobile Login")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: "Mobile Number"),
              onChanged: (v) {
                setState(() {
                  _isMobileValid = MobileAuthService.isValidMobileNumber(v);
                });
              },
            ),
            if (_otpSent)
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Enter OTP"),
              ),
            const SizedBox(height: 20),
            !_otpSent
                ? ElevatedButton(
                    onPressed: _isMobileValid ? _sendOtp : null,
                    child: Text("Send OTP"),
                  )
                : ElevatedButton(
                    onPressed: _verifyOtp,
                    child: Text("Verify OTP"),
                  ),
          ],
        ),
      ),
    );
  }
}