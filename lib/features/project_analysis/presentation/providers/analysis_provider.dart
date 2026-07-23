import 'package:flutter/material.dart';
import '../../domain/entities/project_analysis.dart';
import '../../data/services/project_scanner_service.dart';

class AnalysisProvider extends ChangeNotifier {
  final ProjectScannerService _scannerService;
  
  ProjectAnalysis? _currentAnalysis;
  bool _isScanning = false;
  String? _errorMessage;

  AnalysisProvider(this._scannerService);

  ProjectAnalysis? get currentAnalysis => _currentAnalysis;
  bool get isScanning => _isScanning;
  String? get errorMessage => _errorMessage;

  Future<void> scanProject(String projectPath) async {
    _isScanning = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentAnalysis = await _scannerService.scanProject(projectPath);
    } catch (e) {
      _errorMessage = 'Scan failed: $e';
      _currentAnalysis = null;
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  void clearAnalysis() {
    _currentAnalysis = null;
    _errorMessage = null;
    notifyListeners();
  }
}
