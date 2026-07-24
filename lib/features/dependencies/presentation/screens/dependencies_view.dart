import 'package:flutter_dev_assistant/features/project/presentation/providers/project_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/dependency_provider.dart';
import '../../domain/entities/package_info.dart';

class DependenciesView extends StatelessWidget {
  const DependenciesView({super.key});

  @override
  Widget build(BuildContext context) {
    final depProvider = context.watch<DependencyProvider>();
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
              const Icon(LucideIcons.packageCheck, size: 28, color: Colors.blue),
              const SizedBox(width: 12),
              const Text(
                'Pubspec Analyzer',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(LucideIcons.play),
                label: const Text('Analyze Packages'),
                onPressed: depProvider.isAnalyzing ? null : () {
                  depProvider.analyzeProject(projectProvider.currentProject!.path);
                },
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                icon: const Icon(LucideIcons.download),
                label: const Text('Export Report'),
                onPressed: depProvider.packages.isEmpty ? null : () async {
                  final String? dir = await FilePicker.platform.getDirectoryPath();
                  if (dir != null && context.mounted) {
                    final path = await depProvider.exportReport(dir);
                    if (path != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Report saved to $path')));
                    }
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          if (depProvider.isAnalyzing)
            const Expanded(child: Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Fetching live data from pub.dev...', style: TextStyle(color: Colors.grey)),
              ],
            ))),
          
          if (!depProvider.isAnalyzing && depProvider.errorMessage != null)
            Text(depProvider.errorMessage!, style: const TextStyle(color: Colors.red)),
            
          if (!depProvider.isAnalyzing && depProvider.packages.isNotEmpty)
            Expanded(
              child: Column(
                children: [
                  _buildSummaryCards(context, depProvider.packages),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SingleChildScrollView(
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(Theme.of(context).scaffoldBackgroundColor),
                            columns: const [
                              DataColumn(label: Text('Package')),
                              DataColumn(label: Text('Current')),
                              DataColumn(label: Text('Latest')),
                              DataColumn(label: Text('Risk Level')),
                              DataColumn(label: Text('Issues')),
                            ],
                            rows: depProvider.packages.map((pkg) {
                              return DataRow(cells: [
                                DataCell(
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(pkg.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      if (pkg.isDevDependency)
                                        const Text('dev_dependency', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                DataCell(Text(pkg.currentVersion)),
                                DataCell(Text(pkg.latestVersion ?? 'Unknown', style: const TextStyle(color: Colors.green))),
                                DataCell(_buildRiskBadge(pkg.riskLevel)),
                                DataCell(_buildIssues(pkg)),
                              ]);
                            }).toList(),
                          ),
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

  Widget _buildSummaryCards(BuildContext context, List<PackageInfo> packages) {
    int highRisk = packages.where((p) => p.riskLevel == RiskLevel.high).length;
    int unused = packages.where((p) => p.isUnused).length;
    int discontinued = packages.where((p) => p.isDiscontinued).length;

    return Row(
      children: [
        _buildStat(context, 'Total Packages', packages.length.toString(), Colors.blue),
        const SizedBox(width: 16),
        _buildStat(context, 'High Risk', highRisk.toString(), Colors.red),
        const SizedBox(width: 16),
        _buildStat(context, 'Unused', unused.toString(), Colors.orange),
        const SizedBox(width: 16),
        _buildStat(context, 'Discontinued', discontinued.toString(), Colors.redAccent),
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
            Text(title, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskBadge(RiskLevel level) {
    Color color;
    switch (level) {
      case RiskLevel.high: color = Colors.red; break;
      case RiskLevel.medium: color = Colors.orange; break;
      case RiskLevel.low: color = Colors.green; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(level.name.toUpperCase(), style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildIssues(PackageInfo pkg) {
    List<Widget> chips = [];
    if (pkg.isDiscontinued) {
      chips.add(_buildChip('Discontinued', Colors.red));
    }
    if (pkg.isUnused) {
      chips.add(_buildChip('Unused', Colors.orange));
    }
    if (pkg.isGit || pkg.isLocal) {
      chips.add(_buildChip(pkg.isGit ? 'Git' : 'Local', Colors.blue));
    }

    if (chips.isEmpty) {
      return const Text('None', style: TextStyle(color: Colors.grey));
    }
    return Wrap(spacing: 4, runSpacing: 4, children: chips);
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
    );
  }
}
