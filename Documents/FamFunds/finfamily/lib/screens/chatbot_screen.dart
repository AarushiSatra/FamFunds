import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/chatbot_service.dart';
import '../constants/famfunds_ai_prompt.dart';

/// Models a local chat entry in the screen session
class ChatEntry {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final Widget? customWidget;

  ChatEntry({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.customWidget,
  });
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final List<ChatEntry> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatbotService _chatbotService = ChatbotService();
  final UserFinancialProfile _financialProfile = UserFinancialProfile();
  bool _isTyping = false;

  final List<String> _suggestions = [
    '📊 Calculate Budget',
    '🎯 Savings Calculator',
    '🏦 Combined Balance',
    '📈 Investment Guide',
    '🛡️ Insurance Guide',
    '📝 Tax Estimator',
    '🧠 Take Finance Quiz',
  ];

  @override
  void initState() {
    super.initState();
    // Welcome message from FamFunds AI
    _messages.add(
      ChatEntry(
        text: 'Hello! I am FamFunds AI, your personal finance assistant. 🤝\n\n'
            'I can help you with budgeting, savings, expense tracking, investments, insurance, taxes, banking, loans, or test your finance knowledge with a quick quiz!\n\n'
            'What would you like to explore today?',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend(String text) {
    if (text.trim().isEmpty) return;
    _controller.clear();

    setState(() {
      _messages.add(ChatEntry(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });
    _scrollToBottom();

    // Process with ChatbotService
    Timer(const Duration(milliseconds: 800), () async {
      if (!mounted) return;
      final response = await _chatbotService.processMessage(text, _financialProfile);

      Widget? customWidget;
      if (response.widgetType == 'budget') {
        customWidget = const BudgetCalculatorWidget();
      } else if (response.widgetType == 'savings') {
        customWidget = const SavingsGoalWidget();
      } else if (response.widgetType == 'tax') {
        customWidget = const TaxEstimatorWidget();
      } else if (response.widgetType == 'accounts') {
        customWidget = const FamilyAccountsViewer();
      } else if (response.widgetType == 'insurance') {
        customWidget = const InsuranceGuideWidget();
      } else if (response.widgetType == 'quiz') {
        customWidget = const FinanceQuizWidget();
      }

      setState(() {
        _isTyping = false;
        _messages.add(ChatEntry(
          text: response.text,
          isUser: false,
          timestamp: DateTime.now(),
          customWidget: customWidget,
        ));
      });
      _scrollToBottom();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('FamFunds AI'),
            Text(
              'Personal Finance Companion',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageRow(message);
              },
            ),
          ),
          if (_isTyping) _buildTypingIndicator(),
          if (!_isTyping && _messages.isNotEmpty && !_messages.last.isUser)
            _buildSuggestionsList(),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageRow(ChatEntry message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment:
            message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!message.isUser) ...[
                const CircleAvatar(
                  backgroundColor: AppColors.primary,
                  radius: 16,
                  child: Icon(Icons.psychology_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: message.isUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: message.isUser
                            ? const LinearGradient(
                                colors: [AppColors.primary, AppColors.primaryDark],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: message.isUser ? null : AppColors.surface,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(message.isUser ? 16 : 4),
                          bottomRight: Radius.circular(message.isUser ? 4 : 16),
                        ),
                        border: message.isUser ? null : Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        message.text,
                        style: TextStyle(
                          color: message.isUser ? Colors.white : AppColors.textPrimary,
                          fontSize: 13.5,
                          height: 1.4,
                        ),
                      ),
                    ),
                    if (message.customWidget != null) ...[
                      const SizedBox(height: 8),
                      message.customWidget!,
                    ],
                  ],
                ),
              ),
              if (message.isUser) const SizedBox(width: 24), // Offset for symmetry
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8.0),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.primary,
            radius: 14,
            child: Icon(Icons.psychology_rounded, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PulsingDot(delay: 0),
                SizedBox(width: 4),
                _PulsingDot(delay: 200),
                SizedBox(width: 4),
                _PulsingDot(delay: 400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = _suggestions[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
            child: ActionChip(
              backgroundColor: AppColors.surface,
              side: const BorderSide(color: AppColors.primary),
              label: Text(
                suggestion,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onPressed: () {
                // Stripping visual icon before triggering
                final text = suggestion.substring(2);
                _handleSend(text);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Ask a personal finance question...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              ),
              onSubmitted: _handleSend,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send_rounded, color: AppColors.primary),
            onPressed: () => _handleSend(_controller.text),
          ),
        ],
      ),
    );
  }
}

/// A dot that scales up and down repeatedly to make an animated loading state
class _PulsingDot extends StatefulWidget {
  final int delay;
  const _PulsingDot({required this.delay});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.2).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _animController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// INTERACTIVE WIDGETS
// ----------------------------------------------------

class BudgetCalculatorWidget extends StatefulWidget {
  const BudgetCalculatorWidget({super.key});

  @override
  State<BudgetCalculatorWidget> createState() => _BudgetCalculatorWidgetState();
}

class _BudgetCalculatorWidgetState extends State<BudgetCalculatorWidget> {
  double _income = 50000;

  @override
  Widget build(BuildContext context) {
    double needs = _income * 0.5;
    double wants = _income * 0.3;
    double savings = _income * 0.2;

    return FFCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Interactive 50/30/20 Budget Calculator',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Enter your monthly income to see how you should split it:',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Text('₹', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      hintText: 'e.g. 50000',
                    ),
                    onChanged: (val) {
                      setState(() {
                        _income = double.tryParse(val) ?? 0;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          if (_income > 0) ...[
            const SizedBox(height: AppSpacing.md),
            _buildAllocationBar('Needs (50%)', needs, AppColors.primary, 'Rent, bills, groceries, transport'),
            const SizedBox(height: AppSpacing.sm),
            _buildAllocationBar('Wants (30%)', wants, AppColors.accentAmber, 'Dining out, shopping, entertainment'),
            const SizedBox(height: AppSpacing.sm),
            _buildAllocationBar('Savings (20%)', savings, AppColors.accentGreen, 'Emergency savings, investments, debts'),
          ],
        ],
      ),
    );
  }

  Widget _buildAllocationBar(String title, double amount, Color color, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11)),
            Text('₹${amount.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _income == 0 ? 0 : amount / _income,
            backgroundColor: color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 2),
        Text(description, style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
      ],
    );
  }
}

