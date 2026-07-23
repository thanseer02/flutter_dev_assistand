import 'package:flutter/material.dart';
import '../../domain/entities/apk_file_node.dart';
import '../../data/services/apk_analyzer_service.dart';

class ApkProvider extends ChangeNotifier {
  final ApkAnalyzerService _analyzerService;
  
  ApkFileNode? _rootNode;
  List<ApkFileNode> _largestFiles = [];
  List<String> _recommendations = [];
  bool _isAnalyzing = false;
  String? _errorMessage;

  ApkProvider(this._analyzerService);

  ApkFileNode? get rootNode => _rootNode;
  List<ApkFileNode> get largestFiles => _largestFiles;
  List<String> get recommendations => _recommendations;
  bool get isAnalyzing => _isAnalyzing;
  String? get errorMessage => _errorMessage;

  Future<void> analyzeApk(String filePath) async {
    _isAnalyzing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _analyzerService.analyzeApk(filePath);
      _rootNode = result.root;
      _largestFiles = result.largestFiles;
      _recommendations = result.recommendations;
    } catch (e) {
      _errorMessage = 'Failed to analyze APK: $e';
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  void clear() {
    _rootNode = null;
    _largestFiles = [];
    _recommendations = [];
    _errorMessage = null;
    notifyListeners();
  }
}
