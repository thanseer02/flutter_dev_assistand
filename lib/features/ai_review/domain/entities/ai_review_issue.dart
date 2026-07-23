enum IssueSeverity {
  low,
  medium,
  high,
  critical
}

enum IssueCategory {
  architecture,
  naming,
  readability,
  performance,
  solid,
  cleanCode,
  flutterBestPractice,
  other
}

class AiReviewIssue {
  final String title;
  final String description;
  final String suggestion;
  final IssueSeverity severity;
  final String estimatedImpact;
  final IssueCategory category;

  const AiReviewIssue({
    required this.title,
    required this.description,
    required this.suggestion,
    required this.severity,
    required this.estimatedImpact,
    required this.category,
  });

  factory AiReviewIssue.fromJson(Map<String, dynamic> json) {
    return AiReviewIssue(
      title: json['title'] ?? 'Unknown Issue',
      description: json['description'] ?? '',
      suggestion: json['suggestion'] ?? '',
      severity: _parseSeverity(json['severity']),
      estimatedImpact: json['estimatedImpact'] ?? 'Unknown',
      category: _parseCategory(json['category']),
    );
  }

  static IssueSeverity _parseSeverity(String? val) {
    if (val == null) return IssueSeverity.low;
    switch (val.toLowerCase()) {
      case 'critical': return IssueSeverity.critical;
      case 'high': return IssueSeverity.high;
      case 'medium': return IssueSeverity.medium;
      default: return IssueSeverity.low;
    }
  }

  static IssueCategory _parseCategory(String? val) {
    if (val == null) return IssueCategory.other;
    switch (val.toLowerCase()) {
      case 'architecture': return IssueCategory.architecture;
      case 'naming': return IssueCategory.naming;
      case 'readability': return IssueCategory.readability;
      case 'performance': return IssueCategory.performance;
      case 'solid': return IssueCategory.solid;
      case 'cleancode': return IssueCategory.cleanCode;
      case 'flutterbestpractice': return IssueCategory.flutterBestPractice;
      default: return IssueCategory.other;
    }
  }
}
