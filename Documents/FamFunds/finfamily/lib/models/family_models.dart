/// Mirrors the Firestore schema:
/// families/{familyId}, users/{uid}, accounts/{accountId},
/// transactions/{txnId}, loans/{loanId}

class FamilyMember {
  final String uid;
  final String name;
  final String role; // self | spouse | parent | other
  final List<String> linkedAccountIds;

  FamilyMember({
    required this.uid,
    required this.name,
    required this.role,
    this.linkedAccountIds = const [],
  });

  factory FamilyMember.fromMap(String uid, Map<String, dynamic> map) {
    return FamilyMember(
      uid: uid,
      name: map['name'] ?? '',
      role: map['role'] ?? 'self',
      linkedAccountIds: List<String>.from(map['linkedAccounts'] ?? []),
    );
  }
}

class LinkedAccount {
  final String accountId;
  final String familyId;
  final String ownerUid;
  final String bankName;
  final String accountType; // savings | current
  final String maskedAccountNumber;
  final double balance;

  LinkedAccount({
    required this.accountId,
    required this.familyId,
    required this.ownerUid,
    required this.bankName,
    required this.accountType,
    required this.maskedAccountNumber,
    required this.balance,
  });

  factory LinkedAccount.fromMap(String id, Map<String, dynamic> map) {
    return LinkedAccount(
      accountId: id,
      familyId: map['familyId'] ?? '',
      ownerUid: map['uid'] ?? '',
      bankName: map['bankName'] ?? '',
      accountType: map['accountType'] ?? 'savings',
      maskedAccountNumber: map['maskedAccountNumber'] ?? '',
      balance: (map['balance'] ?? 0).toDouble(),
    );
  }
}

class SalaryBreakdown {
  final double salary;
  final double fixedExpenses;
  final double savings;
  final double discretionary;
  final String aiExplanation;

  SalaryBreakdown({
    required this.salary,
    required this.fixedExpenses,
    required this.savings,
    required this.discretionary,
    required this.aiExplanation,
  });

  double get savingsRate => salary == 0 ? 0 : (savings / salary) * 100;
}

class LoanOption {
  final String source; // bank/account name
  final double principal;
  final double interestRate;
  final int tenureMonths;
  final double emi;
  final double totalInterest;
  final bool recommended;

  LoanOption({
    required this.source,
    required this.principal,
    required this.interestRate,
    required this.tenureMonths,
    required this.emi,
    required this.totalInterest,
    this.recommended = false,
  });
}

class InvestmentSuggestion {
  final String type;
  final String title;
  final String description;
  final String riskLevel;
  final String aiRationale;
  final Map<String, dynamic> facts;
  final String? actionUrl;
  final String? actionLabel;

  InvestmentSuggestion({
    required this.type,
    required this.title,
    required this.description,
    required this.riskLevel,
    required this.aiRationale,
    required this.facts,
    this.actionUrl,
    this.actionLabel,
  });
}

/// Overall financial snapshot shown at the top of the Invest tab.
class FinancialSummary {
  final double combinedBalance;
  final double avgMonthlyExpense;
  final double avgMonthlySurplus;
  final double coverageMonths;

  FinancialSummary({
    required this.combinedBalance,
    required this.avgMonthlyExpense,
    required this.avgMonthlySurplus,
    required this.coverageMonths,
  });
}

class InvestmentResult {
  final FinancialSummary summary;
  final List<InvestmentSuggestion> suggestions;

  InvestmentResult({required this.summary, required this.suggestions});
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}