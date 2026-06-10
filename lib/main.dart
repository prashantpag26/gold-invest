import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';

import 'app.dart';
import 'app/services/app_services.dart';
import 'app/utils/app_config.dart';
import 'app/utils/app_translations.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';

/// Shared startup used by main.dart and all flavor entry points.
///
/// Translations are loaded here — before runApp — so [GetMaterialApp] always
/// receives a fully-populated [AppTranslations] on its first build. Loading
/// them inside a FutureBuilder caused `.tr` to return raw keys on first render.
Future<void> runGoldInvestApp({
  AppConfig? config,
  FirebaseOptions? firebaseOptions,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  final translations = await AppTranslations.load();
  await AppServices.init(
    options: firebaseOptions ?? DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  runApp(GoldInvestApp(
    config: config ?? AppConfig.dev(),
    translations: translations,
  ));
}

Future<void> main() async {
  await runGoldInvestApp();
}
