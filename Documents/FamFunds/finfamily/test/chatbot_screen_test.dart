import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finfamily/screens/chatbot_screen.dart';
import 'package:finfamily/theme/app_theme.dart';
import 'package:finfamily/constants/famfunds_ai_prompt.dart';

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

    // Verify the exact refusal message constant
    expect(
      find.text(famFundsAIOutOfScopeResponse),
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

    // Verify the process text explanation and the presence of BudgetCalculatorWidget
    expect(find.textContaining('how to create a budget step-by-step'), findsOneWidget);
    expect(find.byType(BudgetCalculatorWidget), findsOneWidget);
  });

  testWidgets('Chatbot updates user salary profile and personalizes budget recommendation', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const ChatbotScreen(),
      ),
    );

    // Provide salary input
    await tester.enterText(find.byType(TextField).first, 'My salary is ₹2,50,000.');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();

    // Pump timer (800ms)
    await tester.pump(const Duration(milliseconds: 900));

    // Verify personalized breakdown includes ₹2,50,000 and 50% (₹1,25,000)
    expect(find.textContaining('₹2,50,000'), findsWidgets);
    expect(find.textContaining('₹125,000'), findsWidgets);
  });

  testWidgets('Chatbot handles definition intent question correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const ChatbotScreen(),
      ),
    );

    await tester.enterText(find.byType(TextField).first, 'What is a mutual fund?');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();
    expect(find.textContaining('investment vehicle that pools money', skipOffstage: false), findsOneWidget);
  });

  testWidgets('Chatbot handles process intent question correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const ChatbotScreen(),
      ),
    );

    await tester.enterText(find.byType(TextField).first, 'How do SIPs work?');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();
    expect(find.textContaining('Systematic Investment Plan', skipOffstage: false), findsWidgets);
  });
}
