import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';

/// Shown during sign-in when the account has a second factor enrolled.
/// Firebase throws [FirebaseAuthMultiFactorException] from signIn() —
/// pass that exception here to resolve the challenge.
class MfaVerifyScreen extends StatefulWidget {
  final FirebaseAuthMultiFactorException mfaException;

  const MfaVerifyScreen({super.key, required this.mfaException});

  @override
  State<MfaVerifyScreen> createState() => _MfaVerifyScreenState();
}

class _MfaVerifyScreenState extends State<MfaVerifyScreen> {
  final _codeController = TextEditingController();

  String? _verificationId;
  bool _isLoading = false;
  bool _sending = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sendCode();
  }

  Future<void> _sendCode() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await AuthService.instance.startMfaChallenge(
        mfaException: widget.mfaException,
        onCodeSent: (verificationId) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _sending = false;
          });
        },
        onError: (e) {
          if (!mounted) return;
          setState(() {
            _sending = false;
            _error = e.message ?? 'Could not send code. Try again.';
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
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
      await AuthService.instance.confirmMfaChallenge(
        mfaException: widget.mfaException,
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
    final maskedPhone = AuthService.instance.hintedPhoneNumber(
      widget.mfaException,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Verify it\'s you')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _sending
                  ? 'Sending a code to $maskedPhone…'
                  : 'Enter the code we sent to $maskedPhone',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _codeController,
              enabled: !_sending,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(labelText: 'Enter OTP'),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.accentRed, fontSize: 13),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            FFPrimaryButton(
              label: 'Verify & sign in',
              isLoading: _isLoading,
              onPressed: _sending ? null : _confirmCode,
            ),
            if (!_sending) ...[
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: _sendCode,
                child: const Text('Resend code'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}