class SavingsGoalWidget extends StatefulWidget {
  const SavingsGoalWidget({super.key});

  @override
  State<SavingsGoalWidget> createState() => _SavingsGoalWidgetState();
}

class _SavingsGoalWidgetState extends State<SavingsGoalWidget> {
  final _goalController = TextEditingController(text: 'Emergency Fund');
  double _amount = 100000;
  double _months = 12;

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double monthlySavings = _amount / _months;

    return FFCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Savings Goal Estimator',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 40,
            child: TextField(
              controller: _goalController,
              decoration: const InputDecoration(
                labelText: 'Goal Name',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (val) => setState(() {}),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Target (₹)',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _amount = double.tryParse(val) ?? 0;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Time (Months)',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _months = double.tryParse(val) ?? 1;
                        if (_months <= 0) _months = 1;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (_amount > 0 && _months > 0) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Required Monthly Savings:', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  Text(
                    '₹${monthlySavings.toStringAsFixed(0)} / month',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'To achieve your goal of ₹${_amount.toStringAsFixed(0)} for "${_goalController.text}" in ${_months.toStringAsFixed(0)} months, you need to save ₹${monthlySavings.toStringAsFixed(0)} each month.',
                    style: const TextStyle(fontSize: 10, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }
}

class FamilyAccountsViewer extends StatelessWidget {
  const FamilyAccountsViewer({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return _buildMockAccountsList();
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, userSnap) {
        if (userSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)));
        }
        if (!userSnap.hasData || userSnap.data == null) {
          return _buildMockAccountsList();
        }

        final data = userSnap.data!.data() as Map<String, dynamic>?;
        final familyId = data?['familyId'] as String?;
        if (familyId == null) {
          return _buildMockAccountsList();
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('accounts')
              .where('familyId', isEqualTo: familyId)
              .snapshots(),
          builder: (context, accountsSnap) {
            if (accountsSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)));
            }

            if (!accountsSnap.hasData || accountsSnap.data!.docs.isEmpty) {
              return _buildMockAccountsList();
            }

