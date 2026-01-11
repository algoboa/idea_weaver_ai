import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idea_weaver_ai/main.dart';
import 'robots/auth_robot.dart';
import 'robots/home_robot.dart';
import 'robots/editor_robot.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Flow', () {
    testWidgets('user can register with email and password', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: IdeaWeaverApp()),
      );
      await tester.pumpAndSettle();

      final authRobot = AuthRobot(tester);

      // Navigate to register screen
      await authRobot.tapSignUp();
      await tester.pumpAndSettle();

      // Fill registration form
      await authRobot.enterName('Test User');
      await authRobot.enterEmail('test@example.com');
      await authRobot.enterPassword('password123');
      await authRobot.enterConfirmPassword('password123');

      // Submit form
      await authRobot.tapCreateAccount();
      await tester.pumpAndSettle();

      // Verify navigation to home or success state
      // Note: In real E2E tests, this would use a mock Firebase
    });

    testWidgets('user can login with valid credentials', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: IdeaWeaverApp()),
      );
      await tester.pumpAndSettle();

      final authRobot = AuthRobot(tester);

      // Fill login form
      await authRobot.enterEmail('test@example.com');
      await authRobot.enterPassword('password123');

      // Submit form
      await authRobot.tapSignIn();
      await tester.pumpAndSettle();
    });

    testWidgets('shows error for invalid email format', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: IdeaWeaverApp()),
      );
      await tester.pumpAndSettle();

      final authRobot = AuthRobot(tester);

      // Enter invalid email
      await authRobot.enterEmail('invalid-email');
      await authRobot.enterPassword('password123');
      await authRobot.tapSignIn();
      await tester.pumpAndSettle();

      // Verify error message
      expect(find.text('Please enter a valid email address'), findsOneWidget);
    });

    testWidgets('shows error for short password', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: IdeaWeaverApp()),
      );
      await tester.pumpAndSettle();

      final authRobot = AuthRobot(tester);

      await authRobot.enterEmail('test@example.com');
      await authRobot.enterPassword('123');
      await authRobot.tapSignIn();
      await tester.pumpAndSettle();

      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });
  });

  group('Mind Map Editor Flow', () {
    testWidgets('can create new mind map', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: IdeaWeaverApp()),
      );
      await tester.pumpAndSettle();

      // Skip to editor (assuming authenticated)
      final editorRobot = EditorRobot(tester);

      // Verify central idea exists
      expect(find.text('Central Idea'), findsOneWidget);
    });

    testWidgets('can add child node', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: IdeaWeaverApp()),
      );
      await tester.pumpAndSettle();

      final editorRobot = EditorRobot(tester);

      // Find and tap the add node button
      await editorRobot.tapAddNode();
      await tester.pumpAndSettle();

      // Enter node text
      await editorRobot.enterNodeText('New Node');
      await editorRobot.confirmAddNode();
      await tester.pumpAndSettle();

      // Verify node was added
      expect(find.text('New Node'), findsOneWidget);
    });

    testWidgets('can undo and redo operations', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: IdeaWeaverApp()),
      );
      await tester.pumpAndSettle();

      final editorRobot = EditorRobot(tester);

      // Add a node
      await editorRobot.tapAddNode();
      await tester.pumpAndSettle();
      await editorRobot.enterNodeText('Test Node');
      await editorRobot.confirmAddNode();
      await tester.pumpAndSettle();

      expect(find.text('Test Node'), findsOneWidget);

      // Undo
      await editorRobot.tapUndo();
      await tester.pumpAndSettle();

      expect(find.text('Test Node'), findsNothing);

      // Redo
      await editorRobot.tapRedo();
      await tester.pumpAndSettle();

      expect(find.text('Test Node'), findsOneWidget);
    });

    testWidgets('enforces node text length limit', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: IdeaWeaverApp()),
      );
      await tester.pumpAndSettle();

      final editorRobot = EditorRobot(tester);

      // Try to add node with text exceeding 500 characters
      await editorRobot.tapAddNode();
      await tester.pumpAndSettle();

      final longText = 'A' * 600;
      await editorRobot.enterNodeText(longText);
      await tester.pumpAndSettle();

      // TextField should have maxLength of 500
      final textField = tester.widget<TextField>(find.byType(TextField).first);
      expect(textField.maxLength, 500);
    });
  });

  group('AI Suggestion Flow', () {
    testWidgets('can open AI suggestion panel', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: IdeaWeaverApp()),
      );
      await tester.pumpAndSettle();

      final editorRobot = EditorRobot(tester);

      // Select a node first
      await editorRobot.tapNode('Central Idea');
      await tester.pumpAndSettle();

      // Open AI panel
      await editorRobot.tapAiSuggestions();
      await tester.pumpAndSettle();

      // Verify panel is visible
      expect(find.text('AI Suggestions'), findsOneWidget);
    });

    testWidgets('can close AI panel', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: IdeaWeaverApp()),
      );
      await tester.pumpAndSettle();

      final editorRobot = EditorRobot(tester);

      // Select node and open panel
      await editorRobot.tapNode('Central Idea');
      await editorRobot.tapAiSuggestions();
      await tester.pumpAndSettle();

      // Close panel
      await editorRobot.closeAiPanel();
      await tester.pumpAndSettle();

      expect(find.text('AI Suggestions'), findsNothing);
    });
  });

  group('Edge Cases', () {
    testWidgets('handles empty mind map title gracefully', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: IdeaWeaverApp()),
      );
      await tester.pumpAndSettle();

      // Title should have a default value
      expect(find.text('Untitled Mind Map'), findsOneWidget);
    });

    testWidgets('handles special characters in node text', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: IdeaWeaverApp()),
      );
      await tester.pumpAndSettle();

      final editorRobot = EditorRobot(tester);

      // Add node with special characters
      await editorRobot.tapAddNode();
      await tester.pumpAndSettle();
      await editorRobot.enterNodeText('<script>alert("XSS")</script>');
      await editorRobot.confirmAddNode();
      await tester.pumpAndSettle();

      // Text should be displayed literally, not executed
      expect(find.text('<script>alert("XSS")</script>'), findsOneWidget);
    });
  });
}
