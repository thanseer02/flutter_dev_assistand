import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class FolderSizesChart extends StatelessWidget {
  final Map<String, int> data; // Sizes in bytes

  const FolderSizesChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Center(child: Text('No data'));

    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Top 5
    final topEntries = sortedEntries.take(5).toList();

    return AspectRatio(
      aspectRatio: 1.5,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: topEntries.isEmpty ? 100 : topEntries.first.value.toDouble() * 1.2,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${topEntries[groupIndex].key}\n${(rod.toY / 1024 / 1024).toStringAsFixed(2)} MB',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  if (value.toInt() >= topEntries.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      topEntries[value.toInt()].key,
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(
            topEntries.length,
            (i) => BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: topEntries[i].value.toDouble(),
                  color: Colors.blueAccent,
                  width: 16,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
