import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Slug sektor yang dipilih pengguna sekali di layar onboarding "Pilih
/// Sektor" (lihat `SectorSelectionScreen`). Backend belum punya kolom
/// "sektor pilihan user" (cuma satu sektor aktif saat ini, lihat
/// `SectorController`), jadi pilihannya disimpan lokal di device saja --
/// sama seperti [TokenStorage] menyimpan token auth.
class SectorStorage {
  SectorStorage(this._storage);

  static const _key = 'selected_sector_slug';

  final FlutterSecureStorage _storage;

  String? _cached;
  bool _loaded = false;

  Future<String?> read() async {
    if (_loaded) return _cached;
    _cached = await _storage.read(key: _key);
    _loaded = true;
    return _cached;
  }

  Future<void> save(String slug) async {
    _cached = slug;
    _loaded = true;
    await _storage.write(key: _key, value: slug);
  }

  Future<void> clear() async {
    _cached = null;
    _loaded = true;
    await _storage.delete(key: _key);
  }
}

final sectorStorageProvider = Provider<SectorStorage>((ref) {
  return SectorStorage(const FlutterSecureStorage());
});