            final accounts = accountsSnap.data!.docs;
            double totalBalance = 0;
            for (var doc in accounts) {
              totalBalance += ((doc['balance'] ?? 0) as num).toDouble();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(totalBalance),
                const SizedBox(height: 8),
                ...accounts.map((doc) {
                  final accData = doc.data() as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: _AccountRow(
                      bankName: accData['bankName'] ?? 'Unknown Bank',
                      owner: accData['uid'] == uid ? 'You' : 'Family Member',
                      maskedNumber: accData['maskedAccountNumber'] ?? 'XXXX',
                      balance: ((accData['balance'] ?? 0) as num).toDouble(),
                    ),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryCard(double total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Combined Balance', style: TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 2),
          Text(
            '₹${total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildMockAccountsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryCard(593600),
        const SizedBox(height: 8),
        const _AccountRow(bankName: 'HDFC Bank', owner: 'You', maskedNumber: 'XXXX 4821', balance: 184200),
        const SizedBox(height: 6),
        const _AccountRow(bankName: 'ICICI Bank', owner: 'Spouse', maskedNumber: 'XXXX 7734', balance: 96500),
        const SizedBox(height: 6),
        const _AccountRow(bankName: 'SBI', owner: 'Parent', maskedNumber: 'XXXX 2201', balance: 312900),
      ],
    );
  }
}

class _AccountRow extends StatelessWidget {
  final String bankName;
  final String owner;
  final String maskedNumber;
  final double balance;

  const _AccountRow({
    required this.bankName,
    required this.owner,
    required this.maskedNumber,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.primaryLight,
            radius: 14,
            child: Icon(Icons.account_balance_rounded, color: AppColors.primary, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bankName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Text('$owner · $maskedNumber', style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
              ],
            ),
          ),
          Text(
            '₹${balance.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class InsuranceGuideWidget extends StatefulWidget {
  const InsuranceGuideWidget({super.key});

  @override
  State<InsuranceGuideWidget> createState() => _InsuranceGuideWidgetState();
}

class _InsuranceGuideWidgetState extends State<InsuranceGuideWidget> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FFCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: const Text(
              'Interactive Insurance Guide',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
            ),
          ),
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: const [
              Tab(text: 'Term Life'),
              Tab(text: 'Health'),
              Tab(text: 'Motor'),
            ],
          ),
          SizedBox(
            height: 160,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInsuranceTab(
                  icon: Icons.favorite_rounded,
                  title: 'Term Life Insurance',
                  sub: 'Protects family in case of demise',
                  bullets: [
                    'Rule of Thumb: Coverage should be 10x-15x your annual income.',
                    'Buy early to lock in lower premium rates.',
                    'Keep it simple: Buy pure term plan, avoid ULIPs/endowment plans.',
                  ],
                ),
                _buildInsuranceTab(
                  icon: Icons.medical_services_rounded,
                  title: 'Health Insurance',
                  sub: 'Covers hospitalization & medical bills',
                  bullets: [
                    'Do not rely solely on corporate policy (you lose it if you leave your job).',
                    'Aim for at least ₹5-10 Lakhs base cover + a Super Top-up.',
                    'Look for No Claim Bonus & restoration benefits.',
                  ],
                ),
                _buildInsuranceTab(
                  icon: Icons.directions_car_rounded,
                  title: 'Motor Insurance',
                  sub: 'Covers vehicle damage & liabilities',
                  bullets: [
                    'Third-Party cover is legally mandatory in India.',
                    'Comprehensive cover covers own vehicle damage.',
                    'Add Zero Depreciation rider if vehicle is less than 5 years old.',
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsuranceTab({
    required IconData icon,
    required String title,
    required String sub,
    required List<String> bullets,
  }) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 16),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
          const SizedBox(height: 6),
          ...bullets.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                    Expanded(child: Text(b, style: const TextStyle(fontSize: 10.5))),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class TaxEstimatorWidget extends StatefulWidget {
  const TaxEstimatorWidget({super.key});

  @override
  State<TaxEstimatorWidget> createState() => _TaxEstimatorWidgetState();
}

class _TaxEstimatorWidgetState extends State<TaxEstimatorWidget> {
  double _income = 1200000;

  @override
  Widget build(BuildContext context) {
    double tax = calculateTax(_income);
    double avgRate = _income > 0 ? (tax / _income) * 100 : 0;

    return FFCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'New Tax Regime Estimator (FY 2025-26)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Estimate tax liability under the new regime rules (Standard Deduction of ₹75,000 auto-applied):',
            style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Text('₹', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      hintText: 'Annual Income, e.g. 1200000',
                    ),
                    onChanged: (val) {
                      setState(() {
                        _income = double.tryParse(val) ?? 0;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          if (_income > 0) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _taxRow('Taxable Income (after ₹75k Standard Deduction)', '₹${(_income - 75000).clamp(0.0, double.infinity).toStringAsFixed(0)}'),
                  const Divider(height: 12),
                  _taxRow('Estimated Annual Tax', '₹${tax.toStringAsFixed(0)}', isBold: true, color: AppColors.accentRed),
                  const SizedBox(height: 2),
                  _taxRow('Average Tax Rate', '${avgRate.toStringAsFixed(1)}%'),
                ],
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '*Disclaimer: For general educational guidance only. Actual tax depends on your specific allowances and deductions. Under new regime, income up to ₹7 Lakhs is completely tax-free via rebate.',
              style: TextStyle(fontSize: 8.5, color: AppColors.textSecondary),
            ),
          ]
        ],
      ),
    );
  }

  Widget _taxRow(String label, String value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 12 : 10,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  double calculateTax(double annualIncome) {
    double taxable = annualIncome - 75000;
    if (taxable <= 0) return 0;
    if (taxable <= 700000) return 0;

    double tax = 0;
    
    if (taxable > 1500000) {
      tax += (taxable - 1500000) * 0.30;
      taxable = 1500000;
    }
    if (taxable > 1200000) {
      tax += (taxable - 1200000) * 0.20;
      taxable = 1200000;
    }
    if (taxable > 900000) {
      tax += (taxable - 900000) * 0.15;
      taxable = 900000;
    }
    if (taxable > 600000) {
      tax += (taxable - 600000) * 0.10;
      taxable = 600000;
    }
    if (taxable > 300000) {
      tax += (taxable - 300000) * 0.05;
    }

    return tax * 1.04;
  }
}

class FinanceQuizWidget extends StatefulWidget {
  const FinanceQuizWidget({super.key});

  @override
  State<FinanceQuizWidget> createState() => _FinanceQuizWidgetState();
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });
}

