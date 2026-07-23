import 'dart:io';
import 'dart:isolate';
import 'package:archive/archive.dart';
import '../../domain/entities/apk_file_node.dart';

class ApkAnalyzerResult {
  final ApkFileNode root;
  final List<ApkFileNode> largestFiles;
  final List<String> recommendations;

  ApkAnalyzerResult({
    required this.root,
    required this.largestFiles,
    required this.recommendations,
  });
}

class ApkAnalyzerService {
  Future<ApkAnalyzerResult> analyzeApk(String filePath) async {
    return await Isolate.run(() => _performAnalysis(filePath));
  }

  static ApkAnalyzerResult _performAnalysis(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) throw Exception('File not found');

    final bytes = file.readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(bytes, verify: false);

    // Flat list of files for top 10
    final allFiles = <ApkFileNode>[];
    
    // Directory structure for treemap
    final rootDir = _MutableDirNode(name: 'root', path: '/');

    for (final file in archive) {
      if (file.isFile) {
        final path = file.name;
        final size = file.size; // uncompressed size
        final category = _categorizeFile(path);
        
        final node = ApkFileNode(
          path: path,
          name: path.split('/').last,
          sizeBytes: size,
          category: category,
        );
        
        allFiles.add(node);
        _insertIntoTree(rootDir, path, node);
      }
    }

    // Sort for top 10
    allFiles.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
    final top10 = allFiles.take(10).toList();

    // Convert mutable tree to immutable ApkFileNode tree
    final rootNode = _convertToImmutableNode(rootDir);
    
    // Generate recommendations
    final recommendations = _generateRecommendations(allFiles);

    return ApkAnalyzerResult(
      root: rootNode,
      largestFiles: top10,
      recommendations: recommendations,
    );
  }

  static ApkFileCategory _categorizeFile(String path) {
    path = path.toLowerCase();
    if (path.startsWith('lib/') && path.endsWith('.so')) {
      if (path.contains('libapp.so') || path.contains('libflutter.so')) {
        return ApkFileCategory.dartCode; // App or engine
      }
      return ApkFileCategory.nativeLibrary;
    }
    if (path.contains('flutter_assets/fonts/')) return ApkFileCategory.font;
    if (path.contains('flutter_assets/')) {
      if (path.endsWith('.png') || path.endsWith('.jpg') || path.endsWith('.jpeg') || path.endsWith('.webp')) {
        return ApkFileCategory.image;
      }
      return ApkFileCategory.other;
    }
    if (path.startsWith('res/')) return ApkFileCategory.resource;
    if (path == 'classes.dex') return ApkFileCategory.plugin; // Contains plugin code
    
    return ApkFileCategory.other;
  }

  static void _insertIntoTree(_MutableDirNode root, String path, ApkFileNode fileNode) {
    final parts = path.split('/');
    _MutableDirNode current = root;

    for (int i = 0; i < parts.length - 1; i++) {
      final part = parts[i];
      if (!current.children.containsKey(part)) {
        current.children[part] = _MutableDirNode(name: part, path: parts.sublist(0, i + 1).join('/'));
      }
      current = current.children[part] as _MutableDirNode;
    }

    current.files.add(fileNode);
  }

  static ApkFileNode _convertToImmutableNode(_MutableDirNode dir) {
    int totalSize = 0;
    final children = <ApkFileNode>[];

    for (final childDir in dir.children.values) {
      final childNode = _convertToImmutableNode(childDir as _MutableDirNode);
      if (childNode.sizeBytes > 0) {
        children.add(childNode);
        totalSize += childNode.sizeBytes;
      }
    }

    for (final file in dir.files) {
      children.add(file);
      totalSize += file.sizeBytes;
    }

    // Sort children by size descending for better treemap layout
    children.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));

    return ApkFileNode(
      path: dir.path,
      name: dir.name,
      sizeBytes: totalSize,
      category: ApkFileCategory.other,
      children: children,
    );
  }

  static List<String> _generateRecommendations(List<ApkFileNode> files) {
    final recs = <String>[];
    
    bool hasX86 = files.any((f) => f.path.contains('x86'));
    if (hasX86) {
      recs.add('Consider building an Android App Bundle (.aab) instead of a fat APK to strip unused native architectures like x86.');
    }

    final largeImages = files.where((f) => f.category == ApkFileCategory.image && f.sizeBytes > 500 * 1024).toList();
    if (largeImages.isNotEmpty) {
      recs.add('Found ${largeImages.length} images larger than 500KB. Consider converting them to WebP format.');
    }

    final largeFonts = files.where((f) => f.category == ApkFileCategory.font && f.sizeBytes > 1024 * 1024).toList();
    if (largeFonts.isNotEmpty) {
      recs.add('Found ${largeFonts.length} massive font files. Consider subsetting your fonts to only include the glyphs you use.');
    }

    return recs;
  }
}

class _MutableDirNode {
  final String name;
  final String path;
  final Map<String, dynamic> children = {};
  final List<ApkFileNode> files = [];

  _MutableDirNode({required this.name, required this.path});
}
