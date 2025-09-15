// lib/presentation/login_screen/mobile_login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'mobile_auth_service.dart';
import '../../core/navigation_service.dart';
import '../../core/app_export.dart';

class MobileLoginScreen extends StatefulWidget {
  const MobileLoginScreen({Key? key}) : super(key: key);

  @override
  State<MobileLoginScreen> createState() => _MobileLoginScreenState();
}

class _MobileLoginScreenState extends State<MobileLoginScreen> {
  final TextEditingController _mobileController = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());

  final MobileAuthService _authService = MobileAuthService();
  bool _otpSent = false;
  bool _loading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await _authService.initialize();
      if (_authService.isAuthenticated) {
        final valid = await _authService.refreshSession();
        if (valid) {
          NavigationService.pushReplacementNamed(AppRoutes.homeMarketplaceFeed);
        }
      }
    } catch (e) {
      debugPrint('Auth bootstrap error: $e');
    }
  }

  Future<void> _sendOtp() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      if (!MobileAuthService.isValidMobileNumber(_mobileController.text)) {
        throw MobileAuthException('Enter a valid 10-digit mobile number');
      }

      final response = await _authService.sendOtp(_mobileController.text);
      if (response.success) {
        setState(() => _otpSent = true);
      } else {
        setState(() => _errorMessage = response.message);
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            e is MobileAuthException ? e.message : 'Failed to send OTP';
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final otp = _otpControllers.map((c) => c.text).join();
      final result =
          await _authService.verifyOtp(_mobileController.text, otp);
      if (result.success) {
        NavigationService.pushReplacementNamed(AppRoutes.homeMarketplaceFeed);
      } else {
        setState(() => _errorMessage = result.message);
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            e is MobileAuthException ? e.message : 'Invalid OTP entered';
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Login with Mobile",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                if (!_otpSent) _buildMobileField(),
                if (_otpSent) _buildOtpFields(),
                const SizedBox(height: 16),
                if (_errorMessage != null)
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loading
                      ? null
                      : _otpSent
                          ? _verifyOtp
                          : _sendOtp,
                  child: _loading
                      ? const CircularProgressIndicator()
                      : Text(_otpSent ? "Verify OTP" : "Send OTP"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileField() {
    return TextField(
      controller: _mobileController,
      keyboardType: TextInputType.phone,
      decoration: const InputDecoration(
        labelText: 'Mobile Number',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildOtpFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        return Container(
          width: 40,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: TextField(
            controller: _otpControllers[index],
            maxLength: 1,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              counterText: '',
              filled: _otpControllers[index].text.isNotEmpty, // ✅ only once
              border: const OutlineInputBorder(),
            ),
            onChanged: (val) {
              if (val.isNotEmpty && index < 5) {
                FocusScope.of(context).nextFocus();
              }
            },
          ),
        );
      }),
    );
  }
}