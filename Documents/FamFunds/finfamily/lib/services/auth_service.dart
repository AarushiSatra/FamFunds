import 'package:firebase_auth/firebase_auth.dart';

/// Wraps FirebaseAuth for FinFamily's sign-in flow:
///   1. Email + password (primary factor)
///   2. Phone OTP enrolled as a required second factor (Firebase MFA)
///
/// Sign-up flow: signUp() -> sendEmailVerification() -> checkEmailVerified()
///               -> startPhoneEnrollment() -> confirmPhoneEnrollment()
/// Sign-in flow: signIn() -> (if FirebaseAuthMultiFactorException) ->
///               startMfaChallenge() -> confirmMfaChallenge()
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ---- Primary factor: email / password ----

  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Signs in with email/password. If the account has a second factor
  /// enrolled, Firebase throws [FirebaseAuthMultiFactorException] instead
  /// of completing sign-in — catch that and resolve it with
  /// [startMfaChallenge] / [confirmMfaChallenge].
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() => _auth.signOut();

  // ---- Email verification (required before MFA enrollment) ----

  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  /// Reloads the current user from Firebase and returns whether their
  /// email is now verified. Call this after the user says they've
  /// clicked the link in their inbox.
  Future<bool> checkEmailVerified() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  // ---- Second factor: enroll a phone number (right after sign-up) ----

  /// Starts enrolling [phoneNumber] (E.164, e.g. +919876543210) as the
  /// account's second factor. Sends an SMS code and reports the
  /// verificationId via [onCodeSent], which you then pass to
  /// [confirmPhoneEnrollment] along with the code the user typed.
  Future<void> startPhoneEnrollment({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(FirebaseAuthException e) onError,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No signed-in user to enroll a second factor for.');
    }
    final session = await user.multiFactor.getSession();

    await _auth.verifyPhoneNumber(
      multiFactorSession: session,
      phoneNumber: phoneNumber,
      verificationCompleted: (_) {}, // not used: we always ask for manual code entry
      verificationFailed: onError,
      codeSent: (verificationId, _) => onCodeSent(verificationId),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<void> confirmPhoneEnrollment({
    required String verificationId,
    required String smsCode,
    String displayName = 'Primary phone',
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final assertion = PhoneMultiFactorGenerator.getAssertion(credential);
    await _auth.currentUser!.multiFactor.enroll(
      assertion,
      displayName: displayName,
    );
  }

  // ---- Second factor: challenge during sign-in ----

  /// The masked phone number Firebase will send the code to, taken from
  /// the MFA exception thrown by [signIn]. Use this to show the user
  /// something like "Code sent to +91••••••1234".
  String hintedPhoneNumber(FirebaseAuthMultiFactorException e) {
    final hint = e.resolver.hints.first;
    return hint is PhoneMultiFactorInfo ? hint.phoneNumber : '';
  }

  Future<void> startMfaChallenge({
    required FirebaseAuthMultiFactorException mfaException,
    required void Function(String verificationId) onCodeSent,
    required void Function(FirebaseAuthException e) onError,
  }) async {
    final hint = mfaException.resolver.hints.first as PhoneMultiFactorInfo;
    await _auth.verifyPhoneNumber(
      multiFactorSession: mfaException.resolver.session,
      multiFactorInfo: hint,
      phoneNumber: hint.phoneNumber,
      verificationCompleted: (_) {},
      verificationFailed: onError,
      codeSent: (verificationId, _) => onCodeSent(verificationId),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<UserCredential> confirmMfaChallenge({
    required FirebaseAuthMultiFactorException mfaException,
    required String verificationId,
    required String smsCode,
  }) {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final assertion = PhoneMultiFactorGenerator.getAssertion(credential);
    return mfaException.resolver.resolveSignIn(assertion);
  }
}