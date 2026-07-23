import 'dart:io';
import 'dart:isolate';
import 'package:crypto/crypto.dart';
import '../../domain/entities/asset_issue.dart';
import '../../domain/entities/asset_scan_result.dart';

class AssetScannerService {
  Future<AssetScanResult> scanAssets(String projectPath) async {
    return await Isolate.run(() => _performScan(projectPath));
  }

  static Future<AssetScanResult> _performScan(String projectPath) async {
    final List<AssetIssue> unusedAssets = [];
    final List<AssetIssue> duplicateAssets = [];
    final List<AssetIssue> largeAssets = [];
    final List<AssetIssue> missingAssets = [];
    final List<AssetIssue> emptyFolders = [];

    int potentialSavingsBytes = 0;
    int totalAssetsScanned = 0;

    final rootDir = Directory(projectPath);
    if (!rootDir.existsSync()) {
      return const AssetScanResult(
        unusedAssets: [], duplicateAssets: [], largeAssets: [],
        missingAssets: [], emptyFolders: [], potentialSavingsBytes: 0,
        totalAssetsScanned: 0,
      );
    }

    // 1. Find all asset files
    final List<File> allImages = [];
    final Set<String> allAssetPaths = {}; // Relative to project root
    
    // Scan common asset directories
    final assetDirs = ['assets', 'images', 'icons'];
    for (final dirName in assetDirs) {
      final dir = Directory('${rootDir.path}/$dirName');
      if (dir.existsSync()) {
        final entities = dir.listSync(recursive: true, followLinks: false);
        bool hasFiles = false;

        for (final entity in entities) {
          if (entity is File) {
            hasFiles = true;
            final ext = entity.path.split('.').last.toLowerCase();
            if (['png', 'jpg', 'jpeg', 'svg', 'webp', 'gif'].contains(ext)) {
              allImages.add(entity);
              // Normalize path for matching (e.g. assets/images/logo.png)
              final relPath = entity.path.replaceFirst('${rootDir.path}/', '');
              allAssetPaths.add(relPath);
              totalAssetsScanned++;

              // Check for large assets (> 500KB)
              final size = entity.lengthSync();
              if (size > 500 * 1024) {
                largeAssets.add(AssetIssue(
                  type: AssetIssueType.large,
                  path: entity.path,
                  sizeInBytes: size,
                  description: 'Large image (${(size / 1024).toStringAsFixed(1)} KB)',
                ));
              }
            }
          }
        }

        // Check if directory is empty
        if (!hasFiles && dir.listSync().isEmpty) {
          emptyFolders.add(AssetIssue(
            type: AssetIssueType.emptyFolder,
            path: dir.path,
          ));
        }
      }
    }

    // 2. Find duplicates via hashing
    final Map<String, String> hashes = {};
    for (final file in allImages) {
      try {
        final bytes = file.readAsBytesSync();
        final hash = md5.convert(bytes).toString();
        
        if (hashes.containsKey(hash)) {
          final originalPath = hashes[hash]!;
          final size = bytes.length;
          duplicateAssets.add(AssetIssue(
            type: AssetIssueType.duplicate,
            path: file.path,
            secondaryPath: originalPath,
            sizeInBytes: size,
            description: 'Duplicate of ${originalPath.split('/').last}',
          ));
          potentialSavingsBytes += size;
        } else {
          hashes[hash] = file.path;
        }
      } catch (_) {}
    }

    // 3. Find usages in .dart files
    final Set<String> foundReferences = {};
    final libDir = Directory('${rootDir.path}/lib');
    if (libDir.existsSync()) {
      final dartFiles = libDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
      
      // Simple regex to find string literals that look like asset paths
      final regex = RegExp(r"['""]((?:assets|images|icons)/[^'""]+\.[a-zA-Z0-9]+)['""]");

      for (final file in dartFiles) {
        try {
          final content = file.readAsStringSync();
          final matches = regex.allMatches(content);
          for (final match in matches) {
            final ref = match.group(1);
            if (ref != null) {
              foundReferences.add(ref);
              
              // Check if missing
              if (!allAssetPaths.contains(ref)) {
                missingAssets.add(AssetIssue(
                  type: AssetIssueType.missing,
                  path: ref,
                  secondaryPath: file.path,
                  description: 'Referenced in ${file.path.split('/').last}',
                ));
              }
            }
          }
        } catch (_) {}
      }
    }

    // 4. Determine unused assets
    for (final assetPath in allAssetPaths) {
      if (!foundReferences.contains(assetPath)) {
        final fullPath = '${rootDir.path}/$assetPath';
        try {
          final size = File(fullPath).lengthSync();
          
          // Don't flag as unused if it's already flagged as a duplicate to avoid double counting savings
          bool isDuplicate = duplicateAssets.any((d) => d.path == fullPath);
          
          unusedAssets.add(AssetIssue(
            type: AssetIssueType.unused,
            path: fullPath,
            sizeInBytes: size,
          ));

          if (!isDuplicate) {
            potentialSavingsBytes += size;
          }
        } catch (_) {}
      }
    }

    return AssetScanResult(
      unusedAssets: unusedAssets,
      duplicateAssets: duplicateAssets,
      largeAssets: largeAssets,
      missingAssets: missingAssets,
      emptyFolders: emptyFolders,
      potentialSavingsBytes: potentialSavingsBytes,
      totalAssetsScanned: totalAssetsScanned,
    );
  }
}
