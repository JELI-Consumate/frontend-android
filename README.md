# Aplikasi Perlindungan Konsumen

Aplikasi Android (Flutter) untuk perlindungan konsumen.

## Info Project

- **Package name:** `com.argy.perlindungankonsumen`
- **State management:** [Riverpod](https://riverpod.dev) (`flutter_riverpod`)
- **Ilustrasi:** PNG; `AppIllustration` juga menerima SVG via
  [flutter_svg](https://pub.dev/packages/flutter_svg)
- **Font:** Plus Jakarta Sans (variable), dibundel di `assets/fonts/`
- **HTTP client:** [Dio](https://pub.dev/packages/dio) untuk konsumsi REST API
- **Token:** [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage)
- **Locale:** `id_ID` (via `flutter_localizations` + `intl`) — dipakai date
  picker & format tanggal di form registrasi
- **Backend:** Laravel + Sanctum (`../backend`), prefix `/api/v1`
- **Platform:** Android

## Struktur Folder

```
lib/
  app/
    app_root.dart            # Gate: splash / onboarding+auth / MainShell
    main_shell.dart          # Bottom nav 4 tab (Beranda/Perjalanan/Pencapaian/Profil)
    placeholder_tab_screen.dart  # Tab "Pencapaian" — di luar cakupan saat ini
    splash_screen.dart
  core/
    network/
      api_client.dart        # Dio + interceptor token, base URL API
      api_exception.dart     # Error bertipe dari envelope backend
    storage/
      token_storage.dart     # Simpan token Sanctum (secure storage)
    theme/                   # Token design system + ThemeData
    widgets/                 # Komponen lintas fitur
  features/
    auth/
      application/
        auth_controller.dart # AsyncNotifier: siapa yang sedang login
      data/
        auth_repository.dart # Sembilan endpoint auth
        models/app_user.dart
      presentation/
        auth_screen.dart              # Tab Masuk / Daftar
        forgot_password_screen.dart   # Minta kode reset lewat email
        reset_password_screen.dart    # Tempel kode + kata sandi baru
        widgets/
    learning/
      application/
        learning_providers.dart  # primarySectorDetailProvider, journeyDetailProvider
      data/
        learning_repository.dart # /sectors, /sectors/{slug}, /journeys/{id}
        models/
      presentation/
        dashboard_screen.dart     # Tab "Beranda"
        journeys_screen.dart      # Tab "Perjalanan"
        journey_detail_screen.dart  # Checklist module satu journey
        widgets/
    onboarding/
    home/                    # Sekarang tab "Profil" di dalam MainShell
  main.dart
assets/
  fonts/                     # Plus Jakarta Sans
  images/                    # Ilustrasi + logo Google
```

Setiap fitur baru disarankan mengikuti pola folder `features/<nama_fitur>/{data,presentation}`
seperti pada `features/home`.

## Design System

Semua nilai visual hidup sebagai token di `lib/core/theme/`. Widget membaca
gaya lewat `Theme.of(context)` atau langsung dari kelas token — **jangan**
menulis `Color(0xFF...)` atau ukuran font secara literal di dalam widget.

### Warna

| Token | Hex | Dipakai untuk |
| --- | --- | --- |
| `AppColors.primary` | `#0037B0` | Judul, tombol utama, link, dot aktif |
| `AppColors.ink` | `#434655` | Teks body |
| `AppColors.white` | `#FFFFFF` | Permukaan kartu, teks di atas tombol |
| `AppColors.muted` | `#C4C5D7` | Dot non-aktif, border, disabled |
| `AppColors.background` | `#F8F9FF` | Background layar |

Warna turunan (`primaryPressed`, `inkMuted`, `border`, `primarySoft`)
dihitung dari palet di atas, bukan warna baru.

### Tipografi

Seluruh teks memakai **Plus Jakarta Sans**. Skalanya:

| Grup | Gaya | Ukuran / bobot |
| --- | --- | --- |
| Display (judul halaman, warna primary) | `displayLarge` / `displayMedium` / `displaySmall` | 30/800, 24/800, 20/700 |
| Title | `titleLarge` / `titleMedium` | 18/700, 16/600 |
| Body | `bodyLarge` / `bodyMedium` / `bodySmall` | 15/400, 14/400, 13/400 |
| Aksen & label | `bodyHighlight` / `labelLarge` / `labelMedium` | 15/700, 15/600, 13/500 |

Font ini dibundel sebagai *variable font* (sumbu `wght` 200–800), jadi
`AppTypography` selalu mengirim `fontVariations` bersama `fontWeight` — kalau
hanya `fontWeight`, bobotnya tidak bergerak di sebagian platform. Gaya baru
sebaiknya lewat helper `_style()` supaya perilakunya konsisten.

### Spacing & radius

`AppSpacing` memakai skala kelipatan 4 (`xxs` 4 … `xxxl` 56) plus
`screenPadding` (24) untuk padding horizontal konten layar.
`AppRadius` menyediakan `sm`/`md`/`lg`/`xl` dan `pill` untuk bentuk kapsul.

### Komponen

- `PrimaryButton` — tombol aksi utama, mendukung ikon kanan, state
  `isLoading`, dan otomatis non-aktif kalau `onPressed` bernilai `null`.
- `PageDots` — indikator halaman; opsional bisa ditekan untuk pindah halaman.
- `HighlightText` — paragraf dengan sebagian kata ditebalkan dan diberi warna
  primary. Tandai dengan `**`, mirip Markdown:
  `HighlightText('jadilah **konsumen cerdas** di sini')`.
- `AppIllustration` — pembungkus SVG dengan batas tinggi seragam.

## Halaman Onboarding

`features/onboarding` berisi dua halaman sesuai desain: **Selamat Datang** dan
**Pre-Test**. Isi tiap halaman disimpan sebagai data di
`domain/onboarding_page_data.dart`, jadi menambah atau mengubah urutan halaman
cukup mengedit list `onboardingPages` — tidak perlu menyentuh widget.

Tombol dan indikator titik dipasang tetap di footer, hanya isi halaman yang
bergeser saat di-swipe.

Ilustrasi ada di `assets/images/`. Untuk menggantinya cukup timpa filenya
atau ubah `illustrationAsset` di `onboardingPages` — kode layar tidak perlu
disentuh. `AppIllustration` memilih sendiri antara `Image.asset` dan
`SvgPicture.asset` berdasarkan ekstensi file.

Catatan soal SVG: export SVG dari Figma kadang hanya membungkus gambar raster
di dalam elemen `<pattern>`. flutter_svg tidak mendukung `<pattern>`, jadi file
seperti itu akan render kosong — pakai PNG saja untuk kasus tersebut.

Ilustrasi saat ini beresolusi 338x338 dan 512x512, sementara di layar 3x
dibutuhkan sekitar 810px. Kalau hasilnya terlihat kurang tajam di HP, minta
export yang lebih besar ke desainer, atau sediakan varian
`assets/images/2.0x/` dan `assets/images/3.0x/` dengan nama file yang sama.

## Autentikasi

Backend memakai Laravel Sanctum. Token dikirim sebagai
`Authorization: Bearer <token>` dan disimpan di secure storage.

### Endpoint yang sudah tersambung

| Endpoint | Method | Auth | Dipakai di |
| --- | --- | --- | --- |
| `/auth/register` | POST | publik | Tab Daftar |
| `/auth/login` | POST | publik | Tab Masuk (**email**, bukan lagi email/telepon) |
| `/auth/google` | POST | publik | `loginWithGoogle()` (UI belum aktif) |
| `/auth/forgot-password` | POST | publik | `ForgotPasswordScreen` |
| `/auth/reset-password` | POST | publik | `ResetPasswordScreen` |
| `/auth/verify-email/resend` | POST | publik | Snackbar login + banner Home |
| `/auth/verify-email/{id}/{hash}` | GET | signed link | Dibuka dari email, di luar app |
| `/auth/logout` | POST | Bearer | Tombol Keluar |
| `/auth/me` | GET | Bearer | Bootstrap + tombol muat ulang |
| `/auth/profile` | PATCH | Bearer | Dialog Ubah nama |

### Bentuk respons

Sukses selalu `{"data": ..., "meta": {}}`; error selalu
`{"message": ..., "errors": {...}, "code": ...}`. `ApiException` menormalkan
keduanya, termasuk error validasi Laravel (422) yang tidak punya field `code`.

Error validasi dipetakan ke pesan di bawah field yang bersangkutan. Error lain
(401 `INVALID_CREDENTIALS`, 403 `EMAIL_NOT_VERIFIED`, 422
`GOOGLE_ONLY_ACCOUNT`/`INVALID_RESET_TOKEN`, 429 throttle, atau masalah
koneksi) tampil sebagai SnackBar.

Endpoint aksi (`forgot-password`, `reset-password`, `verify-email/resend`)
tidak mengembalikan `data`, hanya `meta.message` — pesannya sudah dilokalkan
backend dan ditampilkan apa adanya di UI, jadi kalau kalimatnya diubah di
Laravel, tidak perlu ubah apa pun di Flutter.

### Login, lupa kata sandi & verifikasi email

Login sekarang **email-only** — field `identifier` (email atau telepon) sudah
dihapus dari backend, jadi `LoginForm` juga divalidasi sebagai email (format
dicek sama seperti di form Daftar).

`AuthScreen` → tombol **"Lupa kata sandi?"** membuka `ForgotPasswordScreen`.
Backend selalu balas pesan generik yang sama baik emailnya terdaftar atau
tidak (mencegah email enumeration), jadi UI-nya juga tidak pernah bilang
"email tidak ditemukan". Dari layar konfirmasi, tombol **"Sudah Punya
Kode?"** membuka `ResetPasswordScreen` (email ikut ter-*prefill*).

Kode reset **tidak** dikirim lewat deep link — belum ada konfigurasi
App Links/custom scheme di `AndroidManifest.xml`. Jadi alurnya manual:
pengguna buka email, salin kode, tempel ke field "Kode Reset" di app. Kalau
nanti mau upgrade ke tap-link-langsung-buka-app, itu pekerjaan native
terpisah (intent filter + `uni_links`/`app_links`), bukan sekadar ubah
endpoint.

Kalau login gagal dengan kode `EMAIL_NOT_VERIFIED` (403), `LoginForm`
menampilkan SnackBar dengan aksi **"Kirim ulang"** yang memanggil
`/auth/verify-email/resend` pakai email yang baru saja diketik — tidak perlu
token karena endpoint ini publik. `HomeScreen` juga menampilkan banner serupa
kalau `user.isEmailVerified == false`, untuk pengguna yang sudah pernah masuk
tapi belum verifikasi.

Link verifikasi (`GET /auth/verify-email/{id}/{hash}`) sendiri dibuka dari
klien email (browser), **bukan** dari dalam app — sama seperti reset
password, ini butuh deep link kalau mau otomatis kembali ke aplikasi.

### Field registrasi

Semua field di form Daftar wajib diisi di sisi klien: nama, email, nomor HP,
**tanggal lahir**, kata sandi, dan konfirmasinya. Backend sendiri menandai
`phone` dan `date_of_birth` sebagai `nullable` (lihat
`RegisterRequest::rules()`), jadi kewajiban ini murni keputusan produk di
aplikasi — bukan validasi tambahan dari server.

Tanggal lahir diisi lewat `showDatePicker` (bukan input teks bebas), dibatasi
120 tahun ke belakang sampai hari ini, dan dikirim ke `/auth/register` dalam
format `yyyy-MM-dd`.

### Alur di aplikasi

`AppRoot` menentukan layar berdasarkan status login:

- token ada dan `/auth/me` berhasil -> `HomeScreen`
- tidak ada token -> onboarding, lalu `AuthScreen`
- masih memeriksa token -> `SplashScreen`

Status "sedang submit" dipegang lokal oleh masing-masing form, bukan oleh
`authControllerProvider`. Kalau digabung, layar auth ikut ter-unmount saat
tombol ditekan dan penanganan errornya jadi tidak jalan.

### Base URL

Default `http://10.0.2.2:8000/api/v1` — alias emulator Android untuk
`localhost` milik host. Override saat run:

```bash
flutter run --dart-define=API_BASE_URL=https://api.example.com/api/v1
```

Backend perlu jalan lebih dulu:

```bash
cd ../backend && php artisan serve
```

## Pembelajaran (Dashboard & Perjalanan)

Setelah login (dan email terverifikasi — lihat catatan di bawah), `AppRoot`
menampilkan `MainShell`: 4 tab di bawah (Beranda, Perjalanan, Pencapaian,
Profil), masing-masing Scaffold sendiri di dalam `IndexedStack`.

### Endpoint yang dipakai

| Endpoint | Method | Dipakai di |
| --- | --- | --- |
| `/sectors` | GET | `primarySectorDetailProvider` — ambil slug sektor pertama |
| `/sectors/{slug}` | GET | Dashboard (preview) + tab Perjalanan (daftar penuh) |
| `/journeys/{id}` | GET | `JourneyDetailScreen` + kartu "Lanjutkan Belajar" |

Semua route ini butuh `verified` middleware di backend — user yang belum
verifikasi email akan dapat 403 di sini (bukan cuma di `/auth/login`).

### Dua penyesuaian backend yang saya tambahkan

Dua data yang dibutuhkan mockup ternyata tidak ada di endpoint aslinya, jadi
saya tambahkan di sisi Laravel (additive, tidak mengubah field lama):

1. **`modules_count`** di `JourneyResource` — jumlah modul per journey
   (mockup: "13 Materi"). Dihitung via `withCount('modules')` di
   `SectorController::show()`, atau `$journey->modules->count()` kalau
   modules-nya sudah ter-*eager-load* (di `JourneyController::show()`).
2. **`progress`** per module di `GET /journeys/{id}` — backend aslinya cuma
   punya progress per JOURNEY (agregat, dihitung dari total menit), bukan
   per MODULE. `JourneyController::attachModuleProgress()` menghitungnya
   dengan satu query bulk (bukan N+1) dari seluruh `module_progress` user di
   journey itu, lalu ditempel ke tiap module sebagai `{status, percent}` —
   dipakai untuk checklist "Selesai/sedang berjalan/berikutnya" dan untuk
   menentukan modul mana yang dilanjutkan di kartu dashboard.

### Yang sengaja belum dibangun

- **Layar konsumsi konten** (video, artikel, kuis, simulasi, refleksi) —
  menyentuh satu module di checklist cuma menampilkan pesan "belum
  tersedia". Ini scope terpisah yang jauh lebih besar dari Dashboard +
  Perjalanan.
- **Tab "Pencapaian"** — perlu `/badges` dan `/empowerment-index`
  (`BadgeController`, `EmpowermentIndexController`), di luar cakupan
  pekerjaan ini. Sekarang cuma placeholder "Segera hadir".
- **Fitur pencarian** di search bar dashboard — murni visual, tidak ada
  endpoint pencarian yang didiskusikan.

### Ilustrasi kartu

`Sector`/`Journey` tidak punya field gambar besar (`Sector.icon_url` juga
kosong di data yang ada), jadi kartu journey & kartu "Lanjutkan Belajar"
pakai satu ilustrasi SVG bawaan (`assets/images/journey_illustration.svg`),
bukan gambar dari server.

## Yang Perlu Dikonfigurasi

- [ ] Ganti default `API_BASE_URL` di `lib/core/network/api_client.dart` saat deploy.
- [ ] Ganti app icon di `android/app/src/main/res/mipmap-*` (masih default Flutter).
- [ ] Sambungkan `onFinished` di `OnboardingScreen` ke layar pre-test yang sebenarnya.
- [ ] Google Sign-In: butuh OAuth client ID + `google-services.json`, lalu kirim
      `access_token` ke `loginWithGoogle()`. Tombolnya sekarang masih pesan
      "belum tersedia".
- [ ] Deep link untuk email verifikasi & reset kata sandi: sekarang pengguna
      salin-tempel kode manual dari email ke app. Kalau mau upgrade ke
      tap-link-langsung-buka-app, perlu App Links/custom scheme di
      `AndroidManifest.xml` plus `uni_links`/`app_links`.
- [ ] Layar konsumsi konten module (video/kuis/simulasi/dst.) — lihat
      "Pembelajaran" di atas.
- [ ] Tab "Pencapaian" — perlu wiring ke `/badges` dan `/empowerment-index`.

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
