import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/auth_service.dart';
import 'auth/email_verification_screen.dart';
import 'auth/mfa_enroll_screen.dart';
import 'auth/mfa_verify_screen.dart';

/// Email/password sign-in and sign-up. Two-factor login (phone OTP as a
/// required second factor) is handled by EmailVerificationScreen ->
/// MfaEnrollScreen (after sign-up) and MfaVerifyScreen (during sign-in),
/// all driven by AuthService.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSignUp = false;
  bool _isLoading = false;
  String? _error;

  Future<void> _handleContinue() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Enter your email and password');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_isSignUp) {
        await AuthService.instance.signUp(email: email, password: password);
        if (!mounted) return;
        // New accounts must verify email, then enroll a second factor,
        // before reaching /home.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const EmailVerificationScreen()),
        );
      } else {
        await AuthService.instance.signIn(email: email, password: password);
        if (!mounted) return;
        await _routeAfterSuccessfulSignIn();
      }
    } on FirebaseAuthMultiFactorException catch (e) {
      // Expected on sign-in for accounts that already completed 2FA setup.
      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => MfaVerifyScreen(mfaException: e)),
      );
      return;
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        _error = _friendlyError(e);
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Something went wrong. Try again.';
      });
    }
  }

  /// Reaching here means sign-in succeeded WITHOUT a second-factor
  /// challenge — which means this account hasn't finished 2FA setup yet
  /// (no second factor enrolled). Send them to whichever step is left
  /// instead of letting them into /home half set up.
  Future<void> _routeAfterSuccessfulSignIn() async {
    final user = AuthService.instance.currentUser;
    if (user != null && !user.emailVerified) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const EmailVerificationScreen()),
      );
      return;
    }
    // Email verified but no MFA exception was thrown -> no second factor
    // enrolled yet. Send them to finish setup.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MfaEnrollScreen()),
    );
  }

  String _friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found for that email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      default:
        return e.message ?? 'Something went wrong. Try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isSignUp ? 'Create account' : 'Sign in')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
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
              label: _isSignUp ? 'Create account' : 'Continue',
              isLoading: _isLoading,
              onPressed: _handleContinue,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () => setState(() {
                        _isSignUp = !_isSignUp;
                        _error = null;
                      }),
              child: Text(
                _isSignUp
                    ? 'Already have an account? Sign in'
                    : 'New here? Create an account',
              ),
            ),
          ],
        ),
      ),
    );
  }
}