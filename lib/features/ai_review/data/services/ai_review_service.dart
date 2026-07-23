import 'dart:io';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../domain/entities/ai_review_issue.dart';

class AiReviewService {
  Future<List<AiReviewIssue>> analyzeFiles(List<String> filePaths, String apiKey) async {
    if (apiKey.isEmpty) throw Exception('API Key is missing');
    if (filePaths.isEmpty) return [];

    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.2, // Low temperature for more deterministic, analytical responses
      ),
    );

    // Read all files
    final Map<String, String> filesContent = {};
    for (final path in filePaths) {
      final file = File(path);
      if (await file.exists()) {
        filesContent[path.split('/').last] = await file.readAsString();
      }
    }

    if (filesContent.isEmpty) throw Exception('No valid files found to analyze.');

    final prompt = _buildPrompt(filesContent);

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text;
      
      if (text == null || text.isEmpty) throw Exception('Empty response from AI');
      
      final Map<String, dynamic> jsonMap = json.decode(text);
      final List<dynamic> issuesList = jsonMap['issues'] ?? [];
      
      return issuesList.map((json) => AiReviewIssue.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to communicate with AI: $e');
    }
  }

  String _buildPrompt(Map<String, String> filesContent) {
    final sb = StringBuffer();
    sb.writeln('You are an expert Flutter and Dart code reviewer.');
    sb.writeln('Review the following Dart files and provide critical feedback on:');
    sb.writeln('- Architecture & SOLID principles');
    sb.writeln('- Naming conventions & Clean Code');
    sb.writeln('- Readability & Maintainability');
    sb.writeln('- Performance bottlenecks');
    sb.writeln('- Flutter best practices');
    sb.writeln('\nHere is the source code:\n');
    
    filesContent.forEach((fileName, content) {
      sb.writeln('--- FILE: $fileName ---');
      sb.writeln(content);
      sb.writeln('-----------------------\n');
    });

    sb.writeln('You MUST respond ONLY with a valid JSON object matching the following schema. Do not include markdown formatting like ```json in the output.');
    sb.writeln('''
{
  "issues": [
    {
      "title": "Short descriptive title",
      "description": "Detailed explanation of the problem",
      "suggestion": "How to fix it",
      "severity": "low|medium|high|critical",
      "estimatedImpact": "E.g., Minor performance gain, Major readability improvement",
      "category": "architecture|naming|readability|performance|solid|cleanCode|flutterBestPractice"
    }
  ]
}
''');

    return sb.toString();
  }
}
