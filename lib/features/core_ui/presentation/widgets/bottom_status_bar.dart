import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/layout_provider.dart';
import '../../../../project/presentation/providers/project_provider.dart';

class BottomStatusBar extends StatelessWidget {
  const BottomStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      color: Theme.of(context).colorScheme.primary.withOpacity(0.9), // Classic VS Code blue-ish or theme primary
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Consumer<ProjectProvider>(
        builder: (context, projectProvider, child) {
          final project = projectProvider.currentProject;
          final isLoading = projectProvider.isLoading;
          final status = isLoading ? 'Loading...' : (project != null ? 'Ready' : 'No Project');

          return Row(
            children: [
              // Left side
              Icon(isLoading ? LucideIcons.loader : LucideIcons.check, size: 14, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                status,
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
              
              const Spacer(),
              
              // Right side
              _buildStatusItem(project != null ? project.path : '/not/selected'),
              _buildStatusItem('Dart: ${project?.dartVersion ?? "N/A"}'),
              _buildStatusItem('Flutter: ${project?.flutterVersion ?? "N/A"}'),

              // Panel Toggles
              const SizedBox(width: 8),
              InkWell(
                onTap: () => context.read<LayoutProvider>().toggleRightPanel(),
                child: Icon(
                  LucideIcons.panelRight,
                  size: 14,
                  color: context.watch<LayoutProvider>().isRightPanelVisible 
                      ? Colors.white 
                      : Colors.white54,
                ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
        ),
      ),
    );
  }
}
