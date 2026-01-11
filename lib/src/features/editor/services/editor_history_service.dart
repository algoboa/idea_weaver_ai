import 'package:flutter/material.dart';
import '../../../domain/models/mind_map.dart';

/// Maximum number of undo/redo operations to keep in history
const int maxHistorySize = 50;

/// Base class for all editor commands
abstract class EditorCommand {
  /// Execute the command
  MindMap execute(MindMap mindMap);

  /// Reverse the command
  MindMap undo(MindMap mindMap);
}

/// Command for adding a node
class AddNodeCommand extends EditorCommand {
  final String nodeId;
  final String text;
  final Offset position;
  final String? parentId;
  final Color color;

  AddNodeCommand({
    required this.nodeId,
    required this.text,
    required this.position,
    this.parentId,
    required this.color,
  });

  @override
  MindMap execute(MindMap mindMap) {
    final newNode = MindMapNode(
      id: nodeId,
      text: text,
      position: position,
      parentId: parentId,
      color: color,
    );

    final updatedNodes = Map<String, MindMapNode>.from(mindMap.nodes);
    updatedNodes[nodeId] = newNode;

    // Update parent's childIds
    if (parentId != null && updatedNodes.containsKey(parentId)) {
      final parent = updatedNodes[parentId]!;
      updatedNodes[parentId] = parent.copyWith(
        childIds: [...parent.childIds, nodeId],
      );
    }

    return mindMap.copyWith(
      nodes: updatedNodes,
      rootNodeId: mindMap.rootNodeId ?? nodeId,
    );
  }

  @override
  MindMap undo(MindMap mindMap) {
    final updatedNodes = Map<String, MindMapNode>.from(mindMap.nodes);

    // Remove from parent's childIds
    if (parentId != null && updatedNodes.containsKey(parentId)) {
      final parent = updatedNodes[parentId]!;
      updatedNodes[parentId] = parent.copyWith(
        childIds: parent.childIds.where((id) => id != nodeId).toList(),
      );
    }

    // Remove the node
    updatedNodes.remove(nodeId);

    return mindMap.copyWith(nodes: updatedNodes);
  }
}

/// Command for updating node text
class UpdateNodeTextCommand extends EditorCommand {
  final String nodeId;
  final String newText;
  final String oldText;

  UpdateNodeTextCommand({
    required this.nodeId,
    required this.newText,
    required this.oldText,
  });

  @override
  MindMap execute(MindMap mindMap) {
    final node = mindMap.nodes[nodeId];
    if (node == null) return mindMap;

    final updatedNodes = Map<String, MindMapNode>.from(mindMap.nodes);
    updatedNodes[nodeId] = node.copyWith(text: newText);

    return mindMap.copyWith(nodes: updatedNodes);
  }

  @override
  MindMap undo(MindMap mindMap) {
    final node = mindMap.nodes[nodeId];
    if (node == null) return mindMap;

    final updatedNodes = Map<String, MindMapNode>.from(mindMap.nodes);
    updatedNodes[nodeId] = node.copyWith(text: oldText);

    return mindMap.copyWith(nodes: updatedNodes);
  }
}

/// Command for updating node color
class UpdateNodeColorCommand extends EditorCommand {
  final String nodeId;
  final Color newColor;
  final Color oldColor;

  UpdateNodeColorCommand({
    required this.nodeId,
    required this.newColor,
    required this.oldColor,
  });

  @override
  MindMap execute(MindMap mindMap) {
    final node = mindMap.nodes[nodeId];
    if (node == null) return mindMap;

    final updatedNodes = Map<String, MindMapNode>.from(mindMap.nodes);
    updatedNodes[nodeId] = node.copyWith(color: newColor);

    return mindMap.copyWith(nodes: updatedNodes);
  }

