import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/family_models.dart';
import 'rule_engine.dart';

/// DEMO-ONLY: calls the Gemini API directly from the client, since
/// Cloud Functions requires the Blaze plan. Never reuse this pattern
/// in production — the API key ships inside the client bundle.
class InvestmentService {
  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent';
  final _db = FirebaseFirestore.instance;

  Future<InvestmentResult?> getSuggestions() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('No signed-in user.');

    final userDoc = await _db.collection('users').doc(uid).get();
    final familyId = userDoc.data()?['familyId'] as String?;
    if (familyId == null) return null;

    final accountsSnap = await _db
        .collection('accounts')
        .where('familyId', isEqualTo: familyId)
        .get();
    final combinedBalance = accountsSnap.docs.fold<double>(
        0, (sum, doc) => sum + ((doc.data()['balance'] ?? 0) as num).toDouble());

    final summariesSnap = await _db
        .collection('families')
        .doc(familyId)
        .collection('monthlySummaries')
        .orderBy('month', descending: true)
        .limit(6)
        .get();
    final monthlyEntries = summariesSnap.docs.map((d) => d.data()).toList();

    final avgMonthlyExpense = monthlyEntries.isNotEmpty
        ? monthlyEntries.fold<double>(
                0, (sum, e) => sum + ((e['fixedExpenses'] ?? 0) as num).toDouble()) /
            monthlyEntries.length
        : 30000.0;

    final avgMonthlySurplus = computeAvgMonthlySurplus(monthlyEntries);
    final coverageMonths = computeEmergencyFundCoverage(combinedBalance, avgMonthlyExpense);

    final summary = FinancialSummary(
      combinedBalance: combinedBalance,
      avgMonthlyExpense: avgMonthlyExpense,
      avgMonthlySurplus: avgMonthlySurplus,
      coverageMonths: coverageMonths,
    );

    final slots = generateInvestmentSlots(
      combinedBalance: combinedBalance,
      avgMonthlyExpense: avgMonthlyExpense,
      monthlyEntries: monthlyEntries,
    );

    if (slots.isEmpty) {
      return InvestmentResult(summary: summary, suggestions: []);
    }

    final suggestions = await _explainSlots(slots);
    return InvestmentResult(summary: summary, suggestions: suggestions);
  }

  Future<List<InvestmentSuggestion>> _explainSlots(List<InvestmentSlot> slots) async {
    final slotsJson = slots
        .map((s) => {'type': s.type, 'riskLevel': s.riskLevel, 'facts': s.facts})
        .toList();

    final prompt = '''
You are FinFamily's financial explanation assistant, writing for someone
with NO finance background. You will be given a JSON array of investment
suggestion "slots". Each slot already contains every number you're
allowed to use — do NOT invent, estimate, or recompute any figure.

For each slot write:
- "title": a short action-oriented title (under 8 words)
- "description": 1 sentence in the SIMPLEST possible everyday language,
  as if explaining to a friend with no finance knowledge — use the exact
  numbers given, avoid jargon like "consistency ratio" or "coverage
  months" in this field, just plain talk (e.g. "you have enough saved
  to cover 4 months of expenses, but aim for 6")
- "aiRationale": 1-2 sentences on WHY this matters, also in plain
  language, still no invented numbers
- For any "high" riskLevel slot, make both fields noticeably more
  cautious — mention this involves real ups and downs in value.

Respond with ONLY a JSON array, same length and order as input:
{"title": "...", "description": "...", "riskLevel": "...", "aiRationale": "..."}
Copy "riskLevel" directly from the input slot unchanged.

Input slots:
${jsonEncode(slotsJson)}
''';

    final response = await http.post(
      Uri.parse('$_apiUrl?key=$_apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Gemini API error: ${response.statusCode} ${response.body}');
    }

    final data = jsonDecode(response.body);
    final text = data['candidates'][0]['content']['parts'][0]['text'] as String;
    final cleaned = text.replaceAll(RegExp(r'```json|```'), '').trim();

    try {
      final parsed = jsonDecode(cleaned) as List;
      return List.generate(parsed.length, (i) {
        final item = parsed[i];
        final slot = slots[i];
        return InvestmentSuggestion(
          type: slot.type,
          title: item['title'] ?? '',
          description: item['description'] ?? '',
          riskLevel: item['riskLevel'] ?? 'low',
          aiRationale: item['aiRationale'] ?? '',
          facts: slot.facts,
          actionUrl: actionUrlFor(slot.type),
          actionLabel: actionLabelFor(slot.type),
        );
      });
    } catch (_) {
      return slots
          .map((s) => InvestmentSuggestion(
                type: s.type,
                title: s.type.replaceAll('_', ' '),
                description: 'Based on your linked accounts.',
                riskLevel: s.riskLevel,
                aiRationale: 'Generated from your financial data.',
                facts: s.facts,
                actionUrl: actionUrlFor(s.type),
                actionLabel: actionLabelFor(s.type),
              ))
          .toList();
    }
  }

  Future<void> seedDemoData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('No signed-in user.');

    final userDoc = await _db.collection('users').doc(uid).get();
    String? familyId = userDoc.data()?['familyId'] as String?;

    if (familyId == null) {
      final familyRef = await _db.collection('families').add({
        'members': [uid],
        'createdAt': FieldValue.serverTimestamp(),
      });
      familyId = familyRef.id;
      await _db.collection('users').doc(uid).set(
        {'familyId': familyId},
        SetOptions(merge: true),
      );
    }

    final existing = await _db
        .collection('accounts')
        .where('familyId', isEqualTo: familyId)
        .get();
    final batch = _db.batch();
    for (final doc in existing.docs) {
      batch.delete(doc.reference);
    }

    final demoAccounts = [
  {'uid': uid, 'bankName': 'HDFC Bank', 'accountType': 'savings', 'maskedAccountNumber': 'XXXX 4821', 'balance': 50000},
  {'uid': 'demo-spouse', 'bankName': 'ICICI Bank', 'accountType': 'savings', 'maskedAccountNumber': 'XXXX 7734', 'balance': 1120000},
  {'uid': 'demo-parent', 'bankName': 'SBI', 'accountType': 'savings', 'maskedAccountNumber': 'XXXX 2201', 'balance': 180000},
];
    for (final acc in demoAccounts) {
      final ref = _db.collection('accounts').doc();
      batch.set(ref, {...acc, 'familyId': familyId, 'linkedAt': FieldValue.serverTimestamp()});
    }
    await batch.commit();

    final monthlyBatch = _db.batch();
    final now = DateTime.now();
    const baseSalary = 185000.0;
    for (int i = 0; i < 6; i++) {
      final date = DateTime(now.year, now.month - i, 1);
      final month = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      final variance = 1 + (0.05 * (i.isEven ? 1 : -1));
      final salary = (baseSalary * variance).round();
      final fixedExpenses = (salary * 0.45).round();
      final savings = (salary * 0.35).round();
      final discretionary = salary - fixedExpenses - savings;

      final ref = _db
          .collection('families')
          .doc(familyId)
          .collection('monthlySummaries')
          .doc(month);
      monthlyBatch.set(ref, {
        'month': month,
        'salary': salary,
        'fixedExpenses': fixedExpenses,
        'savings': savings,
        'discretionary': discretionary,
      });
    }
    await monthlyBatch.commit();
  }
}