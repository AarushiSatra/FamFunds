import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../routes/app_routes.dart';

/// Household-wide dashboard: linked family accounts, combined balance,
/// quick links into salary breakdown / loans / investments.
class FamilyDashboardScreen extends StatelessWidget {
  const FamilyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('The Sharma Family'), // TODO: pull family name
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _CombinedBalanceCard(),
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(
            title: 'Linked Accounts',
            actionLabel: '+ Link account',
            onAction: () =>
                Navigator.pushNamed(context, AppRoutes.consentIntro),
          ),
          const SizedBox(height: AppSpacing.sm),
          // TODO: replace with StreamBuilder<QuerySnapshot> from Firestore
          const _AccountTile(
            memberName: 'You',
            bankName: 'HDFC Bank',
            maskedNumber: 'XXXX 4821',
            balance: '₹1,84,200',
          ),
          const SizedBox(height: AppSpacing.sm),
          const _AccountTile(
            memberName: 'Spouse',
            bankName: 'ICICI Bank',
            maskedNumber: 'XXXX 7734',
            balance: '₹96,500',
          ),
          const SizedBox(height: AppSpacing.sm),
          const _AccountTile(
            memberName: 'Parent',
            bankName: 'SBI',
            maskedNumber: 'XXXX 2201',
            balance: '₹3,12,900',
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(title: 'Quick Actions'),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.pie_chart_rounded,
                  label: 'Salary\nBreakdown',
                  onTap: () => Navigator.pushNamed(
                      context, AppRoutes.salaryBreakdown),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.compare_arrows_rounded,
                  label: 'Compare\nLoans',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.loanAdvisor),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.trending_up_rounded,
                  label: 'Invest\nSmarter',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.investments),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CombinedBalanceCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FFCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Combined Family Balance',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 6),
          // TODO: sum from linked accounts stream
          const Text('₹5,93,600',
              style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.sm),
          const StatPill(label: '+8.2% this month', color: AppColors.accentGreen),
        ],
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final String memberName;
  final String bankName;
  final String maskedNumber;
  final String balance;

  const _AccountTile({
    required this.memberName,
    required this.bankName,
    required this.maskedNumber,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    return FFCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.account_balance_rounded,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bankName,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('$memberName · $maskedNumber',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Text(balance,
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FFCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