class _FinanceQuizWidgetState extends State<FinanceQuizWidget> {
  int _currentIndex = 0;
  int? _selectedIdx;
  bool _answered = false;

  final List<QuizQuestion> _questions = [
    QuizQuestion(
      question: 'What is the "Rule of 72" used for in finance?',
      options: [
        'Finding your debt-to-income ratio',
        'Estimating how long it takes to double your money',
        'Calculating income tax rate slabs',
        'Computing credit card minimum payments',
      ],
      correctIndex: 1,
      explanation: 'The Rule of 72 is a quick way to estimate when your money will double. Just divide 72 by your expected annual interest rate (e.g. 72 / 8% = 9 years).',
    ),
    QuizQuestion(
      question: 'How does inflation affect the purchasing power of your money?',
      options: [
        'It increases purchasing power over time',
        'It has no effect on purchasing power',
        'It decreases purchasing power over time',
        'It fluctuates daily based on your stock portfolio',
      ],
      correctIndex: 2,
      explanation: 'Inflation means prices rise, which means each Rupee can buy fewer goods. To beat inflation, your investments should earn a rate higher than the inflation rate.',
    ),
    QuizQuestion(
      question: 'What does a higher credit score represent?',
      options: [
        'Higher interest rates on bank deposits',
        'Lower likelihood of paying back a loan',
        'Better loan offers with lower interest rates',
        'Zero income tax liability on salary',
      ],
      correctIndex: 2,
      explanation: 'A higher credit score represents low credit risk, making banks trust you more. Consequently, they offer you loans at lower interest rates.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final q = _questions[_currentIndex];

    return FFCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Financial Literacy Quiz',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
              ),
              Text(
                'Q: ${_currentIndex + 1}/${_questions.length}',
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(q.question, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: AppSpacing.md),
          ...List.generate(q.options.length, (i) {
            Color btnColor = Colors.white;
            Color textColor = AppColors.textPrimary;
            BorderSide border = const BorderSide(color: AppColors.border);

            if (_answered) {
              if (i == q.correctIndex) {
                btnColor = AppColors.accentGreen.withOpacity(0.1);
                textColor = AppColors.accentGreen;
                border = const BorderSide(color: AppColors.accentGreen, width: 1.5);
              } else if (_selectedIdx == i) {
                btnColor = AppColors.accentRed.withOpacity(0.1);
                textColor = AppColors.accentRed;
                border = const BorderSide(color: AppColors.accentRed, width: 1.5);
              }
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: InkWell(
                onTap: _answered
                    ? null
                    : () {
                        setState(() {
                          _selectedIdx = i;
                          _answered = true;
                        });
                      },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: btnColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.fromBorderSide(border),
                  ),
                  child: Text(
                    q.options[i],
                    style: TextStyle(
                      fontSize: 11,
                      color: textColor,
                      fontWeight: _selectedIdx == i || (i == q.correctIndex && _answered)
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          }),
          if (_answered) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                q.explanation,
                style: const TextStyle(fontSize: 10.5, color: AppColors.primary, height: 1.25),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () {
                  setState(() {
                    _currentIndex = (_currentIndex + 1) % _questions.length;
                    _selectedIdx = null;
                    _answered = false;
                  });
                },
                child: const Text('Next Question →', style: TextStyle(fontSize: 11)),
              ),
            ),
          ]
        ],
      ),
    );
  }
}
