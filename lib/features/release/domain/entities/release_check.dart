enum ReleaseCheckStatus {
  pass,
  fail,
  warning,
  info,
}

enum ReleaseCheckCategory {
  configuration,
  assets,
  permissions,
  firebase,
  codeQuality,
  security,
}

class ReleaseCheck {
  final String title;
  final String description;
  final ReleaseCheckStatus status;
  final ReleaseCheckCategory category;

  const ReleaseCheck({
    required this.title,
    required this.description,
    required this.status,
    required this.category,
  });
}
