import 'package:flutter/material.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:provider/provider.dart';

import '../providers/layout_provider.dart';
import '../widgets/top_toolbar.dart';
import '../widgets/left_sidebar.dart';
import '../widgets/right_panel.dart';
import '../widgets/bottom_status_bar.dart';
import '../../../../features/project/presentation/screens/dashboard_view.dart';
import '../../../../features/assets/presentation/screens/assets_view.dart';
import '../../../../features/dependencies/presentation/screens/dependencies_view.dart';
import '../../../../features/code_analyzer/presentation/screens/analyzer_view.dart';
import '../../../../features/imports/presentation/screens/imports_view.dart';
import '../../../../features/performance/presentation/screens/performance_view.dart';
import '../../../../features/ai_review/presentation/screens/ai_review_view.dart';
import '../../../../features/release/presentation/screens/release_view.dart';
import '../../../../features/apk_analyzer/presentation/screens/apk_analyzer_view.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late MultiSplitViewController _splitViewController;

  @override
  void initState() {
    super.initState();
    _splitViewController = MultiSplitViewController(
      areas: [
        Area(flex: 0.15, min: 200), // Left sidebar/explorer equivalent
        Area(flex: 0.65, min: 400), // Center area
        Area(flex: 0.20, min: 200), // Right panel
      ],
    );
  }

  @override
  void dispose() {
    _splitViewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const TopToolbar(),
          Expanded(
            child: Row(
              children: [
                // Left Icon Sidebar
                const LeftSidebar(),
                
                // Resizable Main Areas
                Expanded(
                  child: Consumer<LayoutProvider>(
                    builder: (context, provider, child) {
                      // Adjust areas based on visibility
                      List<Area> activeAreas = [];
                      List<Widget> activeWidgets = [];

                      // Always have a center area (Dashboard, Project, etc. based on selection)
                      activeAreas.add(Area(flex: provider.isRightPanelVisible ? 0.7 : 1.0, min: 400));
                      activeWidgets.add(_buildCenterContent(provider.selectedSidebarItem));

                      if (provider.isRightPanelVisible) {
                        activeAreas.add(Area(flex: 0.3, min: 200));
                        activeWidgets.add(const RightPanel());
                      }

                      // Re-initialize controller if areas count changed to avoid index out of bounds
                      if (_splitViewController.areas.length != activeAreas.length) {
                        _splitViewController = MultiSplitViewController(areas: activeAreas);
                      }

                      return MultiSplitViewTheme(
                        data: MultiSplitViewThemeData(
                          dividerPainter: DividerPainters.grooved1(
                            color: Theme.of(context).dividerColor,
                            highlightedColor: Theme.of(context).colorScheme.primary,
                            size: 20,
                            thickness: 2,
                          ),
                        ),
                        child: MultiSplitView(
                          controller: _splitViewController,
                          builder: (BuildContext context, Area area) => activeWidgets[area.index],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const BottomStatusBar(),
        ],
      ),
    );
  }

  Widget _buildCenterContent(SidebarItem item) {
    // Return appropriate view based on sidebar selection
    if (item == SidebarItem.dashboard) {
      return const DashboardView();
    }
    
    if (item == SidebarItem.assets) {
      return const AssetsView();
    }

    if (item == SidebarItem.dependencies) {
      return const DependenciesView();
    }

    if (item == SidebarItem.analyzer) {
      return const AnalyzerView();
    }

    if (item == SidebarItem.imports) {
      return const ImportsView();
    }

    if (item == SidebarItem.performance) {
      return const PerformanceView();
    }

    if (item == SidebarItem.aiReview) {
      return const AiReviewView();
    }

    if (item == SidebarItem.release) {
      return const ReleaseView();
    }

    if (item == SidebarItem.apkAnalyzer) {
      return const ApkAnalyzerView();
    }
    
    // For now, returning a placeholder for others
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${item.name.toUpperCase()} VIEW',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Content will be implemented later.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
