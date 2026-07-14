import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

/// Compares EMI/interest across linked accounts and flags the best source.
/// TODO: call Cloud Function `compareLoanOptions` with linked account data.
class LoanAdvisorScreen extends StatelessWidget {
  const LoanAdvisorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Loan Advisor')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          FFCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Loan amount (₹)',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Tenure (months)',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                FFPrimaryButton(label: 'Compare Options', onPressed: () {}),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Compared Sources'),
          const SizedBox(height: AppSpacing.sm),
          const _LoanOptionTile(
            source: 'HDFC Bank Personal Loan',
            emi: '₹9,850/mo',
            interest: '11.2% p.a.',
            totalInterest: '₹1,18,200',
            recommended: true,
          ),
          const SizedBox(height: AppSpacing.sm),
          const _LoanOptionTile(
            source: 'ICICI Bank Personal Loan',
            emi: '₹10,120/mo',
            interest: '12.5% p.a.',
            totalInterest: '₹1,34,400',
            recommended: false,
          ),
          const SizedBox(height: AppSpacing.sm),
          const _LoanOptionTile(
            source: 'SBI Gold Loan (parent account)',
            emi: '₹9,420/mo',
            interest: '9.8% p.a.',
            totalInterest: '₹98,600',
            recommended: false,
          ),
          const SizedBox(height: AppSpacing.lg),
          FFCard(
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: AppColors.primary, size: 20),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Code computes every EMI/interest figure — the AI only '
                    'explains the comparison in plain language.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoanOptionTile extends StatelessWidget {
  final String source;
  final String emi;
  final String interest;
  final String totalInterest;
  final bool recommended;

  const _LoanOptionTile({
    required this.source,
    required this.emi,
    required this.interest,
    required this.totalInterest,
    required this.recommended,
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
                child: Text(source,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              if (recommended)
                const StatPill(label: 'Best Option', color: AppColors.accentGreen),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _metric('EMI', emi),
              _metric('Interest', interest),
              _metric('Total Interest', totalInterest),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
