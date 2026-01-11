import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/ai_service.dart';

class AiSuggestionPanel extends ConsumerStatefulWidget {
  final String nodeId;
  final String nodeText;
  final VoidCallback onClose;
  final Function(String) onSuggestionSelected;

  const AiSuggestionPanel({
    super.key,
    required this.nodeId,
    required this.nodeText,
    required this.onClose,
    required this.onSuggestionSelected,
  });

  @override
  ConsumerState<AiSuggestionPanel> createState() => _AiSuggestionPanelState();
}

class _AiSuggestionPanelState extends ConsumerState<AiSuggestionPanel> {
  List<AiSuggestion>? _suggestions;
  bool _isLoading = true;
  String? _error;
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  @override
  void didUpdateWidget(AiSuggestionPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nodeId != widget.nodeId) {
      _loadSuggestions();
    }
  }

  Future<void> _loadSuggestions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final aiService = ref.read(aiServiceProvider);
      final suggestions = await aiService.fetchSuggestions(widget.nodeText);
      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      elevation: 8,
      child: Container(
        color: colorScheme.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Suggestions',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Based on: "${widget.nodeText}"',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onPrimaryContainer
                                .withValues(alpha: 0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
            ),

            // Category filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  _buildCategoryChip('all', 'All'),
                  _buildCategoryChip('related', 'Related'),
                  _buildCategoryChip('opposite', 'Opposite'),
                  _buildCategoryChip('question', 'Questions'),
                  _buildCategoryChip('expansion', 'Expansion'),
                ],
              ),
            ),

            const Divider(height: 1),

            // Suggestions list
            Expanded(
              child: _buildContent(),
            ),

            // Refresh button
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _loadSuggestions,
                icon: const Icon(Icons.refresh),
                label: const Text('Generate More'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category, String label) {
    final isSelected = _selectedCategory == category;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() {
            _selectedCategory = category;
          });
        },
        selectedColor: colorScheme.primaryContainer,
        checkmarkColor: colorScheme.onPrimaryContainer,
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Generating ideas...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadSuggestions,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_suggestions == null || _suggestions!.isEmpty) {
      return const Center(
        child: Text('No suggestions available'),
      );
    }

    final filteredSuggestions = _selectedCategory == 'all'
        ? _suggestions!
        : _suggestions!
            .where((s) => s.category == _selectedCategory)
            .toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: filteredSuggestions.length,
      itemBuilder: (context, index) {
        final suggestion = filteredSuggestions[index];
        return _buildSuggestionTile(suggestion);
      },
    );
  }

  Widget _buildSuggestionTile(AiSuggestion suggestion) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => widget.onSuggestionSelected(suggestion.text),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getCategoryColor(suggestion.category)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(suggestion.category),
                  size: 20,
                  color: _getCategoryColor(suggestion.category),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      suggestion.text,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getCategoryLabel(suggestion.category),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.add_circle_outline,
                color: colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'related':
        return Icons.link;
      case 'opposite':
        return Icons.compare_arrows;
      case 'question':
        return Icons.help_outline;
      case 'expansion':
        return Icons.expand;
      default:
        return Icons.lightbulb_outline;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'related':
        return Colors.blue;
      case 'opposite':
        return Colors.orange;
      case 'question':
        return Colors.purple;
      case 'expansion':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'related':
        return 'Related concept';
      case 'opposite':
        return 'Opposite view';
      case 'question':
        return 'Question to explore';
      case 'expansion':
        return 'Expand further';
      default:
        return 'Suggestion';
    }
  }
}
