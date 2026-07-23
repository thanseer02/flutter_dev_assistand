import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:window_manager/window_manager.dart';

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
            const Text(
              'My Flutter App',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            
            const SizedBox(width: 24),

            // Actions
            IconButton(
              icon: const Icon(LucideIcons.folderOpen, size: 18),
              tooltip: 'Open Project',
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              tooltip: 'Refresh',
              onPressed: () {},
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
