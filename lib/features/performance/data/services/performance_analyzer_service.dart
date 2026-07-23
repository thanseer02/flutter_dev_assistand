import 'dart:io';
import 'dart:convert';
import 'dart:isolate';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import '../../domain/entities/performance_issue.dart';

class PerformanceAnalyzerService {
  Future<List<PerformanceIssue>> analyzePerformance(String projectPath) async {
    return await Isolate.run(() => _performAnalysis(projectPath));
  }

  static Future<List<PerformanceIssue>> _performAnalysis(String projectPath) async {
    final issues = <PerformanceIssue>[];
    
    // 1. Linter Analysis (Missing Const)
    issues.addAll(await _runLinter(projectPath));
    
    // 2. AST Analysis
    final libDir = Directory('$projectPath/lib');
    if (libDir.existsSync()) {
      final dartFiles = libDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
      for (final file in dartFiles) {
        try {
          final content = file.readAsStringSync();
          final parseResult = parseString(content: content, throwIfDiagnostics: false);
          final relativePath = file.path.replaceFirst('$projectPath/', '');
          
          final visitor = _PerformanceAstVisitor(relativePath, issues);
          parseResult.unit.accept(visitor);
        } catch (_) {}
      }
    }
    
    // 3. Asset Analysis (Large Images)
    final assetsDir = Directory('$projectPath/assets');
    if (assetsDir.existsSync()) {
      final imageFiles = assetsDir.listSync(recursive: true).whereType<File>().where((f) {
        final path = f.path.toLowerCase();
        return path.endsWith('.png') || path.endsWith('.jpg') || path.endsWith('.jpeg');
      });
      
      for (final file in imageFiles) {
        final size = file.lengthSync();
        if (size > 1024 * 1024) { // > 1MB
          issues.add(PerformanceIssue(
            type: PerformanceIssueType.largeImage,
            location: file.path.replaceFirst('$projectPath/', ''),
            description: 'Large image file detected (${(size/1024/1024).toStringAsFixed(2)} MB).',
            optimizationSuggestion: 'Compress this image or use a different format (like WebP) to reduce memory usage during decoding.',
          ));
        }
      }
    }

    return issues;
  }

  static Future<List<PerformanceIssue>> _runLinter(String projectPath) async {
    final issues = <PerformanceIssue>[];
    try {
      final result = await Process.run('dart', ['analyze', '--format=json'], workingDirectory: projectPath);
      final output = result.stdout.toString();
      
      final startIndex = output.indexOf('{');
      if (startIndex != -1) {
        final jsonStr = output.substring(startIndex);
        final data = json.decode(jsonStr);
        final diagnostics = data['diagnostics'] as List<dynamic>?;
        if (diagnostics != null) {
          for (final diag in diagnostics) {
            final code = diag['code'];
            if (code == 'prefer_const_constructors' || code == 'prefer_const_literals_to_create_immutables') {
              final location = diag['location'];
              final file = location['file'] as String;
              final line = location['range']['start']['line'];
              
              issues.add(PerformanceIssue(
                type: PerformanceIssueType.missingConst,
                location: '${file.split('/').last}:$line',
                description: 'Missing const keyword.',
                optimizationSuggestion: 'Add the const modifier to reduce GC overhead and prevent unnecessary rebuilds.',
              ));
            }
          }
        }
      }
    } catch (_) {}
    return issues;
  }
}

class _PerformanceAstVisitor extends RecursiveAstVisitor<void> {
  final String filePath;
  final List<PerformanceIssue> issues;
  
  // Track State classes to detect missing disposes
  String? currentClass;
  Set<String> initializedControllers = {};
  bool hasDisposeMethod = false;

  _PerformanceAstVisitor(this.filePath, this.issues);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    currentClass = node.name.lexeme;
    initializedControllers.clear();
    hasDisposeMethod = false;
    
    super.visitClassDeclaration(node);
    
    if (initializedControllers.isNotEmpty && !hasDisposeMethod) {
      issues.add(PerformanceIssue(
        type: PerformanceIssueType.memoryRisk,
        location: '$filePath:${node.name.offset}',
        description: 'State class $currentClass initializes controllers but lacks a dispose method.',
        optimizationSuggestion: 'Override dispose() and properly call dispose on all AnimationControllers, ScrollControllers, etc., to prevent memory leaks.',
      ));
    }
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.lexeme == 'dispose') {
      hasDisposeMethod = true;
    }
    
    if (node.name.lexeme == 'build') {
      // 1. Large Widgets
      final body = node.body.toSource();
      final lineCount = body.split('\n').length;
      if (lineCount > 100) {
        issues.add(PerformanceIssue(
          type: PerformanceIssueType.largeWidget,
          location: '$filePath:${node.name.offset}',
          description: 'Build method exceeds 100 lines ($lineCount lines).',
          optimizationSuggestion: 'Extract sub-trees into separate StatelessWidget classes to limit rebuild scopes and improve readability.',
        ));
      }
      
      // 2. Expensive Builds (Loops inside build)
      if (body.contains('for (') || body.contains('while (')) {
        issues.add(PerformanceIssue(
          type: PerformanceIssueType.expensiveBuild,
          location: '$filePath:${node.name.offset}',
          description: 'Loop detected directly inside build method.',
          optimizationSuggestion: 'Move heavy computation outside of build() or cache the results. Build methods must be fast.',
        ));
      }
    }
    
    super.visitMethodDeclaration(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    // Detect controller initialization
    final typeStr = node.parent?.parent?.toSource() ?? '';
    if (typeStr.contains('Controller(')) {
      initializedControllers.add(node.name.lexeme);
    }
    
    super.visitVariableDeclaration(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final typeName = node.constructorName.type.name2.lexeme;
    
    // 3. Large Lists / Non-Builder ListViews
    if (typeName == 'ListView' && node.constructorName.name == null) {
      issues.add(PerformanceIssue(
        type: PerformanceIssueType.largeList,
        location: '$filePath:${node.offset}',
        description: 'Using ListView without a builder.',
        optimizationSuggestion: 'Use ListView.builder() for long or infinite lists to ensure items are built lazily on demand.',
      ));
    }
    
    // 4. Nested Widgets
    int depth = 0;
    AstNode? current = node;
    while (current != null) {
      if (current is InstanceCreationExpression) {
        depth++;
      }
      current = current.parent;
    }
    if (depth > 8) {
       // Just flag it once per deep tree by checking if parent is already deep, we don't need to spam.
       // A simple approach is just checking if it's exactly depth 9.
       if (depth == 9) {
         issues.add(PerformanceIssue(
          type: PerformanceIssueType.nestedWidget,
          location: '$filePath:${node.offset}',
          description: 'Deeply nested widget tree (depth > 8).',
          optimizationSuggestion: 'Refactor into separate widgets to reduce the depth of the element tree and improve layout performance.',
        ));
       }
    }
    
    super.visitInstanceCreationExpression(node);
  }
}
