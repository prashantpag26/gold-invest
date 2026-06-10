import 'package:get/get.dart';

import '../../app/bindings/admin_shell_binding.dart';
import '../../app/bindings/auth_binding.dart';
import '../../app/bindings/enrollment_binding.dart';
import '../../app/bindings/user_shell_binding.dart';
import '../../app/modules/admin/shell/views/admin_home_shell_view.dart';
import '../../app/modules/auth/views/login_view.dart';
import '../../app/modules/auth/views/pending_approval_view.dart';
import '../../app/modules/auth/views/register_view.dart';
import '../../app/modules/auth/views/splash_view.dart';
import '../../app/modules/user/enrollment/views/enrollment_detail_view.dart';
import '../../app/modules/user/shell/views/user_home_shell_view.dart';
import '../../app/routes/app_routes.dart';
import '../../app/routes/middleware/auth_middleware.dart';

/// Every page carries [AuthMiddleware] to ensure the 5-step auth guard fires
/// on every navigation event (unlike go_router's single global redirect, GetX
/// middleware is per-page only).
class AppPages {
  static final pages = [
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
    GetPage(
      name: AppRoutes.adminHome,
      page: () => const AdminHomeShellView(),
      middlewares: [AuthMiddleware()],
      binding: AdminShellBinding(),
    ),
  ];
}
