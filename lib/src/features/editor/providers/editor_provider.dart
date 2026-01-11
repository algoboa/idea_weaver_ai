import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/models/mind_map.dart';
import '../../home/providers/mind_map_provider.dart';

/// Editor state holding the current mind map and history
class EditorState {
  final MindMap? mindMap;
  final List<MindMap> undoHistory;
  final List<MindMap> redoHistory;
  final bool hasChanges;
  final bool isLoading;
  final String? error;

  EditorState({
    this.mindMap,
    this.undoHistory = const [],
    this.redoHistory = const [],
    this.hasChanges = false,
    this.isLoading = false,
    this.error,
  });

  EditorState copyWith({
    MindMap? mindMap,
    List<MindMap>? undoHistory,
    List<MindMap>? redoHistory,
    bool? hasChanges,
    bool? isLoading,
    String? error,
  }) {
    return EditorState(
      mindMap: mindMap ?? this.mindMap,
      undoHistory: undoHistory ?? this.undoHistory,
      redoHistory: redoHistory ?? this.redoHistory,
      hasChanges: hasChanges ?? this.hasChanges,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Editor provider for managing mind map editing
class EditorNotifier extends Notifier<EditorState> {
  static const _uuid = Uuid();

  @override
  EditorState build() {
    return EditorState();
  }

  void loadMindMap(String id) {
    state = state.copyWith(isLoading: true, error: null);

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

  void _saveState() {
    if (state.mindMap == null) return;

    final newHistory = [...state.undoHistory, state.mindMap!];
    if (newHistory.length > 50) {
      newHistory.removeAt(0);
    }
    state = state.copyWith(
      undoHistory: newHistory,
      redoHistory: [],
      hasChanges: true,
    );
  }

  void undo() {
    if (state.undoHistory.isEmpty || state.mindMap == null) return;

    final newUndo = [...state.undoHistory];
    final previousState = newUndo.removeLast();
    final newRedo = [...state.redoHistory, state.mindMap!];

    state = state.copyWith(
      mindMap: previousState,
      undoHistory: newUndo,
      redoHistory: newRedo,
    );
  }

  void redo() {
    if (state.redoHistory.isEmpty) return;

    final newRedo = [...state.redoHistory];
    final nextState = newRedo.removeLast();
    final newUndo = [...state.undoHistory];
    if (state.mindMap != null) {
      newUndo.add(state.mindMap!);
    }

    state = state.copyWith(
      mindMap: nextState,
      undoHistory: newUndo,
      redoHistory: newRedo,
    );
  }

  void addNode({String? parentId, required String text}) {
    if (state.mindMap == null) return;

    _saveState();

    final mindMap = state.mindMap!;
    final nodeId = _uuid.v4();

    Offset position;
    if (parentId != null) {
      final parent = mindMap.nodes[parentId]!;
      final childCount = parent.childIds.length;
      final angle = (childCount * 0.5) - 0.25;
      position = Offset(
        parent.position.dx + 200 * cos(angle),
        parent.position.dy + 150 + (childCount * 50),
      );
    } else {
      // Find a good position for root-level node
      final existingNodes = mindMap.nodes.values
          .where((n) => n.parentId == null)
          .toList();
      position = Offset(
        existingNodes.length * 250.0,
        0,
      );
    }

    final newNode = MindMapNode(
      id: nodeId,
      text: text,
      position: position,
      parentId: parentId,
    );

    final updatedNodes = Map<String, MindMapNode>.from(mindMap.nodes);
    updatedNodes[nodeId] = newNode;

    // Update parent's childIds
    if (parentId != null) {
      final parent = updatedNodes[parentId]!;
      updatedNodes[parentId] = parent.copyWith(
        childIds: [...parent.childIds, nodeId],
      );
    }

    state = state.copyWith(
      mindMap: mindMap.copyWith(
        nodes: updatedNodes,
        rootNodeId: mindMap.rootNodeId ?? nodeId,
      ),
    );
  }

  void updateNodeText(String nodeId, String text) {
    if (state.mindMap == null) return;

    _saveState();

    final mindMap = state.mindMap!;
    final node = mindMap.nodes[nodeId];
    if (node == null) return;

    final updatedNodes = Map<String, MindMapNode>.from(mindMap.nodes);
    updatedNodes[nodeId] = node.copyWith(text: text);

    state = state.copyWith(
      mindMap: mindMap.copyWith(nodes: updatedNodes),
    );
  }

  void updateNodeColor(String nodeId, Color color) {
    if (state.mindMap == null) return;

    _saveState();

    final mindMap = state.mindMap!;
    final node = mindMap.nodes[nodeId];
    if (node == null) return;

    final updatedNodes = Map<String, MindMapNode>.from(mindMap.nodes);
    updatedNodes[nodeId] = node.copyWith(color: color);

    state = state.copyWith(
      mindMap: mindMap.copyWith(nodes: updatedNodes),
    );
  }

  void moveNode(String nodeId, Offset newPosition) {
    if (state.mindMap == null) return;

    final mindMap = state.mindMap!;
    final node = mindMap.nodes[nodeId];
    if (node == null) return;

    final updatedNodes = Map<String, MindMapNode>.from(mindMap.nodes);
    updatedNodes[nodeId] = node.copyWith(position: newPosition);

    state = state.copyWith(
      mindMap: mindMap.copyWith(nodes: updatedNodes),
      hasChanges: true,
    );
  }

  void deleteNode(String nodeId) {
    if (state.mindMap == null) return;

    _saveState();

    final mindMap = state.mindMap!;
    final node = mindMap.nodes[nodeId];
    if (node == null) return;

    // Can't delete root node
    if (node.parentId == null) return;

    final updatedNodes = Map<String, MindMapNode>.from(mindMap.nodes);

    // Remove from parent's childIds
    final parent = updatedNodes[node.parentId]!;
    updatedNodes[node.parentId!] = parent.copyWith(
      childIds: parent.childIds.where((id) => id != nodeId).toList(),
    );

    // Remove node and all descendants
    _deleteNodeRecursive(nodeId, updatedNodes);

    state = state.copyWith(
      mindMap: mindMap.copyWith(nodes: updatedNodes),
    );
  }

  void _deleteNodeRecursive(String nodeId, Map<String, MindMapNode> nodes) {
    final node = nodes[nodeId];
    if (node == null) return;

    for (final childId in node.childIds) {
      _deleteNodeRecursive(childId, nodes);
    }
    nodes.remove(nodeId);
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

    _saveState();

    final mindMap = state.mindMap!;
    if (mindMap.rootNodeId == null) return;

    final updatedNodes = Map<String, MindMapNode>.from(mindMap.nodes);
    _layoutNode(
      mindMap.rootNodeId!,
      const Offset(0, 0),
      0,
      updatedNodes,
    );

    state = state.copyWith(
      mindMap: mindMap.copyWith(nodes: updatedNodes),
    );
  }

  void _layoutNode(
    String nodeId,
    Offset position,
    int level,
    Map<String, MindMapNode> nodes,
  ) {
    final node = nodes[nodeId];
    if (node == null) return;

    nodes[nodeId] = node.copyWith(position: position);

    final childCount = node.childIds.length;
    if (childCount == 0) return;

    const spacing = 180.0;
    final totalHeight = (childCount - 1) * spacing;
    var yOffset = -totalHeight / 2;

    for (var i = 0; i < childCount; i++) {
      final childId = node.childIds[i];
      final childPosition = Offset(
        position.dx + 250,
        position.dy + yOffset,
      );
      _layoutNode(childId, childPosition, level + 1, nodes);
      yOffset += spacing;
    }
  }
}

final editorProvider = NotifierProvider<EditorNotifier, EditorState>(() {
  return EditorNotifier();
});
