import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';

import 'app/utils/app_config.dart';
import 'firebase_options.dart';
import 'main.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await runGoldInvestApp(
    config: AppConfig.prod(),
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
  );
}
