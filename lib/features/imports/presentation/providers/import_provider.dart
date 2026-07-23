import 'package:flutter/material.dart';
import '../../domain/entities/import_analysis.dart';
import '../../data/services/import_analyzer_service.dart';

class ImportProvider extends ChangeNotifier {
  final ImportAnalyzerService _analyzerService;
  
  ImportAnalysis? _analysis;
  bool _isAnalyzing = false;
  String? _errorMessage;
  String? _selectedNodePath;

  ImportProvider(this._analyzerService);

  ImportAnalysis? get analysis => _analysis;
  bool get isAnalyzing => _isAnalyzing;
  String? get errorMessage => _errorMessage;
  String? get selectedNodePath => _selectedNodePath;

  Future<void> analyzeImports(String projectPath) async {
    _isAnalyzing = true;
    _errorMessage = null;
    _selectedNodePath = null;
    notifyListeners();

    try {
      _analysis = await _analyzerService.analyzeImports(projectPath);
    } catch (e) {
      _errorMessage = 'Import Analysis failed: $e';
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  void selectNode(String path) {
    if (_selectedNodePath != path) {
      _selectedNodePath = path;
      notifyListeners();
    }
  }

  void clearSelection() {
    if (_selectedNodePath != null) {
      _selectedNodePath = null;
      notifyListeners();
    }
  }
}
