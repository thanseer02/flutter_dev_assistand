class ImportNode {
  final String path;
  final List<String> dependencies;
  double x;
  double y;

  ImportNode({
    required this.path,
    required this.dependencies,
    this.x = 0,
    this.y = 0,
  });
}

class ImportAnalysis {
  final Map<String, ImportNode> graph;
  final List<List<String>> circularDependencies;
  final List<String> unusedImports;
  final int maxChainDepth;

  const ImportAnalysis({
    required this.graph,
    this.circularDependencies = const [],
    this.unusedImports = const [],
    this.maxChainDepth = 0,
  });
}
