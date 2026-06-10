import 'package:get/get.dart';

import '../../app/bindings/admin_shell_binding.dart';
import '../../app/bindings/auth_binding.dart';
import '../../app/bindings/enrollment_binding.dart';
import '../../app/bindings/user_shell_binding.dart';
import '../../app/modules/admin/deliveries/views/admin_deliveries_view.dart';
import '../../app/modules/admin/gold_rate/views/admin_gold_rate_view.dart';
import '../../app/modules/admin/plans/views/admin_plans_view.dart';
import '../../app/modules/admin/shell/views/admin_home_shell_view.dart';
import '../../app/modules/auth/views/login_view.dart';
import '../../app/modules/auth/views/pending_approval_view.dart';
import '../../app/modules/auth/views/register_view.dart';
import '../../app/modules/auth/views/splash_view.dart';
import '../../app/modules/user/enrollment/views/enrollment_detail_view.dart';
import '../../app/modules/user/shell/views/user_home_shell_view.dart';
import '../../app/routes/app_routes.dart';
import '../../app/routes/middleware/auth_middleware.dart';

/// Every page carries [AuthMiddleware] so the 5-step auth guard fires on
/// every navigation event.
class AppPages {
  static final pages = [
    // ── Auth ─────────────────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      middlewares: [AuthMiddleware()],
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterView(),
      middlewares: [AuthMiddleware()],
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.pending,
      page: () => const PendingApprovalView(),
      middlewares: [AuthMiddleware()],
      binding: AuthBinding(),
    ),

    // ── User ──────────────────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.userHome,
      page: () => const UserHomeShellView(),
      middlewares: [AuthMiddleware()],
      binding: UserShellBinding(),
    ),
    GetPage(
      name: AppRoutes.enrollment,
      page: () => const EnrollmentDetailView(),
      middlewares: [AuthMiddleware()],
      binding: EnrollmentBinding(),
    ),

    // ── Admin shell ───────────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.adminHome,
      page: () => const AdminHomeShellView(),
      middlewares: [AuthMiddleware()],
      binding: AdminShellBinding(),
    ),

    // ── Admin sub-pages (controllers already registered by AdminShellBinding) ─
    GetPage(
      name: AppRoutes.adminGoldRate,
      page: () => const AdminGoldRateView(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.adminPlans,
      page: () => const AdminPlansView(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.adminDeliveries,
      page: () => const AdminDeliveriesView(),
      middlewares: [AuthMiddleware()],
    ),
  ];
}
