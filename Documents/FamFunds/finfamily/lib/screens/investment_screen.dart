import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/investment_service.dart';
import '../models/family_models.dart';

class InvestmentScreen extends StatefulWidget {
  const InvestmentScreen({super.key});

  @override
  State<InvestmentScreen> createState() => _InvestmentScreenState();
}

class _InvestmentScreenState extends State<InvestmentScreen> {
  final _service = InvestmentService();
  late Future<InvestmentResult?> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getSuggestions();
  }

  void _refresh() {
    setState(() {
      _future = _service.getSuggestions();
    });
  }

  Future<void> _seedAndRefresh() async {
    await _service.seedDemoData();
    _refresh();
  }

  String _money(num value) {
    final intPart = value.round().toString();
    final buffer = StringBuffer();
    final len = intPart.length;
    for (int i = 0; i < len; i++) {
      final posFromEnd = len - i;
      buffer.write(intPart[i]);
      if (posFromEnd > 3 && (posFromEnd - 3) % 2 == 0) buffer.write(',');
    }
    return '₹${buffer.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Investment Suggestions'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _refresh),
        ],
      ),
      body: FutureBuilder<InvestmentResult?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorState(onRetry: _refresh, error: snapshot.error.toString());
          }

          final result = snapshot.data;
          if (result == null) {
            return _EmptyState(onSeedDemo: _seedAndRefresh);
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _SummaryCard(summary: result.summary, moneyFormatter: _money),
              const SizedBox(height: AppSpacing.lg),
              if (result.suggestions.isEmpty)
                FFCard(
                  child: Row(
                    children: const [
                      Icon(Icons.check_circle_rounded, color: AppColors.accentGreen),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          "You're in great shape — no urgent suggestions right now.",
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                const SectionHeader(title: 'Suggestions for you'),
                const SizedBox(height: AppSpacing.sm),
                ...result.suggestions.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _InvestmentCard(suggestion: s, moneyFormatter: _money),
                    )),
              ],
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: TextButton.icon(
                  onPressed: _seedAndRefresh,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Reload Demo Data'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Top-of-screen financial snapshot — the "why" behind every suggestion
/// below, shown in plain numbers before any AI text.
class _SummaryCard extends StatelessWidget {
  final FinancialSummary summary;
  final String Function(num) moneyFormatter;

  const _SummaryCard({required this.summary, required this.moneyFormatter});

  @override
  Widget build(BuildContext context) {
    return FFCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your Financial Snapshot',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _StatBlock(
                  label: 'Combined Balance',
                  value: moneyFormatter(summary.combinedBalance),
                  icon: Icons.account_balance_wallet_rounded,
                ),
              ),
              Expanded(
                child: _StatBlock(
                  label: 'Monthly Surplus',
                  value: moneyFormatter(summary.avgMonthlySurplus),
                  icon: Icons.savings_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _CoverageBar(coverageMonths: summary.coverageMonths),
        ],
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatBlock({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

/// Visual progress bar: how many months of expenses your balance covers,
/// against the 6-month target — makes the emergency fund gap tangible.
class _CoverageBar extends StatelessWidget {
  final double coverageMonths;
  static const target = 6.0;

  const _CoverageBar({required this.coverageMonths});

  @override
  Widget build(BuildContext context) {
    final ratio = (coverageMonths / target).clamp(0.0, 1.0);
    final isComplete = coverageMonths >= target;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Emergency Fund Coverage',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            Text(
              '${coverageMonths.toStringAsFixed(1)} / ${target.toInt()} months',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isComplete ? AppColors.accentGreen : AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: AppColors.border,
            color: isComplete ? AppColors.accentGreen : AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onSeedDemo;
  const _EmptyState({required this.onSeedDemo});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.trending_up_rounded, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.md),
            const Text('No suggestions yet',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Link accounts and build salary history to get suggestions, '
              'or load demo data for testing.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.lg),
            FFPrimaryButton(label: 'Load Demo Data', onPressed: onSeedDemo),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  final String error;
  const _ErrorState({required this.onRetry, required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 40, color: AppColors.accentRed),
            const SizedBox(height: AppSpacing.md),
            Text(error, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: AppSpacing.md),
            FFPrimaryButton(label: 'Retry', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

class _InvestmentCard extends StatefulWidget {
  final InvestmentSuggestion suggestion;
  final String Function(num) moneyFormatter;
  const _InvestmentCard({required this.suggestion, required this.moneyFormatter});

  @override
  State<_InvestmentCard> createState() => _InvestmentCardState();
}

class _InvestmentCardState extends State<_InvestmentCard> {
  bool _expanded = false;

  Color get _riskColor {
    switch (widget.suggestion.riskLevel.toLowerCase()) {
      case 'moderate':
        return AppColors.accentAmber;
      case 'high':
        return AppColors.accentRed;
      default:
        return AppColors.accentGreen;
    }
  }

  IconData get _typeIcon {
    switch (widget.suggestion.type) {
      case 'EMERGENCY_FUND':
        return Icons.shield_rounded;
      case 'INCREASE_SIP':
        return Icons.trending_up_rounded;
      case 'EXPLORE_EQUITY':
        return Icons.pie_chart_rounded;
      case 'AGGRESSIVE_GROWTH':
        return Icons.rocket_launch_rounded;
      default:
        return Icons.lightbulb_rounded;
    }
  }

  Future<void> _openLink() async {
    final url = widget.suggestion.actionUrl;
    if (url == null) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Renders the raw facts map as clean "label: value" chips — this is
  /// the deterministic, rule-engine-computed breakdown, shown separately
  /// from the AI's plain-language explanation above it.
  Widget _buildFactsBreakdown() {
    final facts = widget.suggestion.facts;
    final chips = <Widget>[];

    facts.forEach((key, value) {
      String label = key.replaceAllMapped(
          RegExp(r'([A-Z])'), (m) => ' ${m.group(1)}');
      label = label[0].toUpperCase() + label.substring(1);

      String displayValue;
      if (key.toLowerCase().contains('amount') ||
          key.toLowerCase().contains('surplus') ||
          key.toLowerCase().contains('threshold')) {
        displayValue = widget.moneyFormatter(value as num);
      } else if (key.toLowerCase().contains('ratio')) {
        displayValue = '${((value as num) * 100).round()}%';
      } else if (key.toLowerCase().contains('months')) {
        displayValue = '$value mo';
      } else {
        displayValue = '$value';
      }

      chips.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            children: [
              TextSpan(text: '$label: '),
              TextSpan(
                text: displayValue,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ));
    });

    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.suggestion;

    return FFCard(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _riskColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(_typeIcon, size: 18, color: _riskColor),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(s.title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              ),
              StatPill(label: '${s.riskLevel} Risk', color: _riskColor),
            ],
          ),
          const SizedBox(height: 10),
          Text(s.description,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.45)),

          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox(height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('The numbers behind this',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  _buildFactsBreakdown(),
                  const SizedBox(height: 12),
                  Text(s.aiRationale,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4,
                          fontStyle: FontStyle.italic)),
                  if (s.actionUrl != null) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _openLink,
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: Text(s.actionLabel ?? 'Learn more'),
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(40)),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Icon(
              _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}