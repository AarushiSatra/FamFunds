import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finfamily/screens/chatbot_screen.dart';
import 'package:finfamily/theme/app_theme.dart';

void main() {
  testWidgets('Chatbot Screen initial state rendering', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const ChatbotScreen(),
      ),
    );

    // Verify welcome message is present
    expect(find.textContaining('Hello! I am FamFunds AI'), findsOneWidget);

    // Verify suggestion chips are present
    expect(find.textContaining('Calculate Budget'), findsOneWidget);
    expect(find.textContaining('Savings Calculator'), findsOneWidget);
  });

  testWidgets('Chatbot rejects non-finance question with exact message', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const ChatbotScreen(),
      ),
    );

    // Enter a non-finance question
    await tester.enterText(find.byType(TextField).first, 'What is the capital of Japan?');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump(); // Starts the message processing

    // Pump timer for simulated typing response (800ms)
    await tester.pump(const Duration(milliseconds: 900));

    // Verify the exact refusal message
    expect(
      find.text(
        'I’m the FamFunds financial assistant, so I can only help with personal finance, budgeting, savings, investments, and related topics. Please ask me a finance-related question.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Chatbot accepts budgeting question and shows custom calculator', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const ChatbotScreen(),
      ),
    );

    // Enter a budgeting question
    await tester.enterText(find.byType(TextField).first, 'how to budget');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();

    // Pump timer (800ms)
    await tester.pump(const Duration(milliseconds: 900));

    // Verify the text explanation and the presence of BudgetCalculatorWidget
    expect(find.textContaining('Budgeting is the roadmap of your personal finances'), findsOneWidget);
    expect(find.byType(BudgetCalculatorWidget), findsOneWidget);
  });
}
