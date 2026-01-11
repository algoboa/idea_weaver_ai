import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/models/mind_map.dart';
import '../../../routing/app_router.dart';
import '../providers/editor_provider.dart';
import 'widgets/mind_map_canvas.dart';
import 'widgets/ai_suggestion_panel.dart';

class EditorScreen extends ConsumerStatefulWidget {
  final String? mindMapId;

  const EditorScreen({super.key, this.mindMapId});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  final TransformationController _transformController =
      TransformationController();
  bool _showAiPanel = false;
  String? _selectedNodeId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.mindMapId != null) {
        ref.read(editorProvider.notifier).loadMindMap(widget.mindMapId!);
      } else {
        ref.read(editorProvider.notifier).createNewMindMap();
      }
    });
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final editorState = ref.watch(editorProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
        title: _buildAppBarTitle(editorState, colorScheme),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: () => ref.read(editorProvider.notifier).undo(),
            tooltip: 'Undo',
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: () => ref.read(editorProvider.notifier).redo(),
            tooltip: 'Redo',
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _showShareDialog(),
            tooltip: 'Share',
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () {
              if (editorState.mindMap != null) {
                context.push(AppRoutes.exportPath(editorState.mindMap!.id));
              }
            },
            tooltip: 'Export',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'summary':
                  _showAiSummary();
                  break;
                case 'autoLayout':
                  ref.read(editorProvider.notifier).autoLayout();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'summary',
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 20),
                    SizedBox(width: 8),
                    Text('AI Summary'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'autoLayout',
                child: Row(
                  children: [
                    Icon(Icons.auto_fix_high, size: 20),
                    SizedBox(width: 8),
                    Text('Auto Layout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(editorState, colorScheme),
    );
  }

  Widget _buildAppBarTitle(EditorState editorState, ColorScheme colorScheme) {
    if (editorState.isLoading) {
      return const Text('Loading...');
    }
    if (editorState.error != null) {
      return const Text('Error');
    }
    if (editorState.mindMap == null) {
      return const Text('New Mind Map');
    }
    return GestureDetector(
      onTap: () => _showRenameDialog(editorState.mindMap!),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(editorState.mindMap!.title),
          const SizedBox(width: 4),
          Icon(Icons.edit, size: 16, color: colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }

  Widget _buildBody(EditorState editorState, ColorScheme colorScheme) {
    if (editorState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (editorState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colorScheme.error),
            const SizedBox(height: 16),
            Text('Error: ${editorState.error}'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Go Back'),
            ),
          ],
        ),
      );
    }

    if (editorState.mindMap == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        // Main canvas
        MindMapCanvas(
          mindMap: editorState.mindMap!,
          selectedNodeId: _selectedNodeId,
          transformController: _transformController,
          onNodeSelected: (nodeId) {
            setState(() {
              _selectedNodeId = nodeId.isEmpty ? null : nodeId;
              _showAiPanel = false;
            });
          },
          onNodeMoved: (nodeId, newPosition) {
            ref.read(editorProvider.notifier).moveNode(nodeId, newPosition);
          },
          onNodeDoubleTap: (nodeId) {
            _showEditNodeDialog(editorState.mindMap!.nodes[nodeId]!);
          },
          onAddChildNode: (parentId) {
            _showAddNodeDialog(parentId);
          },
          onShowContextMenu: (nodeId, position) {
            _showContextMenu(nodeId, position, editorState.mindMap!);
          },
        ),

        // AI Suggestion Panel
        if (_showAiPanel && _selectedNodeId != null)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 320,
            child: AiSuggestionPanel(
              nodeId: _selectedNodeId!,
              nodeText: editorState.mindMap!.nodes[_selectedNodeId]?.text ?? '',
              onClose: () => setState(() => _showAiPanel = false),
              onSuggestionSelected: (suggestion) {
                ref.read(editorProvider.notifier).addNode(
                      parentId: _selectedNodeId,
                      text: suggestion,
                    );
              },
            ),
          ),

        // Bottom toolbar
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => _showAddNodeDialog(null),
                    tooltip: 'Add Node',
                  ),
                  IconButton(
                    icon: const Icon(Icons.center_focus_strong),
                    onPressed: _centerView,
                    tooltip: 'Center View',
                  ),
                  IconButton(
                    icon: const Icon(Icons.zoom_in),
                    onPressed: _zoomIn,
                    tooltip: 'Zoom In',
                  ),
                  IconButton(
                    icon: const Icon(Icons.zoom_out),
                    onPressed: _zoomOut,
                    tooltip: 'Zoom Out',
                  ),
                  if (_selectedNodeId != null)
                    IconButton(
                      icon: Icon(
                        Icons.auto_awesome,
                        color: colorScheme.primary,
                      ),
                      onPressed: () => setState(() => _showAiPanel = true),
                      tooltip: 'AI Suggestions',
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _centerView() {
    _transformController.value = Matrix4.identity();
  }

  void _zoomIn() {
    final currentScale = _transformController.value.getMaxScaleOnAxis();
    final newScale = (currentScale * 1.2).clamp(0.5, 3.0);
    _transformController.value = Matrix4.diagonal3Values(newScale, newScale, 1.0);
  }

  void _zoomOut() {
    final currentScale = _transformController.value.getMaxScaleOnAxis();
    final newScale = (currentScale / 1.2).clamp(0.5, 3.0);
    _transformController.value = Matrix4.diagonal3Values(newScale, newScale, 1.0);
  }

  void _showAddNodeDialog(String? parentId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(parentId == null ? 'Add Root Node' : 'Add Child Node'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Node Text',
            hintText: 'Enter node content',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              Navigator.pop(context);
              ref.read(editorProvider.notifier).addNode(
                    parentId: parentId,
                    text: value,
                  );
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context);
                ref.read(editorProvider.notifier).addNode(
                      parentId: parentId,
                      text: controller.text,
                    );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditNodeDialog(MindMapNode node) {
    final controller = TextEditingController(text: node.text);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Node'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Node Text',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              Navigator.pop(context);
              ref.read(editorProvider.notifier).updateNodeText(node.id, value);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context);
                ref
                    .read(editorProvider.notifier)
                    .updateNodeText(node.id, controller.text);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showContextMenu(String nodeId, Offset position, MindMap mindMap) {
    final node = mindMap.nodes[nodeId]!;
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: [
        PopupMenuItem(
          child: const Row(
            children: [
              Icon(Icons.edit, size: 20),
              SizedBox(width: 8),
              Text('Edit'),
            ],
          ),
          onTap: () => Future.delayed(
            Duration.zero,
            () => _showEditNodeDialog(node),
          ),
        ),
        PopupMenuItem(
          child: const Row(
            children: [
              Icon(Icons.add, size: 20),
              SizedBox(width: 8),
              Text('Add Child'),
            ],
          ),
          onTap: () => Future.delayed(
            Duration.zero,
            () => _showAddNodeDialog(nodeId),
          ),
        ),
        PopupMenuItem(
          child: Row(
            children: [
              Icon(Icons.auto_awesome,
                  size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text('AI Suggest',
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.primary)),
            ],
          ),
          onTap: () {
            setState(() {
              _selectedNodeId = nodeId;
              _showAiPanel = true;
            });
          },
        ),
        PopupMenuItem(
          child: const Row(
            children: [
              Icon(Icons.color_lens_outlined, size: 20),
              SizedBox(width: 8),
              Text('Change Color'),
            ],
          ),
          onTap: () => Future.delayed(
            Duration.zero,
            () => _showColorPicker(nodeId),
          ),
        ),
        if (node.parentId != null)
          PopupMenuItem(
            child: Row(
              children: [
                Icon(Icons.delete_outline,
                    size: 20, color: Theme.of(context).colorScheme.error),
                const SizedBox(width: 8),
                Text('Delete',
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
            ),
            onTap: () {
              ref.read(editorProvider.notifier).deleteNode(nodeId);
            },
          ),
      ],
    );
  }

  void _showColorPicker(String nodeId) {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Color'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colors.map((color) {
            return InkWell(
              onTap: () {
                Navigator.pop(context);
                ref.read(editorProvider.notifier).updateNodeColor(nodeId, color);
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showRenameDialog(MindMap mindMap) {
    final controller = TextEditingController(text: mindMap.title);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Mind Map'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Title',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context);
                ref
                    .read(editorProvider.notifier)
                    .updateTitle(controller.text);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showShareDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Mind Map'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Email address',
                hintText: 'Enter collaborator email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Permission: '),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: 'edit',
                  items: const [
                    DropdownMenuItem(value: 'view', child: Text('View only')),
                    DropdownMenuItem(value: 'edit', child: Text('Can edit')),
                  ],
                  onChanged: (_) {},
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invitation sent!')),
              );
            },
            child: const Text('Invite'),
          ),
        ],
      ),
    );
  }

  void _showAiSummary() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome),
            SizedBox(width: 8),
            Text('AI Summary'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Based on your mind map, here\'s a summary:'),
            SizedBox(height: 16),
            Text(
              'This mind map explores project ideas with a focus on mobile app and web platform development. Key themes include modern technology solutions and cross-platform approaches.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // Copy to clipboard
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }
}
