import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/import_provider.dart';
import '../../domain/entities/import_analysis.dart';
import '../../../../project/presentation/providers/project_provider.dart';
import '../widgets/dependency_graph_painter.dart';

class ImportsView extends StatelessWidget {
  const ImportsView({super.key});

  @override
  Widget build(BuildContext context) {
    final importProvider = context.watch<ImportProvider>();
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
              const Icon(LucideIcons.gitMerge, size: 28, color: Colors.blue),
              const SizedBox(width: 12),
              const Text(
                'Dependency Graph',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(LucideIcons.play),
                label: const Text('Analyze Imports'),
                onPressed: importProvider.isAnalyzing ? null : () {
                  importProvider.analyzeImports(projectProvider.currentProject!.path);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          if (importProvider.isAnalyzing)
            const Expanded(child: Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Building graph and running linter...', style: TextStyle(color: Colors.grey)),
              ],
            ))),
            
          if (!importProvider.isAnalyzing && importProvider.errorMessage != null)
            Text(importProvider.errorMessage!, style: const TextStyle(color: Colors.red)),
            
          if (!importProvider.isAnalyzing && importProvider.analysis != null)
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        _buildSummaryCards(context, importProvider.analysis!),
                        const SizedBox(height: 16),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Theme.of(context).dividerColor),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: GestureDetector(
                                onTapDown: (details) {
                                  // Simple hit detection logic is built into the painter, 
                                  // but we'll do it properly using InteractiveViewer interaction.
                                },
                                child: InteractiveViewer(
                                  constrained: false,
                                  boundaryMargin: const EdgeInsets.all(4000),
                                  minScale: 0.1,
                                  maxScale: 5.0,
                                  child: SizedBox(
                                    width: 4000,
                                    height: 4000,
                                    child: CustomPaint(
                                      painter: DependencyGraphPainter(
                                        analysis: importProvider.analysis!,
                                        selectedNodePath: importProvider.selectedNodePath,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 1,
                    child: _buildSidePanel(context, importProvider),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, ImportAnalysis analysis) {
    return Row(
      children: [
        _buildStat(context, 'Total Files', analysis.graph.length.toString(), Colors.blue),
        const SizedBox(width: 16),
        _buildStat(context, 'Circular Paths', analysis.circularDependencies.length.toString(), Colors.red),
        const SizedBox(width: 16),
        _buildStat(context, 'Unused Imports', analysis.unusedImports.length.toString(), Colors.orange),
        const SizedBox(width: 16),
        _buildStat(context, 'Max Chain Depth', analysis.maxChainDepth.toString(), Colors.green),
      ],
    );
  }

  Widget _buildStat(BuildContext context, String title, String val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 8),
            Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildSidePanel(BuildContext context, ImportProvider provider) {
    final analysis = provider.analysis!;
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (analysis.unusedImports.isNotEmpty) ...[
            const Text('Unused Imports', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
            const SizedBox(height: 8),
            ...analysis.unusedImports.map((i) => Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text('- $i', style: const TextStyle(fontSize: 12)),
            )).toList(),
            const Divider(),
          ],
          
          if (analysis.circularDependencies.isNotEmpty) ...[
            const Text('Circular Dependencies', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
            const SizedBox(height: 8),
            ...analysis.circularDependencies.map((cycle) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(cycle.join(' -> '), style: const TextStyle(fontSize: 12, color: Colors.redAccent)),
            )).toList(),
            const Divider(),
          ],
          
          // Selection info could go here later
          const Text('Instructions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Pan and zoom the graph to explore internal dependencies between files in the lib folder.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
