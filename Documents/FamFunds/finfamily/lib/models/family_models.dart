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
  final String ownerUid;
  final String bankName;
  final String accountType; // savings | current
  final String maskedAccountNumber;
  final double balance;

  LinkedAccount({
    required this.accountId,
    required this.ownerUid,
    required this.bankName,
    required this.accountType,
    required this.maskedAccountNumber,
    required this.balance,
  });

  factory LinkedAccount.fromMap(String id, Map<String, dynamic> map) {
    return LinkedAccount(
      accountId: id,
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
  final String title;
  final String description;
  final String riskLevel; // low | medium | high
  final String aiRationale;

  InvestmentSuggestion({
    required this.title,
    required this.description,
    required this.riskLevel,
    required this.aiRationale,
  });
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