  @override
  MindMap undo(MindMap mindMap) {
    final node = mindMap.nodes[nodeId];
    if (node == null) return mindMap;

    final updatedNodes = Map<String, MindMapNode>.from(mindMap.nodes);
    updatedNodes[nodeId] = node.copyWith(color: oldColor);

    return mindMap.copyWith(nodes: updatedNodes);
  }
}

/// Command for deleting a node and its children
class DeleteNodeCommand extends EditorCommand {
  final String nodeId;
  final Map<String, MindMapNode> deletedNodes;
  final String? parentId;
  final List<String> parentChildIds;

  DeleteNodeCommand({
    required this.nodeId,
    required this.deletedNodes,
    required this.parentId,
    required this.parentChildIds,
  });

  @override
  MindMap execute(MindMap mindMap) {
    final updatedNodes = Map<String, MindMapNode>.from(mindMap.nodes);

    // Update parent's childIds
    if (parentId != null && updatedNodes.containsKey(parentId)) {
      final parent = updatedNodes[parentId]!;
      updatedNodes[parentId] = parent.copyWith(
        childIds: parent.childIds.where((id) => id != nodeId).toList(),
      );
    }

    // Remove node and all descendants
    for (final id in deletedNodes.keys) {
      updatedNodes.remove(id);
    }

    return mindMap.copyWith(nodes: updatedNodes);
  }

  @override
  MindMap undo(MindMap mindMap) {
    final updatedNodes = Map<String, MindMapNode>.from(mindMap.nodes);

    // Restore all deleted nodes
    updatedNodes.addAll(deletedNodes);

    // Restore parent's childIds
    if (parentId != null && updatedNodes.containsKey(parentId)) {
      final parent = updatedNodes[parentId]!;
      updatedNodes[parentId] = parent.copyWith(childIds: parentChildIds);
    }

    return mindMap.copyWith(nodes: updatedNodes);
  }
}

/// Command for auto-layout
class AutoLayoutCommand extends EditorCommand {
  final Map<String, Offset> oldPositions;
  final Map<String, Offset> newPositions;

  AutoLayoutCommand({
    required this.oldPositions,
    required this.newPositions,
  });

  @override
  MindMap execute(MindMap mindMap) {
    final updatedNodes = Map<String, MindMapNode>.from(mindMap.nodes);

    for (final entry in newPositions.entries) {
      final node = updatedNodes[entry.key];
      if (node != null) {
        updatedNodes[entry.key] = node.copyWith(position: entry.value);
      }
    }

    return mindMap.copyWith(nodes: updatedNodes);
  }

  @override
  MindMap undo(MindMap mindMap) {
    final updatedNodes = Map<String, MindMapNode>.from(mindMap.nodes);

    for (final entry in oldPositions.entries) {
      final node = updatedNodes[entry.key];
      if (node != null) {
        updatedNodes[entry.key] = node.copyWith(position: entry.value);
      }
    }

    return mindMap.copyWith(nodes: updatedNodes);
  }
}

/// Service for managing editor history with command pattern
class EditorHistoryService {
  final List<EditorCommand> _undoStack = [];
  final List<EditorCommand> _redoStack = [];

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  int get undoCount => _undoStack.length;
  int get redoCount => _redoStack.length;

  /// Execute a command and add it to history
  MindMap execute(EditorCommand command, MindMap mindMap) {
    final result = command.execute(mindMap);

    _undoStack.add(command);
    _redoStack.clear();

    // Trim history if too large
    while (_undoStack.length > maxHistorySize) {
      _undoStack.removeAt(0);
    }

    return result;
  }

  /// Undo the last command
  MindMap? undo(MindMap mindMap) {
    if (!canUndo) return null;

    final command = _undoStack.removeLast();
    _redoStack.add(command);

    return command.undo(mindMap);
  }

  /// Redo the last undone command
  MindMap? redo(MindMap mindMap) {
    if (!canRedo) return null;

    final command = _redoStack.removeLast();
    _undoStack.add(command);

    return command.execute(mindMap);
  }

  /// Clear all history
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }
}
