import 'package:flutter/material.dart';
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapDown: (details) {
            // Deselect when tapping canvas
            widget.onNodeSelected('');
          },
          child: InteractiveViewer(
            transformationController: widget.transformController,
            boundaryMargin: const EdgeInsets.all(2000),
            minScale: 0.3,
            maxScale: 3.0,
            child: SizedBox(
              width: 4000,
              height: 4000,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Grid background
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _GridPainter(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.1),
                      ),
                    ),
                  ),

                  // Connection lines
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _ConnectionPainter(
                        nodes: widget.mindMap.nodes,
                        center: const Offset(2000, 2000),
                      ),
                    ),
                  ),

                  // Nodes
                  ...widget.mindMap.nodes.values.map(
                    (node) => _buildNode(node),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNode(MindMapNode node) {
    final isSelected = widget.selectedNodeId == node.id;
    final position = Offset(
      2000 + node.position.dx,
      2000 + node.position.dy,
    );

    return Positioned(
      left: position.dx - 75,
      top: position.dy - 30,
      child: GestureDetector(
        onTap: () => widget.onNodeSelected(node.id),
        onDoubleTap: () => widget.onNodeDoubleTap(node.id),
        onLongPressStart: (details) {
          widget.onShowContextMenu(node.id, details.globalPosition);
        },
        onPanStart: (details) {
          setState(() {
            _draggingNodeId = node.id;
          });
        },
        onPanUpdate: (details) {
          if (_draggingNodeId == node.id) {
            final scale =
                widget.transformController.value.getMaxScaleOnAxis();
            final newPosition = Offset(
              node.position.dx + details.delta.dx / scale,
              node.position.dy + details.delta.dy / scale,
            );
            widget.onNodeMoved(node.id, newPosition);
          }
        },
        onPanEnd: (_) {
          setState(() {
            _draggingNodeId = null;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 150,
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
                    _buildNodeAction(
                      icon: Icons.add,
                      onTap: () => widget.onAddChildNode(node.id),
                    ),
                    const SizedBox(width: 8),
                    _buildNodeAction(
                      icon: Icons.edit,
                      onTap: () => widget.onNodeDoubleTap(node.id),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNodeAction({
    required IconData icon,
    required VoidCallback onTap,
  }) {
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

    const spacing = 50.0;

    for (var x = 0.0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (var y = 0.0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ConnectionPainter extends CustomPainter {
  final Map<String, MindMapNode> nodes;
  final Offset center;

  _ConnectionPainter({
    required this.nodes,
    required this.center,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final node in nodes.values) {
      if (node.parentId != null) {
        final parent = nodes[node.parentId];
        if (parent != null) {
          _drawConnection(canvas, parent, node);
        }
      }
    }
  }

  void _drawConnection(Canvas canvas, MindMapNode parent, MindMapNode child) {
    final startPoint = Offset(
      center.dx + parent.position.dx,
      center.dy + parent.position.dy,
    );
    final endPoint = Offset(
      center.dx + child.position.dx,
      center.dy + child.position.dy,
    );

    final paint = Paint()
      ..color = parent.color.withValues(alpha: 0.5)
      ..strokeWidth = 3
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
    return nodes != oldDelegate.nodes;
  }
}
