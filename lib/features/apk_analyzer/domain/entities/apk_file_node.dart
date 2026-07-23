enum ApkFileCategory {
  nativeLibrary,
  font,
  image,
  dartCode,
  resource,
  plugin,
  other,
}

class ApkFileNode {
  final String path;
  final String name;
  final int sizeBytes;
  final ApkFileCategory category;
  final List<ApkFileNode> children;

  ApkFileNode({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.category,
    this.children = const [],
  });

  bool get isDirectory => children.isNotEmpty;
}
