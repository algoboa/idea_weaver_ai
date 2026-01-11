import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// Represents a single node in the mind map
class MindMapNode {
  final String id;
  final String text;
  final Offset position;
  final String? parentId;
  final List<String> childIds;
  final Color color;
  final bool isExpanded;
  final DateTime createdAt;
  final DateTime updatedAt;

  MindMapNode({
    String? id,
    required this.text,
    required this.position,
    this.parentId,
    List<String>? childIds,
    Color? color,
    this.isExpanded = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        childIds = childIds ?? [],
        color = color ?? Colors.blue,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  MindMapNode copyWith({
    String? id,
    String? text,
    Offset? position,
    String? parentId,
    List<String>? childIds,
    Color? color,
    bool? isExpanded,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MindMapNode(
      id: id ?? this.id,
      text: text ?? this.text,
      position: position ?? this.position,
      parentId: parentId ?? this.parentId,
      childIds: childIds ?? this.childIds,
      color: color ?? this.color,
      isExpanded: isExpanded ?? this.isExpanded,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'positionX': position.dx,
      'positionY': position.dy,
      'parentId': parentId,
      'childIds': childIds,
      'color': color.toARGB32(),
      'isExpanded': isExpanded,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MindMapNode.fromJson(Map<String, dynamic> json) {
    return MindMapNode(
      id: json['id'] as String,
      text: json['text'] as String,
      position: Offset(
        (json['positionX'] as num).toDouble(),
        (json['positionY'] as num).toDouble(),
      ),
      parentId: json['parentId'] as String?,
      childIds: List<String>.from(json['childIds'] ?? []),
      color: Color(json['color'] as int),
      isExpanded: json['isExpanded'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MindMapNode &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Represents a complete mind map with metadata
class MindMap {
  final String id;
  final String title;
  final String ownerId;
  final Map<String, MindMapNode> nodes;
  final String? rootNodeId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> collaboratorIds;
  final bool isPublic;

  MindMap({
    String? id,
    required this.title,
    required this.ownerId,
    Map<String, MindMapNode>? nodes,
    this.rootNodeId,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? collaboratorIds,
    this.isPublic = false,
  })  : id = id ?? const Uuid().v4(),
        nodes = nodes ?? {},
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        collaboratorIds = collaboratorIds ?? [];

  MindMap copyWith({
    String? id,
    String? title,
    String? ownerId,
    Map<String, MindMapNode>? nodes,
    String? rootNodeId,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? collaboratorIds,
    bool? isPublic,
  }) {
    return MindMap(
      id: id ?? this.id,
      title: title ?? this.title,
      ownerId: ownerId ?? this.ownerId,
      nodes: nodes ?? this.nodes,
      rootNodeId: rootNodeId ?? this.rootNodeId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      collaboratorIds: collaboratorIds ?? this.collaboratorIds,
      isPublic: isPublic ?? this.isPublic,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'ownerId': ownerId,
      'nodes': nodes.map((key, node) => MapEntry(key, node.toJson())),
      'rootNodeId': rootNodeId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'collaboratorIds': collaboratorIds,
      'isPublic': isPublic,
    };
  }

  factory MindMap.fromJson(Map<String, dynamic> json) {
    final nodesJson = json['nodes'] as Map<String, dynamic>? ?? {};
    return MindMap(
      id: json['id'] as String,
      title: json['title'] as String,
      ownerId: json['ownerId'] as String,
      nodes: nodesJson.map(
        (key, value) => MapEntry(
          key,
          MindMapNode.fromJson(value as Map<String, dynamic>),
        ),
      ),
      rootNodeId: json['rootNodeId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      collaboratorIds: List<String>.from(json['collaboratorIds'] ?? []),
      isPublic: json['isPublic'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MindMap && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
