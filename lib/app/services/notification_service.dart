import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../app/data/repositories/user_repository.dart';
import '../../app/modules/auth/controllers/auth_controller.dart';

/// Manages FCM permission, device token registration, and deep-link handling.
///
/// Registered as a permanent GetX service in InitialBinding. Replaces the
/// Riverpod-based NotificationService in lib/services/notification_service.dart.
class GetxNotificationService extends GetxService {
  GetxNotificationService({required UserRepository users}) : _users = users;

  final UserRepository _users;
  StreamSubscription<String>? _tokenRefreshSub;
  String? _currentUid;

  @override
  void onInit() {
    super.onInit();

    // Watch auth changes to sync/reset the FCM token automatically.
    ever(Get.find<AuthController>().appUser, (user) {
      if (user != null) {
        syncForUser(user.uid);
      } else {
        reset();
      }
    });

    // Deep-link: handle taps on push notifications when app was backgrounded.
    FirebaseMessaging.onMessageOpenedApp.listen(_handleDeepLink);

    // Foreground messages — show as GetX snackbar.
    FirebaseMessaging.onMessage.listen(_handleForeground);
  }

  @override
  void onClose() {
    _tokenRefreshSub?.cancel();
    super.onClose();
  }

  /// Requests permission and syncs the FCM token to the user's Firestore
  /// profile. Idempotent — no-op if already registered for [uid].
  Future<void> syncForUser(String uid) async {
    if (_currentUid == uid) return;
    _currentUid = uid;
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _users.updateFcmToken(uid, token);

      _tokenRefreshSub?.cancel();
      _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen(
        (newToken) => _users.updateFcmToken(uid, newToken),
      );
    } catch (e) {
      debugPrint('[GetxNotificationService] syncForUser error: $e');
    }
  }

  void reset() {
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    _currentUid = null;
  }

  void _handleForeground(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;
    final text = [n.title, n.body]
        .where((s) => s != null && s.isNotEmpty)
        .join(' — ');
    if (text.isEmpty) return;
    Get.snackbar('', text,
        snackPosition: SnackPosition.TOP,
        isDismissible: true,
        duration: const Duration(seconds: 4));
  }

  void _handleDeepLink(RemoteMessage message) {
    final route = message.data['route'] as String?;
    if (route != null && route.isNotEmpty) {
      Get.toNamed(route);
    }
  }
}
