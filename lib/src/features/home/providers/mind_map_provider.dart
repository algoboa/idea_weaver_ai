import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/mind_map.dart';

/// Mind maps state
class MindMapsState {
  final List<MindMap> mindMaps;
  final bool isLoading;
  final String? error;

  MindMapsState({
    this.mindMaps = const [],
    this.isLoading = false,
    this.error,
  });

  MindMapsState copyWith({
    List<MindMap>? mindMaps,
    bool? isLoading,
    String? error,
  }) {
    return MindMapsState(
      mindMaps: mindMaps ?? this.mindMaps,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Mock data provider for mind maps
class MindMapsNotifier extends Notifier<MindMapsState> {
  @override
  MindMapsState build() {
    _loadMockData();
    return MindMapsState(isLoading: true);
  }

  void _loadMockData() {
    // Simulate loading delay
    Future.delayed(const Duration(milliseconds: 500), () {
      state = MindMapsState(mindMaps: _getMockMindMaps());
    });
  }

  List<MindMap> _getMockMindMaps() {
    final now = DateTime.now();
    return [
      MindMap(
        id: '1',
        title: 'Project Brainstorm',
        ownerId: 'user1',
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(hours: 1)),
        nodes: {
          'root': MindMapNode(
            id: 'root',
            text: 'Project Ideas',
            position: const Offset(0, 0),
            childIds: ['child1', 'child2'],
          ),
          'child1': MindMapNode(
            id: 'child1',
            text: 'Mobile App',
            position: const Offset(-150, 100),
            parentId: 'root',
          ),
          'child2': MindMapNode(
            id: 'child2',
            text: 'Web Platform',
            position: const Offset(150, 100),
            parentId: 'root',
          ),
        },
        rootNodeId: 'root',
      ),
      MindMap(
        id: '2',
        title: 'Marketing Strategy',
        ownerId: 'user1',
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 1)),
        nodes: {
          'root': MindMapNode(
            id: 'root',
            text: 'Marketing',
            position: const Offset(0, 0),
            childIds: ['child1'],
          ),
          'child1': MindMapNode(
            id: 'child1',
            text: 'Social Media',
            position: const Offset(0, 100),
            parentId: 'root',
          ),
        },
        rootNodeId: 'root',
      ),
      MindMap(
        id: '3',
        title: 'Product Roadmap',
        ownerId: 'user1',
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(days: 3)),
        nodes: {
          'root': MindMapNode(
            id: 'root',
            text: 'Roadmap Q1',
            position: const Offset(0, 0),
          ),
        },
        rootNodeId: 'root',
      ),
    ];
  }

  Future<MindMap> createMindMap(String title, String ownerId) async {
    final newMindMap = MindMap(
      title: title,
      ownerId: ownerId,
      nodes: {
        'root': MindMapNode(
          id: 'root',
          text: title,
          position: const Offset(0, 0),
        ),
      },
      rootNodeId: 'root',
    );

    state = state.copyWith(
      mindMaps: [newMindMap, ...state.mindMaps],
    );

    return newMindMap;
  }

  Future<void> deleteMindMap(String id) async {
    state = state.copyWith(
      mindMaps: state.mindMaps.where((m) => m.id != id).toList(),
    );
  }

  Future<void> duplicateMindMap(String id) async {
    final original = state.mindMaps.firstWhere((m) => m.id == id);
    final duplicate = original.copyWith(
      id: null, // Will generate new ID
      title: '${original.title} (Copy)',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(
      mindMaps: [duplicate, ...state.mindMaps],
    );
  }

  Future<void> renameMindMap(String id, String newTitle) async {
    state = state.copyWith(
      mindMaps: state.mindMaps.map((m) {
        if (m.id == id) {
          return m.copyWith(title: newTitle);
        }
        return m;
      }).toList(),
    );
  }

  void refresh() {
    state = MindMapsState(isLoading: true);
    _loadMockData();
  }

  MindMap? getMindMapById(String id) {
    try {
      return state.mindMaps.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }
}

final mindMapsProvider = NotifierProvider<MindMapsNotifier, MindMapsState>(() {
  return MindMapsNotifier();
});

/// Provider for a single mind map
final mindMapProvider = Provider.family<MindMap?, String>((ref, id) {
  final mindMapsState = ref.watch(mindMapsProvider);
  try {
    return mindMapsState.mindMaps.firstWhere((m) => m.id == id);
  } catch (_) {
    return null;
  }
});
