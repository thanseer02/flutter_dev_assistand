import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/project_provider.dart';
import '../../../../project_analysis/presentation/providers/analysis_provider.dart';
import '../../domain/entities/project_info.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final projectProvider = context.watch<ProjectProvider>();
    final project = projectProvider.currentProject;

    if (projectProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (project != null) {
      return _buildProjectDashboard(context, project);
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

  Widget _buildProjectDashboard(BuildContext context, ProjectInfo project) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.box, size: 32, color: Colors.blue),
              const SizedBox(width: 16),
              Text(
                project.name,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(project.path, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildStatCard(context, 'Flutter Version', project.flutterVersion, LucideIcons.smartphone),
              _buildStatCard(context, 'Dart SDK', project.dartVersion, LucideIcons.code),
              _buildStatCard(context, 'Dart Files', project.dartFilesCount.toString(), LucideIcons.fileCode),
              _buildStatCard(context, 'Assets', project.assetsCount.toString(), LucideIcons.image),
              _buildStatCard(context, 'Packages', project.packagesCount.toString(), LucideIcons.package),
            ],
          ),
          const SizedBox(height: 32),
          const Text('Scan Results', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Consumer<AnalysisProvider>(
            builder: (context, analysisProvider, child) {
              if (analysisProvider.isScanning) {
                return const Row(
                  children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 8),
                    Text('Running deep scan...', style: TextStyle(color: Colors.grey)),
                  ],
                );
              }
              
              if (analysisProvider.errorMessage != null) {
                return Text(analysisProvider.errorMessage!, style: const TextStyle(color: Colors.red));
              }

              final analysis = analysisProvider.currentAnalysis;
              if (analysis == null) {
                return const Text('No deep scan data available.', style: TextStyle(color: Colors.grey));
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildScanStat(context, 'Total Files', analysis.totalFiles.toString(), LucideIcons.files),
                      const SizedBox(width: 16),
                      _buildScanStat(context, 'Total Folders', analysis.totalFolders.toString(), LucideIcons.folder),
                      const SizedBox(width: 16),
                      _buildScanStat(context, 'Total Size', '${(analysis.totalSizeInBytes / 1024 / 1024).toStringAsFixed(2)} MB', LucideIcons.hardDrive),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Top Extensions:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: analysis.filesByExtension.entries.map((e) {
                      return Chip(
                        label: Text('.${e.key} (${e.value.length})'),
                        backgroundColor: Theme.of(context).colorScheme.surface,
                      );
                    }).toList(),
                  )
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScanStat(BuildContext context, String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.blue),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
