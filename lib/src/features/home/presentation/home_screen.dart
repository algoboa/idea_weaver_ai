import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../routing/app_router.dart';
import '../../../domain/models/mind_map.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/mind_map_provider.dart';
import 'widgets/mind_map_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  bool _isGridView = true;
  String _sortBy = 'updatedAt';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mindMapsState = ref.watch(mindMapsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.hub_outlined, color: colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Idea Weaver AI'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
            tooltip: _isGridView ? 'List view' : 'Grid view',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort by',
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'updatedAt',
                child: Row(
                  children: [
                    if (_sortBy == 'updatedAt')
                      Icon(Icons.check, color: colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    const Text('Last modified'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'createdAt',
                child: Row(
                  children: [
                    if (_sortBy == 'createdAt')
                      Icon(Icons.check, color: colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    const Text('Date created'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'title',
                child: Row(
                  children: [
                    if (_sortBy == 'title')
                      Icon(Icons.check, color: colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    const Text('Title'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search mind maps...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
              ),
            ),
          ),

          // Mind maps list/grid
          Expanded(
            child: _buildMindMapsList(mindMapsState, theme, colorScheme),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(),
        icon: const Icon(Icons.add),
        label: const Text('New Map'),
      ),
    );
  }

  Widget _buildMindMapsList(
      MindMapsState mindMapsState, ThemeData theme, ColorScheme colorScheme) {
    if (mindMapsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (mindMapsState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colorScheme.error),
            const SizedBox(height: 16),
            Text('Error loading mind maps', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.read(mindMapsProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final mindMaps = mindMapsState.mindMaps;

    // Filter by search
    var filteredMaps = mindMaps.where((m) {
      final query = _searchController.text.toLowerCase();
      return m.title.toLowerCase().contains(query);
    }).toList();

    // Sort
    filteredMaps.sort((a, b) {
      switch (_sortBy) {
        case 'updatedAt':
          return b.updatedAt.compareTo(a.updatedAt);
        case 'createdAt':
          return b.createdAt.compareTo(a.createdAt);
        case 'title':
          return a.title.compareTo(b.title);
        default:
          return 0;
      }
    });

    if (filteredMaps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 64,
              color: colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty
                  ? 'No mind maps found'
                  : 'No mind maps yet',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isNotEmpty
                  ? 'Try a different search term'
                  : 'Tap + to create your first mind map',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(mindMapsProvider.notifier).refresh();
      },
      child: _isGridView
          ? _buildGridView(filteredMaps)
          : _buildListView(filteredMaps),
    );
  }

  Widget _buildGridView(List<MindMap> mindMaps) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: mindMaps.length,
      itemBuilder: (context, index) {
        return MindMapCard(
          mindMap: mindMaps[index],
          onTap: () => context.push(AppRoutes.editorPath(mindMaps[index].id)),
          onDelete: () => _showDeleteDialog(mindMaps[index]),
          onDuplicate: () => ref
              .read(mindMapsProvider.notifier)
              .duplicateMindMap(mindMaps[index].id),
          onRename: () => _showRenameDialog(mindMaps[index]),
        );
      },
    );
  }

  Widget _buildListView(List<MindMap> mindMaps) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: mindMaps.length,
      itemBuilder: (context, index) {
        final mindMap = mindMaps[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.hub_outlined,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            title: Text(mindMap.title),
            subtitle: Text(
              'Updated ${_formatDate(mindMap.updatedAt)}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'rename':
                    _showRenameDialog(mindMap);
                    break;
                  case 'duplicate':
                    ref
                        .read(mindMapsProvider.notifier)
                        .duplicateMindMap(mindMap.id);
                    break;
                  case 'delete':
                    _showDeleteDialog(mindMap);
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
                          size: 20, color: Theme.of(context).colorScheme.error),
                      const SizedBox(width: 8),
                      Text('Delete',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error)),
                    ],
                  ),
                ),
              ],
            ),
            onTap: () => context.push(AppRoutes.editorPath(mindMap.id)),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes} minutes ago';
      }
      return '${diff.inHours} hours ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return DateFormat.yMMMd().format(date);
    }
  }

  void _showCreateDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Mind Map'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Title',
            hintText: 'Enter mind map title',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              Navigator.pop(context);
              _createMindMap(value);
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
                _createMindMap(controller.text);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _createMindMap(String title) async {
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      final mindMap = await ref
          .read(mindMapsProvider.notifier)
          .createMindMap(title, user.uid);
      if (mounted) {
        context.push(AppRoutes.editorPath(mindMap.id));
      }
    }
  }

  void _showDeleteDialog(MindMap mindMap) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Mind Map'),
        content: Text('Are you sure you want to delete "${mindMap.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(mindMapsProvider.notifier).deleteMindMap(mindMap.id);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
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
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              Navigator.pop(context);
              ref
                  .read(mindMapsProvider.notifier)
                  .renameMindMap(mindMap.id, value);
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
                    .read(mindMapsProvider.notifier)
                    .renameMindMap(mindMap.id, controller.text);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }
}
