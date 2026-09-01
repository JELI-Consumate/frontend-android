import 'package:flutter/foundation.dart';

@immutable
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.dateOfBirth,
    this.avatarUrl,
    this.emailVerifiedAt,
  });

  final String id;
  final String name;
  final String email;
  final String? phone;
  final DateTime? dateOfBirth;
  final String? avatarUrl;
  final DateTime? emailVerifiedAt;

  bool get isEmailVerified => emailVerifiedAt != null;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      dateOfBirth: _parseDate(json['date_of_birth']),
      avatarUrl: json['avatar_url'] as String?,
      emailVerifiedAt: _parseDate(json['email_verified_at']),
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  // Kesetaraan berbasis semua field (bukan cuma `id`) -- ini yang membuat
  // Riverpod tahu ada perubahan berarti (mis. email baru saja diverifikasi,
  // atau nama diganti lewat updateProfile) walau `id` user tetap sama.
  // Kalau cuma `id` yang dibandingkan, AsyncNotifier menganggap state
  // "tidak berubah" dan diam-diam tidak memberi tahu widget yang nonton
  // (lihat AuthController.refreshUser -- inilah yang dipakai layar
  // verifikasi email untuk mendeteksi status terbaru).
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppUser &&
          other.id == id &&
          other.name == name &&
          other.email == email &&
          other.phone == phone &&
          other.dateOfBirth == dateOfBirth &&
          other.avatarUrl == avatarUrl &&
          other.emailVerifiedAt == emailVerifiedAt);

  @override
  int get hashCode => Object.hash(
    id,
    name,
    email,
    phone,
    dateOfBirth,
    avatarUrl,
    emailVerifiedAt,
  );
}
