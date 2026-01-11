import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/mind_map.dart';

/// Firestore service for mind map persistence
class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Collection reference for mind maps
  CollectionReference<Map<String, dynamic>> get _mindMapsCollection =>
      _firestore.collection('mind_maps');

  /// Create a new mind map
  Future<MindMap> createMindMap(MindMap mindMap) async {
    await _mindMapsCollection.doc(mindMap.id).set(mindMap.toJson());
    return mindMap;
  }

  /// Get a mind map by ID
  Future<MindMap?> getMindMap(String id) async {
    final doc = await _mindMapsCollection.doc(id).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return MindMap.fromJson(doc.data()!);
  }

  /// Get all mind maps for a user
  Future<List<MindMap>> getUserMindMaps(String userId) async {
    final querySnapshot = await _mindMapsCollection
        .where('ownerId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => MindMap.fromJson(doc.data()))
        .toList();
  }

  /// Update a mind map
  Future<void> updateMindMap(MindMap mindMap) async {
    await _mindMapsCollection.doc(mindMap.id).update(mindMap.toJson());
  }

  /// Delete a mind map
  Future<void> deleteMindMap(String id) async {
    await _mindMapsCollection.doc(id).delete();
  }

  /// Stream of mind maps for a user (for real-time updates)
  Stream<List<MindMap>> watchUserMindMaps(String userId) {
    return _mindMapsCollection
        .where('ownerId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => MindMap.fromJson(doc.data())).toList());
  }

  /// Stream of a single mind map (for real-time collaboration)
  Stream<MindMap?> watchMindMap(String id) {
    return _mindMapsCollection.doc(id).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return MindMap.fromJson(doc.data()!);
    });
  }

  /// Update a specific node in a mind map
  Future<void> updateNode(String mindMapId, MindMapNode node) async {
    await _mindMapsCollection.doc(mindMapId).update({
      'nodes.${node.id}': node.toJson(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Add a node to a mind map
  Future<void> addNode(String mindMapId, MindMapNode node, String? parentId) async {
    final batch = _firestore.batch();
    final docRef = _mindMapsCollection.doc(mindMapId);

    // Add the new node
    batch.update(docRef, {
      'nodes.${node.id}': node.toJson(),
      'updatedAt': DateTime.now().toIso8601String(),
    });

    // Update parent's childIds if applicable
    if (parentId != null) {
      batch.update(docRef, {
        'nodes.$parentId.childIds': FieldValue.arrayUnion([node.id]),
      });
    }

    await batch.commit();
  }

  /// Delete a node from a mind map
  Future<void> deleteNode(String mindMapId, String nodeId) async {
    await _mindMapsCollection.doc(mindMapId).update({
      'nodes.$nodeId': FieldValue.delete(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Get shared mind maps for a user
  Future<List<MindMap>> getSharedMindMaps(String userId) async {
    final querySnapshot = await _mindMapsCollection
        .where('collaboratorIds', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => MindMap.fromJson(doc.data()))
        .toList();
  }

  /// Add a collaborator to a mind map
  Future<void> addCollaborator(String mindMapId, String userId) async {
    await _mindMapsCollection.doc(mindMapId).update({
      'collaboratorIds': FieldValue.arrayUnion([userId]),
    });
  }

  /// Remove a collaborator from a mind map
  Future<void> removeCollaborator(String mindMapId, String userId) async {
    await _mindMapsCollection.doc(mindMapId).update({
      'collaboratorIds': FieldValue.arrayRemove([userId]),
    });
  }

  /// Duplicate a mind map
  Future<MindMap> duplicateMindMap(MindMap original, String newOwnerId) async {
    final duplicate = MindMap(
      title: '${original.title} (Copy)',
      ownerId: newOwnerId,
      nodes: Map.from(original.nodes),
      rootNodeId: original.rootNodeId,
    );

    await createMindMap(duplicate);
    return duplicate;
  }
}

/// Provider for Firestore service
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});
