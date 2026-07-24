import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/project_info.dart';
import '../../data/services/project_service.dart';

class ProjectProvider extends ChangeNotifier {
  List<String> get recentProjects => [_prefs.getString('recent_project_path') ?? ''].where((s) => s.isNotEmpty).toList();
  Future<void> openProject(String path) => scanProject(path);

  final ProjectService _projectService;
  final SharedPreferences _prefs;

  ProjectInfo? _currentProject;
  bool _isLoading = false;
  String? _errorMessage;

  ProjectProvider(this._projectService, this._prefs) {
    _loadRecentProject();
  }

  ProjectInfo? get currentProject => _currentProject;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> _loadRecentProject() async {
    final recentPath = _prefs.getString('recent_project_path');
    if (recentPath != null && recentPath.isNotEmpty) {
      await scanProject(recentPath);
    }
  }

  Future<void> scanProject(String path) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final isValid = await _projectService.isValidFlutterProject(path);
      if (!isValid) {
        _errorMessage = 'Invalid Flutter project directory. Ensure pubspec.yaml, android, ios, and lib exist.';
        _currentProject = null;
      } else {
        _currentProject = await _projectService.parseProject(path);
        await _prefs.setString('recent_project_path', path);
      }
    } catch (e) {
      _errorMessage = 'Failed to scan project: $e';
      _currentProject = null;
      await _prefs.remove('recent_project_path');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearCurrentProject() {
    _currentProject = null;
    notifyListeners();
  }
}
