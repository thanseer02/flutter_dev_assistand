import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/ai_review_issue.dart';
import '../../data/services/ai_review_service.dart';

class AiReviewProvider extends ChangeNotifier {
  final AiReviewService _service;
  final SharedPreferences _prefs;
  
  List<AiReviewIssue> _issues = [];
  bool _isAnalyzing = false;
  String? _errorMessage;
  String _apiKey = '';

  AiReviewProvider(this._service, this._prefs) {
    _apiKey = _prefs.getString('gemini_api_key') ?? '';
  }

  List<AiReviewIssue> get issues => _issues;
  bool get isAnalyzing => _isAnalyzing;
  String? get errorMessage => _errorMessage;
  String get apiKey => _apiKey;
  bool get hasApiKey => _apiKey.isNotEmpty;

  Future<void> saveApiKey(String key) async {
    _apiKey = key;
    await _prefs.setString('gemini_api_key', key);
    notifyListeners();
  }

  Future<void> clearApiKey() async {
    _apiKey = '';
    await _prefs.remove('gemini_api_key');
    notifyListeners();
  }

  Future<void> reviewFiles(List<String> filePaths) async {
    if (!hasApiKey) {
      _errorMessage = 'API Key is required to run analysis.';
      notifyListeners();
      return;
    }

    _isAnalyzing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _issues = await _service.analyzeFiles(filePaths, _apiKey);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  void clearResults() {
    _issues = [];
    _errorMessage = null;
    notifyListeners();
  }
}
