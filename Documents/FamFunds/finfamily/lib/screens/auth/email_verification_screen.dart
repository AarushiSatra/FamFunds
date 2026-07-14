import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../services/auth_service.dart';
import 'mfa_enroll_screen.dart';

/// Shown right after sign-up. Firebase requires a verified email before
/// a second factor can be enrolled (otherwise someone could register
/// with an email they don't own and lock the real owner out).
class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isChecking = false;
  bool _isResending = false;
  String? _error;
  String? _info;

  @override
  void initState() {
    super.initState();
    _sendInitialLink();
  }

  Future<void> _sendInitialLink() async {
    await AuthService.instance.sendEmailVerification();
  }

  Future<void> _resendLink() async {
    setState(() {
      _isResending = true;
      _error = null;
      _info = null;
    });
    try {
      await AuthService.instance.sendEmailVerification();
      setState(() {
        _isResending = false;
        _info = 'Verification email sent again.';
      });
    } catch (e) {
      setState(() {
        _isResending = false;
        _error = 'Could not resend email. Try again in a moment.';
      });
    }
  }

  Future<void> _checkVerified() async {
    setState(() {
      _isChecking = true;
      _error = null;
      _info = null;
    });
    final verified = await AuthService.instance.checkEmailVerified();
    if (!mounted) return;
    if (verified) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MfaEnrollScreen()),
      );
    } else {
      setState(() {
        _isChecking = false;
        _error = 'Not verified yet. Click the link in your email, then try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = AuthService.instance.currentUser?.email ?? 'your email';
    return Scaffold(
      appBar: AppBar(title: const Text('Verify your email')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'We sent a verification link to $email. Open it, then come '
              'back and tap "I\'ve verified".',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.accentRed, fontSize: 13),
              ),
            ],
            if (_info != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _info!,
                style: const TextStyle(color: AppColors.accentGreen, fontSize: 13),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            FFPrimaryButton(
              label: "I've verified",
              isLoading: _isChecking,
              onPressed: _checkVerified,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: _isResending ? null : _resendLink,
              child: Text(_isResending ? 'Resending…' : 'Resend email'),
            ),
          ],
        ),
      ),
    );
  }
}