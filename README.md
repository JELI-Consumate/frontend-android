# Aplikasi Perlindungan Konsumen

Aplikasi Android (Flutter) untuk perlindungan konsumen.

## Info Project

- **Package name:** `com.argy.perlindungankonsumen`
- **State management:** [Riverpod](https://riverpod.dev) (`flutter_riverpod`)
- **HTTP client:** [Dio](https://pub.dev/packages/dio) untuk konsumsi REST API
- **Platform:** Android

## Struktur Folder

```
lib/
  core/
    network/
      api_client.dart      # Dio client + provider, atur base URL API di sini
  features/
    home/
      data/                # Repository/data source per fitur
      presentation/        # Screen & widget per fitur
  main.dart                # Entry point, bootstrap ProviderScope
```

Setiap fitur baru disarankan mengikuti pola folder `features/<nama_fitur>/{data,presentation}`
seperti pada `features/home`.

## Yang Perlu Dikonfigurasi

- [ ] Ganti `kApiBaseUrl` di `lib/core/network/api_client.dart` dengan base URL backend sebenarnya.
- [ ] Tambahkan interceptor auth (token) di `dioProvider` kalau API butuh autentikasi.
- [ ] Ganti app icon di `android/app/src/main/res/mipmap-*` (masih default Flutter).

## Menjalankan Project

```bash
flutter pub get
flutter run
```

## Menjalankan Test & Analisis

```bash
flutter analyze
flutter test
```
