import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/anim.dart';
import '../../core/config.dart';
import '../../core/constants.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../services/api.dart';
import '../../widgets/common.dart';
import '../../widgets/housing_mark.dart';
import '../../widgets/ui.dart';

class LoginScreen extends StatefulWidget {
  final String reason;
  const LoginScreen({super.key, this.reason = 'Log in to continue'});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  bool _otpStep = false;
  bool _busy = false;
  String? _error;
  int _left = 0;
  Timer? _timer;

  String get _full => normalizePhone(_phone.text);

  void _startTimer() {
    _left = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _left--);
      if (_left <= 0) t.cancel();
    });
  }

  Future<void> _send() async {
    final d = digitsOnly(_phone.text);
    if (d.length != 10) {
      setState(() => _error = 'Enter a valid 10-digit mobile number.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await Api.sendOtp(_full);
      if (!mounted) return;
      setState(() {
        _otpStep = true;
        _busy = false;
      });
      _startTimer();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = errText(e);
      });
    }
  }

  Future<void> _verify() async {
    if (_otp.text.length < 6) {
      setState(() => _error = 'Enter the 6-digit code.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await Api.verifyOtp(_full, _otp.text.trim());
      final p = await Api.bootstrap();
      if (!mounted) return;
      if (p != null && !p.onboarded) {
        await Navigator.of(context).push(fadeRoute(const ProfileSetupScreen()));
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = errText(e);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phone.dispose();
    _otp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(26, 0, 26, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeSlideIn(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: AppColors.brand,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: const [BoxShadow(color: Color(0x40F26B0F), blurRadius: 20, offset: Offset(0, 10))],
                        ),
                        child: const Center(child: HousingMark(size: 44)),
                      ),
                    ),
                    const SizedBox(height: 26),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 80),
                      child: Text(_otpStep ? 'Verify your number' : 'Welcome to ${AppInfo.name}', style: AppText.h1),
                    ),
                    const SizedBox(height: 8),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 140),
                      child: Text(
                        _otpStep ? 'We sent a 6-digit code to ${AppInfo.countryCode} ${digitsOnly(_phone.text)}' : widget.reason,
                        style: AppText.bodyM,
                      ),
                    ),
                    const SizedBox(height: 30),
                    if (!_otpStep) ...[
                      TextField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 1.2),
                        decoration: inputDeco('Mobile number', prefixText: '${AppInfo.countryCode}  ').copyWith(counterText: ''),
                        onSubmitted: (_) => _send(),
                      ),
                    ] else ...[
                      TextField(
                        controller: _otp,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        autofocus: true,
                        textAlign: TextAlign.center,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: 12),
                        decoration: inputDeco('------').copyWith(counterText: ''),
                        onSubmitted: (_) => _verify(),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () => setState(() {
                                      _otpStep = false;
                                      _otp.clear();
                                      _error = null;
                                    }),
                            child: const Text('Change number'),
                          ),
                          TextButton(
                            onPressed: (_left > 0 || _busy) ? null : _send,
                            child: Text(_left > 0 ? 'Resend in ${_left}s' : 'Resend code'),
                          ),
                        ],
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.dangerSoft, borderRadius: BorderRadius.circular(12)),
                        child: Row(children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13))),
                        ]),
                      ),
                    ],
                    const SizedBox(height: 22),
                    FilledButton(
                      onPressed: _busy ? null : (_otpStep ? _verify : _send),
                      child: _busy
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                          : Text(_otpStep ? 'Verify and continue' : 'Send code'),
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Continue browsing'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'By continuing you agree to our Terms and Privacy Policy.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11.5, color: AppColors.text3),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// First-login profile: name + role (+ agency details for agents/builders).
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _name = TextEditingController();
  final _agency = TextEditingController();
  String _role = 'tenant';
  bool _busy = false;

  Future<void> _save() async {
    if (_name.text.trim().length < 2) {
      toast(context, 'Please enter your name.');
      return;
    }
    setState(() => _busy = true);
    try {
      await Api.saveProfile({
        'full_name': _name.text.trim(),
        'role': _role,
        if (kProRoles.contains(_role)) 'agency_name': _agency.text.trim(),
        'onboarded': true,
      });
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      toast(context, errText(e));
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _agency.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pro = kProRoles.contains(_role);
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tell us about you', style: AppText.h1),
                const SizedBox(height: 8),
                const Text('This helps owners and tenants know who they are talking to.', style: AppText.bodyM),
                const SizedBox(height: 26),
                const FormLabel('Your name'),
                TextField(controller: _name, textCapitalization: TextCapitalization.words, decoration: inputDeco('Full name', icon: Icons.person_outline_rounded)),
                const SizedBox(height: 18),
                const FormLabel('I am a'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: kRoles
                      .map((r) => _RoleChip(label: kRoleLabel[r] ?? r, selected: _role == r, onTap: () => setState(() => _role = r)))
                      .toList(),
                ),
                if (pro) ...[
                  const SizedBox(height: 18),
                  const FormLabel('Agency / company name'),
                  TextField(controller: _agency, decoration: inputDeco('e.g. Das Realty', icon: Icons.business_rounded)),
                ],
                const SizedBox(height: 30),
                FilledButton(
                  onPressed: _busy ? null : _save,
                  child: _busy
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                      : const Text('Continue'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RoleChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.primary : AppColors.line),
        ),
        child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.text2)),
      ),
    );
  }
}
