import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/famfunds_ai_prompt.dart';

/// Models the user's financial profile state maintained throughout the chat session.
class UserFinancialProfile {
  double? salary;
  double? monthlyIncome;
  double? expenses;
  double? savings;
  int? age;
  double? loans;
  double? investments;
  String? financialGoals;

  UserFinancialProfile({
    this.salary,
    this.monthlyIncome,
    this.expenses,
    this.savings,
    this.age,
    this.loans,
    this.investments,
    this.financialGoals,
  });

  /// Updates profile values if new numbers are found in user query.
  /// Always prioritizes the newest values provided by the user.
  bool updateFromText(String text) {
    bool updated = false;
    final lower = text.toLowerCase();

    // Match salary / monthly income pattern e.g. "salary is 2,50,000", "income is 80000", "my salary is ₹2,50,000"
    final salaryRegex = RegExp(
        r'\b(?:salary|income|take-home|earning[s]?)\b(?:\s+(?:is|of|about|around|:))?\s*₹?\s*([\d,]+(?:\.\d+)?)\s*(k|lakh|lakhs|l)?\b');
    final salaryMatch = salaryRegex.firstMatch(lower);
    if (salaryMatch != null) {
      final rawVal = salaryMatch.group(1)?.replaceAll(',', '');
      final unit = salaryMatch.group(2);
      if (rawVal != null) {
        double? val = double.tryParse(rawVal);
        if (val != null) {
          if (unit == 'k') val *= 1000;
          if (unit == 'lakh' || unit == 'lakhs' || unit == 'l') val *= 100000;
          salary = val;
          monthlyIncome = val;
          updated = true;
        }
      }
    }

    // Match expenses pattern
    final expenseRegex = RegExp(
        r'\b(?:expense[s]?|outflow[s]?|spending)\b(?:\s+(?:is|are|of|about|around|:))?\s*₹?\s*([\d,]+(?:\.\d+)?)\s*(k|lakh|lakhs|l)?\b');
    final expenseMatch = expenseRegex.firstMatch(lower);
    if (expenseMatch != null) {
      final rawVal = expenseMatch.group(1)?.replaceAll(',', '');
      final unit = expenseMatch.group(2);
      if (rawVal != null) {
        double? val = double.tryParse(rawVal);
        if (val != null) {
          if (unit == 'k') val *= 1000;
          if (unit == 'lakh' || unit == 'lakhs' || unit == 'l') val *= 100000;
          expenses = val;
          updated = true;
        }
      }
    }

    // Match savings pattern
    final savingsRegex = RegExp(
        r'\b(?:savings|saved|reserve[s]?)\b(?:\s+(?:is|are|of|about|around|:))?\s*₹?\s*([\d,]+(?:\.\d+)?)\s*(k|lakh|lakhs|l)?\b');
    final savingsMatch = savingsRegex.firstMatch(lower);
    if (savingsMatch != null) {
      final rawVal = savingsMatch.group(1)?.replaceAll(',', '');
      final unit = savingsMatch.group(2);
      if (rawVal != null) {
        double? val = double.tryParse(rawVal);
        if (val != null) {
          if (unit == 'k') val *= 1000;
          if (unit == 'lakh' || unit == 'lakhs' || unit == 'l') val *= 100000;
          savings = val;
          updated = true;
        }
      }
    }

    // Match age pattern e.g. "i am 28 years old", "age is 30"
    final ageRegex = RegExp(r'\b(?:age|i am|i’m|im)\s*(\d{2})\s*(?:years|yrs)?\b');
    final ageMatch = ageRegex.firstMatch(lower);
    if (ageMatch != null) {
      final val = int.tryParse(ageMatch.group(1) ?? '');
      if (val != null && val > 10 && val < 100) {
        age = val;
        updated = true;
      }
    }

    return updated;
  }

  String formatCurrency(double amount) {
    final str = amount.toStringAsFixed(0);
    return '₹${str.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }
}

class ChatbotResponse {
  final String text;
  final String? widgetType; // e.g. 'budget', 'savings', 'tax', 'accounts', 'insurance', 'quiz'

  ChatbotResponse({required this.text, this.widgetType});
}

class ChatbotService {
  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent';

