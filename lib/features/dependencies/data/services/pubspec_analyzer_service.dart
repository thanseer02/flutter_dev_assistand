import 'dart:io';
import 'dart:convert';
import 'package:yaml/yaml.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/package_info.dart';

class PubspecAnalyzerService {
  Future<List<PackageInfo>> analyze(String projectPath) async {
    final pubspecFile = File('$projectPath/pubspec.yaml');
    if (!await pubspecFile.exists()) return [];

    final yamlString = await pubspecFile.readAsString();
    final yaml = loadYaml(yamlString);

    final List<PackageInfo> initialPackages = [];

    // Parse dependencies
    if (yaml['dependencies'] != null) {
      final deps = yaml['dependencies'] as YamlMap;
      for (final key in deps.keys) {
        if (key == 'flutter' || key == 'flutter_test') continue;
        initialPackages.add(_parseDependency(key.toString(), deps[key], false));
      }
    }

    // Parse dev_dependencies
    if (yaml['dev_dependencies'] != null) {
      final devDeps = yaml['dev_dependencies'] as YamlMap;
      for (final key in devDeps.keys) {
        if (key == 'flutter' || key == 'flutter_test') continue;
        initialPackages.add(_parseDependency(key.toString(), devDeps[key], true));
      }
    }

    // Check for unused packages (only check regular dependencies)
    final Set<String> usedPackages = await _findUsedPackages(projectPath);
    
    // Fetch details from pub.dev concurrently
    final List<Future<PackageInfo>> futures = initialPackages.map((pkg) async {
      bool isUnused = !pkg.isDevDependency && !usedPackages.contains(pkg.name) && !pkg.isGit && !pkg.isLocal;
      
      if (pkg.isGit || pkg.isLocal) {
        return pkg.copyWith(
          isUnused: isUnused,
          riskLevel: RiskLevel.medium,
          description: pkg.isGit ? 'Git dependency' : 'Local path dependency',
        );
      }

      try {
        final response = await http.get(Uri.parse('https://pub.dev/api/packages/${pkg.name}'));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final latestVersion = data['latest']['version'] as String;
          final pubspec = data['latest']['pubspec'];
          final description = pubspec['description'] as String?;
          final isDiscontinued = data['isDiscontinued'] == true;

          // Determine Risk Level
          RiskLevel risk = RiskLevel.low;
          if (isDiscontinued || isUnused) {
            risk = RiskLevel.high;
          } else {
            // Simple version comparison (e.g. ^1.2.0 vs 2.0.0)
            final currentMajor = _getMajorVersion(pkg.currentVersion);
            final latestMajor = _getMajorVersion(latestVersion);
            if (currentMajor != null && latestMajor != null) {
              if (latestMajor > currentMajor) {
                risk = RiskLevel.high; // Major version behind
              } else if (pkg.currentVersion.replaceAll(RegExp(r'[\^~]'), '') != latestVersion) {
                risk = RiskLevel.medium; // Minor/Patch behind
              }
            }
          }

          return pkg.copyWith(
            latestVersion: latestVersion,
            description: description,
            isDiscontinued: isDiscontinued,
            isUnused: isUnused,
            riskLevel: risk,
          );
        }
      } catch (_) {}

      // Fallback if API fails
      return pkg.copyWith(isUnused: isUnused, riskLevel: isUnused ? RiskLevel.high : RiskLevel.medium);
    }).toList();

    return await Future.wait(futures);
  }

  PackageInfo _parseDependency(String name, dynamic value, bool isDev) {
    String version = 'unknown';
    bool isGit = false;
    bool isLocal = false;

    if (value is String) {
      version = value;
    } else if (value is YamlMap) {
      if (value.containsKey('git')) {
        isGit = true;
        version = 'git';
      } else if (value.containsKey('path')) {
        isLocal = true;
        version = 'local';
      } else if (value.containsKey('version')) {
        version = value['version'].toString();
      }
    }

    return PackageInfo(
      name: name,
      currentVersion: version,
      isDevDependency: isDev,
      isGit: isGit,
      isLocal: isLocal,
    );
  }

  Future<Set<String>> _findUsedPackages(String projectPath) async {
    final Set<String> used = {};
    final libDir = Directory('$projectPath/lib');
    if (!await libDir.exists()) return used;

    final dartFiles = libDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
    final importRegex = RegExp(r"import\s+['""]package:([a-zA-Z0-9_]+)/");

    for (final file in dartFiles) {
      try {
        final content = await file.readAsString();
        final matches = importRegex.allMatches(content);
        for (final match in matches) {
          final pkg = match.group(1);
          if (pkg != null) {
            used.add(pkg);
          }
        }
      } catch (_) {}
    }
    return used;
  }

  int? _getMajorVersion(String versionString) {
    // Strip ^ or ~
    final clean = versionString.replaceAll(RegExp(r'[\^~]'), '');
    final parts = clean.split('.');
    if (parts.isNotEmpty) {
      return int.tryParse(parts[0]);
    }
    return null;
  }
}
