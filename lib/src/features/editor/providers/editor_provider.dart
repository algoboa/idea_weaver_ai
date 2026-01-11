import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/canvas_constants.dart';
import '../../../domain/models/mind_map.dart';
import '../../home/providers/mind_map_provider.dart';
import '../services/editor_history_service.dart';

/// Editor state holding the current mind map and editing status
class EditorState {
  final MindMap? mindMap;
  final bool canUndo;
  final bool canRedo;
  final bool hasChanges;
  final bool isLoading;
  final String? error;

  const EditorState({
    this.mindMap,
    this.canUndo = false,
    this.canRedo = false,
    this.hasChanges = false,
    this.isLoading = false,
    this.error,
  });

  EditorState copyWith({
    MindMap? mindMap,
    bool? canUndo,
    bool? canRedo,
    bool? hasChanges,
    bool? isLoading,
    String? error,
  }) {
    return EditorState(
      mindMap: mindMap ?? this.mindMap,
      canUndo: canUndo ?? this.canUndo,
      canRedo: canRedo ?? this.canRedo,
      hasChanges: hasChanges ?? this.hasChanges,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Editor provider for managing mind map editing
class EditorNotifier extends Notifier<EditorState> {
  static const _uuid = Uuid();
  final EditorHistoryService _historyService = EditorHistoryService();

  @override
  EditorState build() {
    return const EditorState();
  }

  void loadMindMap(String id) {
    state = state.copyWith(isLoading: true, error: null);
    _historyService.clear();

    try {
      final mindMapsState = ref.read(mindMapsProvider);
      final mindMap = mindMapsState.mindMaps.firstWhere(
        (m) => m.id == id,
        orElse: () => throw Exception('Mind map not found'),
      );
      state = EditorState(mindMap: mindMap);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  void createNewMindMap() {
    _historyService.clear();

    final rootNode = MindMapNode(
      id: 'root',
      text: 'Central Idea',
      position: const Offset(0, 0),
    );

    final newMindMap = MindMap(
      title: 'Untitled Mind Map',
      ownerId: 'current_user',
      nodes: {'root': rootNode},
      rootNodeId: 'root',
    );

    state = EditorState(mindMap: newMindMap);
  }

  void _updateHistoryState() {
    state = state.copyWith(
      canUndo: _historyService.canUndo,
      canRedo: _historyService.canRedo,
      hasChanges: true,
    );
  }

  void undo() {
    if (state.mindMap == null || !_historyService.canUndo) return;

    final result = _historyService.undo(state.mindMap!);
    if (result != null) {
      state = state.copyWith(
        mindMap: result,
        canUndo: _historyService.canUndo,
        canRedo: _historyService.canRedo,
      );
    }
  }

  void redo() {
    if (state.mindMap == null || !_historyService.canRedo) return;

    final result = _historyService.redo(state.mindMap!);
    if (result != null) {
      state = state.copyWith(
        mindMap: result,
        canUndo: _historyService.canUndo,
        canRedo: _historyService.canRedo,
      );
    }
  }

  void addNode({String? parentId, required String text}) {
    if (state.mindMap == null) return;

    final mindMap = state.mindMap!;
    final nodeId = _uuid.v4();

    Offset position;
    if (parentId != null) {
      final parent = mindMap.nodes[parentId]!;
      final childCount = parent.childIds.length;
      final angle = (childCount * 0.5) - 0.25;
      position = Offset(
        parent.position.dx + 200 * cos(angle),
        parent.position.dy + CanvasConstants.childYOffset + (childCount * 50),
      );
    } else {
      // Find a good position for root-level node
      final existingNodes = mindMap.nodes.values
          .where((n) => n.parentId == null)
          .toList();
      position = Offset(
        existingNodes.length * CanvasConstants.horizontalSpacing,
        0,
      );
    }

    final command = AddNodeCommand(
      nodeId: nodeId,
      text: text,
      position: position,
      parentId: parentId,
      color: Colors.blue,
    );

    final result = _historyService.execute(command, mindMap);
    state = state.copyWith(mindMap: result);
    _updateHistoryState();
  }

  void updateNodeText(String nodeId, String text) {
    if (state.mindMap == null) return;

    final mindMap = state.mindMap!;
    final node = mindMap.nodes[nodeId];
    if (node == null) return;

    final command = UpdateNodeTextCommand(
      nodeId: nodeId,
      newText: text,
      oldText: node.text,
    );

    final result = _historyService.execute(command, mindMap);
    state = state.copyWith(mindMap: result);
    _updateHistoryState();
  }

  void updateNodeColor(String nodeId, Color color) {
    if (state.mindMap == null) return;

    final mindMap = state.mindMap!;
    final node = mindMap.nodes[nodeId];
    if (node == null) return;

    final command = UpdateNodeColorCommand(
      nodeId: nodeId,
      newColor: color,
      oldColor: node.color,
    );

    final result = _historyService.execute(command, mindMap);
    state = state.copyWith(mindMap: result);
    _updateHistoryState();
  }

  void moveNode(String nodeId, Offset newPosition) {
    if (state.mindMap == null) return;

    final mindMap = state.mindMap!;
    final node = mindMap.nodes[nodeId];
    if (node == null) return;

    // Direct update without history for smooth dragging
    final updatedNodes = Map<String, MindMapNode>.from(mindMap.nodes);
    updatedNodes[nodeId] = node.copyWith(position: newPosition);

    state = state.copyWith(
      mindMap: mindMap.copyWith(nodes: updatedNodes),
      hasChanges: true,
    );
  }

  void deleteNode(String nodeId) {
    if (state.mindMap == null) return;

    final mindMap = state.mindMap!;
    final node = mindMap.nodes[nodeId];
    if (node == null) return;

    // Can't delete root node
    if (node.parentId == null) return;

    // Collect all nodes to delete (node and descendants)
    final deletedNodes = <String, MindMapNode>{};
    _collectNodeAndDescendants(nodeId, mindMap.nodes, deletedNodes);

    // Get parent's current childIds
    final parent = mindMap.nodes[node.parentId]!;

    final command = DeleteNodeCommand(
      nodeId: nodeId,
      deletedNodes: deletedNodes,
      parentId: node.parentId,
      parentChildIds: List.from(parent.childIds),
    );

    final result = _historyService.execute(command, mindMap);
    state = state.copyWith(mindMap: result);
    _updateHistoryState();
  }

  void _collectNodeAndDescendants(
    String nodeId,
    Map<String, MindMapNode> nodes,
    Map<String, MindMapNode> collected,
  ) {
    final node = nodes[nodeId];
    if (node == null) return;

    collected[nodeId] = node;
    for (final childId in node.childIds) {
      _collectNodeAndDescendants(childId, nodes, collected);
    }
  }

  void updateTitle(String title) {
    if (state.mindMap == null) return;

    state = state.copyWith(
      mindMap: state.mindMap!.copyWith(title: title),
      hasChanges: true,
    );
  }

  void autoLayout() {
    if (state.mindMap == null) return;

    final mindMap = state.mindMap!;
    if (mindMap.rootNodeId == null) return;

    // Store old positions
    final oldPositions = <String, Offset>{};
    for (final entry in mindMap.nodes.entries) {
      oldPositions[entry.key] = entry.value.position;
    }

    // Calculate new positions
    final newPositions = <String, Offset>{};
    _calculateLayoutPositions(
      mindMap.rootNodeId!,
      const Offset(0, 0),
      0,
      mindMap.nodes,
      newPositions,
    );

    final command = AutoLayoutCommand(
      oldPositions: oldPositions,
      newPositions: newPositions,
    );

    final result = _historyService.execute(command, mindMap);
    state = state.copyWith(mindMap: result);
    _updateHistoryState();
  }

  void _calculateLayoutPositions(
    String nodeId,
    Offset position,
    int level,
    Map<String, MindMapNode> nodes,
    Map<String, Offset> positions,
  ) {
    final node = nodes[nodeId];
    if (node == null) return;

    positions[nodeId] = position;

    final childCount = node.childIds.length;
    if (childCount == 0) return;

    final totalHeight = (childCount - 1) * CanvasConstants.verticalSpacing;
    var yOffset = -totalHeight / 2;

    for (var i = 0; i < childCount; i++) {
      final childId = node.childIds[i];
      final childPosition = Offset(
        position.dx + CanvasConstants.horizontalSpacing,
        position.dy + yOffset,
      );
      _calculateLayoutPositions(childId, childPosition, level + 1, nodes, positions);
      yOffset += CanvasConstants.verticalSpacing;
    }
  }
}

final editorProvider = NotifierProvider<EditorNotifier, EditorState>(() {
  return EditorNotifier();
});
