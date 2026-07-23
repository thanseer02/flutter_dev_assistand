enum AssetIssueType {
  unused,
  duplicate,
  large,
  missing,
  emptyFolder,
}

class AssetIssue {
  final AssetIssueType type;
  final String path;
  final String? secondaryPath; // For duplicates (original file) or missing (referenced in file)
  final int sizeInBytes;
  final String? description;

  const AssetIssue({
    required this.type,
    required this.path,
    this.secondaryPath,
    this.sizeInBytes = 0,
    this.description,
  });
}
