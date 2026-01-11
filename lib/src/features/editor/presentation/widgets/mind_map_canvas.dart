import 'package:flutter/material.dart';
import '../../../../core/constants/canvas_constants.dart';
import '../../../../domain/models/mind_map.dart';

class MindMapCanvas extends StatefulWidget {
  final MindMap mindMap;
  final String? selectedNodeId;
  final TransformationController transformController;
  final Function(String) onNodeSelected;
  final Function(String, Offset) onNodeMoved;
  final Function(String) onNodeDoubleTap;
  final Function(String) onAddChildNode;
  final Function(String, Offset) onShowContextMenu;

  const MindMapCanvas({
    super.key,
    required this.mindMap,
    this.selectedNodeId,
    required this.transformController,
    required this.onNodeSelected,
    required this.onNodeMoved,
    required this.onNodeDoubleTap,
    required this.onAddChildNode,
    required this.onShowContextMenu,
  });

  @override
  State<MindMapCanvas> createState() => _MindMapCanvasState();
}

class _MindMapCanvasState extends State<MindMapCanvas> {
  String? _draggingNodeId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTapDown: (details) {
        // Deselect when tapping canvas
        widget.onNodeSelected('');
      },
      child: InteractiveViewer(
        transformationController: widget.transformController,
        boundaryMargin: const EdgeInsets.all(CanvasConstants.boundaryMargin),
        minScale: CanvasConstants.minScale,
        maxScale: CanvasConstants.maxScale,
        child: SizedBox(
          width: CanvasConstants.canvasWidth,
          height: CanvasConstants.canvasHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Grid background - wrapped in RepaintBoundary for isolation
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _GridPainter(
                      color: theme.colorScheme.outline.withValues(alpha: 0.1),
                    ),
                  ),
                ),
              ),

              // Connection lines - only repaints when nodes change
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _ConnectionPainter(
                      nodes: widget.mindMap.nodes,
                    ),
                  ),
                ),
              ),

              // Nodes - each wrapped in RepaintBoundary
              ...widget.mindMap.nodes.values.map(
                (node) => _MindMapNodeWidget(
                  key: ValueKey(node.id),
                  node: node,
                  isSelected: widget.selectedNodeId == node.id,
                  isDragging: _draggingNodeId == node.id,
                  transformController: widget.transformController,
                  onSelected: widget.onNodeSelected,
                  onDoubleTap: widget.onNodeDoubleTap,
                  onContextMenu: widget.onShowContextMenu,
                  onAddChild: widget.onAddChildNode,
                  onMoved: widget.onNodeMoved,
                  onDragStart: (nodeId) => setState(() => _draggingNodeId = nodeId),
                  onDragEnd: () => setState(() => _draggingNodeId = null),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Optimized node widget that only rebuilds when its specific node changes
class _MindMapNodeWidget extends StatelessWidget {
  final MindMapNode node;
  final bool isSelected;
  final bool isDragging;
  final TransformationController transformController;
  final Function(String) onSelected;
  final Function(String) onDoubleTap;
  final Function(String, Offset) onContextMenu;
  final Function(String) onAddChild;
  final Function(String, Offset) onMoved;
  final Function(String) onDragStart;
  final VoidCallback onDragEnd;

  const _MindMapNodeWidget({
    super.key,
    required this.node,
    required this.isSelected,
    required this.isDragging,
    required this.transformController,
    required this.onSelected,
    required this.onDoubleTap,
    required this.onContextMenu,
    required this.onAddChild,
    required this.onMoved,
    required this.onDragStart,
    required this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    final position = Offset(
      CanvasConstants.canvasCenterX + node.position.dx - CanvasConstants.nodeHalfWidth,
      CanvasConstants.canvasCenterY + node.position.dy - CanvasConstants.nodeHalfHeight / 2,
    );

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: RepaintBoundary(
        child: GestureDetector(
          onTap: () => onSelected(node.id),
          onDoubleTap: () => onDoubleTap(node.id),
          onLongPressStart: (details) {
            onContextMenu(node.id, details.globalPosition);
          },
          onPanStart: (details) => onDragStart(node.id),
          onPanUpdate: (details) {
            if (isDragging) {
              final scale = transformController.value.getMaxScaleOnAxis();
              final newPosition = Offset(
                node.position.dx + details.delta.dx / scale,
                node.position.dy + details.delta.dy / scale,
              );
              onMoved(node.id, newPosition);
            }
          },
          onPanEnd: (_) => onDragEnd(),
          child: AnimatedContainer(
            duration: AnimationConstants.shortDuration,
            width: CanvasConstants.nodeWidth,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? node.color.withValues(alpha: 0.9)
                  : node.color.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: node.color.withValues(alpha: 0.3),
                  blurRadius: isSelected ? 12 : 6,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  node.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isSelected) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _NodeActionButton(
                        icon: Icons.add,
                        onTap: () => onAddChild(node.id),
                      ),
                      const SizedBox(width: 8),
                      _NodeActionButton(
                        icon: Icons.edit,
                        onTap: () => onDoubleTap(node.id),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Optimized action button - const constructor
class _NodeActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NodeActionButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color color;

  _GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    for (var x = 0.0; x < size.width; x += CanvasConstants.gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (var y = 0.0; y < size.height; y += CanvasConstants.gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return color != oldDelegate.color;
  }
}

class _ConnectionPainter extends CustomPainter {
  final Map<String, MindMapNode> nodes;

  // Cache for node positions to detect changes
  late final int _nodesHashCode;

  _ConnectionPainter({required this.nodes})
      : _nodesHashCode = _computeNodesHash(nodes);

  static int _computeNodesHash(Map<String, MindMapNode> nodes) {
    var hash = 0;
    for (final node in nodes.values) {
      hash ^= node.id.hashCode;
      hash ^= node.position.dx.hashCode;
      hash ^= node.position.dy.hashCode;
      hash ^= (node.parentId?.hashCode ?? 0);
      hash ^= node.color.value;
    }
    return hash;
  }

  @override
  void paint(Canvas canvas, Size size) {
    const center = Offset(
      CanvasConstants.canvasCenterX,
      CanvasConstants.canvasCenterY,
    );

    for (final node in nodes.values) {
      if (node.parentId != null) {
        final parent = nodes[node.parentId];
        if (parent != null) {
          _drawConnection(canvas, parent, node, center);
        }
      }
    }
  }

  void _drawConnection(
    Canvas canvas,
    MindMapNode parent,
    MindMapNode child,
    Offset center,
  ) {
    final startPoint = Offset(
      center.dx + parent.position.dx,
      center.dy + parent.position.dy,
    );
    final endPoint = Offset(
      center.dx + child.position.dx,
      center.dy + child.position.dy,
    );

    final paint = Paint()
      ..color = parent.color.withValues(alpha: CanvasConstants.connectionOpacity)
      ..strokeWidth = CanvasConstants.connectionLineWidth
      ..style = PaintingStyle.stroke;

    // Draw curved line
    final controlPoint1 = Offset(
      startPoint.dx + (endPoint.dx - startPoint.dx) * 0.5,
      startPoint.dy,
    );
    final controlPoint2 = Offset(
      startPoint.dx + (endPoint.dx - startPoint.dx) * 0.5,
      endPoint.dy,
    );

    final path = Path()
      ..moveTo(startPoint.dx, startPoint.dy)
      ..cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        endPoint.dx,
        endPoint.dy,
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ConnectionPainter oldDelegate) {
    return _nodesHashCode != oldDelegate._nodesHashCode;
  }
}
