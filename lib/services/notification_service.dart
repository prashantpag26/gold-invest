import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../repositories/user_repository.dart';

/// Background/terminated message handler.
///
/// `notification` messages are displayed in the system tray automatically by
/// the OS, so this is intentionally a no-op — the realtime Firestore streams
/// refresh the UI the next time the app is opened. It must be a top-level
/// function annotated with `@pragma('vm:entry-point')`.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No work needed; kept for future data-message handling.
}

/// Manages FCM permission and token registration.
///
/// Notifications are *sent* by Firestore-triggered Cloud Functions (approval,
/// payment, delivery). The client's only jobs are: ask permission and keep the
/// signed-in user's `fcmToken` fresh in their profile. (Foreground display is
/// owned by the root widget, which shows a snackbar.)
class NotificationService {
  NotificationService({FirebaseMessaging? messaging, UserRepository? users})
      : _messaging = messaging ?? FirebaseMessaging.instance,
        _users = users ?? UserRepository();

  final FirebaseMessaging _messaging;
  final UserRepository _users;

  String? _registeredUid;
  StreamSubscription<String>? _tokenRefreshSub;

  /// Request permission (idempotent) and store the device token on the user's
  /// profile so the server can target them. Should be called once the user's
  /// profile document exists. Never throws — push is best-effort.
  Future<void> syncForUser(String uid) async {
    if (_registeredUid == uid) return; // already wired for this user
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return;
      }

      final token = await _messaging.getToken();
      if (token != null) {
        await _users.updateFcmToken(uid, token);
      }
      _registeredUid = uid;

      // Exactly one refresh listener; replace any previous one so a token
      // rotation never targets a signed-out / previous user.
      await _tokenRefreshSub?.cancel();
      _tokenRefreshSub = _messaging.onTokenRefresh.listen((t) async {
        // update() throws not-found if the profile was deleted mid-session;
        // swallow it — push is best-effort.
        try {
          await _users.updateFcmToken(uid, t);
        } catch (e) {
          debugPrint('FCM token refresh skipped: $e');
        }
      });
    } catch (e) {
      debugPrint('FCM sync skipped: $e');
    }
  }

  /// Call on sign-out so the next user re-registers cleanly.
  void reset() {
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    _registeredUid = null;
  }
}
