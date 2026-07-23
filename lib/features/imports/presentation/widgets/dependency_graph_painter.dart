import 'package:flutter/material.dart';
import '../../domain/entities/import_analysis.dart';

class DependencyGraphPainter extends CustomPainter {
  final ImportAnalysis analysis;
  final String? selectedNodePath;

  DependencyGraphPainter({
    required this.analysis,
    this.selectedNodePath,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final edgePaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final nodePaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;
      
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Draw Edges
    for (final node in analysis.graph.values) {
      for (final depPath in node.dependencies) {
        final target = analysis.graph[depPath];
        if (target != null) {
          canvas.drawLine(
            Offset(node.x, node.y),
            Offset(target.x, target.y),
            edgePaint,
          );
        }
      }
    }

    // Draw Nodes
    for (final node in analysis.graph.values) {
      canvas.drawCircle(Offset(node.x, node.y), 8.0, nodePaint);
      
      final label = node.path.split('/').last;
      textPainter.text = TextSpan(
        text: label,
        style: const TextStyle(color: Colors.white, fontSize: 10, backgroundColor: Colors.black54),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(node.x + 12, node.y - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant DependencyGraphPainter oldDelegate) {
    return oldDelegate.analysis != analysis || oldDelegate.selectedNodePath != selectedNodePath;
  }
}
