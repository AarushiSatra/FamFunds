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
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _error;

  Future<void> _handleContinue() async {
    final username = _usernameController.text.trim();
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (_isSignUp) {
      if (username.isEmpty || fullName.isEmpty || email.isEmpty || password.isEmpty) {
        setState(() => _error = 'Fill in all fields');
        return;
      }
      if (password != confirmPassword) {
        setState(() => _error = 'Passwords do not match');
        return;
      }
    } else {
      if (email.isEmpty || password.isEmpty) {
        setState(() => _error = 'Enter your email and password');
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_isSignUp) {
        await AuthService.instance.signUp(
          email: email,
          password: password,
          username: username,
          fullName: fullName,
        );
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const EmailVerificationScreen()),
        );
      } else {
        await AuthService.instance.signIn(email: email, password: password);
        if (!mounted) return;
        await _routeAfterSuccessfulSignIn();
      }
    } on FirebaseAuthMultiFactorException catch (e) {
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

  Future<void> _routeAfterSuccessfulSignIn() async {
    final user = AuthService.instance.currentUser;
    if (user != null && !user.emailVerified) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const EmailVerificationScreen()),
      );
      return;
    }
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

  void _switchMode(bool signUp) {
    if (_isSignUp == signUp) return;
    setState(() {
      _isSignUp = signUp;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.family_restroom_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'FinFamily',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _isSignUp
                    ? 'Create an account for your family'
                    : 'One app for your whole family\'s money',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(child: _SegmentButton(
                      label: 'Sign in',
                      selected: !_isSignUp,
                      onTap: _isLoading ? null : () => _switchMode(false),
                    )),
                    Expanded(child: _SegmentButton(
                      label: 'Sign up',
                      selected: _isSignUp,
                      onTap: _isLoading ? null : () => _switchMode(true),
                    )),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FFCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_isSignUp) ...[
                        TextField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Username',