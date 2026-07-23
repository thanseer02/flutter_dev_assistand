import 'dart:io';
import 'dart:isolate';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import '../../domain/entities/analyzer_result.dart';

class CodeAnalyzerService {
  Future<AnalyzerResult> analyzeCode(String projectPath) async {
    return await Isolate.run(() => _performAnalysis(projectPath));
  }

  static Future<AnalyzerResult> _performAnalysis(String projectPath) async {
    final libDir = Directory('$projectPath/lib');
    if (!libDir.existsSync()) return const AnalyzerResult();

    final dartFiles = libDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

    final Map<String, List<String>> methodBodies = {};
    final Map<String, List<String>> widgetBodies = {};
    final Map<String, List<String>> stringLiterals = {};
    int totalNodes = 0;
    int duplicatedNodes = 0;

    for (final file in dartFiles) {
      try {
        final content = file.readAsStringSync();
        final parseResult = parseString(content: content, throwIfDiagnostics: false);
        final unit = parseResult.unit;
        
        final relativePath = file.path.replaceFirst('$projectPath/', '');
        
        final visitor = _DuplicateVisitor(relativePath, methodBodies, widgetBodies, stringLiterals);
        unit.accept(visitor);
        
        totalNodes += visitor.nodeCount;
      } catch (_) {}
    }

    // Process maps to find duplicates
    final List<DuplicateIssue> methods = [];
    final List<DuplicateIssue> widgets = [];
    final List<DuplicateIssue> strings = [];

    // Arbitrary threshold for strings to be considered "spammy" duplicates
    stringLiterals.forEach((snippet, locations) {
      if (locations.length >= 3 && snippet.length > 5) { // At least 3 times, longer than 5 chars
        strings.add(DuplicateIssue(
          type: DuplicateType.string,
          snippet: snippet,
          locations: locations,
          suggestion: 'Extract to a constant or l10n file.',
        ));
        duplicatedNodes += locations.length;
      }
    });

    methodBodies.forEach((snippet, locations) {
      if (locations.length >= 2) { // At least 2 times
        methods.add(DuplicateIssue(
          type: DuplicateType.method,
          snippet: snippet,
          locations: locations,
          suggestion: 'Extract to a shared utility or mixin.',
        ));
        // A method is considered a larger chunk of duplicated nodes (e.g. 10 nodes)
        duplicatedNodes += (locations.length * 10);
      }
    });

    widgetBodies.forEach((snippet, locations) {
      if (locations.length >= 2) {
        widgets.add(DuplicateIssue(
          type: DuplicateType.widget,
          snippet: snippet,
          locations: locations,
          suggestion: 'Extract to a reusable custom Widget.',
        ));
        duplicatedNodes += (locations.length * 20); // Widgets are even larger
      }
    });

    double percentage = 0.0;
    if (totalNodes > 0) {
      percentage = (duplicatedNodes / totalNodes) * 100;
      if (percentage > 100) percentage = 100; // Cap at 100
    }

    // Sort by location count descending
    methods.sort((a, b) => b.locations.length.compareTo(a.locations.length));
    widgets.sort((a, b) => b.locations.length.compareTo(a.locations.length));
    strings.sort((a, b) => b.locations.length.compareTo(a.locations.length));

    return AnalyzerResult(
      methods: methods,
      widgets: widgets,
      strings: strings,
      duplicatePercentage: percentage,
    );
  }
}

class _DuplicateVisitor extends RecursiveAstVisitor<void> {
  final String filePath;
  final Map<String, List<String>> methodBodies;
  final Map<String, List<String>> widgetBodies;
  final Map<String, List<String>> stringLiterals;
  int nodeCount = 0;

  _DuplicateVisitor(this.filePath, this.methodBodies, this.widgetBodies, this.stringLiterals);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    nodeCount++;
    
    // Check if it's a build method
    if (node.name.lexeme == 'build' && node.parameters?.parameters.length == 1) {
      final bodyStr = _normalizeSyntax(node.body.toSource());
      if (bodyStr.length > 50) { // Only care about substantial widgets
        final location = '$filePath:${node.name.offset}';
        widgetBodies.putIfAbsent(bodyStr, () => []).add(location);
      }
    } else {
      // Normal method
      final bodyStr = _normalizeSyntax(node.body.toSource());
      if (bodyStr.length > 50) { // Only care about substantial methods
        final location = '$filePath:${node.name.offset}';
        methodBodies.putIfAbsent(bodyStr, () => []).add(location);
      }
    }
    
    super.visitMethodDeclaration(node);
  }
  
  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    nodeCount++;
    final bodyStr = _normalizeSyntax(node.functionExpression.body.toSource());
    if (bodyStr.length > 50) {
      final location = '$filePath:${node.name.offset}';
      methodBodies.putIfAbsent(bodyStr, () => []).add(location);
    }
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitStringLiteral(StringLiteral node) {
    nodeCount++;
    final val = node.stringValue;
    if (val != null && val.isNotEmpty) {
      final location = '$filePath:${node.offset}';
      stringLiterals.putIfAbsent(val, () => []).add(location);
    }
    super.visitStringLiteral(node);
  }

  String _normalizeSyntax(String source) {
    // Remove whitespace and comments to compare structural equality roughly
    return source.replaceAll(RegExp(r'\s+'), '').replaceAll(RegExp(r'//.*'), '');
  }
}
