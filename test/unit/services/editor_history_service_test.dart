import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:idea_weaver_ai/src/domain/models/mind_map.dart';
import 'package:idea_weaver_ai/src/features/editor/services/editor_history_service.dart';

void main() {
  group('EditorHistoryService', () {
    late EditorHistoryService historyService;
    late MindMap initialMindMap;

    setUp(() {
      historyService = EditorHistoryService();
      initialMindMap = MindMap(
        id: 'test-map',
        title: 'Test Mind Map',
        ownerId: 'user-1',
        nodes: {
          'root': MindMapNode(
            id: 'root',
            text: 'Central Idea',
            position: const Offset(0, 0),
          ),
        },
        rootNodeId: 'root',
      );
    });

    test('initially cannot undo or redo', () {
      expect(historyService.canUndo, false);
      expect(historyService.canRedo, false);
    });

    group('AddNodeCommand', () {
      test('executes and adds node to mind map', () {
        final command = AddNodeCommand(
          nodeId: 'node-1',
          text: 'New Node',
          position: const Offset(100, 100),
          parentId: 'root',
          color: Colors.blue,
        );

        final result = historyService.execute(command, initialMindMap);

        expect(result.nodes.length, 2);
        expect(result.nodes['node-1'], isNotNull);
        expect(result.nodes['node-1']!.text, 'New Node');
        expect(result.nodes['root']!.childIds, contains('node-1'));
      });

      test('can undo add node', () {
        final command = AddNodeCommand(
          nodeId: 'node-1',
          text: 'New Node',
          position: const Offset(100, 100),
          parentId: 'root',
          color: Colors.blue,
        );

        final afterAdd = historyService.execute(command, initialMindMap);
        expect(afterAdd.nodes.length, 2);
        expect(historyService.canUndo, true);

        final afterUndo = historyService.undo(afterAdd);
        expect(afterUndo, isNotNull);
        expect(afterUndo!.nodes.length, 1);
        expect(afterUndo.nodes['node-1'], isNull);
      });

      test('can redo add node', () {
        final command = AddNodeCommand(
          nodeId: 'node-1',
          text: 'New Node',
          position: const Offset(100, 100),
          parentId: 'root',
          color: Colors.blue,
        );

        final afterAdd = historyService.execute(command, initialMindMap);
        final afterUndo = historyService.undo(afterAdd)!;
        expect(historyService.canRedo, true);

        final afterRedo = historyService.redo(afterUndo);
        expect(afterRedo, isNotNull);
        expect(afterRedo!.nodes.length, 2);
        expect(afterRedo.nodes['node-1'], isNotNull);
      });
    });

    group('UpdateNodeTextCommand', () {
      test('executes and updates node text', () {
        final command = UpdateNodeTextCommand(
          nodeId: 'root',
          newText: 'Updated Text',
          oldText: 'Central Idea',
        );

        final result = historyService.execute(command, initialMindMap);

        expect(result.nodes['root']!.text, 'Updated Text');
      });

      test('can undo text update', () {
        final command = UpdateNodeTextCommand(
          nodeId: 'root',
          newText: 'Updated Text',
          oldText: 'Central Idea',
        );

        final afterUpdate = historyService.execute(command, initialMindMap);
        expect(afterUpdate.nodes['root']!.text, 'Updated Text');

        final afterUndo = historyService.undo(afterUpdate);
        expect(afterUndo!.nodes['root']!.text, 'Central Idea');
      });
    });

    group('UpdateNodeColorCommand', () {
      test('executes and updates node color', () {
        final command = UpdateNodeColorCommand(
          nodeId: 'root',
          newColor: Colors.red,
          oldColor: initialMindMap.nodes['root']!.color,
        );

        final result = historyService.execute(command, initialMindMap);

        expect(result.nodes['root']!.color, Colors.red);
      });

      test('can undo color update', () {
        final originalColor = initialMindMap.nodes['root']!.color;
        final command = UpdateNodeColorCommand(
          nodeId: 'root',
          newColor: Colors.red,
          oldColor: originalColor,
        );

        final afterUpdate = historyService.execute(command, initialMindMap);
        final afterUndo = historyService.undo(afterUpdate);

        expect(afterUndo!.nodes['root']!.color, originalColor);
      });
    });

    group('DeleteNodeCommand', () {
      late MindMap mapWithChild;

      setUp(() {
        mapWithChild = MindMap(
          id: 'test-map',
          title: 'Test Mind Map',
          ownerId: 'user-1',
          nodes: {
            'root': MindMapNode(
              id: 'root',
              text: 'Central Idea',
              position: const Offset(0, 0),
              childIds: ['child-1'],
            ),
            'child-1': MindMapNode(
              id: 'child-1',
              text: 'Child Node',
              position: const Offset(100, 100),
              parentId: 'root',
            ),
          },
          rootNodeId: 'root',
        );
      });

      test('executes and deletes node', () {
        final command = DeleteNodeCommand(
          nodeId: 'child-1',
          deletedNodes: {'child-1': mapWithChild.nodes['child-1']!},
          parentId: 'root',
          parentChildIds: ['child-1'],
        );

        final result = historyService.execute(command, mapWithChild);

        expect(result.nodes.length, 1);
        expect(result.nodes['child-1'], isNull);
        expect(result.nodes['root']!.childIds, isEmpty);
      });

      test('can undo delete node', () {
        final command = DeleteNodeCommand(
          nodeId: 'child-1',
          deletedNodes: {'child-1': mapWithChild.nodes['child-1']!},
          parentId: 'root',
          parentChildIds: ['child-1'],
        );

        final afterDelete = historyService.execute(command, mapWithChild);
        expect(afterDelete.nodes.length, 1);

        final afterUndo = historyService.undo(afterDelete);
        expect(afterUndo!.nodes.length, 2);
        expect(afterUndo.nodes['child-1'], isNotNull);
        expect(afterUndo.nodes['root']!.childIds, contains('child-1'));
      });
    });

    group('AutoLayoutCommand', () {
      test('executes and updates positions', () {
        final command = AutoLayoutCommand(
          oldPositions: {'root': const Offset(0, 0)},
          newPositions: {'root': const Offset(50, 50)},
        );

        final result = historyService.execute(command, initialMindMap);

        expect(result.nodes['root']!.position, const Offset(50, 50));
      });

      test('can undo layout', () {
        final command = AutoLayoutCommand(
          oldPositions: {'root': const Offset(0, 0)},
          newPositions: {'root': const Offset(50, 50)},
        );

        final afterLayout = historyService.execute(command, initialMindMap);
        final afterUndo = historyService.undo(afterLayout);

        expect(afterUndo!.nodes['root']!.position, const Offset(0, 0));
      });
    });

    group('History limits', () {
      test('limits history to maxHistorySize', () {
        var currentMap = initialMindMap;

        // Execute more than maxHistorySize commands
        for (var i = 0; i < 60; i++) {
          final command = UpdateNodeTextCommand(
            nodeId: 'root',
            newText: 'Text $i',
            oldText: i == 0 ? 'Central Idea' : 'Text ${i - 1}',
          );
          currentMap = historyService.execute(command, currentMap);
        }

        // History should be limited
        expect(historyService.undoCount, lessThanOrEqualTo(maxHistorySize));
      });

      test('clears redo stack on new command', () {
        final command1 = UpdateNodeTextCommand(
          nodeId: 'root',
          newText: 'Text 1',
          oldText: 'Central Idea',
        );

        var currentMap = historyService.execute(command1, initialMindMap);
        historyService.undo(currentMap);
        expect(historyService.canRedo, true);

        // New command should clear redo stack
        final command2 = UpdateNodeTextCommand(
          nodeId: 'root',
          newText: 'Text 2',
          oldText: 'Central Idea',
        );
        historyService.execute(command2, initialMindMap);
        expect(historyService.canRedo, false);
      });
    });

    test('clear() resets all history', () {
      final command = UpdateNodeTextCommand(
        nodeId: 'root',
        newText: 'New Text',
        oldText: 'Central Idea',
      );

      historyService.execute(command, initialMindMap);
      expect(historyService.canUndo, true);

      historyService.clear();
      expect(historyService.canUndo, false);
      expect(historyService.canRedo, false);
    });
  });
}
