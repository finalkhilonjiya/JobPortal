import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class OtpVerificationWidget extends StatefulWidget {
  final String contactMethod;
  final String contactValue;
  final VoidCallback onVerified;
  final VoidCallback onResend;

  const OtpVerificationWidget({
    Key? key,
    required this.contactMethod,
    required this.contactValue,
    required this.onVerified,
    required this.onResend,
  }) : super(key: key);

  @override
  State<OtpVerificationWidget> createState() => _OtpVerificationWidgetState();
}

class _OtpVerificationWidgetState extends State<OtpVerificationWidget> {
  final List<TextEditingController> _controllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  bool _isVerifying = false;
  bool _canResend = false;
  int _resendTimer = 60;

  String get _maskedContact {
    if (widget.contactMethod == 'email') {
      final parts = widget.contactValue.split('@');
      if (parts.length == 2) {
        final username = parts[0];
        final domain = parts[1];
        final maskedUsername = username.length > 2
            ? '${username.substring(0, 2)}${'*' * (username.length - 2)}'
            : username;
        return '$maskedUsername@$domain';
      }
    } else {
      if (widget.contactValue.length > 4) {
        return '${widget.contactValue.substring(0, 2)}${'*' * (widget.contactValue.length - 4)}${widget.contactValue.substring(widget.contactValue.length - 2)}';
      }
    }
    return widget.contactValue;
  }

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    setState(() {
      _canResend = false;
      _resendTimer = 60;
    });

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _resendTimer--;
        });
        if (_resendTimer <= 0) {
          setState(() {
            _canResend = true;
          });
          return false;
        }
        return true;
      }
      return false;
    });
  }

  void _onDigitChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _verifyOtp();
      }
    }
  }

  void _onBackspace(int index) {
    if (index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
    }
  }

  String get _enteredOtp {
    return _controllers.map((controller) => controller.text).join();
  }

  bool get _isOtpComplete {
    return _enteredOtp.length == 6;
  }

  Future<void> _verifyOtp() async {
    if (!_isOtpComplete) return;

    setState(() {
      _isVerifying = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    // Mock verification - accept "123456" as valid OTP
    if (_enteredOtp == "123456") {
      widget.onVerified();
    } else {
      _showErrorDialog();
    }

    setState(() {
      _isVerifying = false;
    });
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invalid OTP'),
        content: const Text(
            'The verification code you entered is incorrect. Please try again.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearOtp();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _clearOtp() {
    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  void _handleResend() {
    widget.onResend();
    _startResendTimer();
    _clearOtp();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          SizedBox(height: 4.h),

          // Illustration
          Container(
            width: 30.w,
            height: 30.w,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primary
                  .withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: CustomIconWidget(
              iconName: widget.contactMethod == 'email' ? 'email' : 'sms',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 60,
            ),
          ),

          SizedBox(height: 4.h),

          // Instructions
          Text(
            'Enter Verification Code',
            style: AppTheme.lightTheme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 1.h),

          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              children: [
                const TextSpan(text: 'We sent a 6-digit code to\n'),
                TextSpan(
                  text: _maskedContact,
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 4.h),

          // OTP Input Fields
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(6, (index) {
              return SizedBox(
                width: 12.w,
                child: TextFormField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  style: AppTheme.lightTheme.textTheme.headlineSmall,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    counterText: '',
                    contentPadding: EdgeInsets.symmetric(vertical: 4.w),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.lightTheme.colorScheme.outline,
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: AppTheme.lightTheme.colorScheme.surface,
                  ),
                  onChanged: (value) => _onDigitChanged(value, index),
                  onTap: () {
                    _controllers[index].selection = TextSelection.fromPosition(
                      TextPosition(offset: _controllers[index].text.length),
                    );
                  },
                  onFieldSubmitted: (value) {
                    if (value.isEmpty && index > 0) {
                      _onBackspace(index);
                    }
                  },
                ),
              );
            }),
          ),

          SizedBox(height: 4.h),

          // Verify Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isOtpComplete && !_isVerifying ? _verifyOtp : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isOtpComplete
                    ? AppTheme.lightTheme.colorScheme.primary
                    : AppTheme.lightTheme.colorScheme.outline
                        .withValues(alpha: 0.3),
                foregroundColor: _isOtpComplete
                    ? Colors.white
                    : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              child: _isVerifying
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Verify Code'),
            ),
          ),

          SizedBox(height: 3.h),

          // Resend Section
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Didn't receive the code? ",
                style: AppTheme.lightTheme.textTheme.bodyMedium,
              ),
              GestureDetector(
                onTap: _canResend ? _handleResend : null,
                child: Text(
                  _canResend ? 'Resend' : 'Resend in ${_resendTimer}s',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: _canResend
                        ? AppTheme.lightTheme.colorScheme.primary
                        : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // Help text
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primary
                  .withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.primary
                    .withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'info',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 16,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'For testing purposes, use "123456" as the verification code.',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
