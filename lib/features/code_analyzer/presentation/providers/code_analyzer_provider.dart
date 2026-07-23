import 'package:flutter/material.dart';
import '../../domain/entities/analyzer_result.dart';
import '../../data/services/code_analyzer_service.dart';

class CodeAnalyzerProvider extends ChangeNotifier {
  final CodeAnalyzerService _analyzerService;
  
  AnalyzerResult? _result;
  bool _isAnalyzing = false;
  String? _errorMessage;

  CodeAnalyzerProvider(this._analyzerService);

  AnalyzerResult? get result => _result;
  bool get isAnalyzing => _isAnalyzing;
  String? get errorMessage => _errorMessage;

  Future<void> analyzeCode(String projectPath) async {
    _isAnalyzing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _result = await _analyzerService.analyzeCode(projectPath);
    } catch (e) {
      _errorMessage = 'Code Analysis failed: $e';
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  void clearData() {
    _result = null;
    _errorMessage = null;
    notifyListeners();
  }
}
