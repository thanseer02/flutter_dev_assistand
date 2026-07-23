import 'package:flutter/material.dart';

enum SidebarItem {
  dashboard,
  project,
  assets,
  dependencies,
  analyzer,
  imports,
  performance,
  aiReview,
  git,
  settings,
}

class LayoutProvider extends ChangeNotifier {
  SidebarItem _selectedSidebarItem = SidebarItem.dashboard;
  bool _isRightPanelVisible = true;
  bool _isLeftSidebarVisible = true;

  SidebarItem get selectedSidebarItem => _selectedSidebarItem;
  bool get isRightPanelVisible => _isRightPanelVisible;
  bool get isLeftSidebarVisible => _isLeftSidebarVisible;

  void setSidebarItem(SidebarItem item) {
    if (_selectedSidebarItem != item) {
      _selectedSidebarItem = item;
      
      // If sidebar is hidden, show it when an item is selected
      if (!_isLeftSidebarVisible) {
        _isLeftSidebarVisible = true;
      }
      
      notifyListeners();
    }
  }

  void toggleRightPanel() {
    _isRightPanelVisible = !_isRightPanelVisible;
    notifyListeners();
  }

  void toggleLeftSidebar() {
    _isLeftSidebarVisible = !_isLeftSidebarVisible;
    notifyListeners();
  }
}
