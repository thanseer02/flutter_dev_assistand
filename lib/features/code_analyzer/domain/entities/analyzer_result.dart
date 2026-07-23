enum DuplicateType {
  widget,
  method,
  string,
  constant,
}

class DuplicateIssue {
  final DuplicateType type;
  final String snippet;
  final List<String> locations;
  final String suggestion;

  const DuplicateIssue({
    required this.type,
    required this.snippet,
    required this.locations,
    required this.suggestion,
  });
}

class AnalyzerResult {
  final List<DuplicateIssue> widgets;
  final List<DuplicateIssue> methods;
  final List<DuplicateIssue> strings;
  final List<DuplicateIssue> constants;
  final double duplicatePercentage;

  const AnalyzerResult({
    this.widgets = const [],
    this.methods = const [],
    this.strings = const [],
    this.constants = const [],
    this.duplicatePercentage = 0.0,
  });

  List<DuplicateIssue> get allIssues => [
    ...widgets,
    ...methods,
    ...strings,
    ...constants,
  ];
}
