import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../routes/app_routes.dart';

/// Step 1 of the mock Account Aggregator consent flow.
/// Mirrors what Setu's real consent screen shows: what data will be
/// shared, for how long, and why — before the user proceeds.
class ConsentIntroScreen extends StatelessWidget {
  const ConsentIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Link Bank Account')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.verified_user_rounded,
                size: 48, color: AppColors.primary),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'FinFamily is requesting access to:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.md),
            const _ConsentItem(label: 'Account balance'),
            const _ConsentItem(label: 'Transaction history (last 6 months)'),
            const _ConsentItem(label: 'Account profile (holder name, type)'),
            const SizedBox(height: AppSpacing.lg),
            FFCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Purpose', style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Text(
                    'Personal finance management — salary breakdown, loan '
                    'comparison, and investment guidance.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  SizedBox(height: 10),
                  Text('Consent duration', style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Text('6 months, revocable anytime',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            const Spacer(),
            Text(
              'This mirrors India\'s RBI Account Aggregator framework — '
              'your bank data is never stored without explicit consent.',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            FFPrimaryButton(
              label: 'Continue',
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.otpVerification),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConsentItem extends StatelessWidget {
  final String label;
  const _ConsentItem({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: AppColors.accentGreen, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Text(label),
        ],
      ),
    );
  }
}
