import 'dart:io';
import 'dart:isolate';
import '../../domain/entities/release_check.dart';

class ReleaseAnalyzerService {
  Future<List<ReleaseCheck>> analyzeRelease(String projectPath) async {
    return await Isolate.run(() => _performAnalysis(projectPath));
  }

  static Future<List<ReleaseCheck>> _performAnalysis(String projectPath) async {
    final checks = <ReleaseCheck>[];

    // 1. Pubspec.yaml checks
    final pubspecFile = File('$projectPath/pubspec.yaml');
    String pubspecContent = '';
    if (pubspecFile.existsSync()) {
      pubspecContent = pubspecFile.readAsStringSync();
      
      // Version
      final versionMatch = RegExp(r'^version:\s*([^\n]+)', multiLine: true).firstMatch(pubspecContent);
      if (versionMatch != null) {
        checks.add(ReleaseCheck(
          title: 'Version Configured',
          description: 'Current version: ${versionMatch.group(1)}',
          status: ReleaseCheckStatus.pass,
          category: ReleaseCheckCategory.configuration,
        ));
      } else {
        checks.add(const ReleaseCheck(
          title: 'Version Missing',
          description: 'Could not find version field in pubspec.yaml.',
          status: ReleaseCheckStatus.warning,
          category: ReleaseCheckCategory.configuration,
        ));
      }

      // App Icons / Splash
      if (pubspecContent.contains('flutter_launcher_icons:')) {
        checks.add(const ReleaseCheck(
          title: 'App Icons',
          description: 'flutter_launcher_icons package detected.',
          status: ReleaseCheckStatus.pass,
          category: ReleaseCheckCategory.assets,
        ));
      } else {
        checks.add(const ReleaseCheck(
          title: 'App Icons',
          description: 'Ensure you have configured production app icons (flutter_launcher_icons not detected).',
          status: ReleaseCheckStatus.info,
          category: ReleaseCheckCategory.assets,
        ));
      }

      if (pubspecContent.contains('flutter_native_splash:')) {
        checks.add(const ReleaseCheck(
          title: 'Splash Screen',
          description: 'flutter_native_splash package detected.',
          status: ReleaseCheckStatus.pass,
          category: ReleaseCheckCategory.assets,
        ));
      } else {
        checks.add(const ReleaseCheck(
          title: 'Splash Screen',
          description: 'Verify your native splash screens are configured for production.',
          status: ReleaseCheckStatus.info,
          category: ReleaseCheckCategory.assets,
        ));
      }
    }

    // 2. Firebase / Crashlytics
    final androidGoogleServices = File('$projectPath/android/app/google-services.json').existsSync();
    final iosGoogleServices = File('$projectPath/ios/Runner/GoogleService-Info.plist').existsSync();
    
    if (androidGoogleServices || iosGoogleServices) {
      checks.add(const ReleaseCheck(
        title: 'Firebase Configuration',
        description: 'Google Services config files detected.',
        status: ReleaseCheckStatus.pass,
        category: ReleaseCheckCategory.firebase,
      ));
      
      if (pubspecContent.contains('firebase_crashlytics')) {
        checks.add(const ReleaseCheck(
          title: 'Crashlytics',
          description: 'Crash reporting is integrated.',
          status: ReleaseCheckStatus.pass,
          category: ReleaseCheckCategory.firebase,
        ));
      } else {
        checks.add(const ReleaseCheck(
          title: 'Crashlytics Missing',
          description: 'Consider adding firebase_crashlytics for production monitoring.',
          status: ReleaseCheckStatus.warning,
          category: ReleaseCheckCategory.firebase,
        ));
      }
    } else {
      checks.add(const ReleaseCheck(
        title: 'Firebase Configuration',
        description: 'No Firebase config files detected. If not using Firebase, you can ignore this.',
        status: ReleaseCheckStatus.info,
        category: ReleaseCheckCategory.firebase,
      ));
    }

    // 3. Android Signing
    if (File('$projectPath/android/key.properties').existsSync()) {
      checks.add(const ReleaseCheck(
        title: 'Android Signing',
        description: 'key.properties found. Ensure your release keystore is secure.',
        status: ReleaseCheckStatus.pass,
        category: ReleaseCheckCategory.security,
      ));
    } else {
      checks.add(const ReleaseCheck(
        title: 'Android Signing',
        description: 'key.properties not found. You must configure signing for Android releases.',
        status: ReleaseCheckStatus.warning,
        category: ReleaseCheckCategory.security,
      ));
    }

    // 4. Code Quality (TODOs, Debug Prints)
    int todoCount = 0;
    int printCount = 0;
    
    final libDir = Directory('$projectPath/lib');
    if (libDir.existsSync()) {
      final dartFiles = libDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
      for (final file in dartFiles) {
        final lines = file.readAsLinesSync();
        for (final line in lines) {
          if (line.contains('// TODO') || line.contains('// FIXME')) todoCount++;
          if (line.contains('print(') || line.contains('debugPrint(')) printCount++;
        }
      }
    }

    if (printCount > 0) {
      checks.add(ReleaseCheck(
        title: 'Debug Prints',
        description: 'Found $printCount debug print statements. Use a logging framework instead.',
        status: ReleaseCheckStatus.fail,
        category: ReleaseCheckCategory.codeQuality,
      ));
    } else {
      checks.add(const ReleaseCheck(
        title: 'Debug Prints',
        description: 'No stray print statements found.',
        status: ReleaseCheckStatus.pass,
        category: ReleaseCheckCategory.codeQuality,
      ));
    }

    if (todoCount > 0) {
      checks.add(ReleaseCheck(
        title: 'TODOs/FIXMEs',
        description: 'Found $todoCount unresolved TODO/FIXME comments.',
        status: ReleaseCheckStatus.warning,
        category: ReleaseCheckCategory.codeQuality,
      ));
    } else {
      checks.add(const ReleaseCheck(
        title: 'TODOs/FIXMEs',
        description: 'No unresolved TODOs.',
        status: ReleaseCheckStatus.pass,
        category: ReleaseCheckCategory.codeQuality,
      ));
    }

    // 5. Obfuscation (Informational)
    checks.add(const ReleaseCheck(
      title: 'Code Obfuscation',
      description: 'Remember to build with --obfuscate and --split-debug-info for production.',
      status: ReleaseCheckStatus.info,
      category: ReleaseCheckCategory.security,
    ));

    return checks;
  }
}
