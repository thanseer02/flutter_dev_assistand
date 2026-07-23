import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/performance_provider.dart';
import '../../domain/entities/performance_issue.dart';
import '../../../../project/presentation/providers/project_provider.dart';

class PerformanceView extends StatelessWidget {
  const PerformanceView({super.key});

  @override
  Widget build(BuildContext context) {
    final perfProvider = context.watch<PerformanceProvider>();
    final projectProvider = context.watch<ProjectProvider>();

    if (projectProvider.currentProject == null) {
      return const Center(child: Text('Please open a project first.'));
    }

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.zap, size: 28, color: Colors.blue),
              const SizedBox(width: 12),
              const Text(
                'Static Performance Analyzer',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(LucideIcons.play),
                label: const Text('Analyze Performance'),
                onPressed: perfProvider.isAnalyzing ? null : () {
                  perfProvider.analyzePerformance(projectProvider.currentProject!.path);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          if (perfProvider.isAnalyzing)
            const Expanded(child: Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Running static analysis and linter...', style: TextStyle(color: Colors.grey)),
              ],
            ))),
          
          if (!perfProvider.isAnalyzing && perfProvider.errorMessage != null)
            Text(perfProvider.errorMessage!, style: const TextStyle(color: Colors.red)),
            
          if (!perfProvider.isAnalyzing && perfProvider.issues.isNotEmpty)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: _buildScorePanel(context, perfProvider),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: perfProvider.issues.length,
                          itemBuilder: (context, index) {
                            return _buildIssueTile(perfProvider.issues[index]);
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScorePanel(BuildContext context, PerformanceProvider provider) {
    final score = provider.performanceScore;
    Color scoreColor = Colors.green;
    if (score < 60) scoreColor = Colors.red;
    else if (score < 80) scoreColor = Colors.orange;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Performance Score', style: TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 16),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 12,
                    color: scoreColor,
                    backgroundColor: scoreColor.withOpacity(0.2),
                  ),
                ),
                Text(
                  score.toString(),
                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: scoreColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text('Issue Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          _buildSummaryRow('Memory Risks', provider.issues.where((i) => i.type == PerformanceIssueType.memoryRisk).length, Colors.red),
          _buildSummaryRow('Expensive Builds', provider.issues.where((i) => i.type == PerformanceIssueType.expensiveBuild).length, Colors.orange),
          _buildSummaryRow('Large Widgets', provider.issues.where((i) => i.type == PerformanceIssueType.largeWidget).length, Colors.orangeAccent),
          _buildSummaryRow('Nested Widgets', provider.issues.where((i) => i.type == PerformanceIssueType.nestedWidget).length, Colors.yellow),
          _buildSummaryRow('Large Lists', provider.issues.where((i) => i.type == PerformanceIssueType.largeList).length, Colors.orange),
          _buildSummaryRow('Large Images', provider.issues.where((i) => i.type == PerformanceIssueType.largeImage).length, Colors.purple),
          _buildSummaryRow('Missing Const', provider.issues.where((i) => i.type == PerformanceIssueType.missingConst).length, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, int count, Color color) {
    if (count == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.grey)),
            ],
          ),
          Text(count.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildIssueTile(PerformanceIssue issue) {
    Color iconColor;
    IconData icon;

    switch (issue.type) {
      case PerformanceIssueType.memoryRisk:
        iconColor = Colors.red;
        icon = LucideIcons.alertTriangle;
        break;
      case PerformanceIssueType.expensiveBuild:
        iconColor = Colors.orange;
        icon = LucideIcons.timer;
        break;
      case PerformanceIssueType.largeList:
        iconColor = Colors.orange;
        icon = LucideIcons.list;
        break;
      case PerformanceIssueType.nestedWidget:
        iconColor = Colors.yellow;
        icon = LucideIcons.layers;
        break;
      case PerformanceIssueType.largeWidget:
        iconColor = Colors.orangeAccent;
        icon = LucideIcons.maximize;
        break;
      case PerformanceIssueType.missingConst:
        iconColor = Colors.blue;
        icon = LucideIcons.code;
        break;
      case PerformanceIssueType.largeImage:
        iconColor = Colors.purple;
        icon = LucideIcons.image;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(icon, color: iconColor),
        title: Text(issue.description),
        subtitle: Text(issue.location, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            color: Colors.black.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Optimization Suggestion:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(issue.optimizationSuggestion, style: const TextStyle(color: Colors.greenAccent)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
