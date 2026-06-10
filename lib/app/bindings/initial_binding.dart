import 'package:get/get.dart';

import '../../app/data/repositories/delivery_repository.dart';
import '../../app/data/repositories/enrollment_repository.dart';
import '../../app/data/repositories/gold_rate_repository.dart';
import '../../app/data/repositories/payment_repository.dart';
import '../../app/data/repositories/plan_repository.dart';
import '../../app/data/repositories/user_repository.dart';
import '../../app/modules/auth/controllers/auth_controller.dart';
import '../../app/modules/admin/gold_rate/controllers/gold_rate_controller.dart';
import '../../app/services/logger_service.dart';
import '../../app/services/notification_service.dart';
import '../../app/themes/theme_controller.dart';
import '../../app/utils/app_config.dart';
import '../../services/auth_service.dart';
import '../../services/functions_service.dart';

/// Registers all permanent (app-lifetime) singletons before the first route
/// renders. Passed as `initialBinding` to [GetMaterialApp].
///
/// Lazy bindings for screen-specific controllers are declared in per-screen
/// binding classes (e.g. UserShellBinding, AuthBinding, etc.).
class InitialBinding extends Bindings {
  InitialBinding({AppConfig? config}) : _config = config ?? AppConfig.dev();

  final AppConfig _config;

  @override
  void dependencies() {
    // ── Config ──────────────────────────────────────────────────────────────
    Get.put(_config, permanent: true);

    // ── Repositories (Firestore wrappers, stateless) ──────────────────────
    Get.put(UserRepository(), permanent: true);
    Get.put(PlanRepository(), permanent: true);
    Get.put(EnrollmentRepository(), permanent: true);
    Get.put(PaymentRepository(), permanent: true);
    Get.put(GoldRateRepository(), permanent: true);
    Get.put(DeliveryRepository(), permanent: true);

    // ── Firebase services ────────────────────────────────────────────────
    Get.put(
      AuthService(users: Get.find<UserRepository>()),
      permanent: true,
    );
    Get.put(FunctionsService(), permanent: true);

    // ── Logger (Analytics + Crashlytics) ─────────────────────────────────
    Get.put(LoggerService(), permanent: true);

    // ── AuthController — must be permanent; middleware reads it on every
    //    navigation event. ──────────────────────────────────────────────────
    Get.put(
      AuthController(
        authService: Get.find<AuthService>(),
        userRepo: Get.find<UserRepository>(),
        logger: Get.find<LoggerService>(),
      ),
      permanent: true,
    );

    // ── Notification service — permanent; watches AuthController.appUser ──
    Get.put(
      GetxNotificationService(users: Get.find<UserRepository>()),
      permanent: true,
    );

    // ── GoldRateController — permanent; GoldRateCard is shared across
    //    both the user and admin dashboards. ─────────────────────────────────
    Get.put(
      GoldRateController(
        goldRateRepo: Get.find<GoldRateRepository>(),
        functionsService: Get.find<FunctionsService>(),
      ),
      permanent: true,
    );

    // ── ThemeController — permanent; manages light/dark preference ────────
    Get.put(ThemeController(), permanent: true);
  }
}
