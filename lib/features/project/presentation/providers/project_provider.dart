import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/project_info.dart';
import '../data/services/project_service.dart';

class ProjectProvider extends ChangeNotifier {
  final ProjectService _projectService;
  final SharedPreferences _prefs;

  ProjectInfo? _currentProject;
  List<String> _recentProjects = [];
  bool _isLoading = false;
  String? _errorMessage;

  ProjectProvider(this._projectService, this._prefs) {
    _loadRecentProjects();
  }

  ProjectInfo? get currentProject => _currentProject;
  List<String> get recentProjects => _recentProjects;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _loadRecentProjects() {
    _recentProjects = _prefs.getStringList('recent_projects') ?? [];
    notifyListeners();
  }

  Future<void> _saveRecentProject(String path) async {
    if (_recentProjects.contains(path)) {
      _recentProjects.remove(path);
    }
    _recentProjects.insert(0, path);
    // Keep top 10
    if (_recentProjects.length > 10) {
      _recentProjects = _recentProjects.sublist(0, 10);
    }
    await _prefs.setStringList('recent_projects', _recentProjects);
    notifyListeners();
  }

  Future<void> openProject(String path) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final isValid = await _projectService.isValidFlutterProject(path);
      if (!isValid) {
        _errorMessage = 'Invalid Flutter project directory. Ensure pubspec.yaml, android, ios, and lib exist.';
        _currentProject = null;
      } else {
        final info = await _projectService.parseProject(path);
        _currentProject = info;
        await _saveRecentProject(path);
      }
    } catch (e) {
      _errorMessage = 'Error opening project: $e';
      _currentProject = null;
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
