import 'package:get/get.dart';

import '../modules/auth/controllers/auth_controller.dart';
import '../modules/user/dashboard/controllers/dashboard_controller.dart';
import '../modules/user/plans/controllers/plans_controller.dart';
import '../modules/user/profile/controllers/profile_controller.dart';
import '../modules/user/redemption/controllers/redemption_controller.dart';
import '../modules/user/shell/controllers/user_shell_controller.dart';
import '../../app/data/repositories/enrollment_repository.dart';
import '../../app/data/repositories/plan_repository.dart';

class UserShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => UserShellController());

    Get.lazyPut(() => DashboardController(
          enrollmentRepo: Get.find<EnrollmentRepository>(),
          authController: Get.find<AuthController>(),
        ));

    Get.lazyPut(() => PlansController(
          planRepo: Get.find<PlanRepository>(),
          enrollmentRepo: Get.find<EnrollmentRepository>(),
          authController: Get.find<AuthController>(),
        ));

    Get.lazyPut(() => RedemptionController(
          enrollmentRepo: Get.find<EnrollmentRepository>(),
          authController: Get.find<AuthController>(),
        ));

    Get.lazyPut(() => ProfileController(
          authController: Get.find<AuthController>(),
        ));
  }
}
