import 'package:flutter_dev_assistant/features/project_analysis/presentation/providers/analysis_provider.dart';
import 'package:flutter_dev_assistant/features/project/presentation/providers/project_provider.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:window_manager/window_manager.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

class TopToolbar extends StatelessWidget {
  const TopToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Allow window dragging from the top toolbar
      onPanStart: (details) {
        windowManager.startDragging();
      },
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Mac window controls spacer (if needed, but usually handled by OS)
            const SizedBox(width: 60), 

            // Project Info
            const Icon(LucideIcons.folder, size: 18),
            const SizedBox(width: 8),
            Consumer<ProjectProvider>(
              builder: (context, provider, child) {
                return Text(
                  provider.currentProject?.name ?? 'No Project Open',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                );
              },
            ),
            
            const SizedBox(width: 24),

            // Actions
            IconButton(
              icon: const Icon(LucideIcons.folderOpen, size: 18),
              tooltip: 'Open Project',
              onPressed: () async {
                final String? directoryPath = await FilePicker.platform.getDirectoryPath();
                if (directoryPath != null && context.mounted) {
                  await context.read<ProjectProvider>().openProject(directoryPath);
                  if (context.mounted) {
                    context.read<AnalysisProvider>().scanProject(directoryPath);
                  }
                }
              },
            ),
            IconButton(
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              tooltip: 'Refresh',
              onPressed: () async {
                final provider = context.read<ProjectProvider>();
                if (provider.currentProject != null) {
                  await provider.openProject(provider.currentProject!.path);
                  if (context.mounted) {
                    context.read<AnalysisProvider>().scanProject(provider.currentProject!.path);
                  }
                }
              },
            ),

            const Spacer(),

            // Search Bar
            Container(
              width: 300,
              height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Search in project...',
                  prefixIcon: Icon(LucideIcons.search, size: 16),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                style: TextStyle(fontSize: 13),
              ),
            ),

            const SizedBox(width: 16),
            
            // Window controls spacer (optional depending on OS titleBarStyle)
          ],
        ),
      ),
    );
  }
}
