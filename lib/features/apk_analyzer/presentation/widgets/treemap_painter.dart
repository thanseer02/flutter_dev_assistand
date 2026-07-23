import 'package:flutter/material.dart';
import '../../domain/entities/apk_file_node.dart';

class TreemapPainter extends CustomPainter {
  final ApkFileNode rootNode;

  TreemapPainter({required this.rootNode});

  @override
  void paint(Canvas canvas, Size size) {
    if (rootNode.sizeBytes == 0) return;
    
    _drawNode(canvas, rootNode, Rect.fromLTWH(0, 0, size.width, size.height), 0);
  }

  void _drawNode(Canvas canvas, ApkFileNode node, Rect rect, int depth) {
    if (rect.width < 2 || rect.height < 2) return; // Too small to draw
    
    // Draw background
    final paint = Paint()
      ..color = _getColorForCategory(node.category, depth)
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(rect, paint);
    
    // Draw border
    final borderPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRect(rect, borderPaint);

    // Draw Label if it's a leaf or big enough and it's a directory
    if (!node.isDirectory && rect.width > 50 && rect.height > 20) {
      final textPainter = TextPainter(textDirection: TextDirection.ltr);
      textPainter.text = TextSpan(
        text: '${node.name}\n${(node.sizeBytes / 1024).toStringAsFixed(1)} KB',
        style: const TextStyle(color: Colors.white, fontSize: 10, backgroundColor: Colors.black54),
      );
      textPainter.layout(maxWidth: rect.width - 4);
      
      textPainter.paint(
        canvas,
        Offset(rect.left + 2, rect.top + 2),
      );
    }

    if (!node.isDirectory || node.children.isEmpty) return;

    // Slice and Dice Algorithm
    final isHorizontal = rect.width > rect.height;
    double currentPos = isHorizontal ? rect.left : rect.top;
    
    final totalSize = node.sizeBytes;
    
    for (final child in node.children) {
      if (child.sizeBytes == 0) continue;
      
      final fraction = child.sizeBytes / totalSize;
      
      if (isHorizontal) {
        final width = rect.width * fraction;
        final childRect = Rect.fromLTWH(currentPos, rect.top, width, rect.height);
        _drawNode(canvas, child, childRect, depth + 1);
        currentPos += width;
      } else {
        final height = rect.height * fraction;
        final childRect = Rect.fromLTWH(rect.left, currentPos, rect.width, height);
        _drawNode(canvas, child, childRect, depth + 1);
        currentPos += height;
      }
    }
  }

  Color _getColorForCategory(ApkFileCategory category, int depth) {
    Color baseColor;
    switch (category) {
      case ApkFileCategory.dartCode: baseColor = Colors.blue; break;
      case ApkFileCategory.nativeLibrary: baseColor = Colors.red; break;
      case ApkFileCategory.font: baseColor = Colors.purple; break;
      case ApkFileCategory.image: baseColor = Colors.green; break;
      case ApkFileCategory.resource: baseColor = Colors.orange; break;
      case ApkFileCategory.plugin: baseColor = Colors.teal; break;
      case ApkFileCategory.other: baseColor = Colors.grey; break;
    }
    
    // Lighten based on depth for nested directories that aren't leaves
    // Actually, leaves have categories, directories are usually 'other'
    // Let's just use the base color but slightly alter opacity based on depth.
    return baseColor.withOpacity(1.0 - (depth * 0.1).clamp(0.0, 0.8));
  }

  @override
  bool shouldRepaint(covariant TreemapPainter oldDelegate) {
    return oldDelegate.rootNode != rootNode;
  }
}
