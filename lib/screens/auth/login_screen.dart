import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/config.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../services/favorites_store.dart';
import '../../widgets/common.dart';

/// Returns true if the user is (now) logged in, otherwise opens the login screen.
Future<bool> requireLogin(BuildContext context) async {
  if (AuthService.isLoggedIn) return true;
  final result = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const LoginScreen(),
    ),
  );
  return result == true;
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  bool _otpSent = false;
  bool _busy = false;
  String _phone = '';
  int _cooldown = 0;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _startCooldown() async {
    setState(() => _cooldown = 30);
    while (mounted && _cooldown > 0) {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() => _cooldown--);
    }
  }

  Future<void> _sendOtp() async {
    final digits = digitsOnly(_phoneCtrl.text);
    if (digits.length != 10) {
      showSnack(context, 'Enter a valid 10-digit mobile number', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      _phone = await AuthService.sendOtp(digits);
      if (!mounted) return;
      setState(() {
        _otpSent = true;
        _busy = false;
      });
      _startCooldown();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showSnack(context, 'Could not send OTP. Please try again.', error: true);
    }
  }

  Future<void> _verify() async {
    final code = _otpCtrl.text.trim();
    if (code.length != 6) {
      showSnack(context, 'Enter the 6-digit OTP', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      await AuthService.verifyOtp(_phone, code);
      await FavoritesStore.instance.load();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showSnack(context, 'Invalid or expired OTP', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.ink,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.home_work_rounded,
                    size: 34, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              Text(
                _otpSent ? 'Verify your number' : 'Welcome to ${AppInfo.name}',
                style: AppText.display,
              ),
              const SizedBox(height: 8),
              Text(
                _otpSent
                    ? 'Enter the 6-digit code sent to $_phone'
                    : 'Log in to shortlist homes, contact owners and post your own property.',
                style: AppText.body,
              ),
              const SizedBox(height: 32),
              if (!_otpSent) ...[
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: AppText.h3,
                  decoration: inputDeco('Mobile number',
                          hint: '98765 43210', prefixText: '${AppInfo.countryCode}  ')
                      .copyWith(counterText: ''),
                  onSubmitted: (_) => _sendOtp(),
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'Send OTP',
                  loading: _busy,
                  onPressed: _sendOtp,
                ),
              ] else ...[
                TextField(
                  controller: _otpCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: AppText.h1.copyWith(letterSpacing: 10),
                  decoration: inputDeco('OTP').copyWith(counterText: ''),
                  onSubmitted: (_) => _verify(),
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'Verify & continue',
                  loading: _busy,
                  onPressed: _verify,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => setState(() {
                        _otpSent = false;
                        _otpCtrl.clear();
                      }),
                      child: const Text('Change number'),
                    ),
                    TextButton(
                      onPressed: _cooldown > 0 || _busy ? null : _sendOtp,
                      child: Text(_cooldown > 0
                          ? 'Resend in ${_cooldown}s'
                          : 'Resend OTP'),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 28),
              Text(
                'By continuing you agree to our Terms of Use and Privacy Policy.',
                style: AppText.small,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
