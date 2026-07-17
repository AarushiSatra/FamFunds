const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const admin = require('firebase-admin');
const Anthropic = require('@anthropic-ai/sdk');

const { generateInvestmentSlots } = require('./ruleEngine');
const { explainInvestmentSlots } = require('./llm');

admin.initializeApp();
const db = admin.firestore();

// Set with: firebase functions:secrets:set ANTHROPIC_API_KEY
const anthropicApiKey = defineSecret('ANTHROPIC_API_KEY');

exports.getInvestmentSuggestions = onCall(
  { secrets: [anthropicApiKey] },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError('unauthenticated', 'Sign in required.');
    }

    const userDoc = await db.collection('users').doc(uid).get();
    const familyId = userDoc.data()?.familyId;
    if (!familyId) {
      throw new HttpsError('failed-precondition', 'No family found for this user.');
    }

    const accountsSnap = await db
      .collection('accounts')
      .where('familyId', '==', familyId)
      .get();
    const combinedBalance = accountsSnap.docs.reduce(
      (sum, doc) => sum + (doc.data().balance || 0),
      0
    );

    const summariesSnap = await db
      .collection('families')
      .doc(familyId)
      .collection('monthlySummaries')
      .orderBy('month', 'desc')
      .limit(6)
      .get();

    const monthlyEntries = summariesSnap.docs.map((d) => d.data());

    const avgMonthlyExpense = monthlyEntries.length
      ? monthlyEntries.reduce((sum, e) => sum + (e.fixedExpenses || 0), 0) /
        monthlyEntries.length
      : 30000; // conservative default for demo purposes

    const slots = generateInvestmentSlots({
      combinedBalance,
      avgMonthlyExpense,
      monthlyEntries,
    });

    if (!slots.length) {
      return { suggestions: [] };
    }

    const client = new Anthropic({ apiKey: anthropicApiKey.value() });
    const suggestions = await explainInvestmentSlots(client, slots);

    return { suggestions };
  }
);
/**
 * seedDemoData
 * Callable, dev/demo-only. Populates the caller's family with:
 *   - 3 linked accounts (mirrors the mock AA flow's expected shape)
 *   - 6 months of salary breakdown history
 * so getInvestmentSuggestions has real numbers to work with without
 * needing Setu sandbox access to be finished.
 */
exports.seedDemoData = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError('unauthenticated', 'Sign in required.');
  }

  const userDoc = await db.collection('users').doc(uid).get();
  let familyId = userDoc.data()?.familyId;

  if (!familyId) {
    const familyRef = await db.collection('families').add({
      members: [uid],
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    familyId = familyRef.id;
    await db.collection('users').doc(uid).update({ familyId });
  }

  const existing = await db
    .collection('accounts')
    .where('familyId', '==', familyId)
    .get();
  const batch = db.batch();
  existing.docs.forEach((doc) => batch.delete(doc.ref));

  const demoAccounts = [
    { uid, bankName: 'HDFC Bank', accountType: 'savings', maskedAccountNumber: 'XXXX 4821', balance: 92000 },
    { uid: 'demo-spouse', bankName: 'ICICI Bank', accountType: 'savings', maskedAccountNumber: 'XXXX 7734', balance: 38000 },
    { uid: 'demo-parent', bankName: 'SBI', accountType: 'savings', maskedAccountNumber: 'XXXX 2201', balance: 23000 },
  ];
  demoAccounts.forEach((acc) => {
    const ref = db.collection('accounts').doc();
    batch.set(ref, { ...acc, familyId, linkedAt: admin.firestore.FieldValue.serverTimestamp() });
  });
  await batch.commit();

  const monthlyBatch = db.batch();
  const now = new Date();
  const baseSalary = 85000;
  for (let i = 0; i < 6; i++) {
    const date = new Date(now.getFullYear(), now.getMonth() - i, 1);
    const month = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
    const variance = 1 + (Math.sin(i) * 0.05);
    const salary = Math.round(baseSalary * variance);
    const fixedExpenses = Math.round(salary * 0.45);
    const savings = Math.round(salary * 0.35);
    const discretionary = salary - fixedExpenses - savings;

    const ref = db
      .collection('families')
      .doc(familyId)
      .collection('monthlySummaries')
      .doc(month);
    monthlyBatch.set(ref, { month, salary, fixedExpenses, savings, discretionary });
  }
  await monthlyBatch.commit();

  return { familyId, accountsSeeded: demoAccounts.length, monthsSeeded: 6 };
});