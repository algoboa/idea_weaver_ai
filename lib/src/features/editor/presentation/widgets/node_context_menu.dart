import 'package:flutter/material.dart';

class NodeContextMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onAddChild;
  final VoidCallback onAiSuggest;
  final VoidCallback onChangeColor;
  final VoidCallback? onDelete;
  final Offset position;

  const NodeContextMenu({
    super.key,
    required this.onEdit,
    required this.onAddChild,
    required this.onAiSuggest,
    required this.onChangeColor,
    this.onDelete,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 180,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMenuItem(
                context,
                icon: Icons.edit,
                label: 'Edit',
                onTap: onEdit,
              ),
              _buildMenuItem(
                context,
                icon: Icons.add,
                label: 'Add Child',
                onTap: onAddChild,
              ),
              _buildMenuItem(
                context,
                icon: Icons.auto_awesome,
                label: 'AI Suggest',
                onTap: onAiSuggest,
                isPrimary: true,
              ),
              _buildMenuItem(
                context,
                icon: Icons.color_lens_outlined,
                label: 'Change Color',
                onTap: onChangeColor,
              ),
              if (onDelete != null)
                _buildMenuItem(
                  context,
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  onTap: onDelete!,
                  isDestructive: true,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
    bool isDestructive = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isDestructive
        ? colorScheme.error
        : isPrimary
            ? colorScheme.primary
            : colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
