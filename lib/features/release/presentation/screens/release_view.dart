import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/release_provider.dart';
import '../../domain/entities/release_check.dart';
import '../../../../project/presentation/providers/project_provider.dart';

class ReleaseView extends StatelessWidget {
  const ReleaseView({super.key});

  @override
  Widget build(BuildContext context) {
    final releaseProvider = context.watch<ReleaseProvider>();
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
              const Icon(LucideIcons.rocket, size: 28, color: Colors.blue),
              const SizedBox(width: 12),
              const Text(
                'Release Readiness',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (releaseProvider.checks.isNotEmpty) ...[
                OutlinedButton.icon(
                  icon: const Icon(LucideIcons.download),
                  label: const Text('Export PDF'),
                  onPressed: () async {
                    String? outputFile = await FilePicker.platform.saveFile(
                      dialogTitle: 'Please select an output file:',
                      fileName: 'release_report.pdf',
                    );
                    
                    if (outputFile != null) {
                      await releaseProvider.exportReport(
                        projectProvider.currentProject!.name,
                        outputFile,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('PDF Exported Successfully')),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(width: 16),
              ],
              ElevatedButton.icon(
                icon: const Icon(LucideIcons.play),
                label: const Text('Run Readiness Check'),
                onPressed: releaseProvider.isAnalyzing ? null : () {
                  releaseProvider.analyzeRelease(projectProvider.currentProject!.path);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          if (releaseProvider.isAnalyzing)
            const Expanded(child: Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Auditing release configurations...', style: TextStyle(color: Colors.grey)),
              ],
            ))),
          
          if (!releaseProvider.isAnalyzing && releaseProvider.errorMessage != null)
            Text(releaseProvider.errorMessage!, style: const TextStyle(color: Colors.red)),
            
          if (!releaseProvider.isAnalyzing && releaseProvider.checks.isNotEmpty)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: _buildScorePanel(context, releaseProvider),
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
                          itemCount: releaseProvider.checks.length,
                          itemBuilder: (context, index) {
                            return _buildCheckTile(releaseProvider.checks[index]);
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

  Widget _buildScorePanel(BuildContext context, ReleaseProvider provider) {
    final score = provider.releaseScore;
    Color scoreColor = Colors.green;
    if (score < 80) scoreColor = Colors.orange;
    if (score < 60) scoreColor = Colors.red;

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
          const Text('Readiness Score', style: TextStyle(color: Colors.grey, fontSize: 16)),
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
          const Text('Results Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          _buildSummaryRow('Passed', provider.checks.where((c) => c.status == ReleaseCheckStatus.pass).length, Colors.green),
          _buildSummaryRow('Failed', provider.checks.where((c) => c.status == ReleaseCheckStatus.fail).length, Colors.red),
          _buildSummaryRow('Warnings', provider.checks.where((c) => c.status == ReleaseCheckStatus.warning).length, Colors.orange),
          _buildSummaryRow('Info', provider.checks.where((c) => c.status == ReleaseCheckStatus.info).length, Colors.blue),
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

  Widget _buildCheckTile(ReleaseCheck check) {
    Color iconColor;
    IconData icon;

    switch (check.status) {
      case ReleaseCheckStatus.pass:
        iconColor = Colors.green;
        icon = LucideIcons.checkCircle2;
        break;
      case ReleaseCheckStatus.fail:
        iconColor = Colors.red;
        icon = LucideIcons.xCircle;
        break;
      case ReleaseCheckStatus.warning:
        iconColor = Colors.orange;
        icon = LucideIcons.alertTriangle;
        break;
      case ReleaseCheckStatus.info:
        iconColor = Colors.blue;
        icon = LucideIcons.info;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(check.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(check.description, style: const TextStyle(color: Colors.grey)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            check.category.name.toUpperCase(), 
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)
          ),
        ),
      ),
    );
  }
}
