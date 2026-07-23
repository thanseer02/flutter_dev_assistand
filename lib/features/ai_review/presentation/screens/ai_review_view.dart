import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/ai_review_provider.dart';
import '../../domain/entities/ai_review_issue.dart';

class AiReviewView extends StatefulWidget {
  const AiReviewView({super.key});

  @override
  State<AiReviewView> createState() => _AiReviewViewState();
}

class _AiReviewViewState extends State<AiReviewView> {
  final TextEditingController _apiKeyController = TextEditingController();
  List<String> _selectedFiles = [];

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['dart'],
    );
    if (result != null) {
      setState(() {
        _selectedFiles = result.paths.whereType<String>().toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final aiProvider = context.watch<AiReviewProvider>();

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.sparkles, size: 28, color: Colors.blue),
              const SizedBox(width: 12),
              const Text(
                'AI Code Reviewer',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (aiProvider.hasApiKey)
                OutlinedButton.icon(
                  icon: const Icon(LucideIcons.key),
                  label: const Text('Update API Key'),
                  onPressed: () {
                    aiProvider.clearApiKey();
                    _apiKeyController.clear();
                  },
                ),
            ],
          ),
          const SizedBox(height: 24),
          
          if (!aiProvider.hasApiKey)
            _buildSetupPanel(context, aiProvider)
          else
            Expanded(child: _buildReviewPanel(context, aiProvider)),
        ],
      ),
    );
  }

  Widget _buildSetupPanel(BuildContext context, AiReviewProvider provider) {
    return Center(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(LucideIcons.lock, color: Colors.blue),
                SizedBox(width: 8),
                Text('Gemini API Key Required', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'To perform AI reviews, this app requires a valid Gemini API key. Your key is stored securely on your local device and is only used to communicate directly with Google servers.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _apiKeyController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'API Key',
                border: OutlineInputBorder(),
                prefixIcon: Icon(LucideIcons.key),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_apiKeyController.text.isNotEmpty) {
                    provider.saveApiKey(_apiKeyController.text);
                  }
                },
                child: const Text('Save & Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewPanel(BuildContext context, AiReviewProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ElevatedButton.icon(
              icon: const Icon(LucideIcons.fileSearch),
              label: const Text('Select Dart Files'),
              onPressed: provider.isAnalyzing ? null : _pickFiles,
            ),
            const SizedBox(width: 16),
            if (_selectedFiles.isNotEmpty)
              Text('${_selectedFiles.length} files selected', style: const TextStyle(color: Colors.green)),
            const Spacer(),
            FilledButton.icon(
              icon: const Icon(LucideIcons.play),
              label: const Text('Start AI Review'),
              onPressed: (_selectedFiles.isEmpty || provider.isAnalyzing) ? null : () {
                provider.reviewFiles(_selectedFiles);
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        if (provider.isAnalyzing)
          const Expanded(child: Center(child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('AI is analyzing the architecture and code quality...', style: TextStyle(color: Colors.grey)),
            ],
          ))),
          
        if (!provider.isAnalyzing && provider.errorMessage != null)
          Text(provider.errorMessage!, style: const TextStyle(color: Colors.red)),
          
        if (!provider.isAnalyzing && provider.issues.isNotEmpty)
          Expanded(
            child: ListView.builder(
              itemCount: provider.issues.length,
              itemBuilder: (context, index) {
                return _buildIssueCard(provider.issues[index]);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildIssueCard(AiReviewIssue issue) {
    Color severityColor;
    switch (issue.severity) {
      case IssueSeverity.critical: severityColor = Colors.red; break;
      case IssueSeverity.high: severityColor = Colors.orange; break;
      case IssueSeverity.medium: severityColor = Colors.yellow; break;
      case IssueSeverity.low: severityColor = Colors.blue; break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: Icon(LucideIcons.messageSquare, color: severityColor),
        title: Text(issue.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Row(
          children: [
            Text('Severity: ${issue.severity.name.toUpperCase()}', style: TextStyle(color: severityColor, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(width: 16),
            Text('Category: ${issue.category.name}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            color: Colors.black.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(issue.description),
                const SizedBox(height: 16),
                const Text('Impact', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(issue.estimatedImpact, style: const TextStyle(color: Colors.orange)),
                const SizedBox(height: 16),
                const Text('Suggestion', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(issue.suggestion, style: const TextStyle(color: Colors.greenAccent)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
