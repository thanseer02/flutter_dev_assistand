import 'dart:io';
import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import '../../domain/entities/import_analysis.dart';

class ImportAnalyzerService {
  Future<ImportAnalysis> analyzeImports(String projectPath) async {
    return await Isolate.run(() => _performAnalysis(projectPath));
  }

  static Future<ImportAnalysis> _performAnalysis(String projectPath) async {
    final libDir = Directory('$projectPath/lib');
    if (!libDir.existsSync()) return const ImportAnalysis(graph: {});

    final dartFiles = libDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
    
    final Map<String, ImportNode> graph = {};
    
    // 1. Build Graph
    final importRegex = RegExp(r"import\s+['""]([^'""]+)['""]");
    
    for (final file in dartFiles) {
      final relativePath = file.path.replaceFirst('${libDir.path}/', '');
      final currentDir = file.parent.path.replaceFirst('${libDir.path}', '');
      
      final content = file.readAsStringSync();
      final matches = importRegex.allMatches(content);
      
      final List<String> dependencies = [];
      
      for (final match in matches) {
        final importPath = match.group(1);
        if (importPath != null) {
          // We only care about internal project imports for the graph
          if (importPath.startsWith('package:')) {
            // Check if it's our own package
            // A simple heuristic: if it contains the project name, or we can just ignore package imports 
            // and focus on relative imports for internal dependency graphing, 
            // but many projects use package:my_app/... for internal imports.
            // For now, we will track relative imports mainly, or try to normalize package imports if we knew the package name.
            // To be safe, we will just track relative imports for the internal graph.
            continue;
          }
          if (importPath.startsWith('dart:')) continue;
          
          // Normalize relative path
          // E.g., import '../models/user.dart';
          String normalized = _normalizeRelativePath(currentDir, importPath);
          if (normalized.startsWith('/')) normalized = normalized.substring(1);
          
          dependencies.add(normalized);
        }
      }
      
      graph[relativePath] = ImportNode(path: relativePath, dependencies: dependencies);
    }

    // 2. Find Circular Dependencies (Simple DFS)
    final List<List<String>> cycles = _findCycles(graph);
    
    // 3. Find Max Chain Depth
    int maxDepth = _calculateMaxDepth(graph);
    
    // 4. Run `dart analyze` to find unused imports
    final List<String> unusedImports = await _findUnusedImports(projectPath);

    // 5. Layout Graph (Simple Force Directed / Circle layout logic)
    _applyCircleLayout(graph);

    return ImportAnalysis(
      graph: graph,
      circularDependencies: cycles,
      unusedImports: unusedImports,
      maxChainDepth: maxDepth,
    );
  }
  
  static String _normalizeRelativePath(String currentDir, String importPath) {
    if (!importPath.startsWith('.')) return importPath; // Not relative
    
    List<String> currentParts = currentDir.split('/').where((p) => p.isNotEmpty).toList();
    List<String> importParts = importPath.split('/');
    
    for (String part in importParts) {
      if (part == '..') {
        if (currentParts.isNotEmpty) currentParts.removeLast();
      } else if (part != '.') {
        currentParts.add(part);
      }
    }
    
    return currentParts.join('/');
  }

  static List<List<String>> _findCycles(Map<String, ImportNode> graph) {
    List<List<String>> cycles = [];
    Set<String> visited = {};
    Set<String> recursionStack = {};
    List<String> path = [];

    void dfs(String node) {
      if (recursionStack.contains(node)) {
        // Cycle found
        int idx = path.indexOf(node);
        if (idx != -1) {
          cycles.add(path.sublist(idx)..add(node));
        }
        return;
      }
      if (visited.contains(node)) return;

      visited.add(node);
      recursionStack.add(node);
      path.add(node);

      final neighbors = graph[node]?.dependencies ?? [];
      for (final neighbor in neighbors) {
        if (graph.containsKey(neighbor)) {
          dfs(neighbor);
        }
      }

      recursionStack.remove(node);
      path.removeLast();
    }

    for (final node in graph.keys) {
      if (!visited.contains(node)) {
        dfs(node);
      }
    }
    
    // Deduplicate cycles roughly
    final uniqueCycles = <String, List<String>>{};
    for (var cycle in cycles) {
      var sorted = List<String>.from(cycle)..sort();
      uniqueCycles[sorted.join(',')] = cycle;
    }

    return uniqueCycles.values.toList();
  }

  static int _calculateMaxDepth(Map<String, ImportNode> graph) {
    int maxDepth = 0;
    Map<String, int> memo = {};

    int dfsDepth(String node, Set<String> visiting) {
      if (visiting.contains(node)) return 0; // Cycle, break
      if (memo.containsKey(node)) return memo[node]!;

      visiting.add(node);
      int depth = 0;
      for (final neighbor in graph[node]?.dependencies ?? []) {
        if (graph.containsKey(neighbor)) {
          depth = max(depth, dfsDepth(neighbor, visiting));
        }
      }
      visiting.remove(node);
      
      memo[node] = depth + 1;
      return depth + 1;
    }

    for (final node in graph.keys) {
      maxDepth = max(maxDepth, dfsDepth(node, {}));
    }
    return maxDepth;
  }

  static Future<List<String>> _findUnusedImports(String projectPath) async {
    final List<String> unused = [];
    try {
      final result = await Process.run('dart', ['analyze', '--format=json'], workingDirectory: projectPath);
      // dart analyze returns exit code 1 if issues found, but output is still valid json on stdout
      final output = result.stdout.toString();
      
      // Parse the JSON output (format: {"version":1,"diagnostics":[{...}]})
      final startIndex = output.indexOf('{');
      if (startIndex != -1) {
        final jsonStr = output.substring(startIndex);
        final data = json.decode(jsonStr);
        final diagnostics = data['diagnostics'] as List<dynamic>?;
        if (diagnostics != null) {
          for (final diag in diagnostics) {
            if (diag['code'] == 'unused_import' || diag['code'] == 'duplicate_import') {
              final location = diag['location'];
              final file = location['file'] as String;
              final msg = diag['problemMessage'] as String;
              unused.add('$msg in ${file.split('/').last}');
            }
          }
        }
      }
    } catch (_) {}
    return unused;
  }

  static void _applyCircleLayout(Map<String, ImportNode> graph) {
    final nodes = graph.values.toList();
    if (nodes.isEmpty) return;

    final double radius = max(200.0, nodes.length * 15.0);
    final double center = radius + 50.0;
    final double angleStep = (2 * pi) / nodes.length;

    for (int i = 0; i < nodes.length; i++) {
      nodes[i].x = center + radius * cos(i * angleStep);
      nodes[i].y = center + radius * sin(i * angleStep);
    }
  }
}
