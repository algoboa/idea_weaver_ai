import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/mind_map.dart';
import 'firestore_service.dart';

/// Represents a user's cursor position during collaboration
class CollaboratorCursor {
  final String odId;
  final String displayName;
  final Color color;
  final Offset position;
  final DateTime lastUpdated;

  CollaboratorCursor({
    required this.odId,
    required this.displayName,
    required this.color,
    required this.position,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() => {
        'userId': odId,
        'displayName': displayName,
        'color': color.toARGB32(),
        'positionX': position.dx,
        'positionY': position.dy,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory CollaboratorCursor.fromJson(Map<String, dynamic> json) {
    return CollaboratorCursor(
      odId: json['userId'] as String,
      displayName: json['displayName'] as String,
      color: Color(json['color'] as int),
      position: Offset(
        (json['positionX'] as num).toDouble(),
        (json['positionY'] as num).toDouble(),
      ),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }
}

/// Real-time collaboration service
class CollaborationService {
  final FirebaseFirestore _firestore;
  final FirestoreService _firestoreService;

  StreamSubscription? _mindMapSubscription;
  StreamSubscription? _cursorsSubscription;

  final _mindMapController = StreamController<MindMap>.broadcast();
  final _cursorsController = StreamController<List<CollaboratorCursor>>.broadcast();

  Stream<MindMap> get mindMapStream => _mindMapController.stream;
  Stream<List<CollaboratorCursor>> get cursorsStream => _cursorsController.stream;

  String? _currentMindMapId;
  String? _currentUserId;

  CollaborationService({
    FirebaseFirestore? firestore,
    required FirestoreService firestoreService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _firestoreService = firestoreService;

  /// Join a collaborative session for a mind map
  Future<void> joinSession(String mindMapId, String odId, String displayName) async {
    _currentMindMapId = mindMapId;
    _currentUserId = odId;

    // Subscribe to mind map updates
    _mindMapSubscription = _firestoreService.watchMindMap(mindMapId).listen((mindMap) {
      if (mindMap != null) {
        _mindMapController.add(mindMap);
      }
    });

    // Subscribe to cursor updates
    _cursorsSubscription = _firestore
        .collection('mind_maps')
        .doc(mindMapId)
        .collection('cursors')
        .snapshots()
        .listen((snapshot) {
      final cursors = snapshot.docs
          .map((doc) => CollaboratorCursor.fromJson(doc.data()))
          .where((cursor) => cursor.odId != odId) // Exclude own cursor
          .where((cursor) {
            // Only show cursors updated in the last 30 seconds
            final thirtySecondsAgo = DateTime.now().subtract(const Duration(seconds: 30));
            return cursor.lastUpdated.isAfter(thirtySecondsAgo);
          })
          .toList();
      _cursorsController.add(cursors);
    });

    // Add presence
    await _updatePresence(displayName);
  }

  /// Leave the collaborative session
  Future<void> leaveSession() async {
    if (_currentMindMapId != null && _currentUserId != null) {
      // Remove cursor
      await _firestore
          .collection('mind_maps')
          .doc(_currentMindMapId)
          .collection('cursors')
          .doc(_currentUserId)
          .delete();
    }

    _mindMapSubscription?.cancel();
    _cursorsSubscription?.cancel();
    _currentMindMapId = null;
    _currentUserId = null;
  }

  /// Update cursor position
  Future<void> updateCursorPosition(Offset position) async {
    if (_currentMindMapId == null || _currentUserId == null) return;

    await _firestore
        .collection('mind_maps')
        .doc(_currentMindMapId)
        .collection('cursors')
        .doc(_currentUserId)
        .update({
      'positionX': position.dx,
      'positionY': position.dy,
      'lastUpdated': DateTime.now().toIso8601String(),
    });
  }

  /// Update node in real-time
  Future<void> updateNode(MindMapNode node) async {
    if (_currentMindMapId == null) return;
    await _firestoreService.updateNode(_currentMindMapId!, node);
  }

  /// Add node in real-time
  Future<void> addNode(MindMapNode node, String? parentId) async {
    if (_currentMindMapId == null) return;
    await _firestoreService.addNode(_currentMindMapId!, node, parentId);
  }

  /// Delete node in real-time
  Future<void> deleteNode(String nodeId) async {
    if (_currentMindMapId == null) return;
    await _firestoreService.deleteNode(_currentMindMapId!, nodeId);
  }

  Future<void> _updatePresence(String displayName) async {
    if (_currentMindMapId == null || _currentUserId == null) return;

    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
    ];

    final color = colors[_currentUserId.hashCode % colors.length];

    await _firestore
        .collection('mind_maps')
        .doc(_currentMindMapId)
        .collection('cursors')
        .doc(_currentUserId)
        .set(CollaboratorCursor(
          odId: _currentUserId!,
          displayName: displayName,
          color: color,
          position: Offset.zero,
          lastUpdated: DateTime.now(),
        ).toJson());
  }

  void dispose() {
    _mindMapSubscription?.cancel();
    _cursorsSubscription?.cancel();
    _mindMapController.close();
    _cursorsController.close();
  }
}

/// Provider for collaboration service
final collaborationServiceProvider = Provider<CollaborationService>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return CollaborationService(firestoreService: firestoreService);
});
