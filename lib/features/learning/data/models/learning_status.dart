/// Cermin dari `ProgressStatus` enum di backend (`not_started`, `in_progress`,
/// `completed`) — dipakai di sector, journey, dan module.
enum LearningStatus {
  notStarted('not_started'),
  inProgress('in_progress'),
  completed('completed');

  const LearningStatus(this.value);

  final String value;

  bool get isCompleted => this == LearningStatus.completed;
  bool get isInProgress => this == LearningStatus.inProgress;

  static LearningStatus fromJson(Object? value) {
    return LearningStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => LearningStatus.notStarted,
    );
  }
}

/// Bentuk `{status, percent}` yang berulang di banyak resource backend
/// (sector, journey, module).
class LearningProgress {
  const LearningProgress({required this.status, required this.percent});

  final LearningStatus status;
  final int percent;

  static const zero = LearningProgress(
    status: LearningStatus.notStarted,
    percent: 0,
  );

  factory LearningProgress.fromJson(Map<String, dynamic>? json) {
    if (json == null) return zero;
    return LearningProgress(
      status: LearningStatus.fromJson(json['status']),
      percent: (json['percent'] as num?)?.toInt() ?? 0,
    );
  }
}
