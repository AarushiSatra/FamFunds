import 'package:flutter/material.dart';

import '../screens/splash_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/home_shell.dart';
import '../screens/family_dashboard_screen.dart';
import '../screens/salary_breakdown_screen.dart';
import '../screens/loan_advisor_screen.dart';
import '../screens/investment_screen.dart';
import '../screens/chatbot_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/account_linking/consent_intro_screen.dart';
import '../screens/account_linking/otp_verification_screen.dart';
import '../screens/account_linking/select_accounts_screen.dart';
import '../screens/account_linking/consent_success_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/change_password_screen.dart';

class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const auth = '/auth';
  static const home = '/home';
  static const dashboard = '/dashboard';
  static const salaryBreakdown = '/salary-breakdown';
  static const loanAdvisor = '/loan-advisor';
  static const investments = '/investments';
  static const chatbot = '/chatbot';
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
static const changePassword = '/profile/change-password';

  // Account linking (consent) flow
  static const consentIntro = '/link/consent-intro';
  static const otpVerification = '/link/otp';
  static const selectAccounts = '/link/select-accounts';
  static const consentSuccess = '/link/success';

  static Map<String, WidgetBuilder> get routes => {
        splash: (_) => const SplashScreen(),
        onboarding: (_) => const OnboardingScreen(),
        auth: (_) => const AuthScreen(),
        home: (_) => const HomeShell(),
        dashboard: (_) => const FamilyDashboardScreen(),
        salaryBreakdown: (_) => const SalaryBreakdownScreen(),
        loanAdvisor: (_) => const LoanAdvisorScreen(),
        investments: (_) => const InvestmentScreen(),
        chatbot: (_) => const ChatbotScreen(),
        profile: (_) => const ProfileScreen(),
        editProfile: (_) => const EditProfileScreen(),
        changePassword: (_) => const ChangePasswordScreen(),
        consentIntro: (_) => const ConsentIntroScreen(),
        otpVerification: (_) => const OtpVerificationScreen(),
        selectAccounts: (_) => const SelectAccountsScreen(),
        consentSuccess: (_) => const ConsentSuccessScreen(),
      };
}
