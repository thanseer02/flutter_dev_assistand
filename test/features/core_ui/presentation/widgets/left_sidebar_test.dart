import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dev_assistant/features/core_ui/presentation/widgets/left_sidebar.dart';
import 'package:flutter_dev_assistant/features/core_ui/presentation/providers/layout_provider.dart';

void main() {
  testWidgets('LeftSidebar renders all items', (WidgetTester tester) async {
    final layoutProvider = LayoutProvider();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<LayoutProvider>.value(
            value: layoutProvider,
            child: const Row(
              children: [
                LeftSidebar(),
              ],
            ),
          ),
        ),
      ),
    );

    // Verify main items are present
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Project Scan'), findsOneWidget);
    expect(find.text('Assets'), findsOneWidget);
    expect(find.text('Dependencies'), findsOneWidget);
    
    // Test interaction
    await tester.tap(find.text('Project Scan'));
    await tester.pumpAndSettle();
    
    expect(layoutProvider.currentSidebarItem, SidebarItem.projectScanner);
  });
}
