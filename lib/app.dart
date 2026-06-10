import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/bindings/initial_binding.dart';
import 'app/modules/auth/controllers/auth_controller.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/utils/app_config.dart';
import 'app/utils/app_translations.dart';
import 'core/theme/app_theme.dart';

/// Root widget. Translations are loaded before runApp() and passed in so that
/// every `.tr` call resolves correctly on the very first frame.
class GoldInvestApp extends StatelessWidget {
  const GoldInvestApp({
    super.key,
    AppConfig? config,
    AppTranslations? translations,
  })  : _config = config,
        _translations = translations;

  final AppConfig? _config;
  final AppTranslations? _translations;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Gold Invest',
      debugShowCheckedModeBanner: false,
      initialBinding: InitialBinding(config: _config),
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
      translations: _translations,
      locale: Get.deviceLocale ?? const Locale('en', 'US'),
      fallbackLocale: const Locale('en', 'US'),
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      // Once the navigator is mounted, run the first route evaluation.
      // This catches the case where ever() fired before the navigator was ready.
      onReady: () => Get.find<AuthController>().onRouterReady(),
    );
  }
}
