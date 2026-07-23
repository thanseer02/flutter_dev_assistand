import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/project_provider.dart';
import '../../../../project_analysis/presentation/providers/analysis_provider.dart';
import '../../domain/entities/project_info.dart';
import '../../../../project_analysis/domain/entities/project_analysis.dart';

import '../widgets/stat_card.dart';
import '../widgets/charts/files_by_extension_chart.dart';
import '../widgets/charts/folder_sizes_chart.dart';
import '../widgets/charts/project_timeline_chart.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final projectProvider = context.watch<ProjectProvider>();
    final project = projectProvider.currentProject;
    final analysisProvider = context.watch<AnalysisProvider>();

    if (projectProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (project != null) {
      return _buildProjectDashboard(context, project, analysisProvider);
    }

    return _buildNoProjectView(context, projectProvider);
  }

  Widget _buildNoProjectView(BuildContext context, ProjectProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome to Flutter Dev Assistant',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Open a project to start analyzing.',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 32),
          if (provider.errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                border: Border.all(color: Colors.red.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.alertCircle, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(child: Text(provider.errorMessage!, style: const TextStyle(color: Colors.red))),
                ],
              ),
            ),
          const Text('Recent Projects', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          if (provider.recentProjects.isEmpty)
            const Text('No recent projects.', style: TextStyle(color: Colors.grey)),
          Expanded(
            child: ListView.builder(
              itemCount: provider.recentProjects.length,
              itemBuilder: (context, index) {
                final path = provider.recentProjects[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(LucideIcons.folder, color: Colors.blue),
                  title: Text(path.split('/').last),
                  subtitle: Text(path, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  onTap: () async {
                    await provider.openProject(path);
                    if (context.mounted) {
                      context.read<AnalysisProvider>().scanProject(path);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectDashboard(BuildContext context, ProjectInfo project, AnalysisProvider analysisProvider) {
    final analysis = analysisProvider.currentAnalysis;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.activity, size: 28, color: Colors.blue),
              const SizedBox(width: 12),
              const Text(
                'Dashboard',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (analysisProvider.isScanning)
                const Row(
                  children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 8),
                    Text('Scanning...', style: TextStyle(color: Colors.grey)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Animated Grid of Stat Cards
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: _buildCardsGrid(project, analysis),
          ),

          const SizedBox(height: 32),
          
          // Charts Section
          if (analysis != null) ...[
            const Text('Insights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: _buildChartsGrid(context, analysis),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCardsGrid(ProjectInfo project, ProjectAnalysis? analysis) {
    // Determine Project Health
    String health = 'Good';
    Color healthColor = Colors.green;
    if (analysis != null && analysis.analysisOptions.isEmpty) {
      health = 'Warning (No lints)';
      healthColor = Colors.orange;
    }

    final String sizeStr = analysis != null 
        ? '${(analysis.totalSizeInBytes / 1024 / 1024).toStringAsFixed(1)} MB' 
        : '...';

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 800 ? 3 : 2);
        
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 2.2, // Adjust card ratio
          children: [
            StatCard(title: 'Project Health', value: health, icon: LucideIcons.heartPulse, color: healthColor),
            StatCard(title: 'Flutter Version', value: project.flutterVersion, icon: LucideIcons.smartphone, color: Colors.blue),
            StatCard(title: 'Dart Version', value: project.dartVersion, icon: LucideIcons.code, color: Colors.blueAccent),
            StatCard(title: 'Package Count', value: project.packagesCount.toString(), icon: LucideIcons.package, color: Colors.purple),
            StatCard(title: 'Assets', value: analysis != null ? (analysis.folders.where((f) => f.contains('assets')).length.toString()) : project.assetsCount.toString(), icon: LucideIcons.image, color: Colors.orange),
            StatCard(title: 'Dart Files', value: analysis != null ? (analysis.filesByExtension['dart']?.length.toString() ?? '0') : project.dartFilesCount.toString(), icon: LucideIcons.fileCode, color: Colors.teal),
            StatCard(title: 'Project Size', value: sizeStr, icon: LucideIcons.hardDrive, color: Colors.redAccent),
            StatCard(title: 'Latest Scan', value: analysis != null ? 'Just now' : 'Pending', icon: LucideIcons.clock, color: Colors.grey),
          ],
        );
      },
    );
  }

  Widget _buildChartsGrid(BuildContext context, ProjectAnalysis analysis) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWide = constraints.maxWidth > 900;
        
        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildChartContainer(
                    context, 
                    'Files by Extension', 
                    FilesByExtensionChart(data: analysis.filesByExtension.map((k, v) => MapEntry(k, v.length))),
                  ),
                ),
                if (isWide) const SizedBox(width: 16),
                if (isWide)
                  Expanded(
                    child: _buildChartContainer(
                      context, 
                      'Folder Sizes', 
                      FolderSizesChart(data: analysis.folderSizes),
                    ),
                  ),
              ],
            ),
            if (!isWide) const SizedBox(height: 16),
            if (!isWide)
              _buildChartContainer(
                context, 
                'Folder Sizes', 
                FolderSizesChart(data: analysis.folderSizes),
              ),
            const SizedBox(height: 16),
            _buildChartContainer(
              context, 
              'Project Timeline (Last 30 Days)', 
              ProjectTimelineChart(filesByExtension: analysis.filesByExtension),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChartContainer(BuildContext context, String title, Widget chart) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          chart,
        ],
      ),
    );
  }
}