  /// Backend Intent Classifier Logic:
  /// Evaluates whether the user question is finance-related.
  bool isFinanceRelated(String userQuery) {
    final q = userQuery.toLowerCase().trim();
    if (q.isEmpty) return false;

    // Explicit non-finance blacklisted topics
    final nonFinanceRx = RegExp(
      r'\b('
      r'code|coding|programmer|programming|software|developer|development|javascript|python|flutter|dart|java|c\+\+|html|css|'
      r'physics|chemistry|biology|science|homework|math(?:ematics)?\s+homework|equation|'
      r'medical|doctor|symptom|illness|disease|health\s+advice|mental\s+health|therapy|depression|'
      r'sports|cricket|football|soccer|basketball|tennis|ipl|match|stadium|player|'
      r'movie|movies|cinema|film|actor|actress|celebrity|music|song|album|hollywood|bollywood|'
      r'politics|election|prime\s+minister|president|vote|political|religion|god|prayer|church|temple|mosque|'
      r'geography|capital\s+of|mountain|ocean|continent|history|historical|war|king|queen|'
      r'game|gaming|playstation|xbox|nintendo|recipe|dish|food|cooking|dinner|lunch|breakfast|'
      r'travel|vacation|hotel|flight|fashion|outfit|clothes|wear|joke|riddle|story|poem'
      r')\b',
    );

    // If query matches explicit non-finance topic, classify as non-finance
    if (nonFinanceRx.hasMatch(q)) {
      return false;
    }

    // Pleasantries / Greetings
    final greetingRx = RegExp(
        r'^\s*(hi|hello|hey|greetings|good morning|good afternoon|good evening|who are you|what can you do|help|thanks|thank you|bye|goodbye)\b');
    if (greetingRx.hasMatch(q)) {
      return true;
    }

    // Allowed Finance Topics / Keywords
    final financeRx = RegExp(
      r'\b('
      r'finance|financial|money|rupee[s]?|₹|salary|income|expense[s]?|spent|spending|outflow|budget|budgeting|'
      r'sav(e|ing|ings)|emergency\s+fund|goal[s]?|plan|planning|retire|retirement|wealth|compound|compounding|'
      r'invest|investment[s]?|stock[s]?|share[s]?|mutual\s+fund[s]?|sip[s]?|lumpsum|etf[s]?|bond[s]?|gold|silver|crypto|cryptocurrency|'
      r'index\s+fund|portfolio|diversification|asset|risk|long-term|short-term|'
      r'bank|banking|account[s]?|savings\s+account|current\s+account|fd|fixed\s+deposit|rd|recurring\s+deposit|interest|rate[s]?|'
      r'upi|neft|rtgs|imps|netbanking|internet\s+banking|mobile\s+banking|debit|credit|card[s]?|bank\s+charge[s]?|'
      r'loan[s]?|emi|eligibility|repayment|debt|cibil|credit\s+score|'
      r'insur(ance|e)?|policy|term|health\s+cover|medical\s+insurance|life\s+cover|premium|claim|'
      r'tax|taxes|itr|gst|deduction[s]?|80c|80d|slab|rebate|compliance|'
      r'business|profit|loss|revenue|cash\s+flow|pricing|cost|startup|financial\s+statement|accounting|'
      r'inflation|simple\s+interest|exchange\s+rate|forex|economy|economic|net\s+worth|ratio[s]?'
      r')\b',
    );

    // Also check for numeric value setting like "salary is 250000" or "i earn 50000"
    final valueSettingRx = RegExp(
        r'\b(?:salary|income|expense|spending|savings|earn|earned|pay)\b.*\d+');

    return financeRx.hasMatch(q) || valueSettingRx.hasMatch(q);
  }

  /// Detects if user query requests live market / interest / rate data
  bool isLiveDataQuery(String q) {
    final lower = q.toLowerCase();
    final liveRx = RegExp(
        r'\b(today|live|current|real-time|latest)\b.*\b(stock|share|nav|crypto|bitcoin|ethereum|exchange rate|interest rate|tax slab|price[s]?)\b');
    return liveRx.hasMatch(lower);
  }

