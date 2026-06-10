import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';

/// Initialises all Firebase services and local storage before runApp().
class AppServices {
  AppServices._();

  static Future<void> init({FirebaseOptions? options}) async {
    await Firebase.initializeApp(options: options);
    await GetStorage.init();
    _setupCrashlytics();
    await _setupAppCheck();
  }

  static void _setupCrashlytics() {
    final crashlytics = FirebaseCrashlytics.instance;
    FlutterError.onError = crashlytics.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      crashlytics.recordError(error, stack, fatal: true);
      return true;
    };
  }

  static Future<void> _setupAppCheck() async {
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode
          ? AndroidProvider.debug
          : AndroidProvider.playIntegrity,
      appleProvider:
          kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
    );
  }
}
