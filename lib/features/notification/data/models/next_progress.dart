import 'package:flutter/foundation.dart';

/// Hasil `GET /progress/next` -- titik modul pertama yang belum
/// diselesaikan user, lintas sektor. Semua field `null` kalau seluruh modul
/// sudah selesai (lihat `ProgressResolverService::resolveNext` di backend).
@immutable
class NextProgress {
  const NextProgress({this.sectorId, this.journeyId, this.modulePageId});

  final int? sectorId;
  final int? journeyId;
  final int? modulePageId;

  factory NextProgress.fromJson(Map<String, dynamic> json) {
    return NextProgress(
      sectorId: (json['sector_id'] as num?)?.toInt(),
      journeyId: (json['journey_id'] as num?)?.toInt(),
      modulePageId: (json['module_page_id'] as num?)?.toInt(),
    );
  }
}
