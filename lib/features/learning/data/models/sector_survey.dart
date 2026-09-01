import 'package:flutter/foundation.dart';

/// Survei eksternal (Google Form) pretest/posttest satu sektor -- terpisah
/// dari kuis in-app pretest/posttest (`Journey.quizScore` dkk). Backend
/// tidak bisa tahu isian Google Form-nya, jadi [completedAt] murni
/// self-report: terisi begitu user menekan "Saya sudah mengisi" di app
/// (lihat `LearningRepository.completePretestSurvey`/`completePosttestSurvey`).
@immutable
class SectorSurvey {
  const SectorSurvey({required this.link, required this.completedAt});

  final String? link;
  final DateTime? completedAt;

  static const empty = SectorSurvey(link: null, completedAt: null);

  /// Admin belum mengisi link survei ini di Filament -- tidak ada yang bisa
  /// ditampilkan/ditandai selesai.
  bool get isConfigured => link != null && link!.isNotEmpty;

  bool get isCompleted => completedAt != null;

  factory SectorSurvey.fromJson(Map<String, dynamic>? json) {
    if (json == null) return empty;
    return SectorSurvey(
      link: json['link'] as String?,
      completedAt: switch (json['completed_at']) {
        String value => DateTime.tryParse(value),
        _ => null,
      },
    );
  }
}

/// Pasangan survei pretest + posttest satu sektor -- bagian dari respons
/// `GET /sectors`, `GET /sectors/{slug}`, dan endpoint complete-nya.
@immutable
class SectorSurveys {
  const SectorSurveys({required this.pretest, required this.posttest});

  final SectorSurvey pretest;
  final SectorSurvey posttest;

  static const empty = SectorSurveys(
    pretest: SectorSurvey.empty,
    posttest: SectorSurvey.empty,
  );

  factory SectorSurveys.fromJson(Map<String, dynamic>? json) {
    if (json == null) return empty;
    return SectorSurveys(
      pretest: SectorSurvey.fromJson(json['pretest'] as Map<String, dynamic>?),
      posttest: SectorSurvey.fromJson(
        json['posttest'] as Map<String, dynamic>?,
      ),
    );
  }
}
