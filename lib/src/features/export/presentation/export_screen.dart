import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../services/export_service.dart';
import '../../home/providers/mind_map_provider.dart';

class ExportScreen extends ConsumerStatefulWidget {
  final String mindMapId;

  const ExportScreen({super.key, required this.mindMapId});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  ExportFormat _selectedFormat = ExportFormat.png;
  bool _isExporting = false;
  bool _transparentBackground = false;
  int _quality = 100;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mindMapsState = ref.watch(mindMapsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: _buildBody(mindMapsState, theme, colorScheme),
    );
  }

  Widget _buildBody(MindMapsState mindMapsState, ThemeData theme, ColorScheme colorScheme) {
    if (mindMapsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (mindMapsState.error != null) {
      return Center(child: Text('Error: ${mindMapsState.error}'));
    }

    final mindMaps = mindMapsState.mindMaps;
    final mindMap = mindMaps.firstWhere(
      (m) => m.id == widget.mindMapId,
      orElse: () => throw Exception('Mind map not found'),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Preview card
          Card(
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.hub_outlined,
                        size: 48,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        mindMap.title,
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        '${mindMap.nodes.length} nodes',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Format selection
          Text(
            'Export Format',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          _buildFormatOption(
            context,
            format: ExportFormat.png,
            icon: Icons.image,
            title: 'PNG Image',
            description: 'High-quality image for sharing',
            isPro: false,
          ),
          _buildFormatOption(
            context,
            format: ExportFormat.pdf,
            icon: Icons.picture_as_pdf,
            title: 'PDF Document',
            description: 'Printable document format',
            isPro: false,
          ),
          _buildFormatOption(
            context,
            format: ExportFormat.markdown,
            icon: Icons.text_snippet,
            title: 'Markdown',
            description: 'Text format for docs and notes',
            isPro: true,
          ),
          _buildFormatOption(
            context,
            format: ExportFormat.opml,
            icon: Icons.code,
            title: 'OPML',
            description: 'Outline format for other apps',
            isPro: true,
          ),

          const SizedBox(height: 24),

          // Options for PNG
          if (_selectedFormat == ExportFormat.png) ...[
            Text(
              'Options',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Transparent background'),
                    subtitle: const Text('Remove white background'),
                    value: _transparentBackground,
                    onChanged: (value) {
                      setState(() {
                        _transparentBackground = value;
                      });
                    },
                  ),
                  ListTile(
                    title: const Text('Quality'),
                    subtitle: Text('$_quality%'),
                    trailing: SizedBox(
                      width: 200,
                      child: Slider(
                        value: _quality.toDouble(),
                        min: 50,
                        max: 100,
                        divisions: 10,
                        label: '$_quality%',
                        onChanged: (value) {
                          setState(() {
                            _quality = value.round();
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Export button
          FilledButton.icon(
            onPressed: _isExporting ? null : () => _export(mindMap),
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.file_download),
            label: Text(_isExporting ? 'Exporting...' : 'Export'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
            ),
          ),

          const SizedBox(height: 16),

          // Share button
          OutlinedButton.icon(
            onPressed: _isExporting ? null : () => _exportAndShare(mindMap),
            icon: const Icon(Icons.share),
            label: const Text('Export & Share'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatOption(
    BuildContext context, {
    required ExportFormat format,
    required IconData icon,
    required String title,
    required String description,
    required bool isPro,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _selectedFormat == format;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedFormat = format;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? colorScheme.primary : Colors.transparent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (isPro) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'PRO',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _export(dynamic mindMap) async {
    setState(() {
      _isExporting = true;
    });

    try {
      final exportService = ref.read(exportServiceProvider);

      switch (_selectedFormat) {
        case ExportFormat.png:
          await exportService.exportToPng(mindMap);
          break;
        case ExportFormat.pdf:
          await exportService.exportToPdf(mindMap);
          break;
        case ExportFormat.markdown:
          exportService.exportToMarkdown(mindMap);
          break;
        case ExportFormat.opml:
          exportService.exportToOpml(mindMap);
          break;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export completed!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _exportAndShare(dynamic mindMap) async {
    setState(() {
      _isExporting = true;
    });

    try {
      final exportService = ref.read(exportServiceProvider);
      final filename = '${mindMap.title.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}';

      switch (_selectedFormat) {
        case ExportFormat.png:
          final data = await exportService.exportToPng(mindMap);
          await exportService.shareExport('$filename.png', data, 'image/png');
          break;
        case ExportFormat.pdf:
          final data = await exportService.exportToPdf(mindMap);
          await exportService.shareExport(
              '$filename.pdf', data, 'application/pdf');
          break;
        case ExportFormat.markdown:
          final content = exportService.exportToMarkdown(mindMap);
          await exportService.shareTextExport('$filename.md', content);
          break;
        case ExportFormat.opml:
          final content = exportService.exportToOpml(mindMap);
          await exportService.shareTextExport('$filename.opml', content);
          break;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export shared!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }
}
