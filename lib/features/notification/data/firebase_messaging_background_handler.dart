import 'package:firebase_messaging/firebase_messaging.dart';

/// Harus top-level function (bukan method di class) dan diberi anotasi ini
/// -- kontrak `FirebaseMessaging.onBackgroundMessage`, dijalankan di isolate
/// terpisah saat app background/ketutup. Kosong dengan sengaja: sistem
/// Android sendiri yang menampilkan notification payload-nya di tray,
/// handler ini cuma perlu ada supaya data payload tidak didrop diam-diam.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}