  /// Generates response using Gemini API if key is set, or structured fallback logic.
  Future<ChatbotResponse> processMessage(
      String userQuery, UserFinancialProfile profile) async {
    // 1. Backend Intent Classifier check
    if (!isFinanceRelated(userQuery)) {
      return ChatbotResponse(text: famFundsAIOutOfScopeResponse);
    }

    // 2. Check for financial profile update in user query
    final profileUpdated = profile.updateFromText(userQuery);

    // 3. Check for live information request warning
    String liveWarning = '';
    if (isLiveDataQuery(userQuery)) {
      liveWarning =
          '\n\n📌 *Live Data Notice*: Stock prices, NAVs, crypto values, exchange rates, and tax slabs fluctuate continuously. Please verify current figures with official financial institutions or live market exchanges.';
    }

    // If Gemini API Key available, make LLM request with system prompt & updated context
    if (_apiKey.isNotEmpty) {
      try {
        final llmResponse = await _callGemini(userQuery, profile);
        if (llmResponse != null && llmResponse.isNotEmpty) {
          return ChatbotResponse(text: '$llmResponse$liveWarning');
        }
      } catch (e) {
        // Fallback to structured response on API error
      }
    }

    // 4. Structured Local Generator matching FamFunds AI rules
    return _generateStructuredResponse(userQuery, profile, profileUpdated, liveWarning);
  }

