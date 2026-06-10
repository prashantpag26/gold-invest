import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../app/modules/auth/controllers/auth_controller.dart';
import '../app_routes.dart';

/// Auth/role guard — attached to EVERY [GetPage].
///
/// Implements the same 5-step chain that was in go_router's redirect callback:
///   1. Auth stream not resolved yet  → /splash
///   2. Signed out                    → /login
///   3. Profile stream not resolved   → /splash
///   4. Profile missing / not approved → /pending
///   5. Approved admin                → /admin
///      Approved user                 → /  (blocked from /admin/*)
class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    final auth = Get.find<AuthController>();
    final loc = route ?? '/';

    // 1. Auth still resolving.
    if (auth.isLoadingAuth.value) {
      return loc == AppRoutes.splash
          ? null
          : const RouteSettings(name: AppRoutes.splash);
    }

    // 2. Signed out.
    if (!auth.isSignedIn) {
      final atAuthScreen =
          loc == AppRoutes.login || loc == AppRoutes.register;
      return atAuthScreen
          ? null
          : const RouteSettings(name: AppRoutes.login);
    }

    // 3. Profile still loading.
    if (auth.isLoadingProfile.value) {
      return loc == AppRoutes.splash
          ? null
          : const RouteSettings(name: AppRoutes.splash);
    }

    // 4. Profile missing or not approved.
    if (!auth.isApproved) {
      return loc == AppRoutes.pending
          ? null
          : const RouteSettings(name: AppRoutes.pending);
    }

    // 5. Approved — role-based routing.
    final atPreAuth = loc == AppRoutes.login ||
        loc == AppRoutes.register ||
        loc == AppRoutes.pending ||
        loc == AppRoutes.splash;

    if (auth.isAdmin) {
      return atPreAuth
          ? const RouteSettings(name: AppRoutes.adminHome)
          : null;
    } else {
      if (atPreAuth || loc.startsWith('/admin')) {
        return const RouteSettings(name: AppRoutes.userHome);
      }
      return null;
    }
  }
}
