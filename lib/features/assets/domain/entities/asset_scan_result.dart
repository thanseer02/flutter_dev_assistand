import 'asset_issue.dart';

class AssetScanResult {
  final List<AssetIssue> unusedAssets;
  final List<AssetIssue> duplicateAssets;
  final List<AssetIssue> largeAssets;
  final List<AssetIssue> missingAssets;
  final List<AssetIssue> emptyFolders;

  final int potentialSavingsBytes;
  final int totalAssetsScanned;

  const AssetScanResult({
    required this.unusedAssets,
    required this.duplicateAssets,
    required this.largeAssets,
    required this.missingAssets,
    required this.emptyFolders,
    required this.potentialSavingsBytes,
    required this.totalAssetsScanned,
  });

  List<AssetIssue> get allIssues => [
    ...unusedAssets,
    ...duplicateAssets,
    ...largeAssets,
    ...missingAssets,
    ...emptyFolders,
  ];
}
