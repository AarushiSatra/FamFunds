import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

/// AI-guided investment suggestions, personalized to real savings history.
/// TODO: call Cloud Function `getInvestmentSuggestions`.
class InvestmentScreen extends StatelessWidget {
  const InvestmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Investment Suggestions')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: const [
          _InvestmentCard(
            title: 'Increase SIP by ₹5,000/mo',
            riskLevel: 'Low',
            riskColor: AppColors.accentGreen,
            rationale:
                'Based on your last 6 months of savings, you consistently '
                'have surplus of ₹8,000+ left after expenses. Directing '
                'part of that into an existing SIP compounds faster than '
                'idle savings.',
          ),
          SizedBox(height: AppSpacing.sm),
          _InvestmentCard(
            title: 'Build a 6-month emergency fund',
            riskLevel: 'Low',
            riskColor: AppColors.accentGreen,
            rationale:
                'Your combined family balance covers about 2.3 months of '
                'expenses. AA framework guidance suggests 6 months as a '
                'safety buffer before increasing equity exposure.',
          ),
          SizedBox(height: AppSpacing.sm),
          _InvestmentCard(
            title: 'Explore equity mutual funds',
            riskLevel: 'Medium',
            riskColor: AppColors.accentAmber,
            rationale:
                'Once your emergency fund is complete, your risk capacity '
                'and time horizon support moderate equity allocation for '
                'long-term goals.',
          ),
        ],
      ),
    );
  }
}

class _InvestmentCard extends StatelessWidget {
  final String title;
  final String riskLevel;
  final Color riskColor;
  final String rationale;

  const _InvestmentCard({
    required this.title,
    required this.riskLevel,
    required this.riskColor,
    required this.rationale,
  });

  @override
  Widget build(BuildContext context) {
    return FFCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              StatPill(label: '$riskLevel Risk', color: riskColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(rationale,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
        ],
      ),
    );
  }
}
