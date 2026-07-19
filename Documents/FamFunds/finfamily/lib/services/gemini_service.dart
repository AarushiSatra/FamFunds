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
You are FamFunds AI, a personal finance assistant.
Your purpose is to help users with:
- Budgeting
- Saving money
- Expense tracking
- Financial planning
- Investments (general educational information only)
- Insurance
- Taxes (general guidance)
- Banking
- Financial literacy

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

CRITICAL RULE:
If a user asks a question unrelated to personal finance (such as programming, software engineering, sports, entertainment, history, homework, geography, general science, or general knowledge), you MUST politely decline and say exactly:
"I’m the FamFunds financial assistant, so I can only help with personal finance, budgeting, savings, investments, and related topics. Please ask me a finance-related question."

Do NOT answer unrelated questions under any circumstances. Do not ask the user for any API keys or give any options to configure API keys.
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

  String _formatRupees(double amount) {
    final intVal = amount.round();
    final str = intVal.toString();
    if (str.length <= 3) return str;
    
    var result = '';
    var count = 0;
    for (var i = str.length - 1; i >= 0; i--) {
      if (count == 3) {
        result = ',$result';
      } else if (count > 3 && (count - 3) % 2 == 0) {
        result = ',$result';
      }
      result = str[i] + result;
      count++;
    }
    return result;
  }

  /// Local simulated financial assistant responses for offline/no-key usage.
  Future<String> sendLocalResponse(String text) async {
    // Artificial delay to simulate thinking (makes it feel premium!)
    await Future.delayed(const Duration(milliseconds: 900));

    final query = text.toLowerCase().trim();

    // 1. Check for greetings
    final greetings = ['hi', 'hello', 'hey', 'greetings', 'yo', 'howdy'];
    bool isGreeting = greetings.any((g) => query == g || query.startsWith('$g ') || query.contains(' $g'));

    // 2. Check for unrelated topic triggers
    final unrelatedKeywords = [
      'code', 'python', 'javascript', 'c++', 'java', 'html', 'css', 'function', 'variable', 'database', 'api', 'sql', 'programming', 'compile', 'git', 'developer',
      'sport', 'sports', 'football', 'cricket', 'soccer', 'tennis', 'basketball', 'olympics', 'match', 'game', 'score', 'ipl', 'athlete',
      'movie', 'film', 'song', 'music', 'actor', 'actress', 'show', 'series', 'netflix', 'celebrity', 'singer',
      'history', 'war', 'king', 'queen', 'ancient', 'empire', 'president', 'century', 'historical', 'dynasty',
      'homework', 'physics', 'chemistry', 'biology', 'science', 'solve', 'equation', 'geography', 'capital of', 'weather', 'joke', 'recipe', 'cook', 'food', 'poem',
    ];

    // If query contains unrelated triggers, decline.
    bool hasUnrelatedTrigger = unrelatedKeywords.any((keyword) => query.contains(keyword));

    // 3. Check for related finance keywords
    final financeKeywords = [
      'rate', 'saving', 'salary', 'budget', 'breakdown', 'expense', 'spend', 'earn', 'cost', 'income',
      'balance', 'total', 'money', 'account', 'linked', 'bank', 'hdfc', 'icici', 'sbi', 'sharma',
      'sip', 'invest', 'mutual fund', 'stock', 'share', 'equity', 'smarter', 'grow', 'compound', 'interest', 'market', 'wealth',
      'loan', 'compare', 'emi', 'interest', 'borrow', 'debt',
      'emergency', 'buffer', 'safety',
      'tax', 'taxes', 'gst', 'itr', 'deduction', 'income tax',
      'insurance', 'policy', 'premium', 'term plan', 'health insurance', 'lic',
      'finance', 'financial', 'budgeting', 'saving money', 'expense tracking', 'financial planning', 'banking', 'financial literacy'
    ];

    bool hasFinanceKeyword = financeKeywords.any((keyword) => query.contains(keyword));

    if (hasUnrelatedTrigger || (!isGreeting && !hasFinanceKeyword)) {
      return "I’m the FamFunds financial assistant, so I can only help with personal finance, budgeting, savings, investments, and related topics. Please ask me a finance-related question.";
    }

    if (isGreeting) {
      return "Hello! I'm **FamFunds AI**, your personal finance assistant. I have analyzed the Sharma Family's financial profile. Ask me anything about your balance, savings, loans, or investments!";
    }

    if (query.contains('rate') || query.contains('saving') || query.contains('salary') || query.contains('budget') || query.contains('breakdown') || query.contains('expense') || query.contains('spend') || query.contains('cost') || query.contains('income')) {
      double? customSalary;
      final regExp = RegExp(r'\b(\d{1,3}(?:,\d{3})*(?:\.\d+)?|\d+(?:\.\d+)?)\s*(k|lakh|lakhs|lac|lacs)?\b');
      final match = regExp.firstMatch(query);
      if (match != null) {
        final numStr = match.group(1)!.replaceAll(',', '');
        final suffix = match.group(2)?.toLowerCase();
        double? val = double.tryParse(numStr);
        if (val != null) {
          if (suffix == 'k') {
            val *= 1000;
          } else if (suffix != null && (suffix.startsWith('lakh') || suffix.startsWith('lac'))) {
            val *= 100000;
          }
          if (val >= 1000) {
            customSalary = val;
          }
        }
      }

      final salary = customSalary ?? 85000.0;
      final fixedExpenses = salary * 0.45;
      final savings = salary * 0.35;
      final discretionary = salary * 0.20;

      final salaryStr = _formatRupees(salary);
      final fixedStr = _formatRupees(fixedExpenses);
      final savingsStr = _formatRupees(savings);
      final discretionaryStr = _formatRupees(discretionary);

      double sipRecommend = 5000;
      if (customSalary != null) {
        sipRecommend = (customSalary * 0.06 / 1000).round() * 1000.0;
        if (sipRecommend < 1000) sipRecommend = 1000;
      }
      final sipRecommendStr = _formatRupees(sipRecommend);

      return "Of your **₹$salaryStr monthly family salary**, here is the breakdown:\n\n"
          "- **Fixed Expenses**: 45% (₹$fixedStr) - Covers rent, bills, and EMIs.\n"
          "- **Savings**: 35% (₹$savingsStr) - Directed to your linked bank accounts.\n"
          "- **Discretionary**: 20% (₹$discretionaryStr) - Fun budget.\n\n"
          "Your **35% savings rate** is excellent! We recommend setting up an automatic transfer of **₹$sipRecommendStr/mo** to your mutual fund SIP.";
    }

    if (query.contains('balance') || query.contains('total') || query.contains('money') || query.contains('account') || query.contains('linked') || query.contains('bank')) {
      return "The Sharma Family's combined balance across all linked accounts is **₹5,93,600**:\n\n"
          "- **HDFC Bank** (You): **₹1,84,200**\n"
          "- **ICICI Bank** (Spouse): **₹96,500**\n"
          "- **SBI** (Parent): **₹3,12,900**\n\n"
          "Your family balance is up **+8.2%** this month!";
    }

    if (query.contains('sip') || query.contains('invest') || query.contains('mutual fund') || query.contains('stock') || query.contains('share') || query.contains('equity') || query.contains('smarter')) {
      return "Here are our current **Investment Suggestions**:\n\n"
          "1. **Increase SIP by ₹5,000/mo** (Low Risk): You have a consistent ₹8,000+ monthly surplus. Compounding this in HDFC Mutual Fund will yield faster returns than leaving it idle.\n"
          "2. **Build a 6-month Emergency Fund** (Low Risk): Your current balance covers **2.3 months** of expenses. We recommend reaching **6 months** (approx. ₹2.3 Lakhs) before expanding high-risk equity positions.\n"
          "3. **Explore Equity Mutual Funds** (Medium Risk): Once emergency reserves are complete, diversify into mid-cap index funds.";
    }

    if (query.contains('loan') || query.contains('compare') || query.contains('emi') || query.contains('interest') || query.contains('borrow') || query.contains('debt')) {
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

    if (query.contains('tax') || query.contains('gst') || query.contains('itr') || query.contains('insurance') || query.contains('policy') || query.contains('premium') || query.contains('finance') || query.contains('planning') || query.contains('literacy')) {
      return "I am your **FamFunds AI** assistant. I specialize in personal finance, budgeting, savings, investments, insurance, and taxes. \n\n"
          "While I am running in local offline mode, here are some questions you can ask me:\n"
          "- *What is our total balance?*\n"
          "- *How is our savings rate?*\n"
          "- *Should we increase our SIP?*\n"
          "- *Compare our loan options.*";
    }

    return "I am your **FamFunds AI** assistant. I specialize in your household budget, savings, and investments. \n\n"
        "Here are some questions you can ask me:\n"
        "- *What is our total balance?*\n"
        "- *How is our savings rate?*\n"
        "- *Should we increase our SIP?*\n"
        "- *Compare our loan options.*";
  }
}
