import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../domain/models/mind_map.dart';

/// Export format types
enum ExportFormat {
  png,
  pdf,
  markdown,
  opml,
}

/// Export service for generating exports
class ExportService {
  /// Export mind map to PNG image
  Future<Uint8List> exportToPng(MindMap mindMap, {int width = 1920, int height = 1080}) async {
    // Create a picture recorder
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw background
    final paint = Paint()..color = Colors.white;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      paint,
    );

    // Calculate center offset
    final centerX = width / 2;
    final centerY = height / 2;

    // Draw connections first
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    for (final node in mindMap.nodes.values) {
      if (node.parentId != null) {
        final parent = mindMap.nodes[node.parentId];
        if (parent != null) {
          linePaint.color = parent.color.withValues(alpha: 0.5);

          final startX = centerX + parent.position.dx;
          final startY = centerY + parent.position.dy;
          final endX = centerX + node.position.dx;
          final endY = centerY + node.position.dy;

          final path = Path()
            ..moveTo(startX, startY)
            ..cubicTo(
              startX + (endX - startX) * 0.5,
              startY,
              startX + (endX - startX) * 0.5,
              endY,
              endX,
              endY,
            );

          canvas.drawPath(path, linePaint);
        }
      }
    }

    // Draw nodes
    for (final node in mindMap.nodes.values) {
      final nodeX = centerX + node.position.dx;
      final nodeY = centerY + node.position.dy;

      // Node background
      final nodePaint = Paint()..color = node.color;
      final nodeRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(nodeX, nodeY), width: 150, height: 60),
        const Radius.circular(12),
      );
      canvas.drawRRect(nodeRect, nodePaint);

      // Node text
      final textPainter = TextPainter(
        text: TextSpan(
          text: node.text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.layout(maxWidth: 130);
      textPainter.paint(
        canvas,
        Offset(nodeX - textPainter.width / 2, nodeY - textPainter.height / 2),
      );
    }

    // Convert to image
    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  /// Export mind map to PDF document
  Future<Uint8List> exportToPdf(MindMap mindMap) async {
    final pdf = pw.Document();

    // Add title page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                mindMap.title,
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Created: ${mindMap.createdAt.toString().split('.')[0]}',
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
              ),
              pw.Text(
                'Last modified: ${mindMap.updatedAt.toString().split('.')[0]}',
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 24),
              pw.Divider(),
              pw.SizedBox(height: 24),
              pw.Text(
                'Mind Map Structure',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 16),
              ..._buildPdfNodeTree(mindMap, mindMap.rootNodeId, 0),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  List<pw.Widget> _buildPdfNodeTree(MindMap mindMap, String? nodeId, int level) {
    if (nodeId == null) return [];

    final node = mindMap.nodes[nodeId];
    if (node == null) return [];

    final widgets = <pw.Widget>[];

    widgets.add(
      pw.Padding(
        padding: pw.EdgeInsets.only(left: level * 20.0),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: 8,
              height: 8,
              margin: const pw.EdgeInsets.only(top: 4, right: 8),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(node.color.toARGB32()),
                shape: pw.BoxShape.circle,
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                node.text,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: level == 0 ? pw.FontWeight.bold : pw.FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 8));

    for (final childId in node.childIds) {
      widgets.addAll(_buildPdfNodeTree(mindMap, childId, level + 1));
    }

    return widgets;
  }

  /// Export mind map to Markdown format
  String exportToMarkdown(MindMap mindMap) {
    final buffer = StringBuffer();

    buffer.writeln('# ${mindMap.title}');
    buffer.writeln();
    buffer.writeln('*Created: ${mindMap.createdAt.toString().split('.')[0]}*');
    buffer.writeln('*Last modified: ${mindMap.updatedAt.toString().split('.')[0]}*');
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();

    if (mindMap.rootNodeId != null) {
      _writeMarkdownNode(buffer, mindMap, mindMap.rootNodeId!, 0);
    }

    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln('*Exported from Idea Weaver AI*');

    return buffer.toString();
  }

  void _writeMarkdownNode(StringBuffer buffer, MindMap mindMap, String nodeId, int level) {
    final node = mindMap.nodes[nodeId];
    if (node == null) return;

    if (level == 0) {
      buffer.writeln('## ${node.text}');
    } else {
      final indent = '  ' * (level - 1);
      buffer.writeln('$indent- ${node.text}');
    }

    for (final childId in node.childIds) {
      _writeMarkdownNode(buffer, mindMap, childId, level + 1);
    }
  }

  /// Export mind map to OPML format
  String exportToOpml(MindMap mindMap) {
    final buffer = StringBuffer();

    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<opml version="2.0">');
    buffer.writeln('  <head>');
    buffer.writeln('    <title>${_escapeXml(mindMap.title)}</title>');
    buffer.writeln('    <dateCreated>${mindMap.createdAt.toIso8601String()}</dateCreated>');
    buffer.writeln('    <dateModified>${mindMap.updatedAt.toIso8601String()}</dateModified>');
    buffer.writeln('  </head>');
    buffer.writeln('  <body>');

    if (mindMap.rootNodeId != null) {
      _writeOpmlNode(buffer, mindMap, mindMap.rootNodeId!, 2);
    }

    buffer.writeln('  </body>');
    buffer.writeln('</opml>');

    return buffer.toString();
  }

  void _writeOpmlNode(StringBuffer buffer, MindMap mindMap, String nodeId, int indent) {
    final node = mindMap.nodes[nodeId];
    if (node == null) return;

    final spaces = '  ' * indent;

    if (node.childIds.isEmpty) {
      buffer.writeln('$spaces<outline text="${_escapeXml(node.text)}" />');
    } else {
      buffer.writeln('$spaces<outline text="${_escapeXml(node.text)}">');
      for (final childId in node.childIds) {
        _writeOpmlNode(buffer, mindMap, childId, indent + 1);
      }
      buffer.writeln('$spaces</outline>');
    }
  }

  String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  /// Save and share exported file
  Future<void> shareExport(
    String filename,
    Uint8List data,
    String mimeType,
  ) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$filename');
    await file.writeAsBytes(data);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: mimeType)],
        subject: 'Mind Map Export',
      ),
    );
  }

  /// Save and share text export
  Future<void> shareTextExport(String filename, String content) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$filename');
    await file.writeAsString(content);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'text/plain')],
        subject: 'Mind Map Export',
      ),
    );
  }
}

/// Provider for export service
final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService();
});
