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

              // ---- Header: badge + wordmark + tagline ----
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

              // ---- Segmented Sign in / Sign up toggle ----
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

              // ---- Form card ----
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
                            prefixIcon: Icon(Icons.alternate_email_rounded),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextField(
                          controller: _fullNameController,
                          decoration: const InputDecoration(
                            labelText: 'Full name',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.mail_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () =>
                                setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      if (_isSignUp) ...[
                        const SizedBox(height: AppSpacing.md),
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          decoration: InputDecoration(
                            labelText: 'Confirm password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () => setState(
                                  () => _obscureConfirmPassword = !_obscureConfirmPassword),
                            ),
                          ),
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: AppColors.accentRed, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                    color: AppColors.accentRed, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      FFPrimaryButton(
                        label: _isSignUp ? 'Create account' : 'Continue',
                        isLoading: _isLoading,
                        onPressed: _handleContinue,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
              Center(
                child: Text(
                  _isSignUp
                      ? 'By creating an account, all family members you invite\nwill be able to see shared family income.'
                      : 'Every family member sees the same shared picture.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

/// One tab of the Sign in / Sign up pill toggle.
class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: selected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}