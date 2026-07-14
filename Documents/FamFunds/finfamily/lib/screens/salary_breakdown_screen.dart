import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

/// Shows the rule-engine computed salary split (savings/expenses/discretionary)
/// plus the AI-generated plain-language explanation.
/// TODO: call Cloud Function `getSalaryBreakdown` and populate real data.
class SalaryBreakdownScreen extends StatelessWidget {
  const SalaryBreakdownScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Salary Breakdown')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          FFCard(
            child: Column(
              children: [
                SizedBox(
                  height: 180,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 40,
                      sections: [
                        PieChartSectionData(
                          value: 45,
                          color: AppColors.primary,
                          title: '45%',
                          radius: 50,
                          titleStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700),
                        ),
                        PieChartSectionData(
                          value: 35,
                          color: AppColors.accentGreen,
                          title: '35%',
                          radius: 50,
                          titleStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700),
                        ),
                        PieChartSectionData(
                          value: 20,
                          color: AppColors.accentAmber,
                          title: '20%',
                          radius: 50,
                          titleStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const _LegendRow(),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'AI Explanation'),
          const SizedBox(height: AppSpacing.sm),
          FFCard(
            child: const Text(
              // TODO: replace with LLM response from Cloud Function
              'Of your ₹85,000 salary, 45% (₹38,250) covers fixed expenses '
              'like rent and EMIs, 35% (₹29,750) goes to savings, and 20% '
              '(₹17,000) is discretionary spending. Your savings rate is '
              'healthy — consider directing part of the discretionary '
              'amount toward your emergency fund.',
              style: TextStyle(height: 1.5, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow();

  @override
  Widget build(BuildContext context) {
    Widget dot(Color c, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        );

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        dot(AppColors.primary, 'Fixed Expenses'),
        dot(AppColors.accentGreen, 'Savings'),
        dot(AppColors.accentAmber, 'Discretionary'),
      ],
    );
  }
}
