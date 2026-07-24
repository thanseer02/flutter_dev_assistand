import 'package:flutter_dev_assistant/features/project/presentation/providers/project_provider.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/asset_provider.dart';
import '../../domain/entities/asset_issue.dart';

class AssetsView extends StatelessWidget {
  const AssetsView({super.key});

  @override
  Widget build(BuildContext context) {
    final assetProvider = context.watch<AssetProvider>();
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
              const Icon(LucideIcons.image, size: 28, color: Colors.blue),
              const SizedBox(width: 12),
              const Text(
                'Asset Scanner',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(LucideIcons.play),
                label: const Text('Scan Assets'),
                onPressed: assetProvider.isScanning ? null : () {
                  assetProvider.scanAssets(projectProvider.currentProject!.path);
                },
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                icon: const Icon(LucideIcons.download),
                label: const Text('Export Report'),
                onPressed: assetProvider.lastResult == null ? null : () async {
                  final String? dir = await FilePicker.platform.getDirectoryPath();
                  if (dir != null && context.mounted) {
                    final path = await assetProvider.exportReport(dir);
                    if (path != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Report saved to $path')));
                    }
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          if (assetProvider.isScanning)
            const Expanded(child: Center(child: CircularProgressIndicator())),
          
          if (!assetProvider.isScanning && assetProvider.errorMessage != null)
            Text(assetProvider.errorMessage!, style: const TextStyle(color: Colors.red)),
            
          if (!assetProvider.isScanning && assetProvider.lastResult != null)
            Expanded(
              child: DefaultTabController(
                length: 5,
                child: Column(
                  children: [
                    _buildSummaryCards(context, assetProvider),
                    const SizedBox(height: 24),
                    const TabBar(
                      isScrollable: true,
                      tabs: [
                        Tab(text: 'Unused'),
                        Tab(text: 'Duplicates'),
                        Tab(text: 'Large Files'),
                        Tab(text: 'Missing'),
                        Tab(text: 'Empty Folders'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildIssueList(context, assetProvider.lastResult!.unusedAssets, assetProvider),
                          _buildIssueList(context, assetProvider.lastResult!.duplicateAssets, assetProvider),
                          _buildIssueList(context, assetProvider.lastResult!.largeAssets, assetProvider),
                          _buildIssueList(context, assetProvider.lastResult!.missingAssets, assetProvider),
                          _buildIssueList(context, assetProvider.lastResult!.emptyFolders, assetProvider),
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

  Widget _buildSummaryCards(BuildContext context, AssetProvider provider) {
    final res = provider.lastResult!;
    return Row(
      children: [
        _buildStat(context, 'Total Scanned', res.totalAssetsScanned.toString(), Colors.blue),
        const SizedBox(width: 16),
        _buildStat(context, 'Total Issues', res.allIssues.length.toString(), Colors.orange),
        const SizedBox(width: 16),
        _buildStat(context, 'Potential Savings', '${(res.potentialSavingsBytes / 1024 / 1024).toStringAsFixed(2)} MB', Colors.green),
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

  Widget _buildIssueList(BuildContext context, List<AssetIssue> issues, AssetProvider provider) {
    if (issues.isEmpty) return const Center(child: Text('No issues found in this category.'));

    return ListView.builder(
      itemCount: issues.length,
      itemBuilder: (context, index) {
        final issue = issues[index];
        final bool isImage = ['png', 'jpg', 'jpeg', 'gif', 'webp'].any((e) => issue.path.toLowerCase().endsWith(e));
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: (isImage && issue.type != AssetIssueType.missing)
                ? Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.file(File(issue.path), fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.broken_image)),
                    ),
                  )
                : const Icon(LucideIcons.fileWarning),
            title: Text(issue.path.split('/').last),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(issue.path, style: const TextStyle(fontSize: 12)),
                if (issue.description != null) 
                  Text(issue.description!, style: const TextStyle(fontSize: 12, color: Colors.orange)),
              ],
            ),
            trailing: (issue.type == AssetIssueType.unused || issue.type == AssetIssueType.duplicate || issue.type == AssetIssueType.large)
                ? IconButton(
                    icon: const Icon(LucideIcons.trash2, color: Colors.red),
                    onPressed: () async {
                      bool deleted = await provider.deleteAsset(issue.path);
                      if (deleted && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File deleted.')));
                      }
                    },
                  )
                : null,
          ),
        );
      },
    );
  }
}
