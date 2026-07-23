import 'dart:io';
import 'dart:isolate';
import 'package:yaml/yaml.dart';
import '../../domain/entities/file_info.dart';
import '../../domain/entities/project_analysis.dart';

class ProjectScannerService {
  final List<String> _targetDirs = [
    'lib', 'assets', 'android', 'ios', 'test', 'web', 'windows', 'linux', 'macos'
  ];

  Future<ProjectAnalysis> scanProject(String projectPath) async {
    // Run the heavy scanning in a separate isolate to prevent UI freezes
    return await Isolate.run(() => _performScan(projectPath, _targetDirs));
  }

  // This method runs entirely on the background isolate
  static Future<ProjectAnalysis> _performScan(String projectPath, List<String> targetDirs) async {
    final Map<String, List<FileInfo>> filesByExtension = {};
    final Map<String, int> folderSizes = {};
    final List<String> folders = [];
    int totalFiles = 0;
    int totalFolders = 0;
    int totalSizeInBytes = 0;

    final rootDir = Directory(projectPath);

    if (rootDir.existsSync()) {
      for (final dirName in targetDirs) {
        final targetDir = Directory('${rootDir.path}/$dirName');
        if (targetDir.existsSync()) {
          int currentFolderSize = 0;
          final entities = targetDir.listSync(recursive: true, followLinks: false);
          
          for (final entity in entities) {
            // Ignore hidden files and folders (e.g., .git)
            if (entity.path.split('/').last.startsWith('.')) continue;

            if (entity is Directory) {
              folders.add(entity.path);
              totalFolders++;
            } else if (entity is File) {
              try {
                final stat = entity.statSync();
                final name = entity.path.split('/').last;
                final ext = name.contains('.') ? name.split('.').last : 'unknown';
                
                final fileInfo = FileInfo(
                  path: entity.path,
                  name: name,
                  extension: ext,
                  sizeInBytes: stat.size,
                  lastModified: stat.modified,
                );

                if (!filesByExtension.containsKey(ext)) {
                  filesByExtension[ext] = [];
                }
                filesByExtension[ext]!.add(fileInfo);
                
                totalFiles++;
                totalSizeInBytes += stat.size;
                currentFolderSize += stat.size;
              } catch (_) {
                // Ignore files that can't be read (permissions, etc.)
              }
            }
          }
          folderSizes[dirName] = currentFolderSize;
        }
      }
    }

    // Read YAML files
    Map<String, dynamic> pubspecMap = {};
    Map<String, dynamic> analysisOptionsMap = {};

    try {
      final pubspecFile = File('$projectPath/pubspec.yaml');
      if (pubspecFile.existsSync()) {
        final yaml = loadYaml(pubspecFile.readAsStringSync());
        pubspecMap = _convertYamlMapToDartMap(yaml);
      }
    } catch (_) {}

    try {
      final analysisFile = File('$projectPath/analysis_options.yaml');
      if (analysisFile.existsSync()) {
        final yaml = loadYaml(analysisFile.readAsStringSync());
        analysisOptionsMap = _convertYamlMapToDartMap(yaml);
      }
    } catch (_) {}

    return ProjectAnalysis(
      filesByExtension: filesByExtension,
      folderSizes: folderSizes,
      folders: folders,
      totalFiles: totalFiles,
      totalFolders: totalFolders,
      totalSizeInBytes: totalSizeInBytes,
      pubspec: pubspecMap,
      analysisOptions: analysisOptionsMap,
    );
  }

  static Map<String, dynamic> _convertYamlMapToDartMap(dynamic yamlNode) {
    if (yamlNode is YamlMap) {
      final map = <String, dynamic>{};
      for (final key in yamlNode.keys) {
        map[key.toString()] = _convertYamlMapToDartMap(yamlNode[key]);
      }
      return map;
    } else if (yamlNode is YamlList) {
      return {'_list': yamlNode.nodes.map((node) => _convertYamlMapToDartMap(node.value)).toList()};
    }
    return yamlNode;
  }
}
