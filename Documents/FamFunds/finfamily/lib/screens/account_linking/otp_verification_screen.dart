import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../routes/app_routes.dart';

/// Step 2 — mobile number + OTP verification.
/// Mock equivalent of Setu FIP-2's static OTP (123456), so demo day
/// doesn't depend on real SMS delivery.
class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _isLoading = false;
  String? _error;

  static const _mockOtp = '123456'; // matches Setu FIP-2 sandbox behavior

  void _sendOtp() {
    if (_mobileController.text.trim().length != 10) {
      setState(() => _error = 'Enter a valid 10-digit mobile number');
      return;
    }
    setState(() {
      _otpSent = true;
      _error = null;
    });
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.trim() != _mockOtp) {
      setState(() => _error = 'Incorrect OTP. Use 123456 for this demo.');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    // TODO: call Cloud Function `createMockConsent` here, store consent id
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pushNamed(context, AppRoutes.selectAccounts);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Mobile Number')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _mobileController,
              enabled: !_otpSent,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: const InputDecoration(
                labelText: 'Mobile number',
                prefixText: '+91  ',
              ),
            ),
            if (_otpSent) ...[
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Enter OTP',
                  helperText: 'Sandbox OTP: 123456',
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_error!, style: const TextStyle(color: AppColors.accentRed, fontSize: 13)),
            ],
            const SizedBox(height: AppSpacing.lg),
            FFPrimaryButton(
              label: _otpSent ? 'Verify & Continue' : 'Send OTP',
              isLoading: _isLoading,
              onPressed: _otpSent ? _verifyOtp : _sendOtp,
            ),
          ],
        ),
      ),
    );
  }
}
