import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dev_assistant/features/release/data/services/release_analyzer_service.dart';
import 'package:flutter_dev_assistant/features/release/domain/entities/release_check.dart';

void main() {
  group('ReleaseAnalyzerService', () {
    late ReleaseAnalyzerService analyzer;
    late Directory tempDir;

    setUp(() {
      analyzer = ReleaseAnalyzerService();
      tempDir = Directory.systemTemp.createTempSync('flutter_dev_assistant_test_release');
      
      // Mock basic structure
      File('${tempDir.path}/pubspec.yaml').writeAsStringSync('name: test\nversion: 1.0.0+1\n');
      
      Directory('${tempDir.path}/android/app').createSync(recursive: true);
      File('${tempDir.path}/android/app/google-services.json').writeAsStringSync('{}');
      
      Directory('${tempDir.path}/lib').createSync();
      File('${tempDir.path}/lib/main.dart').writeAsStringSync('void main() {\n  // TODO: fix this\n  print("debug");\n}');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('should analyze release readiness', () async {
      final checks = await analyzer.analyzeRelease(tempDir.path);
      
      expect(checks, isNotEmpty);
      
      final versionCheck = checks.firstWhere((c) => c.title == 'Version Configured');
      expect(versionCheck.status, ReleaseCheckStatus.pass);

      final printsCheck = checks.firstWhere((c) => c.title == 'Debug Prints');
      expect(printsCheck.status, ReleaseCheckStatus.fail); // We added a print

      final todoCheck = checks.firstWhere((c) => c.title == 'TODOs/FIXMEs');
      expect(todoCheck.status, ReleaseCheckStatus.warning); // We added a TODO
      
      final firebaseCheck = checks.firstWhere((c) => c.title == 'Firebase Configuration');
      expect(firebaseCheck.status, ReleaseCheckStatus.pass); // We added google-services.json
    });
  });
}
