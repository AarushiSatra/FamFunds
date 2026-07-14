import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';

/// Shown immediately after sign-up. Enrolls a phone number as the
/// account's required second factor before the user can reach /home.
class MfaEnrollScreen extends StatefulWidget {
  const MfaEnrollScreen({super.key});

  @override
  State<MfaEnrollScreen> createState() => _MfaEnrollScreenState();
}

class _MfaEnrollScreenState extends State<MfaEnrollScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();

  String? _verificationId;
  bool _codeSent = false;
  bool _isLoading = false;
  String? _error;

  Future<void> _sendCode() async {
    final digits = _phoneController.text.trim();
    if (digits.length != 10) {
      setState(() => _error = 'Enter a valid 10-digit mobile number');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await AuthService.instance.startPhoneEnrollment(
        phoneNumber: '+91$digits',
        onCodeSent: (verificationId) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _codeSent = true;
            _isLoading = false;
          });
        },
        onError: (e) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _error = e.message ?? 'Could not send code. Try again.';
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Something went wrong. Try again.';
      });
    }
  }

  Future<void> _confirmCode() async {
    if (_verificationId == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await AuthService.instance.confirmPhoneEnrollment(
        verificationId: _verificationId!,
        smsCode: _codeController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.message ?? 'Incorrect code. Try again.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Incorrect code. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set up two-factor login')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Add your phone number. We\'ll text a code every time you '
              'sign in, in addition to your password.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _phoneController,
              enabled: !_codeSent,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: const InputDecoration(
                labelText: 'Mobile number',
                prefixText: '+91  ',
              ),
            ),
            if (_codeSent) ...[
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(labelText: 'Enter OTP'),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.accentRed, fontSize: 13),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            FFPrimaryButton(
              label: _codeSent ? 'Verify & finish setup' : 'Send code',
              isLoading: _isLoading,
              onPressed: _codeSent ? _confirmCode : _sendCode,
            ),
          ],
        ),
      ),
    );
  }
}