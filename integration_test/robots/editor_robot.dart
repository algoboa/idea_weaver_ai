import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Robot for interacting with the editor screen
class EditorRobot {
  final WidgetTester tester;

  EditorRobot(this.tester);

  /// Tap on a node by its text
  Future<void> tapNode(String nodeText) async {
    final node = find.text(nodeText);
    if (node.evaluate().isNotEmpty) {
      await tester.tap(node.first);
      await tester.pump();
    }
  }

  /// Double tap on a node to edit
  Future<void> doubleTapNode(String nodeText) async {
    final node = find.text(nodeText);
    if (node.evaluate().isNotEmpty) {
      await tester.tap(node.first);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(node.first);
      await tester.pump();
    }
  }

  /// Tap the add node button in the toolbar
  Future<void> tapAddNode() async {
    final addButton = find.byIcon(Icons.add_circle_outline);
    if (addButton.evaluate().isNotEmpty) {
      await tester.tap(addButton.first);
      await tester.pump();
    }
  }

  /// Enter text in the node text field (in dialog)
  Future<void> enterNodeText(String text) async {
    final textField = find.byType(TextField);
    if (textField.evaluate().isNotEmpty) {
      await tester.enterText(textField.first, text);
      await tester.pump();
    }
  }

  /// Confirm adding/editing a node
  Future<void> confirmAddNode() async {
    final addButton = find.text('Add');
    if (addButton.evaluate().isNotEmpty) {
      await tester.tap(addButton.first);
      await tester.pump();
    } else {
      // Try save button for edit mode
      final saveButton = find.text('Save');
      if (saveButton.evaluate().isNotEmpty) {
        await tester.tap(saveButton.first);
        await tester.pump();
      }
    }
  }

  /// Cancel adding/editing a node
  Future<void> cancelAddNode() async {
    final cancelButton = find.text('Cancel');
    if (cancelButton.evaluate().isNotEmpty) {
      await tester.tap(cancelButton.first);
      await tester.pump();
    }
  }

  /// Tap undo button
  Future<void> tapUndo() async {
    final undoButton = find.byIcon(Icons.undo);
    if (undoButton.evaluate().isNotEmpty) {
      await tester.tap(undoButton.first);
      await tester.pump();
    }
  }

  /// Tap redo button
  Future<void> tapRedo() async {
    final redoButton = find.byIcon(Icons.redo);
    if (redoButton.evaluate().isNotEmpty) {
      await tester.tap(redoButton.first);
      await tester.pump();
    }
  }

  /// Tap AI suggestions button
  Future<void> tapAiSuggestions() async {
    final aiButton = find.byIcon(Icons.auto_awesome);
    if (aiButton.evaluate().isNotEmpty) {
      await tester.tap(aiButton.first);
      await tester.pump();
    }
  }

  /// Close AI panel
  Future<void> closeAiPanel() async {
    final closeButton = find.byIcon(Icons.close);
    if (closeButton.evaluate().isNotEmpty) {
      await tester.tap(closeButton.first);
      await tester.pump();
    }
  }

  /// Tap center view button
  Future<void> tapCenterView() async {
    final centerButton = find.byIcon(Icons.center_focus_strong);
    if (centerButton.evaluate().isNotEmpty) {
      await tester.tap(centerButton.first);
      await tester.pump();
    }
  }

  /// Tap zoom in button
  Future<void> tapZoomIn() async {
    final zoomInButton = find.byIcon(Icons.zoom_in);
    if (zoomInButton.evaluate().isNotEmpty) {
      await tester.tap(zoomInButton.first);
      await tester.pump();
    }
  }

  /// Tap zoom out button
  Future<void> tapZoomOut() async {
    final zoomOutButton = find.byIcon(Icons.zoom_out);
    if (zoomOutButton.evaluate().isNotEmpty) {
      await tester.tap(zoomOutButton.first);
      await tester.pump();
    }
  }

