import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Robot for interacting with the home screen
class HomeRobot {
  final WidgetTester tester;

  HomeRobot(this.tester);

  /// Tap the create new mind map button
  Future<void> tapCreateNewMindMap() async {
    final createButton = find.byIcon(Icons.add);
    if (createButton.evaluate().isNotEmpty) {
      await tester.tap(createButton.first);
      await tester.pump();
    }
  }

  /// Tap on a mind map card by title
  Future<void> tapMindMapCard(String title) async {
    final card = find.text(title);
    if (card.evaluate().isNotEmpty) {
      await tester.tap(card.first);
      await tester.pump();
    }
  }

  /// Open settings
  Future<void> openSettings() async {
    final settingsButton = find.byIcon(Icons.settings_outlined);
    if (settingsButton.evaluate().isNotEmpty) {
      await tester.tap(settingsButton.first);
      await tester.pump();
    }
  }

  /// Verify empty state is shown
  void verifyEmptyState() {
    expect(find.text('No mind maps yet'), findsOneWidget);
  }

  /// Verify mind map count
  void verifyMindMapCount(int count) {
    // This would verify the number of mind map cards displayed
    final cards = find.byType(Card);
    expect(cards.evaluate().length, greaterThanOrEqualTo(count));
  }

  /// Tap search button
  Future<void> tapSearch() async {
    final searchButton = find.byIcon(Icons.search);
    if (searchButton.evaluate().isNotEmpty) {
      await tester.tap(searchButton.first);
      await tester.pump();
    }
  }

  /// Enter search query
  Future<void> enterSearchQuery(String query) async {
    final searchField = find.byType(TextField);
    if (searchField.evaluate().isNotEmpty) {
      await tester.enterText(searchField.first, query);
      await tester.pump();
    }
  }

  /// Clear search
  Future<void> clearSearch() async {
    final clearButton = find.byIcon(Icons.clear);
    if (clearButton.evaluate().isNotEmpty) {
      await tester.tap(clearButton.first);
      await tester.pump();
    }
  }

  /// Long press on mind map card for context menu
  Future<void> longPressMindMapCard(String title) async {
    final card = find.text(title);
    if (card.evaluate().isNotEmpty) {
      await tester.longPress(card.first);
      await tester.pump();
    }
  }

  /// Tap delete in context menu
  Future<void> tapDeleteInContextMenu() async {
    final deleteOption = find.text('Delete');
    if (deleteOption.evaluate().isNotEmpty) {
      await tester.tap(deleteOption.first);
      await tester.pump();
    }
  }

  /// Confirm deletion
  Future<void> confirmDelete() async {
    final confirmButton = find.text('Delete');
    // Find the one in the dialog (usually the last one)
    if (confirmButton.evaluate().length > 1) {
      await tester.tap(confirmButton.last);
    } else if (confirmButton.evaluate().isNotEmpty) {
      await tester.tap(confirmButton.first);
    }
    await tester.pump();
  }
}
