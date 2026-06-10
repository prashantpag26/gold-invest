import 'package:get/get.dart';

import '../modules/auth/controllers/auth_controller.dart';
import '../modules/user/enrollment/controllers/enrollment_detail_controller.dart';
import '../../app/data/repositories/enrollment_repository.dart';
import '../../app/data/repositories/payment_repository.dart';

class EnrollmentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => EnrollmentDetailController(
          enrollmentId: Get.arguments as String,
          enrollmentRepo: Get.find<EnrollmentRepository>(),
          paymentRepo: Get.find<PaymentRepository>(),
          authController: Get.find<AuthController>(),
        ));
  }
}
