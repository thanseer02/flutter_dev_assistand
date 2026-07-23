class ProjectInfo {
  final String name;
  final String path;
  final String flutterVersion;
  final String dartVersion;
  final int dartFilesCount;
  final int assetsCount;
  final int packagesCount;
  final List<String> architectures;

  const ProjectInfo({
    required this.name,
    required this.path,
    required this.flutterVersion,
    required this.dartVersion,
    required this.dartFilesCount,
    required this.assetsCount,
    required this.packagesCount,
    required this.architectures,
  });

  @override
  String toString() {
    return 'ProjectInfo(name: $name, path: $path, architectures: $architectures)';
  }
}
