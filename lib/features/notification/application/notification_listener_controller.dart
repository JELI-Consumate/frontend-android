import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/app_navigator.dart';
import '../../learning/data/learning_repository.dart';
import '../../module/presentation/module_screen.dart';
import '../data/local_notification_service.dart';
import '../data/resume_progress_repository.dart';

class NotificationListenerController {
  NotificationListenerController(this._ref);

  final Ref _ref;

  bool _attached = false;

  Future<void> attach() async {
    if (_attached) return;
    _attached = true;

    try {
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(
        (_) => _navigateToResumePoint(),
      );

      final initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      if (initialMessage != null) {
        await _navigateToResumePoint();
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('NotificationListenerController.attach gagal: $error');
      }
    }
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _ref
        .read(localNotificationServiceProvider)
        .show(title: notification.title, body: notification.body);
  }

  Future<void> _navigateToResumePoint() async {
    try {
      final next = await _ref.read(resumeProgressRepositoryProvider).next();
      final journeyId = next.journeyId;
      final modulePageId = next.modulePageId;
      if (journeyId == null || modulePageId == null) return;

      final journeyDetail = await _ref
          .read(learningRepositoryProvider)
          .journeyDetail(journeyId);

      final targetModule = journeyDetail.modules
          .where((module) => module.pageIds.contains(modulePageId))
          .firstOrNull;
      if (targetModule == null) return;

      final navigator = _ref.read(navigatorKeyProvider).currentState;
      navigator?.push(
        MaterialPageRoute(
          builder: (_) => ModuleScreen(
            moduleId: targetModule.id,
            journeyModuleIds: journeyDetail.modules
                .map((module) => module.id)
                .toList(),
          ),
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Gagal navigate ke titik lanjut belajar: $error');
      }
    }
  }
}

final notificationListenerControllerProvider =
    Provider<NotificationListenerController>((ref) {
      return NotificationListenerController(ref);
    });
