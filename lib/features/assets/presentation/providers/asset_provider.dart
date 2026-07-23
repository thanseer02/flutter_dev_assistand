import 'dart:io';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import '../../domain/entities/asset_scan_result.dart';
import '../../domain/entities/asset_issue.dart';
import '../../data/services/asset_scanner_service.dart';

class AssetProvider extends ChangeNotifier {
  final AssetScannerService _scannerService;
  
  AssetScanResult? _lastResult;
  bool _isScanning = false;
  String? _errorMessage;

  AssetProvider(this._scannerService);

  AssetScanResult? get lastResult => _lastResult;
  bool get isScanning => _isScanning;
  String? get errorMessage => _errorMessage;

  Future<void> scanAssets(String projectPath) async {
    _isScanning = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _lastResult = await _scannerService.scanAssets(projectPath);
    } catch (e) {
      _errorMessage = 'Asset scan failed: $e';
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<bool> deleteAsset(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        // Remove from current result
        if (_lastResult != null) {
          _lastResult!.unusedAssets.removeWhere((i) => i.path == path);
          _lastResult!.duplicateAssets.removeWhere((i) => i.path == path);
          _lastResult!.largeAssets.removeWhere((i) => i.path == path);
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<String?> exportReport(String saveDirectory) async {
    if (_lastResult == null) return null;

    try {
      final List<List<String>> rows = [
        ['Type', 'Path', 'Size (Bytes)', 'Details']
      ];

      for (final issue in _lastResult!.allIssues) {
        rows.add([
          issue.type.name,
          issue.path,
          issue.sizeInBytes.toString(),
          issue.description ?? '',
        ]);
      }

      final csvData = const ListToCsvConverter().convert(rows);
      final file = File('$saveDirectory/asset_report.csv');
      await file.writeAsString(csvData);
      return file.path;
    } catch (e) {
      return null;
    }
  }

  void clearResult() {
    _lastResult = null;
    _errorMessage = null;
    notifyListeners();
  }
}
