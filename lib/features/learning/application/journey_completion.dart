import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../badges/application/badge_providers.dart';
import '../../badges/data/models/badge.dart';
import '../data/models/journey_detail.dart';
import 'learning_providers.dart';

/// Semua yang dibutuhkan layar perayaan setelah sebuah journey tuntas.
@immutable
class JourneyCelebrationData {
  const JourneyCelebrationData({
    required this.journeyOrder,
    required this.badge,
    required this.modulesCompleted,
    required this.modulesTotal,
    required this.quizScore,
    required this.nextJourneyId,
  });

  final int journeyOrder;
  final Badge badge;
  final int modulesCompleted;
  final int modulesTotal;
  final int? quizScore;
  final String? nextJourneyId;
}

/// Orkestrasi "journey baru saja selesai": ambil ulang detail journey, cek
/// apakah statusnya kini `completed`, lalu kumpulkan badge yang diraih dan
/// id journey berikutnya. Murni data -- navigasi tetap di layar pemanggil.
class JourneyCompletionController {
  JourneyCompletionController(this._ref);

  final Ref _ref;

  /// Dipanggil sesudah user keluar dari rantai module sebuah journey.
  /// Mengembalikan data perayaan kalau journey-nya BARU tuntas di sesi ini,
  /// atau `null` kalau belum selesai / memang sudah lama selesai.
  Future<JourneyCelebrationData?> celebrationAfterModules({
    required String journeyId,
    required bool wasCompletedBefore,
  }) async {
    if (wasCompletedBefore) return null;

    // Ambil ulang dari server -- pakai `Ref` provider ini (stabil), bukan
    // `WidgetRef` pemanggil yang bisa sudah ter-dispose begitu
    // `journeyDetailProvider` (autoDispose) di-invalidate dan `JourneyDetail`
    // sempat menampilkan spinner.
    _ref.invalidate(journeyDetailProvider(journeyId));
    _ref.invalidate(primarySectorDetailProvider);
    final refreshed = await _ref.read(journeyDetailProvider(journeyId).future);
    if (!refreshed.journey.progress.status.isCompleted) return null;

    _ref.invalidate(badgesProvider);
    final badges = await _ref.read(badgesProvider.future);

    Badge? earnedBadge;
    for (final candidate in badges) {
      if (candidate.journeyId == journeyId) {
        earnedBadge = candidate;
        break;
      }
    }

    final sectorDetail = await _ref.read(primarySectorDetailProvider.future);
    String? nextJourneyId;
    for (final journey in sectorDetail?.journeys ?? const []) {
      if (journey.order == refreshed.journey.order + 1) {
        nextJourneyId = journey.id;
        break;
      }
    }

    return JourneyCelebrationData(
      journeyOrder: refreshed.journey.order,
      badge: earnedBadge ?? _fallbackBadge(journeyId, refreshed),
      modulesCompleted: refreshed.completedModuleCount,
      modulesTotal: refreshed.modules.length,
      quizScore: refreshed.quizScore,
      nextJourneyId: nextJourneyId,
    );
  }

  Badge _fallbackBadge(String journeyId, JourneyDetail refreshed) {
    return Badge(
      id: '',
      journeyId: journeyId,
      name: '${refreshed.journey.title} Selesai',
      description: 'Kamu telah menuntaskan seluruh materi journey ini.',
      congratulationMessage:
          'Selamat! Kamu telah menuntaskan seluruh materi journey ini.',
      motivationalMessage: null,
      iconUrl: null,
      earned: true,
      earnedAt: DateTime.now(),
    );
  }
}

final journeyCompletionControllerProvider = Provider(
  (ref) => JourneyCompletionController(ref),
);
