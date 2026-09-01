import 'package:flutter/foundation.dart';

/// Satu pasangan yang SUDAH pernah dijawab benar sejauh ini -- jawaban salah
/// tidak pernah disimpan server, jadi tidak akan pernah muncul di sini
/// (lihat `SimulationAttemptResource`, gaya Duolingo: coba lagi sampai benar).
@immutable
class MatchingReviewItem {
  const MatchingReviewItem({required this.pairId, required this.isCorrect});

  final String pairId;
  final bool isCorrect;

  factory MatchingReviewItem.fromJson(Map<String, dynamic> json) {
    return MatchingReviewItem(
      pairId: json['simulation_matching_pair_id'] as String,
      isCorrect: json['is_correct'] as bool? ?? false,
    );
  }
}

/// Satu langkah yang SUDAH pernah ditempatkan di posisi yang benar.
@immutable
class OrderingReviewItem {
  const OrderingReviewItem({
    required this.stepId,
    required this.submittedPosition,
    required this.isCorrect,
  });

  final String stepId;
  final int submittedPosition;
  final bool isCorrect;

  factory OrderingReviewItem.fromJson(Map<String, dynamic> json) {
    return OrderingReviewItem(
      stepId: json['simulation_ordering_step_id'] as String,
      submittedPosition: (json['submitted_position'] as num).toInt(),
      isCorrect: json['is_correct'] as bool? ?? false,
    );
  }
}

/// Snapshot attempt simulasi -- dikembalikan tiap kali
/// `POST /simulation-attempts/{id}/check` dipanggil (bukan cuma di akhir).
/// [isCompleted] baru `true` begitu SELURUH item (matching + ordering)
/// sudah pernah dijawab benar.
@immutable
class SimulationAttempt {
  const SimulationAttempt({
    required this.attemptId,
    required this.simulationContentId,
    required this.score,
    required this.maxScore,
    required this.isPassed,
    required this.isCompleted,
    required this.matchingReview,
    required this.orderingReview,
  });

  final String attemptId;
  final String simulationContentId;
  final int? score;
  final int? maxScore;
  final bool? isPassed;
  final bool isCompleted;
  final List<MatchingReviewItem> matchingReview;
  final List<OrderingReviewItem> orderingReview;

  factory SimulationAttempt.fromJson(Map<String, dynamic> json) {
    final rawMatching = json['matching_review'];
    final rawOrdering = json['ordering_review'];
    return SimulationAttempt(
      attemptId: json['attempt_id'] as String,
      simulationContentId: json['simulation_content_id'] as String,
      score: (json['score'] as num?)?.toInt(),
      maxScore: (json['max_score'] as num?)?.toInt(),
      isPassed: json['is_passed'] as bool?,
      isCompleted: json['completed_at'] != null,
      matchingReview: rawMatching is List
          ? rawMatching
                .cast<Map<String, dynamic>>()
                .map(MatchingReviewItem.fromJson)
                .toList()
          : const [],
      orderingReview: rawOrdering is List
          ? rawOrdering
                .cast<Map<String, dynamic>>()
                .map(OrderingReviewItem.fromJson)
                .toList()
          : const [],
    );
  }
}

/// Hasil satu panggilan `POST /simulation-attempts/{id}/check` -- [correct]
/// menentukan apakah item yang baru saja dicoba itu sendiri benar; [attempt]
/// selalu snapshot TERBARU seluruh attempt (dipakai untuk tahu kapan seluruh
/// game selesai lewat [SimulationAttempt.isCompleted]).
@immutable
class SimulationCheckResult {
  const SimulationCheckResult({required this.correct, required this.attempt});

  final bool correct;
  final SimulationAttempt attempt;

  factory SimulationCheckResult.fromJson(Map<String, dynamic> json) {
    return SimulationCheckResult(
      correct: json['correct'] as bool? ?? false,
      attempt: SimulationAttempt.fromJson(
        json['attempt'] as Map<String, dynamic>,
      ),
    );
  }
}