  /// Tap share button
  Future<void> tapShare() async {
    final shareButton = find.byIcon(Icons.share_outlined);
    if (shareButton.evaluate().isNotEmpty) {
      await tester.tap(shareButton.first);
      await tester.pump();
    }
  }

  /// Tap export button
  Future<void> tapExport() async {
    final exportButton = find.byIcon(Icons.file_download_outlined);
    if (exportButton.evaluate().isNotEmpty) {
      await tester.tap(exportButton.first);
      await tester.pump();
    }
  }

  /// Tap menu button
  Future<void> tapMenu() async {
    final menuButton = find.byType(PopupMenuButton);
    if (menuButton.evaluate().isNotEmpty) {
      await tester.tap(menuButton.first);
      await tester.pump();
    }
  }

  /// Tap auto layout option in menu
  Future<void> tapAutoLayout() async {
    await tapMenu();
    await tester.pumpAndSettle();

    final autoLayoutOption = find.text('Auto Layout');
    if (autoLayoutOption.evaluate().isNotEmpty) {
      await tester.tap(autoLayoutOption.first);
      await tester.pump();
    }
  }

  /// Tap AI summary option in menu
  Future<void> tapAiSummary() async {
    await tapMenu();
    await tester.pumpAndSettle();

    final summaryOption = find.text('AI Summary');
    if (summaryOption.evaluate().isNotEmpty) {
      await tester.tap(summaryOption.first);
      await tester.pump();
    }
  }

  /// Long press on node to show context menu
  Future<void> longPressNode(String nodeText) async {
    final node = find.text(nodeText);
    if (node.evaluate().isNotEmpty) {
      await tester.longPress(node.first);
      await tester.pump();
    }
  }

  /// Tap delete option in context menu
  Future<void> tapDeleteInContextMenu() async {
    final deleteOption = find.text('Delete');
    if (deleteOption.evaluate().isNotEmpty) {
      await tester.tap(deleteOption.first);
      await tester.pump();
    }
  }

  /// Tap color option in context menu
  Future<void> tapChangeColor() async {
    final colorOption = find.text('Change Color');
    if (colorOption.evaluate().isNotEmpty) {
      await tester.tap(colorOption.first);
      await tester.pump();
    }
  }

  /// Select a color in the color picker
  Future<void> selectColor(Color color) async {
    // Find color containers and tap one
    final colorContainer = find.byWidgetPredicate(
      (widget) =>
          widget is Container &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).color == color,
    );
    if (colorContainer.evaluate().isNotEmpty) {
      await tester.tap(colorContainer.first);
      await tester.pump();
    }
  }

  /// Verify node exists
  void verifyNodeExists(String nodeText) {
    expect(find.text(nodeText), findsOneWidget);
  }

  /// Verify node does not exist
  void verifyNodeDoesNotExist(String nodeText) {
    expect(find.text(nodeText), findsNothing);
  }

  /// Tap back button
  Future<void> tapBack() async {
    final backButton = find.byIcon(Icons.arrow_back);
    if (backButton.evaluate().isNotEmpty) {
      await tester.tap(backButton.first);
      await tester.pump();
    }
  }

  /// Tap on title to rename
  Future<void> tapTitle() async {
    final title = find.byIcon(Icons.edit);
    if (title.evaluate().isNotEmpty) {
      await tester.tap(title.first);
      await tester.pump();
    }
  }

  /// Enter new title
  Future<void> enterTitle(String title) async {
    final textField = find.byType(TextField);
    if (textField.evaluate().isNotEmpty) {
      await tester.enterText(textField.first, title);
      await tester.pump();
    }
  }

  /// Confirm rename
  Future<void> confirmRename() async {
    final renameButton = find.text('Rename');
    if (renameButton.evaluate().isNotEmpty) {
      await tester.tap(renameButton.first);
      await tester.pump();
    }
  }
}
