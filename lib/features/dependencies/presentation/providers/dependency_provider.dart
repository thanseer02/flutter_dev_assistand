import 'dart:io';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import '../../domain/entities/package_info.dart';
import '../../data/services/pubspec_analyzer_service.dart';

class DependencyProvider extends ChangeNotifier {
  final PubspecAnalyzerService _analyzerService;
  
  List<PackageInfo> _packages = [];
  bool _isAnalyzing = false;
  String? _errorMessage;

  DependencyProvider(this._analyzerService);

  List<PackageInfo> get packages => _packages;
  bool get isAnalyzing => _isAnalyzing;
  String? get errorMessage => _errorMessage;

  Future<void> analyzeProject(String projectPath) async {
    _isAnalyzing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _packages = await _analyzerService.analyze(projectPath);
    } catch (e) {
      _errorMessage = 'Analysis failed: $e';
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  Future<String?> exportReport(String saveDirectory) async {
    if (_packages.isEmpty) return null;

    try {
      final List<List<String>> rows = [
        ['Package', 'Current Version', 'Latest Version', 'Type', 'Risk Level', 'Issues', 'Description']
      ];

      for (final pkg in _packages) {
        String type = pkg.isDevDependency ? 'Dev' : 'Regular';
        if (pkg.isGit) type += ' (Git)';
        if (pkg.isLocal) type += ' (Local)';

        List<String> issues = [];
        if (pkg.isDiscontinued) issues.add('Discontinued');
        if (pkg.isUnused) issues.add('Unused');
        if (pkg.riskLevel == RiskLevel.high && !pkg.isDiscontinued && !pkg.isUnused) {
          issues.add('Outdated (Major)');
        }

        rows.add([
          pkg.name,
          pkg.currentVersion,
          pkg.latestVersion ?? 'Unknown',
          type,
          pkg.riskLevel.name.toUpperCase(),
          issues.join(', '),
          pkg.description ?? '',
        ]);
      }

      final csvData = const ListToCsvConverter().convert(rows);
      final file = File('$saveDirectory/dependency_report.csv');
      await file.writeAsString(csvData);
      return file.path;
    } catch (e) {
      return null;
    }
  }

  void clearData() {
    _packages = [];
    _errorMessage = null;
    notifyListeners();
  }
}
