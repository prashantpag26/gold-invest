import 'package:get/get.dart';

import '../modules/admin/dashboard/controllers/admin_dashboard_controller.dart';
import '../modules/admin/deliveries/controllers/admin_deliveries_controller.dart';
import '../modules/admin/payments/controllers/admin_payments_controller.dart';
import '../modules/admin/plans/controllers/admin_plans_controller.dart';
import '../modules/admin/shell/controllers/admin_shell_controller.dart';
import '../modules/admin/users/controllers/admin_users_controller.dart';
import '../../app/data/repositories/delivery_repository.dart';
import '../../app/data/repositories/enrollment_repository.dart';
import '../../app/data/repositories/plan_repository.dart';
import '../../app/data/repositories/user_repository.dart';
import '../../services/functions_service.dart';

class AdminShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AdminShellController());

    Get.lazyPut(() => AdminDashboardController(
          userRepo: Get.find<UserRepository>(),
          enrollmentRepo: Get.find<EnrollmentRepository>(),
        ));

    Get.lazyPut(() => AdminUsersController(
          userRepo: Get.find<UserRepository>(),
          functionsService: Get.find<FunctionsService>(),
        ));

    Get.lazyPut(() => AdminPaymentsController(
          enrollmentRepo: Get.find<EnrollmentRepository>(),
          userRepo: Get.find<UserRepository>(),
        ));

    Get.lazyPut(() => AdminPlansController(
          planRepo: Get.find<PlanRepository>(),
        ));

    Get.lazyPut(() => AdminDeliveriesController(
          deliveryRepo: Get.find<DeliveryRepository>(),
          userRepo: Get.find<UserRepository>(),
        ));
  }
}
