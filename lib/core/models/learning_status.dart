import 'package:flutter/foundation.dart';

/// Kosakata progres bersama seluruh domain belajar (sector, journey, module,
/// module page). Sengaja di `core/` -- bukan milik satu fitur -- karena
/// dipakai lintas fitur `learning` dan `module`.
enum LearningStatus {
  notStarted('not_started'),
  inProgress('in_progress'),
  completed('completed');

  const LearningStatus(this.value);

  final String value;

  bool get isCompleted => this == LearningStatus.completed;
  bool get isInProgress => this == LearningStatus.inProgress;
  bool get isNotStarted => this == LearningStatus.notStarted;

  static LearningStatus fromJson(Object? value) {
    return LearningStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => LearningStatus.notStarted,
    );
  }
}

@immutable
class LearningProgress {
  const LearningProgress({required this.status, required this.percent});

  final LearningStatus status;
  final int percent;

  LearningProgress copyWith({LearningStatus? status, int? percent}) {
    return LearningProgress(
      status: status ?? this.status,
      percent: percent ?? this.percent,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LearningProgress &&
      other.status == status &&
      other.percent == percent;

  @override
  int get hashCode => Object.hash(status, percent);

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
