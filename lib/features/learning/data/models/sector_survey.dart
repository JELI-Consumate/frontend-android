import 'package:flutter/foundation.dart';

@immutable
class SectorSurvey {
  const SectorSurvey({required this.link, required this.completedAt});

  final String? link;
  final DateTime? completedAt;

  static const empty = SectorSurvey(link: null, completedAt: null);

  bool get isConfigured => link != null && link!.isNotEmpty;

  bool get isCompleted => completedAt != null;

  SectorSurvey copyWith({String? link, DateTime? completedAt}) {
    return SectorSurvey(
      link: link ?? this.link,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SectorSurvey &&
      other.link == link &&
      other.completedAt == completedAt;

  @override
  int get hashCode => Object.hash(link, completedAt);

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

@immutable
class SectorSurveys {
  const SectorSurveys({required this.pretest, required this.posttest});

  final SectorSurvey pretest;
  final SectorSurvey posttest;

  static const empty = SectorSurveys(
    pretest: SectorSurvey.empty,
    posttest: SectorSurvey.empty,
  );

  SectorSurveys copyWith({SectorSurvey? pretest, SectorSurvey? posttest}) {
    return SectorSurveys(
      pretest: pretest ?? this.pretest,
      posttest: posttest ?? this.posttest,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SectorSurveys &&
      other.pretest == pretest &&
      other.posttest == posttest;

  @override
  int get hashCode => Object.hash(pretest, posttest);

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
