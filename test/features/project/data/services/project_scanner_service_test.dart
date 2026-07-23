import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dev_assistant/features/project_analysis/data/services/project_scanner_service.dart';

void main() {
  group('ProjectScannerService', () {
    late ProjectScannerService scanner;
    late Directory tempDir;

    setUp(() {
      scanner = ProjectScannerService();
      tempDir = Directory.systemTemp.createTempSync('flutter_dev_assistant_test');
      
      // Create mock project structure
      File('${tempDir.path}/pubspec.yaml').writeAsStringSync('name: test_project\n');
      
      Directory('${tempDir.path}/lib').createSync();
      File('${tempDir.path}/lib/main.dart').writeAsStringSync('void main() {}');
      
      Directory('${tempDir.path}/assets').createSync();
      File('${tempDir.path}/assets/image.png').writeAsBytesSync([1, 2, 3]);
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('should scan a valid flutter project', () async {
      final project = await scanner.scanProject(tempDir.path);
      
      expect(project.name, 'test_project');
      expect(project.path, tempDir.path);
      expect(project.hasPubspec, true);
      expect(project.totalFiles, greaterThan(0));
      expect(project.totalSize, greaterThan(0));
      expect(project.filesByExtension.containsKey('.dart'), true);
      expect(project.filesByExtension.containsKey('.png'), true);
    });

    test('should throw if directory does not exist', () async {
      expect(
        () => scanner.scanProject('/invalid/path/that/does/not/exist'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
