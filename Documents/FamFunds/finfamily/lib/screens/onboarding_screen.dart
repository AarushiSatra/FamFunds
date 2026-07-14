import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../routes/app_routes.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const Icon(Icons.family_restroom_rounded,
                  size: 64, color: AppColors.primary),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'One app for your\nwhole family\'s money',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Link accounts, understand your salary, compare loans, '
                'and invest smarter — together.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
              ),
              const Spacer(),
              FFPrimaryButton(
                label: 'Get Started',
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.auth),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, AppRoutes.home),
                child: const Text('Explore as guest'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
