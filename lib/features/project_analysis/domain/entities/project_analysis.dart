import 'file_info.dart';

class ProjectAnalysis {
  final Map<String, List<FileInfo>> filesByExtension;
  final List<String> folders;
  final int totalFiles;
  final int totalFolders;
  final int totalSizeInBytes;
  final Map<String, dynamic> pubspec;
  final Map<String, dynamic> analysisOptions;

  const ProjectAnalysis({
    required this.filesByExtension,
    required this.folders,
    required this.totalFiles,
    required this.totalFolders,
    required this.totalSizeInBytes,
    required this.pubspec,
    required this.analysisOptions,
  });
}
