import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GeminiService {
  GeminiService._();
  static final GeminiService instance = GeminiService._();

  static const String _keyApiKey = 'gemini_api_key';

  String? _preferredModelName;

  Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyApiKey);
  }

  Future<void> saveApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyApiKey, apiKey);
    _preferredModelName = null; // Reset to re-negotiate model name
  }

  Future<void> removeApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyApiKey);
    _preferredModelName = null;
  }

  Future<bool> hasKey() async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty;
  }

  Future<GenerativeModel> _getOrInitModel(String modelName) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw StateError('No Gemini API key configured.');
    }

    const systemPrompt = '''
You are the FinFamily Assistant, a smart, friendly, and helpful financial literacy and planning assistant for the Sharma family.
Here is the household financial context you have access to:
- Household Name: The Sharma Family
- Combined Balance: ₹5,93,600
- Linked Accounts:
  1. HDFC Bank (You - XXXX 4821): ₹1,84,200
  2. ICICI Bank (Spouse - XXXX 7734): ₹96,500
  3. SBI (Parent - XXXX 2201): ₹3,12,900
- Salary Details:
  - Monthly Salary: ₹85,000
  - Split: 45% (₹38,250) Fixed Expenses, 35% (₹29,750) Savings, 20% (₹17,000) Discretionary spending
- Current Financial Advice:
  1. Increase SIP by ₹5,000/mo (Risk: Low). Surplus is ₹8,000+ left after expenses.
  2. Build a 6-month emergency fund (Risk: Low). Currently only covers 2.3 months.
  3. Explore equity mutual funds (Risk: Medium) once emergency fund is built.

Provide helpful advice, explain financial concepts (savings, loans, investing, compound interest) in plain language, and make tailored suggestions using the family's financial context when appropriate. Be concise, polite, and professional. Use markdown formatting like bold text and lists where helpful to make your answers readable. Keep responses relatively short and direct.
''';

    return GenerativeModel(
      model: modelName,
      apiKey: apiKey,
      systemInstruction: Content.system(systemPrompt),
    );
  }

  /// Sends a message to the Gemini API or falls back to local responses if no key exists.
  Future<String> sendMessage(String text, List<Content> history) async {
    final hasApiKey = await hasKey();
    if (!hasApiKey) {
      return sendLocalResponse(text);
    }

    final candidates = [
      if (_preferredModelName != null) _preferredModelName!,
      'gemini-1.5-flash',
      'gemini-2.5-flash',
      'gemini-2.0-flash',
      'gemini-1.5-pro',
      'gemini-pro',
    ];

    final uniqueCandidates = candidates.toSet().toList();
    Object? lastError;

    for (final modelName in uniqueCandidates) {
      try {
        final model = await _getOrInitModel(modelName);
        final chat = model.startChat(history: history);
        final response = await chat.sendMessage(Content.text(text));
        
        _preferredModelName = modelName;
        return response.text ?? 'Empty response received from Gemini.';
      } catch (e) {
        lastError = e;
        final errStr = e.toString().toLowerCase();
        
        if (errStr.contains('not found') || 
            errStr.contains('not supported') || 
            errStr.contains('404') || 
            errStr.contains('does not exist') ||
            errStr.contains('unsupported')) {
          if (_preferredModelName == modelName) {
            _preferredModelName = null;
          }
          continue;
        } else {
          rethrow;
        }
      }
    }

    throw lastError ?? StateError('All candidate models failed to initialize.');
  }

  /// Local simulated financial assistant responses for offline/no-key usage.
  Future<String> sendLocalResponse(String text) async {
    // Artificial delay to simulate thinking (makes it feel premium!)
    await Future.delayed(const Duration(milliseconds: 900));

    final query = text.toLowerCase();

    if (query.contains('hi') || query.contains('hello') || query.contains('hey')) {
      return "Hello! I'm your **FinFamily Assistant**. I have analyzed the Sharma Family's financial profile. Ask me anything about your balance, savings, loans, or investments!";
    }

    if (query.contains('rate') || query.contains('saving') || query.contains('salary') || query.contains('budget') || query.contains('breakdown')) {
      return "Of your **₹85,000 monthly family salary**, here is the breakdown:\n\n"
          "- **Fixed Expenses**: 45% (₹38,250) - Covers rent, bills, and EMIs.\n"
          "- **Savings**: 35% (₹29,750) - Directed to your linked bank accounts.\n"
          "- **Discretionary**: 20% (₹17,000) - Fun budget.\n\n"
          "Your **35% savings rate** is excellent! We recommend setting up an automatic transfer of **₹5,000/mo** to your mutual fund SIP.";
    }

    if (query.contains('balance') || query.contains('total') || query.contains('how much money') || query.contains('account') || query.contains('linked')) {
      return "The Sharma Family's combined balance across all linked accounts is **₹5,93,600**:\n\n"
          "- **HDFC Bank** (You): **₹1,84,200**\n"
          "- **ICICI Bank** (Spouse): **₹96,500**\n"
          "- **SBI** (Parent): **₹3,12,900**\n\n"
          "Your family balance is up **+8.2%** this month!";
    }

    if (query.contains('sip') || query.contains('invest') || query.contains('mutual fund') || query.contains('stock') || query.contains('smarter')) {
      return "Here are our current **Investment Suggestions**:\n\n"
          "1. **Increase SIP by ₹5,000/mo** (Low Risk): You have a consistent ₹8,000+ monthly surplus. Compounding this in HDFC Mutual Fund will yield faster returns than leaving it idle.\n"
          "2. **Build a 6-month Emergency Fund** (Low Risk): Your current balance covers **2.3 months** of expenses. We recommend reaching **6 months** (approx. ₹2.3 Lakhs) before expanding high-risk equity positions.\n"
          "3. **Explore Equity Mutual Funds** (Medium Risk): Once emergency reserves are complete, diversify into mid-cap index funds.";
    }

    if (query.contains('loan') || query.contains('compare') || query.contains('emi') || query.contains('interest')) {
      return "We compared personal and gold loan options for you:\n\n"
          "- **SBI Gold Loan (Parent account)**: **9.8% p.a.** (EMI: ₹9,420/mo, Interest: ₹98,600) - *Recommended / Best Option*\n"
          "- **HDFC Bank Personal Loan**: **11.2% p.a.** (EMI: ₹9,850/mo, Interest: ₹1,18,200)\n"
          "- **ICICI Bank Personal Loan**: **12.5% p.a.** (EMI: ₹10,120/mo, Interest: ₹1,34,400)\n\n"
          "Using the parent's SBI Gold Loan option will save the household **₹35,800** in interest compared to ICICI!";
    }

    if (query.contains('emergency') || query.contains('buffer') || query.contains('safety')) {
      return "Your family currently has **₹5,93,600** total balance, which covers **2.3 months** of household fixed expenses. "
          "We recommend building a safety net that covers at least **6 months** of expenses. Try to redirect **₹10,000/mo** of your savings into a high-yield liquid fund until that buffer is met.";
    }

    if (query.contains('compound') || query.contains('grow')) {
      return "Compound interest is when the interest you earn on your money starts earning interest itself! "
          "For example, if you invest **₹5,000/mo** in a mutual fund compounding at **12% p.a.**:\n"
          "- In **5 years**: You will have **₹4.1 Lakhs**\n"
          "- In **10 years**: You will have **₹11.6 Lakhs**\n\n"
          "Starting early is the key to building wealth!";
    }

    return "I am your **FinFamily Assistant**. I specialize in your household budget, savings, and investments. \n\n"
        "Here are some questions you can ask me:\n"
        "- *What is our total balance?*\n"
        "- *How is our savings rate?*\n"
        "- *Should we increase our SIP?*\n"
        "- *Compare our loan options.*\n\n"
        "*(Optional: You can connect your Gemini API key in the top right corner to ask any general financial questions!)*";
  }
}
