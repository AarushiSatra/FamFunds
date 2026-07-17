/**
 * Rule engine for investment suggestions — pure, deterministic math.
 * No AI calls happen here. Every number the app shows the user is
 * computed in this file; the LLM layer (llm.js) only explains these
 * pre-computed facts in plain language afterward.
 */

function computeEmergencyFundCoverage(combinedBalance, avgMonthlyExpense) {
  if (avgMonthlyExpense <= 0) return 0;
  return combinedBalance / avgMonthlyExpense;
}

function computeAvgMonthlySurplus(monthlyEntries) {
  if (!monthlyEntries.length) return 0;
  const total = monthlyEntries.reduce((sum, e) => sum + (e.savings || 0), 0);
  return total / monthlyEntries.length;
}

function computeSurplusConsistency(monthlyEntries) {
  if (!monthlyEntries.length) return 0;
  const positiveMonths = monthlyEntries.filter((e) => (e.savings || 0) > 0).length;
  return positiveMonths / monthlyEntries.length;
}

const EMERGENCY_FUND_TARGET_MONTHS = 6;

function generateInvestmentSlots(facts) {
  const { combinedBalance, avgMonthlyExpense, monthlyEntries } = facts;

  const coverageMonths = computeEmergencyFundCoverage(combinedBalance, avgMonthlyExpense);
  const avgSurplus = computeAvgMonthlySurplus(monthlyEntries);
  const consistency = computeSurplusConsistency(monthlyEntries);

  const slots = [];

  if (coverageMonths < EMERGENCY_FUND_TARGET_MONTHS) {
    const targetBalance = avgMonthlyExpense * EMERGENCY_FUND_TARGET_MONTHS;
    const shortfall = Math.max(0, targetBalance - combinedBalance);
    slots.push({
      type: 'EMERGENCY_FUND',
      riskLevel: 'low',
      facts: {
        currentCoverageMonths: Number(coverageMonths.toFixed(1)),
        targetCoverageMonths: EMERGENCY_FUND_TARGET_MONTHS,
        shortfallAmount: Math.round(shortfall),
      },
    });
  }

  if (avgSurplus > 0 && consistency >= 0.5) {
    const suggestedIncrease = Math.round(avgSurplus * 0.5 / 500) * 500;
    if (suggestedIncrease > 0) {
      slots.push({
        type: 'INCREASE_SIP',
        riskLevel: 'low',
        facts: {
          avgMonthlySurplus: Math.round(avgSurplus),
          suggestedIncreaseAmount: suggestedIncrease,
          consistencyRatio: Number(consistency.toFixed(2)),
        },
      });
    }
  }

  if (coverageMonths >= EMERGENCY_FUND_TARGET_MONTHS && avgSurplus > 0 && consistency >= 0.7) {
    slots.push({
      type: 'EXPLORE_EQUITY',
      riskLevel: 'medium',
      facts: {
        avgMonthlySurplus: Math.round(avgSurplus),
        emergencyFundStatus: 'complete',
      },
    });
  }

  return slots;
}

module.exports = {
  computeEmergencyFundCoverage,
  computeAvgMonthlySurplus,
  computeSurplusConsistency,
  generateInvestmentSlots,
  EMERGENCY_FUND_TARGET_MONTHS,
};