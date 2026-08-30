import 'package:perlindungan_konsumen/core/network/api_exception.dart';
import 'package:perlindungan_konsumen/features/badges/data/badge_repository.dart';
import 'package:perlindungan_konsumen/features/badges/data/models/badge.dart';

/// Empat badge, satu per journey dari `FakeLearningRepository.defaultJourneys`
/// (journey id 1..4) -- persis pemetaan `BadgeSeeder` di backend
/// (journey_id unik per badge). Badge journey 1 sengaja ditandai sudah
/// diraih supaya ada contoh tampilan "diraih" di test, sisanya belum.
class FakeBadgeRepository implements BadgeRepository {
  FakeBadgeRepository({List<Badge>? items}) : items = items ?? defaultBadges;

  List<Badge> items;

  ApiException? failWith;

  final List<String> calls = [];

  static final defaultBadges = [
    Badge(
      id: 1,
      journeyId: 1,
      name: 'Consumer Rights Explorer',
      description: 'Memahami dasar-dasar hak dan kewajiban konsumen.',
      congratulationMessage:
          'Selamat! Kamu telah berhasil menuntaskan seluruh tantangan pada '
          'Journey 1: Kenali Hakmu sebagai Konsumen.',
      motivationalMessage:
          'Yuk, ambil langkah selanjutnya dan mari pelajari strategi jitu '
          'menyaring reputasi toko digital pada Journey 2!',
      iconUrl: 'https://placehold.co/256x256?text=Consumer+Rights+Explorer',
      earned: true,
      earnedAt: DateTime.utc(2026, 1, 10),
    ),
    const Badge(
      id: 2,
      journeyId: 2,
      name: 'Smart Shopper',
      description: 'Mampu membuat keputusan belanja yang tepat.',
      // Belum diraih -- pesan ucapan selamat & motivasi cuma relevan begitu
      // badge diraih (lihat BadgeDetailSheet), jadi wajar null di sini.
      congratulationMessage: null,
      motivationalMessage: null,
      iconUrl: 'https://placehold.co/256x256?text=Smart+Shopper',
      earned: false,
      earnedAt: null,
    ),
    const Badge(
      id: 3,
      journeyId: 3,
      name: 'Digital Safety Guardian',
      description: 'Mampu melindungi diri dari risiko digital.',
      congratulationMessage: null,
      motivationalMessage: null,
      iconUrl: 'https://placehold.co/256x256?text=Digital+Safety+Guardian',
      earned: false,
      earnedAt: null,
    ),
    const Badge(
      id: 4,
      journeyId: 4,
      name: 'Consumer Champion',
      description: 'Berani memperjuangkan hak sebagai konsumen.',
      congratulationMessage: null,
      motivationalMessage: null,
      iconUrl: 'https://placehold.co/256x256?text=Consumer+Champion',
      earned: false,
      earnedAt: null,
    ),
  ];

  @override
  Future<List<Badge>> badges() async {
    calls.add('badges');
    if (failWith != null) throw failWith!;
    return items;
  }
}
