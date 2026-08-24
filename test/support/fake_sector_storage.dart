import 'package:perlindungan_konsumen/core/storage/sector_storage.dart';

/// Pengganti [SectorStorage] di test -- in-memory, tidak menyentuh
/// `flutter_secure_storage` (plugin asli tidak tersedia di widget test).
class FakeSectorStorage implements SectorStorage {
  FakeSectorStorage({String? initialSlug}) : _slug = initialSlug;

  String? _slug;

  @override
  Future<String?> read() async => _slug;

  @override
  Future<void> save(String slug) async => _slug = slug;

  @override
  Future<void> clear() async => _slug = null;
}
