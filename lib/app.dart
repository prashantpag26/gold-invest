import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/bindings/initial_binding.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/utils/app_config.dart';
import 'app/utils/app_translations.dart';
import 'core/theme/app_theme.dart';

/// Root widget. Configures GetMaterialApp with:
///  - [InitialBinding] — registers all permanent services (auth, repos, logger…)
///  - [AppPages] — named routes, each with [AuthMiddleware]
///  - [AppTranslations] — EN / AR / HI / GU localization
///  - Light + dark Material 3 themes seeded from the gold colour
class GoldInvestApp extends StatelessWidget {
  const GoldInvestApp({super.key, AppConfig? config}) : _config = config;

  final AppConfig? _config;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppTranslations>(
      future: AppTranslations.load(),
      builder: (context, snapshot) {
        final translations = snapshot.data;
        return GetMaterialApp(
          title: 'app_name'.tr,
          debugShowCheckedModeBanner: false,
          initialBinding: InitialBinding(config: _config),
          initialRoute: AppRoutes.splash,
          getPages: AppPages.pages,
          translations: translations,
          locale: Get.deviceLocale,
          fallbackLocale: const Locale('en', 'US'),
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.system,
        );
      },
    );
  }
}
