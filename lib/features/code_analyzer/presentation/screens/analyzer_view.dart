import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/code_analyzer_provider.dart';
import '../../domain/entities/analyzer_result.dart';
import '../../../../project/presentation/providers/project_provider.dart';

class AnalyzerView extends StatelessWidget {
  const AnalyzerView({super.key});

  @override
  Widget build(BuildContext context) {
    final analyzerProvider = context.watch<CodeAnalyzerProvider>();
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
              const Icon(LucideIcons.code2, size: 28, color: Colors.blue),
              const SizedBox(width: 12),
              const Text(
                'Source Code Analyzer',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(LucideIcons.play),
                label: const Text('Analyze Source'),
                onPressed: analyzerProvider.isAnalyzing ? null : () {
                  analyzerProvider.analyzeCode(projectProvider.currentProject!.path);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          if (analyzerProvider.isAnalyzing)
            const Expanded(child: Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Parsing Abstract Syntax Trees...', style: TextStyle(color: Colors.grey)),
              ],
            ))),
          
          if (!analyzerProvider.isAnalyzing && analyzerProvider.errorMessage != null)
            Text(analyzerProvider.errorMessage!, style: const TextStyle(color: Colors.red)),
            
          if (!analyzerProvider.isAnalyzing && analyzerProvider.result != null)
            Expanded(
              child: DefaultTabController(
                length: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCard(context, analyzerProvider.result!),
                    const SizedBox(height: 24),
                    const TabBar(
                      isScrollable: true,
                      tabs: [
                        Tab(text: 'Duplicate Widgets'),
                        Tab(text: 'Duplicate Methods'),
                        Tab(text: 'Repeated Strings'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildIssueList(context, analyzerProvider.result!.widgets),
                          _buildIssueList(context, analyzerProvider.result!.methods),
                          _buildIssueList(context, analyzerProvider.result!.strings),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, AnalyzerResult result) {
    Color color = Colors.green;
    if (result.duplicatePercentage > 15) color = Colors.red;
    else if (result.duplicatePercentage > 5) color = Colors.orange;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Estimated Code Duplication', style: TextStyle(color: Colors.grey, fontSize: 16)),
                const SizedBox(height: 8),
                Text(
                  '${result.duplicatePercentage.toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 60, color: Theme.of(context).dividerColor),
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Issues', style: TextStyle(color: Colors.grey, fontSize: 16)),
                const SizedBox(height: 8),
                Text(
                  result.allIssues.length.toString(),
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueList(BuildContext context, List<DuplicateIssue> issues) {
    if (issues.isEmpty) return const Center(child: Text('No duplicates found in this category!'));

    return ListView.builder(
      itemCount: issues.length,
      itemBuilder: (context, index) {
        final issue = issues[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            title: Text('Duplicated ${issue.locations.length} times'),
            subtitle: Text(
              issue.suggestion,
              style: const TextStyle(color: Colors.orange, fontSize: 12),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Locations:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...issue.locations.map((loc) => Text('- $loc', style: const TextStyle(fontSize: 12, fontFamily: 'monospace'))).toList(),
                    const SizedBox(height: 16),
                    const Text('Structural Snippet:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        issue.snippet.length > 200 ? '${issue.snippet.substring(0, 200)}...' : issue.snippet,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.greenAccent),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
