import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/layout_provider.dart';

class LeftSidebar extends StatelessWidget {
  const LeftSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildSidebarItem(context, SidebarItem.dashboard, LucideIcons.layoutDashboard, 'Dashboard'),
          _buildSidebarItem(context, SidebarItem.project, LucideIcons.folderTree, 'Project'),
          _buildSidebarItem(context, SidebarItem.assets, LucideIcons.image, 'Assets'),
          _buildSidebarItem(context, SidebarItem.dependencies, LucideIcons.package, 'Dependencies'),
          _buildSidebarItem(context, SidebarItem.analyzer, LucideIcons.activity, 'Analyzer'),
          _buildSidebarItem(context, SidebarItem.imports, LucideIcons.gitMerge, 'Imports'),
          _buildSidebarItem(context, SidebarItem.performance, LucideIcons.zap, 'Performance'),
          _buildSidebarItem(context, SidebarItem.aiReview, LucideIcons.sparkles, 'AI Review'),
          _buildSidebarItem(context, SidebarItem.release, LucideIcons.rocket, 'Release Readiness'),
          _buildSidebarItem(context, SidebarItem.apkAnalyzer, LucideIcons.packageOpen, 'APK Analyzer'),
          _buildSidebarItem(context, SidebarItem.git, LucideIcons.gitBranch, 'Git'),
          
          const Spacer(),
          
          _buildSidebarItem(context, SidebarItem.settings, LucideIcons.settings, 'Settings'),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
    BuildContext context,
    SidebarItem item,
    IconData icon,
    String tooltip,
  ) {
    final provider = context.watch<LayoutProvider>();
    final isSelected = provider.selectedSidebarItem == item;
    
    final color = isSelected 
        ? Theme.of(context).colorScheme.primary 
        : Theme.of(context).iconTheme.color?.withOpacity(0.6);

    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: InkWell(
        onTap: () => context.read<LayoutProvider>().setSidebarItem(item),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
