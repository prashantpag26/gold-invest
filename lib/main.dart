import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';

import 'app.dart';
import 'app/services/app_services.dart';
import 'app/utils/app_config.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';

/// Shared startup used by main.dart and all flavor entry points.
Future<void> runGoldInvestApp({
  AppConfig? config,
  FirebaseOptions? firebaseOptions,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppServices.init(
    options: firebaseOptions ?? DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  runApp(GoldInvestApp(config: config ?? AppConfig.dev()));
}

Future<void> main() async {
  await runGoldInvestApp();
}
