import 'dart:io';
import 'package:yaml/yaml.dart';
import '../../domain/entities/project_info.dart';

class ProjectService {
  Future<bool> isValidFlutterProject(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) return false;

    final pubspec = File('${dir.path}/pubspec.yaml');
    final libDir = Directory('${dir.path}/lib');
    final androidDir = Directory('${dir.path}/android');
    final iosDir = Directory('${dir.path}/ios');

    return await pubspec.exists() &&
           await libDir.exists() &&
           await androidDir.exists() &&
           await iosDir.exists();
  }

  Future<ProjectInfo> parseProject(String path) async {
    final pubspecFile = File('$path/pubspec.yaml');
    final pubspecString = await pubspecFile.readAsString();
    final pubspec = loadYaml(pubspecString) as YamlMap;

    final name = pubspec['name']?.toString() ?? 'Unknown Project';
    
    // Parse environment / flutter version
    String flutterVersion = 'Unknown';
    String dartVersion = 'Unknown';
    
    final env = pubspec['environment'];
    if (env is YamlMap) {
      if (env['sdk'] != null) dartVersion = env['sdk'].toString();
      if (env['flutter'] != null) flutterVersion = env['flutter'].toString();
    }

    // Dependencies & Architecture Detection
    List<String> architectures = [];
    int packagesCount = 0;
    
    final dependencies = pubspec['dependencies'];
    if (dependencies is YamlMap) {
      packagesCount = dependencies.length;
      
      if (dependencies.containsKey('provider')) architectures.add('Provider');
      if (dependencies.containsKey('flutter_bloc') || dependencies.containsKey('bloc')) architectures.add('Bloc');
      if (dependencies.containsKey('flutter_riverpod') || dependencies.containsKey('riverpod')) architectures.add('Riverpod');
      if (dependencies.containsKey('get')) architectures.add('GetX');
    }

    // Dev Dependencies count
    final devDependencies = pubspec['dev_dependencies'];
    if (devDependencies is YamlMap) {
      packagesCount += devDependencies.length;
    }

    // Assets Count
    int assetsCount = 0;
    final flutterNode = pubspec['flutter'];
    if (flutterNode is YamlMap && flutterNode['assets'] is YamlList) {
      assetsCount = (flutterNode['assets'] as YamlList).length;
    } else {
      final assetsDir = Directory('$path/assets');
      if (await assetsDir.exists()) {
        try {
          final files = await assetsDir.list(recursive: true).where((entity) => entity is File).toList();
          assetsCount = files.length;
        } catch (_) {}
      }
    }

    // Dart Files Count (shallow/simple count in lib)
    int dartFilesCount = 0;
    final libDir = Directory('$path/lib');
    if (await libDir.exists()) {
      try {
        final files = await libDir.list(recursive: true).where((entity) => entity is File && entity.path.endsWith('.dart')).toList();
        dartFilesCount = files.length;
      } catch (_) {}
    }

    return ProjectInfo(
      name: name,
      path: path,
      flutterVersion: flutterVersion,
      dartVersion: dartVersion,
      dartFilesCount: dartFilesCount,
      assetsCount: assetsCount,
      packagesCount: packagesCount,
      architectures: architectures,
    );
  }
}
