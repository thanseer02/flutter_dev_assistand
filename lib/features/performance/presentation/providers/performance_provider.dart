import 'package:flutter/material.dart';
import '../../domain/entities/performance_issue.dart';
import '../../data/services/performance_analyzer_service.dart';

class PerformanceProvider extends ChangeNotifier {
  final PerformanceAnalyzerService _analyzerService;
  
  List<PerformanceIssue> _issues = [];
  bool _isAnalyzing = false;
  String? _errorMessage;

  PerformanceProvider(this._analyzerService);

  List<PerformanceIssue> get issues => _issues;
  bool get isAnalyzing => _isAnalyzing;
  String? get errorMessage => _errorMessage;

  int get performanceScore {
    if (_issues.isEmpty) return 100;
    
    // Deduct points based on severity of issues
    int penalty = 0;
    for (final issue in _issues) {
      switch (issue.type) {
        case PerformanceIssueType.memoryRisk: penalty += 15; break;
        case PerformanceIssueType.expensiveBuild: penalty += 10; break;
        case PerformanceIssueType.largeList: penalty += 5; break;
        case PerformanceIssueType.nestedWidget: penalty += 2; break;
        case PerformanceIssueType.largeWidget: penalty += 3; break;
        case PerformanceIssueType.missingConst: penalty += 1; break;
        case PerformanceIssueType.largeImage: penalty += 10; break;
      }
    }
    
    final score = 100 - penalty;
    return score < 0 ? 0 : score;
  }

  Future<void> analyzePerformance(String projectPath) async {
    _isAnalyzing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _issues = await _analyzerService.analyzePerformance(projectPath);
    } catch (e) {
      _errorMessage = 'Performance Analysis failed: $e';
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  void clearData() {
    _issues = [];
    _errorMessage = null;
    notifyListeners();
  }
}
