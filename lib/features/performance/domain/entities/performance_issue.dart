enum PerformanceIssueType {
  largeWidget,
  missingConst,
  expensiveBuild,
  nestedWidget,
  memoryRisk,
  largeList,
  largeImage,
}

class PerformanceIssue {
  final PerformanceIssueType type;
  final String location;
  final String description;
  final String optimizationSuggestion;

  const PerformanceIssue({
    required this.type,
    required this.location,
    required this.description,
    required this.optimizationSuggestion,
  });
}
