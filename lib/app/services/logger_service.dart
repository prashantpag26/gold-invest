import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Wraps Firebase Analytics + Crashlytics behind a single logging surface.
///
/// Registered as a permanent GetX service in InitialBinding so any controller
/// or service can call `Get.find<LoggerService>()`.
class LoggerService extends GetxService {
  final _analytics = FirebaseAnalytics.instance;
  final _crashlytics = FirebaseCrashlytics.instance;

  Future<void> logEvent(
    String name, {
    Map<String, Object>? params,
  }) async {
    try {
      await _analytics.logEvent(name: name, parameters: params);
    } catch (e) {
      debugPrint('[LoggerService] logEvent error: $e');
    }
  }

  Future<void> logScreen(String screenName) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
    } catch (e) {
      debugPrint('[LoggerService] logScreen error: $e');
    }
  }

  Future<void> setUserId(String? uid) async {
    try {
      await _analytics.setUserId(id: uid);
      await _crashlytics.setUserIdentifier(uid ?? '');
    } catch (e) {
      debugPrint('[LoggerService] setUserId error: $e');
    }
  }

  void logError(Object error, StackTrace? stack, {String? reason}) {
    try {
      _crashlytics.recordError(error, stack, reason: reason);
    } catch (e) {
      debugPrint('[LoggerService] logError error: $e');
    }
  }
}
