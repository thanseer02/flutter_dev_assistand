enum RiskLevel {
  low,
  medium,
  high
}

class PackageInfo {
  final String name;
  final String currentVersion;
  final String? latestVersion;
  final String? description;
  final bool isDevDependency;
  final bool isGit;
  final bool isLocal;
  final bool isDiscontinued;
  final bool isUnused;
  final RiskLevel riskLevel;

  const PackageInfo({
    required this.name,
    required this.currentVersion,
    this.latestVersion,
    this.description,
    this.isDevDependency = false,
    this.isGit = false,
    this.isLocal = false,
    this.isDiscontinued = false,
    this.isUnused = false,
    this.riskLevel = RiskLevel.low,
  });

  PackageInfo copyWith({
    String? latestVersion,
    String? description,
    bool? isDiscontinued,
    bool? isUnused,
    RiskLevel? riskLevel,
  }) {
    return PackageInfo(
      name: name,
      currentVersion: currentVersion,
      latestVersion: latestVersion ?? this.latestVersion,
      description: description ?? this.description,
      isDevDependency: isDevDependency,
      isGit: isGit,
      isLocal: isLocal,
      isDiscontinued: isDiscontinued ?? this.isDiscontinued,
      isUnused: isUnused ?? this.isUnused,
      riskLevel: riskLevel ?? this.riskLevel,
    );
  }
}
