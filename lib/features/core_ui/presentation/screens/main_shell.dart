import 'package:flutter/material.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:provider/provider.dart';

import '../providers/layout_provider.dart';
import '../widgets/top_toolbar.dart';
import '../widgets/left_sidebar.dart';
import '../widgets/right_panel.dart';
import '../widgets/bottom_status_bar.dart';
import '../../../../project/presentation/screens/dashboard_view.dart';

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
        Area(weight: 0.15, minimalSize: 200), // Left sidebar/explorer equivalent
        Area(weight: 0.65, minimalSize: 400), // Center area
        Area(weight: 0.20, minimalSize: 200), // Right panel
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
                      activeAreas.add(Area(weight: provider.isRightPanelVisible ? 0.7 : 1.0, minimalSize: 400));
                      activeWidgets.add(_buildCenterContent(provider.selectedSidebarItem));

                      if (provider.isRightPanelVisible) {
                        activeAreas.add(Area(weight: 0.3, minimalSize: 200));
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
                          children: activeWidgets,
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
