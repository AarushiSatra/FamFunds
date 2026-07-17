/// Pure deterministic rule engine — Dart port of the original Cloud
/// Functions rule engine. All math lives here; the AI layer only
/// explains these pre-computed facts, never computes them.

class InvestmentSlot {
  final String type;
  final String riskLevel;
  final Map<String, dynamic> facts;

  InvestmentSlot({
    required this.type,
    required this.riskLevel,
    required this.facts,
  });
}

const emergencyFundTargetMonths = 6;

double computeEmergencyFundCoverage(double combinedBalance, double avgMonthlyExpense) {
  if (avgMonthlyExpense <= 0) return 0;
  return combinedBalance / avgMonthlyExpense;
}

double computeAvgMonthlySurplus(List<Map<String, dynamic>> monthlyEntries) {
  if (monthlyEntries.isEmpty) return 0;
  final total = monthlyEntries.fold<double>(
      0, (sum, e) => sum + ((e['savings'] ?? 0) as num).toDouble());
  return total / monthlyEntries.length;
}

double computeSurplusConsistency(List<Map<String, dynamic>> monthlyEntries) {
  if (monthlyEntries.isEmpty) return 0;
  final positiveMonths =
      monthlyEntries.where((e) => ((e['savings'] ?? 0) as num) > 0).length;
  return positiveMonths / monthlyEntries.length;
}

List<InvestmentSlot> generateInvestmentSlots({
  required double combinedBalance,
  required double avgMonthlyExpense,
  required List<Map<String, dynamic>> monthlyEntries,
}) {
  final coverageMonths = computeEmergencyFundCoverage(combinedBalance, avgMonthlyExpense);
  final avgSurplus = computeAvgMonthlySurplus(monthlyEntries);
  final consistency = computeSurplusConsistency(monthlyEntries);

  final slots = <InvestmentSlot>[];

  // Low risk: emergency fund shortfall.
  if (coverageMonths < emergencyFundTargetMonths) {
    final targetBalance = avgMonthlyExpense * emergencyFundTargetMonths;
    final shortfall = (targetBalance - combinedBalance).clamp(0, double.infinity);
    slots.add(InvestmentSlot(
      type: 'EMERGENCY_FUND',
      riskLevel: 'low',
      facts: {
        'currentCoverageMonths': double.parse(coverageMonths.toStringAsFixed(1)),
        'targetCoverageMonths': emergencyFundTargetMonths,
        'shortfallAmount': shortfall.round(),
      },
    ));
  }

  // Low risk: increase SIP.
  if (avgSurplus > 0 && consistency >= 0.5) {
    final suggestedIncrease = ((avgSurplus * 0.5) / 500).round() * 500;
    if (suggestedIncrease > 0) {
      slots.add(InvestmentSlot(
        type: 'INCREASE_SIP',
        riskLevel: 'low',
        facts: {
          'avgMonthlySurplus': avgSurplus.round(),
          'suggestedIncreaseAmount': suggestedIncrease,
          'consistencyRatio': double.parse(consistency.toStringAsFixed(2)),
        },
      ));
    }
  }

  // Moderate risk: emergency fund complete, decent consistent surplus.
  if (coverageMonths >= emergencyFundTargetMonths && avgSurplus > 0 && consistency >= 0.7) {
    slots.add(InvestmentSlot(
      type: 'EXPLORE_EQUITY',
      riskLevel: 'moderate',
      facts: {
        'avgMonthlySurplus': avgSurplus.round(),
        'emergencyFundStatus': 'complete',
      },
    ));
  }

  // High risk: emergency fund complete AND surplus is large AND
  // near-perfect consistency. Deliberately the hardest tier to unlock.
  final highRiskSurplusThreshold = avgMonthlyExpense * 0.5;
  if (coverageMonths >= emergencyFundTargetMonths &&
      avgSurplus > highRiskSurplusThreshold &&
      consistency >= 0.9) {
    slots.add(InvestmentSlot(
      type: 'AGGRESSIVE_GROWTH',
      riskLevel: 'high',
      facts: {
        'avgMonthlySurplus': avgSurplus.round(),
        'surplusThreshold': highRiskSurplusThreshold.round(),
        'consistencyRatio': double.parse(consistency.toStringAsFixed(2)),
      },
    ));
  }

  return slots;
}

/// Maps each suggestion type to a category-level link — never a specific
/// fund recommendation, since naming individual products requires SEBI
/// Investment Advisor registration. These are real, verified Groww
/// category pages (confirmed working as of Jul 2026) — double check
/// they still resolve before your demo, in case Groww restructures URLs.
String? actionUrlFor(String slotType) {
  switch (slotType) {
    case 'EMERGENCY_FUND':
      return 'https://groww.in/mutual-funds/category/best-debt-mutual-funds';
    case 'INCREASE_SIP':
      return 'https://groww.in/mutual-funds/category/best-equity-mutual-funds';
    case 'EXPLORE_EQUITY':
      return 'https://groww.in/mutual-funds/category/best-equity-mutual-funds';
    case 'AGGRESSIVE_GROWTH':
      return 'https://groww.in/mutual-funds/category/best-small-cap-mutual-funds';
    default:
      return null;
  }
}

String actionLabelFor(String slotType) {
  switch (slotType) {
    case 'EMERGENCY_FUND':
      return 'Explore debt funds & FDs';
    case 'INCREASE_SIP':
      return 'Explore equity SIPs';
    case 'EXPLORE_EQUITY':
      return 'Explore equity mutual funds';
    case 'AGGRESSIVE_GROWTH':
      return 'Explore small-cap funds';
    default:
      return 'Learn more';
  }
}