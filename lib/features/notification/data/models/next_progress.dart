import 'package:flutter/foundation.dart';

@immutable
class NextProgress {
  const NextProgress({this.sectorId, this.journeyId, this.modulePageId});

  final String? sectorId;
  final String? journeyId;
  final String? modulePageId;

  factory NextProgress.fromJson(Map<String, dynamic> json) {
    return NextProgress(
      sectorId: json['sector_id'] as String?,
      journeyId: json['journey_id'] as String?,
      modulePageId: json['module_page_id'] as String?,
    );
  }
}
