class FileInfo {
  final String path;
  final String name;
  final String extension;
  final int sizeInBytes;
  final DateTime lastModified;

  const FileInfo({
    required this.path,
    required this.name,
    required this.extension,
    required this.sizeInBytes,
    required this.lastModified,
  });
}
