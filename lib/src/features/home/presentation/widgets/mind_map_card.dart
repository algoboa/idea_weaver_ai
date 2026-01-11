import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../domain/models/mind_map.dart';

class MindMapCard extends StatelessWidget {
  final MindMap mindMap;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final VoidCallback onRename;

  const MindMapCard({
    super.key,
    required this.mindMap,
    required this.onTap,
    required this.onDelete,
    required this.onDuplicate,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preview area
            Expanded(
              child: Container(
                color: colorScheme.surfaceContainerHighest,
                child: Stack(
                  children: [
                    // Simple preview of nodes
                    Center(
                      child: CustomPaint(
                        size: const Size(double.infinity, double.infinity),
                        painter: _MindMapPreviewPainter(
                          nodeCount: mindMap.nodes.length,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    // Menu button
                    Positioned(
                      top: 4,
                      right: 4,
                      child: PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          color: colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        onSelected: (value) {
                          switch (value) {
                            case 'rename':
                              onRename();
                              break;
                            case 'duplicate':
                              onDuplicate();
                              break;
                            case 'delete':
                              onDelete();
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'rename',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 20),
                                SizedBox(width: 8),
                                Text('Rename'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'duplicate',
                            child: Row(
                              children: [
                                Icon(Icons.copy_outlined, size: 20),
                                SizedBox(width: 8),
                                Text('Duplicate'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline,
                                    size: 20, color: colorScheme.error),
                                const SizedBox(width: 8),
                                Text('Delete',
                                    style: TextStyle(color: colorScheme.error)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Title and info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mindMap.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(mindMap.updatedAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.circle,
                        size: 8,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${mindMap.nodes.length} nodes',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return DateFormat.MMMd().format(date);
    }
  }
}

class _MindMapPreviewPainter extends CustomPainter {
  final int nodeCount;
  final Color color;

  _MindMapPreviewPainter({
    required this.nodeCount,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.15;

    // Draw center node
    canvas.drawCircle(center, radius, paint);

    // Draw child nodes
    final childCount = (nodeCount - 1).clamp(0, 4);
    for (int i = 0; i < childCount; i++) {
      final angle = (i * 2 * 3.14159 / childCount) - 3.14159 / 2;
      final childCenter = Offset(
        center.dx + size.width * 0.25 * cos(angle),
        center.dy + size.height * 0.25 * sin(angle),
      );

      // Draw line
      canvas.drawLine(center, childCenter, linePaint);

      // Draw child node
      canvas.drawCircle(childCenter, radius * 0.6, paint);
    }
  }

  double cos(double radians) => _cos(radians);
  double sin(double radians) => _sin(radians);

  double _cos(double x) {
    return 1 -
        (x * x) / 2 +
        (x * x * x * x) / 24 -
        (x * x * x * x * x * x) / 720;
  }

  double _sin(double x) {
    return x -
        (x * x * x) / 6 +
        (x * x * x * x * x) / 120 -
        (x * x * x * x * x * x * x) / 5040;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
