import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../project_analysis/domain/entities/file_info.dart';

class ProjectTimelineChart extends StatelessWidget {
  final Map<String, List<FileInfo>> filesByExtension;

  const ProjectTimelineChart({super.key, required this.filesByExtension});

  @override
  Widget build(BuildContext context) {
    if (filesByExtension.isEmpty) return const Center(child: Text('No data'));

    // Aggregate file modification counts by day over the last 30 days
    final now = DateTime.now();
    final Map<int, int> filesPerDay = {};
    for (int i = 0; i < 30; i++) {
      filesPerDay[i] = 0;
    }

    for (final files in filesByExtension.values) {
      for (final file in files) {
        final diff = now.difference(file.lastModified).inDays;
        if (diff >= 0 && diff < 30) {
          filesPerDay[diff] = (filesPerDay[diff] ?? 0) + 1;
        }
      }
    }

    // Convert to spots (x = days ago, y = count)
    // We want x=0 to be 30 days ago, x=30 to be today for left-to-right reading
    final spots = <FlSpot>[];
    for (int i = 29; i >= 0; i--) {
      spots.add(FlSpot((29 - i).toDouble(), filesPerDay[i]!.toDouble()));
    }

    return AspectRatio(
      aspectRatio: 1.5,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 10,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Theme.of(context).dividerColor,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 5,
                getTitlesWidget: (value, meta) {
                  final daysAgo = 29 - value.toInt();
                  if (daysAgo == 0) return const Text('Today', style: TextStyle(fontSize: 10));
                  return Text('${daysAgo}d ago', style: const TextStyle(fontSize: 10));
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.greenAccent,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.greenAccent.withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
