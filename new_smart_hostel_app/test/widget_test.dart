import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:new_smart_hostel_app/main.dart';
import 'package:new_smart_hostel_app/screens/onboarding_screen.dart';
import 'package:new_smart_hostel_app/screens/welcome_screen.dart';

void main() {
  final int nowMillis = DateTime.now().millisecondsSinceEpoch;
  final int thirtyDaysMillis = 30 * 24 * 60 * 60 * 1000;

  // -------------------------------
  // Student flows
  // -------------------------------
  group('SmartHostelApp - Student role', () {
    testWidgets('shows onboarding if not seen', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: SmartHostelApp(
          seenOnboarding: false,
          role: 'student',
          isLoggedOut: true,
          logoutTime: null,
          nowMillis: nowMillis,
          thirtyDaysMillis: thirtyDaysMillis,
        ),
      ));

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.byType(ElevatedButton), findsWidgets);
    });

    testWidgets('shows welcome if onboarding seen', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: SmartHostelApp(
          seenOnboarding: true,
          role: 'student',
          isLoggedOut: true,
          logoutTime: null,
          nowMillis: nowMillis,
          thirtyDaysMillis: thirtyDaysMillis,
        ),
      ));

      await tester.pumpAndSettle();
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.textContaining('Welcome'), findsOneWidget);
    });

    testWidgets('shows welcome after logout', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: SmartHostelApp(
          seenOnboarding: true,
          role: null, // simulate logged out
          isLoggedOut: true,
          logoutTime: null,
          nowMillis: nowMillis,
          thirtyDaysMillis: thirtyDaysMillis,
        ),
      ));

      await tester.pumpAndSettle();
      expect(find.byType(WelcomeScreen), findsOneWidget);
    });
  });

  // -------------------------------
  // Agent flows
  // -------------------------------
  group('SmartHostelApp - Agent role', () {
    testWidgets('shows onboarding if not seen', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: SmartHostelApp(
          seenOnboarding: false,
          role: 'agent',
          isLoggedOut: true,
          logoutTime: null,
          nowMillis: nowMillis,
          thirtyDaysMillis: thirtyDaysMillis,
        ),
      ));

      expect(find.byType(OnboardingScreen), findsOneWidget);
    });

    testWidgets('shows welcome if onboarding seen', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: SmartHostelApp(
          seenOnboarding: true,
          role: 'agent',
          isLoggedOut: true,
          logoutTime: null,
          nowMillis: nowMillis,
          thirtyDaysMillis: thirtyDaysMillis,
        ),
      ));

      await tester.pumpAndSettle();
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.textContaining('Welcome'), findsOneWidget);
    });

    testWidgets('shows welcome after logout', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: SmartHostelApp(
          seenOnboarding: true,
          role: null, // simulate logged out
          isLoggedOut: true,
          logoutTime: null,
          nowMillis: nowMillis,
          thirtyDaysMillis: thirtyDaysMillis,
        ),
      ));

      await tester.pumpAndSettle();
      expect(find.byType(WelcomeScreen), findsOneWidget);
    });
  });
}
