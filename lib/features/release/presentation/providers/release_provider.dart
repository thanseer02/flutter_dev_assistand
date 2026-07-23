import 'package:flutter/material.dart';
import '../../domain/entities/release_check.dart';
import '../../data/services/release_analyzer_service.dart';
import '../../data/services/pdf_export_service.dart';

class ReleaseProvider extends ChangeNotifier {
  final ReleaseAnalyzerService _analyzerService;
  final PdfExportService _pdfService;
  
  List<ReleaseCheck> _checks = [];
  bool _isAnalyzing = false;
  String? _errorMessage;

  ReleaseProvider(this._analyzerService, this._pdfService);

  List<ReleaseCheck> get checks => _checks;
  bool get isAnalyzing => _isAnalyzing;
  String? get errorMessage => _errorMessage;

  int get releaseScore {
    if (_checks.isEmpty) return 0;
    
    int score = 100;
    for (final check in _checks) {
      if (check.status == ReleaseCheckStatus.fail) score -= 20;
      else if (check.status == ReleaseCheckStatus.warning) score -= 5;
    }
    
    return score < 0 ? 0 : score;
  }

  Future<void> analyzeRelease(String projectPath) async {
    _isAnalyzing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _checks = await _analyzerService.analyzeRelease(projectPath);
    } catch (e) {
      _errorMessage = 'Release Analysis failed: $e';
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  Future<void> exportReport(String projectName, String savePath) async {
    if (_checks.isEmpty) return;
    try {
      await _pdfService.exportReport(projectName, releaseScore, _checks, savePath);
    } catch (e) {
      _errorMessage = 'Failed to export PDF: $e';
      notifyListeners();
    }
  }
}
