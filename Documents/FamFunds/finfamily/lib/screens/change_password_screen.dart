import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/auth_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

/// Which step of the flow the user is currently on.
enum _Stage { currentPassword, mfaCode, newPassword }

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _mfaCodeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  _Stage _stage = _Stage.currentPassword;
  bool _isLoading = false;
  bool _resetEmailSent = false;
  String? _error;

  // Held between the password step and the MFA step.
  FirebaseAuthMultiFactorException? _pendingMfaException;
  String? _pendingVerificationId;

  Future<void> _verifyCurrentPassword() async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    final currentPassword = _currentPasswordController.text;

    if (email == null || currentPassword.isEmpty) {
      setState(() => _error = 'Enter your current password');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final credential = EmailAuthProvider.credential(email: email, password: currentPassword);
      await user!.reauthenticateWithCredential(credential);

      // No MFA exception thrown -> account somehow has no second factor.
      // Straight to setting the new password.
      setState(() {
        _stage = _Stage.newPassword;
        _isLoading = false;
      });
    } on FirebaseAuthMultiFactorException catch (e) {
      // Expected for accounts with phone MFA enrolled: password was correct,
      // but Firebase now wants the second factor before it'll trust this
      // reauthentication. Kick off the SMS challenge.
      _pendingMfaException = e;
      await AuthService.instance.startMfaChallenge(
        mfaException: e,
        onCodeSent: (verificationId) {
          _pendingVerificationId = verificationId;
          setState(() {
            _stage = _Stage.mfaCode;
            _isLoading = false;
          });
        },
        onError: (err) {
          setState(() {
            _isLoading = false;
            _error = err.message ?? 'Could not send verification code.';
          });
        },
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.code == 'wrong-password' || e.code == 'invalid-credential'
            ? 'Incorrect current password.'
            : (e.message ?? 'Something went wrong.');
      });
    }
  }

  Future<void> _confirmMfaCode() async {
    final code = _mfaCodeController.text.trim();
    if (code.length < 6 || _pendingMfaException == null || _pendingVerificationId == null) {
      setState(() => _error = 'Enter the 6-digit code');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await AuthService.instance.confirmMfaChallenge(
        mfaException: _pendingMfaException!,
        verificationId: _pendingVerificationId!,
        smsCode: code,
      );
      setState(() {
        _stage = _Stage.newPassword;
        _isLoading = false;
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.message ?? 'Incorrect code.';
      });
    }
  }

  Future<void> _sendResetEmail() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      setState(() {
        _isLoading = false;
        _resetEmailSent = true;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Could not send email. Try again.';
      });
    }
  }

  Future<void> _setNewPassword() async {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword.isEmpty || newPassword != confirmPassword) {
      setState(() => _error = 'Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await FirebaseAuth.instance.currentUser!.updatePassword(newPassword);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated')),
      );
      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.code == 'weak-password'
            ? 'Password should be at least 6 characters.'
            : (e.message ?? 'Something went wrong.');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change password')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_stage == _Stage.currentPassword) ..._buildCurrentPasswordStage(),
            if (_stage == _Stage.mfaCode) ..._buildMfaStage(),
            if (_stage == _Stage.newPassword) ..._buildNewPasswordStage(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCurrentPasswordStage() {
    return [
      const Text(
        'Enter your current password to continue.',
        style: TextStyle(color: AppColors.textSecondary),
      ),
      const SizedBox(height: AppSpacing.md),
      TextField(
        controller: _currentPasswordController,
        obscureText: true,
        decoration: const InputDecoration(
          labelText: 'Current password',
          prefixIcon: Icon(Icons.lock_outline_rounded),
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      if (_error != null && !_resetEmailSent)
        Text(_error!, style: const TextStyle(color: AppColors.accentRed, fontSize: 13)),
      const SizedBox(height: AppSpacing.sm),
      FFPrimaryButton(
        label: 'Continue',
        isLoading: _isLoading,
        onPressed: _verifyCurrentPassword,
      ),
      const SizedBox(height: AppSpacing.md),
      if (_resetEmailSent)
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Check your email for a link to reset your password.',
            style: TextStyle(color: AppColors.primary, fontSize: 13),
          ),
        )
      else
        Center(
          child: TextButton(
            onPressed: _isLoading ? null : _sendResetEmail,
            child: const Text('Forgot your password? Email me a reset link'),
          ),
        ),
    ];
  }

  List<Widget> _buildMfaStage() {
    return [
      const Text(
        'Enter the verification code sent to your phone.',
        style: TextStyle(color: AppColors.textSecondary),
      ),
      const SizedBox(height: AppSpacing.md),
      TextField(
        controller: _mfaCodeController,
        keyboardType: TextInputType.number,
        maxLength: 6,
        decoration: const InputDecoration(
          labelText: 'SMS code',
          prefixIcon: Icon(Icons.sms_outlined),
        ),
      ),
      if (_error != null) ...[
        const SizedBox(height: AppSpacing.sm),
        Text(_error!, style: const TextStyle(color: AppColors.accentRed, fontSize: 13)),
      ],
      const SizedBox(height: AppSpacing.sm),
      FFPrimaryButton(
        label: 'Verify code',
        isLoading: _isLoading,
        onPressed: _confirmMfaCode,
      ),
    ];
  }

  List<Widget> _buildNewPasswordStage() {
    return [
      const Text(
        'Verified. Choose a new password.',
        style: TextStyle(color: AppColors.accentGreen),
      ),
      const SizedBox(height: AppSpacing.md),
      TextField(
        controller: _newPasswordController,
        obscureText: true,
        decoration: const InputDecoration(
          labelText: 'New password',
          prefixIcon: Icon(Icons.lock_outline_rounded),
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      TextField(
        controller: _confirmPasswordController,
        obscureText: true,
        decoration: const InputDecoration(
          labelText: 'Confirm new password',
          prefixIcon: Icon(Icons.lock_outline_rounded),
        ),
      ),
      if (_error != null) ...[
        const SizedBox(height: AppSpacing.sm),
        Text(_error!, style: const TextStyle(color: AppColors.accentRed, fontSize: 13)),
      ],
      const SizedBox(height: AppSpacing.lg),
      FFPrimaryButton(
        label: 'Update password',
        isLoading: _isLoading,
        onPressed: _setNewPassword,
      ),
    ];
  }
}