  Future<String?> _callGemini(String query, UserFinancialProfile profile) async {
    final contextBuffer = StringBuffer();
    if (profile.salary != null) {
      contextBuffer.writeln('User Current Salary/Income: ${profile.formatCurrency(profile.salary!)}');
    }
    if (profile.expenses != null) {
      contextBuffer.writeln('User Monthly Expenses: ${profile.formatCurrency(profile.expenses!)}');
    }
    if (profile.savings != null) {
      contextBuffer.writeln('User Savings: ${profile.formatCurrency(profile.savings!)}');
    }
    if (profile.age != null) {
      contextBuffer.writeln('User Age: ${profile.age}');
    }

    final prompt = '''
$famFundsAISystemPrompt

[User Context Profile]
${contextBuffer.isEmpty ? 'No financial profile provided yet.' : contextBuffer.toString()}

User Question: "$query"
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

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
      return text?.trim();
    }
    return null;
  }

  ChatbotResponse _generateStructuredResponse(
    String userQuery,
    UserFinancialProfile profile,
    bool profileUpdated,
    String liveWarning,
  ) {
    final query = userQuery.toLowerCase().trim();

    // Check pleasantries / greetings
    if (RegExp(r'\b(hi|hello|hey|greetings|good morning|good afternoon|good evening|who are you|what can you do|help)\b')
        .hasMatch(query)) {
      String extra = profile.salary != null
          ? ' I see your current monthly salary is ${profile.formatCurrency(profile.salary!)}. How can I assist with your financial questions today?'
          : ' How can I assist you with personal finance, budgeting, savings, investments, loans, taxes, or insurance today?';
      return ChatbotResponse(
        text: 'Hello! I am FamFunds AI, the official intelligent financial assistant for FamFunds. 🤝$extra',
      );
    }

    if (RegExp(r'\b(thanks|thank you|awesome|great|cool|bye|goodbye)\b').hasMatch(query)) {
      return ChatbotResponse(
        text: 'You\'re welcome! I am FamFunds AI, always here to educate and assist with your financial questions.',
      );
    }

    // If profile was updated just now (e.g. "My salary is ₹2,50,000")
    if (profileUpdated && profile.salary != null) {
      final salaryStr = profile.formatCurrency(profile.salary!);
      final needs = profile.formatCurrency(profile.salary! * 0.5);
      final wants = profile.formatCurrency(profile.salary! * 0.3);
      final savings = profile.formatCurrency(profile.salary! * 0.2);

      return ChatbotResponse(
        text: 'Got it! I have updated your monthly salary to **$salaryStr**.\n\n'
            'Based on your updated salary of $salaryStr, here is your personalized **50/30/20 budget recommendation**:\n'
            '• **Needs (50%)**: $needs (Rent, utilities, groceries, EMIs)\n'
            '• **Wants (30%)**: $wants (Dining, shopping, hobbies)\n'
            '• **Savings & Investments (20%)**: $savings (Emergency fund, SIPs, FDs)\n\n'
            'From now on, I will use $salaryStr for all your financial calculations and recommendations!$liveWarning',
        widgetType: 'budget',
      );
    }

    // QUESTION INTENT TYPE 1: DEFINITIONS ("what is", "what are", "meaning of", "define")
    final isDefinition = RegExp(r'\b(what is|what are|define|meaning of|definition of)\b').hasMatch(query);
    if (isDefinition) {
      if (query.contains('mutual fund')) {
        return ChatbotResponse(
          text: 'A **Mutual Fund** is an investment vehicle that pools money from multiple investors to purchase a diversified portfolio of securities such as stocks, bonds, or short-term debt securities. Each investor owns units representing a portion of the fund\'s total holdings, managed professionally by an Asset Management Company (AMC).$liveWarning',
        );
      }
      if (query.contains('sip')) {
        return ChatbotResponse(
          text: 'A **SIP (Systematic Investment Plan)** is an investment method offered by mutual funds that allows an investor to invest a fixed amount of money at regular intervals (such as monthly or quarterly) into a chosen mutual fund scheme.$liveWarning',
        );
      }
      if (query.contains('emergency fund')) {
        return ChatbotResponse(
          text: 'An **Emergency Fund** is a dedicated cash reserve set aside to cover unexpected life expenses or financial emergencies—such as medical crises, sudden job loss, or urgent home repairs—without taking on high-interest debt.$liveWarning',
        );
      }
      if (query.contains('cibil') || query.contains('credit score')) {
        return ChatbotResponse(
          text: 'A **Credit Score (CIBIL Score)** is a 3-digit numerical summary (ranging from 300 to 900) of your credit history and repayment behavior. Lenders use it to evaluate your creditworthiness before approving loans or credit cards.$liveWarning',
        );
      }
      if (query.contains('fd') || query.contains('fixed deposit')) {
        return ChatbotResponse(
          text: 'A **Fixed Deposit (FD)** is a financial instrument provided by banks and NBFCs where you deposit a lump sum of money for a fixed tenure at a predetermined, guaranteed interest rate.$liveWarning',
        );
      }
    }

    // QUESTION INTENT TYPE 2: PROCESS ("how do", "how does", "how to", "process of")
    final isProcess = RegExp(r'\b(how do|how does|how to|how works|process of|working of)\b').hasMatch(query);
    if (isProcess) {
      if (query.contains('sip')) {
        return ChatbotResponse(
          text: 'Here is **how a SIP (Systematic Investment Plan) works**:\n\n'
              '1. **Auto-Deduction**: On a fixed date each month, a set amount is automatically debited from your bank account.\n'
              '2. **Unit Allocation**: The funds purchase mutual fund units based on the scheme\'s current Net Asset Value (NAV).\n'
              '3. **Rupee Cost Averaging**: When market prices are lower, you buy more units; when prices are higher, you buy fewer units.\n'
              '4. **Compounding**: Returns generated earn additional returns over time, multiplying your wealth over long periods.$liveWarning',
        );
      }
      if (query.contains('budget')) {
        return ChatbotResponse(
          text: 'Here is **how to create a budget step-by-step**:\n\n'
              '1. **Calculate Total Income**: Identify your monthly net take-home salary.\n'
              '2. **List Essential Outflows**: Subtract mandatory expenses (rent, groceries, EMIs, utilities).\n'
              '3. **Allocate 50/30/20**: Direct 50% to Needs, 30% to Wants, and 20% to Savings.\n'
              '4. **Track & Adjust**: Log weekly expenses to ensure you remain within limits.$liveWarning',
          widgetType: 'budget',
        );
      }
    }

    // QUESTION INTENT TYPE 3: GUIDANCE / DECISION ("should i", "is it good to", "would it be wise")
    final isGuidance = RegExp(r'\b(should i|is it good|is it wise|would it be good)\b').hasMatch(query);
    if (isGuidance) {
      if (query.contains('mutual fund')) {
        return ChatbotResponse(
          text: 'Investing in mutual funds can be beneficial if you seek inflation-beating growth and professional portfolio management.\n\n'
              '• **Benefits**: High liquidity, diversification across multiple companies, professional management, low entry barriers.\n'
              '• **Risks**: Market volatility, potential short-term value fluctuations.\n'
              '• **Guidance**: Align your investment with your specific timeframe and risk tolerance. For short-term goals (< 3 years), prefer Debt/Liquid funds; for long-term goals (> 5 years), consider Equity funds.$liveWarning',
        );
      }
    }

    // QUESTION INTENT TYPE 4: RECOMMENDATION ("which is best", "recommend", "best mutual fund", "best investment", "which scheme")
    final isRecommendation = RegExp(r'\b(which is best|best|recommend|suggest|which scheme|top)\b').hasMatch(query);
    if (isRecommendation) {
      if (query.contains('mutual fund') || query.contains('invest')) {
        return ChatbotResponse(
          text: 'The "best" mutual fund category depends directly on your financial goals and timeframe:\n\n'
              '• **For Long-Term Growth (> 5 years)**: Nifty 50 Index Funds or Flexi-Cap Equity Funds offer broad market diversification.\n'
              '• **For Medium-Term Goals (3-5 years)**: Large-Cap Equity Funds or Hybrid Funds provide stability with growth.\n'
              '• **For Short-Term Safety (< 3 years)**: Liquid Funds or Short-Duration Debt Funds protect principal while providing liquidity.\n\n'
              '⚠️ *Note: Recommendations should match your risk tolerance. Evaluate fund performance history and expense ratios before investing.$liveWarning',
          widgetType: 'savings',
        );
      }
    }

    // QUESTION INTENT TYPE 5: COMPARISON ("compare", "vs", "difference between")
    final isComparison = RegExp(r'\b(compare|vs|versus|difference between|diff between)\b').hasMatch(query);
    if (isComparison) {
      if ((query.contains('fd') || query.contains('fixed deposit')) && query.contains('mutual fund')) {
        return ChatbotResponse(
          text: 'Here is an unbiased comparison between **Fixed Deposits (FD)** and **Mutual Funds**:\n\n'
              '• **Returns**: FD returns are fixed and guaranteed (typically 6-7.5%); Equity Mutual Fund returns fluctuate with market conditions but historically yield 10-14% long-term.\n'
              '• **Risk**: FDs carry low risk; Mutual Funds carry market risk.\n'
              '• **Liquidity**: FDs may impose penalty on early withdrawal; Liquid/Equity Mutual Funds allow redemption anytime (subject to exit load/tax rules).\n'
              '• **Inflation Protection**: FDs may lag behind inflation; Equity Mutual Funds are designed to beat inflation over time.$liveWarning',
        );
      }
    }

    // QUESTION INTENT TYPE 6: REASONING ("why", "why should i")
    final isWhy = RegExp(r'\b(why|why should|why do)\b').hasMatch(query);
    if (isWhy) {
      if (query.contains('sav') || query.contains('invest')) {
        return ChatbotResponse(
          text: 'Saving and investing are crucial because of **Inflation** and **Compounding**:\n\n'
              '1. **Defeating Inflation**: Prices rise yearly, diminishing cash purchasing power. Investing helps your capital grow faster than inflation.\n'
              '2. **Financial Security**: An emergency fund prevents debt when unexpected expenses arise.\n'
              '3. **Wealth Creation**: Compounding allows your earnings to generate their own earnings over time.$liveWarning',
        );
      }
    }

    // FALLBACK INTENT CATEGORIZATIONS IF EXPLICIT INTENT PREFIX IS NOT INCLUDED

    // Budgeting intent fallback
    if (RegExp(r'\b(budget|budgeting|allocate|50/30/20|expense rule)\b').hasMatch(query)) {
      String personalization = '';
      if (profile.salary != null) {
        final salaryStr = profile.formatCurrency(profile.salary!);
        final needs = profile.formatCurrency(profile.salary! * 0.5);
        final wants = profile.formatCurrency(profile.salary! * 0.3);
        final savings = profile.formatCurrency(profile.salary! * 0.2);
        personalization = '\n\n**Personalized breakdown for your salary of $salaryStr**:\n'
            '• **Needs (50%)**: $needs\n'
            '• **Wants (30%)**: $wants\n'
            '• **Savings (20%)**: $savings';
      }

      return ChatbotResponse(
        text: 'Budgeting gives every Rupee a clear purpose! The **50/30/20 Rule** is a practical framework:\n\n'
            '• **50% Needs**: Essential living costs (rent, groceries, bills, debt repayments).\n'
            '• **30% Wants**: Lifestyle outlays (entertainment, dining out, subscriptions).\n'
            '• **20% Savings**: Wealth creation (emergency reserves, mutual funds, SIPs).'
            '$personalization$liveWarning',
        widgetType: 'budget',
      );
    }

    // Savings & Emergency Fund intent fallback
    if (RegExp(r'\b(sav(e|ing|ings)|emergency fund|rainy day|how to save)\b').hasMatch(query)) {
      String details = '';
      if (profile.expenses != null) {
        final reqFund = profile.formatCurrency(profile.expenses! * 6);
        details = '\n\nBased on your monthly expenses of ${profile.formatCurrency(profile.expenses!)}, your target emergency fund (6 months) is **$reqFund**.';
      }
      return ChatbotResponse(
        text: 'Building a disciplined savings strategy is your financial foundation! Key recommendations:\n\n'
            '1. **Emergency Fund**: Maintain 6 months of fixed expenses in a liquid savings account or FD.\n'
            '2. **Automate Savings**: Set up automated transfers on salary day.\n'
            '3. **Goal-Based Buckets**: Assign specific timelines to short and long-term targets.'
            '$details$liveWarning',
        widgetType: 'savings',
      );
    }

    // Expenses intent fallback
    if (RegExp(r'\b(expense(s)?|spent|spending|track(ing)?|transaction(s)?|outflow)\b').hasMatch(query)) {
      return ChatbotResponse(
        text: 'Tracking expenses prevents leakages in household cash flow:\n\n'
            '• Categorize transactions into Needs vs. Wants.\n'
            '• Conduct monthly subscription audits.\n'
            '• Review spending alerts on your FamFunds dashboard.$liveWarning',
      );
    }

    // Investments / SIP intent fallback
    if (RegExp(r'\b(invest(ment|ing|s)?|stock(s)?|mutual fund(s)?|sip|lumpsum|etf|bond|gold|crypto|portfolio|asset)\b')
        .hasMatch(query)) {
      return ChatbotResponse(
        text: 'Investing helps your money outperform inflation over time. Here is a practical overview:\n\n'
            '• **Low Risk**: Fixed Deposits (FD), Debt Mutual Funds, PPF (Best for goals < 3 years).\n'
            '• **Moderate Risk**: Index Funds, Balanced Advantage Funds.\n'
            '• **High Risk**: Direct Equity Shares, Mid/Small-Cap Funds (Best for long-term goals > 5-7 years).\n\n'
            '⚠️ *Investment Risk Note*: All investments carry market risk. Diversify across asset classes and match your risk tolerance.$liveWarning',
      );
    }

    // Insurance intent fallback
    if (RegExp(r'\b(insur(ance|e)?|policy|term plan|health cover|life cover|premium|claim)\b').hasMatch(query)) {
      return ChatbotResponse(
        text: 'Insurance is the protective shield for your family\'s wealth:\n\n'
            '• **Term Life Insurance**: Aim for coverage 10x-15x your annual salary.\n'
            '• **Health Insurance**: Base policy of ₹5-10 Lakhs plus Super Top-up.\n'
            '• **Motor Insurance**: Comprehensive cover with zero-depreciation rider for vehicles.$liveWarning',
        widgetType: 'insurance',
      );
    }

    // Taxes intent fallback
    if (RegExp(r'\b(tax(es)?|itr|slab|80c|80d|deduction(s)?|income tax|gst)\b').hasMatch(query)) {
      return ChatbotResponse(
        text: 'Tax planning optimizes your net take-home pay legally:\n\n'
            '• **New Tax Regime (FY 2025-26)**: Auto ₹75,000 standard deduction, tax-free rebate up to ₹7 Lakhs.\n'
            '• **Old Tax Regime**: Utilize Section 80C (PPF, ELSS, EPF up to ₹1.5L) and Section 80D (Health Insurance).\n\n'
            'Check out our interactive Tax Estimator below to calculate your estimated tax liability!$liveWarning',
        widgetType: 'tax',
      );
    }

    // Banking & Accounts intent fallback
    if (RegExp(r'\b(bank(ing)?|account(s)?|balance|fd|rd|deposit|loan(s)?|credit card|debit|upi|neft|rtgs|imps)\b')
        .hasMatch(query)) {
      return ChatbotResponse(
        text: 'Here is your linked family bank accounts overview and combined balance snapshot:$liveWarning',
        widgetType: 'accounts',
      );
    }

    // Quiz / Literacy intent fallback
    if (RegExp(r'\b(quiz|learn|test|literacy|education|rule of 72|inflation|compound interest|knowledge)\b')
        .hasMatch(query)) {
      return ChatbotResponse(
        text: 'Testing your financial literacy strengthens healthy money habits! Try this quick finance challenge:$liveWarning',
        widgetType: 'quiz',
      );
    }

    // General Finance Guidance default
    String salaryContext = profile.salary != null
        ? ' (based on your registered salary of ${profile.formatCurrency(profile.salary!)})'
        : '';
    return ChatbotResponse(
      text: 'As FamFunds AI, I can help answer your specific finance questions$salaryContext on budgeting, savings, investments, loans, taxes, or insurance. What would you like to ask?$liveWarning',
    );
  }
}
