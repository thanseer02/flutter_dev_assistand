import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/apk_provider.dart';
import '../../domain/entities/apk_file_node.dart';
import '../widgets/treemap_painter.dart';

class ApkAnalyzerView extends StatelessWidget {
  const ApkAnalyzerView({super.key});

  @override
  Widget build(BuildContext context) {
    final apkProvider = context.watch<ApkProvider>();

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.packageOpen, size: 28, color: Colors.blue),
              const SizedBox(width: 12),
              const Text(
                'APK/AAB Analyzer',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(LucideIcons.folderSearch),
                label: const Text('Select APK/AAB'),
                onPressed: apkProvider.isAnalyzing ? null : () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['apk', 'aab', 'zip'],
                  );
                  if (result != null && result.files.single.path != null) {
                    apkProvider.analyzeApk(result.files.single.path!);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          if (apkProvider.isAnalyzing)
            const Expanded(child: Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Parsing archive headers...', style: TextStyle(color: Colors.grey)),
              ],
            ))),
            
          if (!apkProvider.isAnalyzing && apkProvider.errorMessage != null)
            Text(apkProvider.errorMessage!, style: const TextStyle(color: Colors.red)),
            
          if (!apkProvider.isAnalyzing && apkProvider.rootNode != null)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left side: Treemap
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
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return InteractiveViewer(
                              constrained: true,
                              child: CustomPaint(
                                size: Size(constraints.maxWidth, constraints.maxHeight),
                                painter: TreemapPainter(rootNode: apkProvider.rootNode!),
                              ),
                            );
                          }
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  
                  // Right side: Largest Files & Recommendations
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        _buildTotalSizeCard(context, apkProvider.rootNode!),
                        const SizedBox(height: 16),
                        
                        if (apkProvider.recommendations.isNotEmpty) ...[
                          _buildRecommendationsCard(context, apkProvider.recommendations),
                          const SizedBox(height: 16),
                        ],

                        Expanded(
                          child: _buildTopFilesCard(context, apkProvider.largestFiles),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTotalSizeCard(BuildContext context, ApkFileNode root) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Uncompressed Size', style: TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            '${(root.sizeBytes / 1024 / 1024).toStringAsFixed(2)} MB',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          const SizedBox(height: 16),
          _buildLegendRow(Colors.blue, 'Dart/Flutter Engine'),
          _buildLegendRow(Colors.red, 'Native Libraries (.so)'),
          _buildLegendRow(Colors.purple, 'Fonts'),
          _buildLegendRow(Colors.green, 'Images'),
          _buildLegendRow(Colors.orange, 'Resources'),
        ],
      ),
    );
  }

  Widget _buildLegendRow(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard(BuildContext context, List<String> recs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.lightbulb, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text('Recommendations', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
            ],
          ),
          const SizedBox(height: 12),
          ...recs.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(color: Colors.orange)),
                Expanded(child: Text(r, style: const TextStyle(fontSize: 12))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildTopFilesCard(BuildContext context, List<ApkFileNode> files) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Top 10 Largest Files', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: files.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final file = files[index];
                return ListTile(
                  title: Text(file.name, style: const TextStyle(fontSize: 14)),
                  subtitle: Text(
                    file.path, 
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    '${(file.sizeBytes / 1024).toStringAsFixed(1)} KB',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
