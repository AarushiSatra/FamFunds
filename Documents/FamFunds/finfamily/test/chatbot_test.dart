import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finfamily/services/gemini_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('FamFunds AI local response tests', () {
    test('Greets user correctly', () async {
      final response = await GeminiService.instance.sendLocalResponse('hi');
      expect(response, contains('FamFunds AI'));
      expect(response, contains('analyzed the Sharma Family\'s financial profile'));
    });

    test('Answers balance query', () async {
      final response = await GeminiService.instance.sendLocalResponse('What is our total balance?');
      expect(response, contains('Sharma Family\'s combined balance'));
      expect(response, contains('₹5,93,600'));
    });

    test('Answers savings rate query', () async {
      final response = await GeminiService.instance.sendLocalResponse('savings rate');
      expect(response, contains('₹85,000 monthly family salary'));
      expect(response, contains('35% savings rate'));
    });

    test('Declines unrelated programming query', () async {
      final response = await GeminiService.instance.sendLocalResponse('Write a python function to print hello world');
      expect(response, equals("I’m the FamFunds financial assistant, so I can only help with personal finance, budgeting, savings, investments, and related topics. Please ask me a finance-related question."));
    });

    test('Declines unrelated sports query', () async {
      final response = await GeminiService.instance.sendLocalResponse('who won the football world cup in 2022?');
      expect(response, equals("I’m the FamFunds financial assistant, so I can only help with personal finance, budgeting, savings, investments, and related topics. Please ask me a finance-related question."));
    });

    test('Declines general knowledge/math query', () async {
      final response = await GeminiService.instance.sendLocalResponse('what is the capital of France?');
      expect(response, equals("I’m the FamFunds financial assistant, so I can only help with personal finance, budgeting, savings, investments, and related topics. Please ask me a finance-related question."));
    });
  });
}
