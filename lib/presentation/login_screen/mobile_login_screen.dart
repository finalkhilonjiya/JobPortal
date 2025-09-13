// mobile_login_screen.dart
import 'package:flutter/material.dart';
import 'mobile_auth_service.dart';

class MobileLoginScreen extends StatefulWidget {
  const MobileLoginScreen({Key? key}) : super(key: key);

  @override
  _MobileLoginScreenState createState() => _MobileLoginScreenState();
}

class _MobileLoginScreenState extends State<MobileLoginScreen> {
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final MobileAuthService _authService = MobileAuthService();

  bool _otpSent = false;
  bool _isMobileValid = false;

  @override
  void dispose() {
    _mobileController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final connected = await _authService.checkConnection();
    if (!connected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No connection"))
        );
      }
      return;
    }

    final success = await _authService.sendOtp(_mobileController.text);
    if (mounted) {
      if (success) {
        setState(() => _otpSent = true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to send OTP"))
        );
      }
    }
  }

  Future<void> _verifyOtp() async {
    final valid = await _authService.refreshSession();
    if (!valid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Session invalid"))
        );
      }
      return;
    }

    final success = await _authService.verifyOtp(_mobileController.text, _otpController.text);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login successful"))
        );
        // Navigate to next screen or handle successful login
        Navigator.of(context).pushReplacementNamed('/dashboard');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid OTP"))
        );
      }
    }
  }

  void _resetOtp() {
    setState(() {
      _otpSent = false;
      _otpController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mobile Login"),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            Icon(
              Icons.phone_android,
              size: 80,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 20),
            Text(
              _otpSent ? "Enter OTP" : "Enter Mobile Number",
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              _otpSent 
                ? "We've sent a verification code to ${_mobileController.text}"
                : "We'll send you a verification code",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _mobileController,
              enabled: !_otpSent,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: "Mobile Number",
                prefixText: "+91 ",
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _isMobileValid 
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
              ),
              onChanged: (v) {
                setState(() {
                  _isMobileValid = MobileAuthService.isValidMobileNumber(v);
                });
              },
            ),
            if (_otpSent) ...[
              const SizedBox(height: 20),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: "Enter OTP",
                  hintText: "123456",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  counterText: "",
                ),
              ),
            ],
            const SizedBox(height: 30),
            !_otpSent
                ? ElevatedButton(
                    onPressed: _isMobileValid ? _sendOtp : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Send OTP",
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : Column(
                    children: [
                      ElevatedButton(
                        onPressed: _otpController.text.isNotEmpty ? _verifyOtp : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Verify OTP",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Didn't receive the code?"),
                          TextButton(
                            onPressed: _sendOtp,
                            child: const Text("Resend"),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: _resetOtp,
                        child: const Text("Change Number"),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}