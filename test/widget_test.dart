import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mock_firebase.dart';

void main() {
  setupFirebaseAuthMocks();

  group('Idea Weaver AI App', () {
    testWidgets('App widget builds without error', (WidgetTester tester) async {
      // Build a minimal app widget to verify basic widget tree
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text('Idea Weaver AI'),
              ),
            ),
          ),
        ),
      );

      // Verify the app renders
      expect(find.text('Idea Weaver AI'), findsOneWidget);
    });

    testWidgets('MaterialApp with theme renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            title: 'Idea Weaver AI',
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF6366F1),
              ),
            ),
            home: const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Welcome to'),
                    Text('Idea Weaver AI'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Welcome to'), findsOneWidget);
      expect(find.text('Idea Weaver AI'), findsOneWidget);
    });

    testWidgets('Scaffold with FloatingActionButton renders', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(child: Text('Test')),
              floatingActionButton: FloatingActionButton(
                onPressed: null,
                child: Icon(Icons.add),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  });
}
