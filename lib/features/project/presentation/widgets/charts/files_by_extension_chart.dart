import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class FilesByExtensionChart extends StatelessWidget {
  final Map<String, int> data;

  const FilesByExtensionChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Center(child: Text('No data'));

    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Take top 5, group rest into "Other"
    final topEntries = sortedEntries.take(5).toList();
    final otherCount = sortedEntries.skip(5).fold(0, (sum, e) => sum + e.value);
    
    if (otherCount > 0) {
      topEntries.add(MapEntry('other', otherCount));
    }

    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.grey,
    ];

    return AspectRatio(
      aspectRatio: 1.5,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: List.generate(topEntries.length, (i) {
            final isTouched = false;
            final fontSize = isTouched ? 16.0 : 12.0;
            final radius = isTouched ? 60.0 : 50.0;
            return PieChartSectionData(
              color: colors[i % colors.length],
              value: topEntries[i].value.toDouble(),
              title: '${topEntries[i].key}\n${topEntries[i].value}',
              radius: radius,
              titleStyle: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }),
        ),
      ),
    );
  }
}
