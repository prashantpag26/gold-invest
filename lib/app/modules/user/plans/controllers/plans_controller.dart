import 'dart:async';

import 'package:get/get.dart';

import '../../../../data/models/investment_plan.dart';
import '../../../../data/repositories/enrollment_repository.dart';
import '../../../../data/repositories/plan_repository.dart';
import 'package:gold_invest/app/modules/auth/controllers/auth_controller.dart';

class PlansController extends GetxController {
  PlansController({
    required PlanRepository planRepo,
    required EnrollmentRepository enrollmentRepo,
    required AuthController authController,
  })  : _planRepo = planRepo,
        _enrollmentRepo = enrollmentRepo,
        _auth = authController;

  final PlanRepository _planRepo;
  final EnrollmentRepository _enrollmentRepo;
  final AuthController _auth;

  final RxList<InvestmentPlan> activePlans = <InvestmentPlan>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isEnrolling = false.obs;
  StreamSubscription<List<InvestmentPlan>>? _sub;

  @override
  void onInit() {
    super.onInit();
    _sub = _planRepo.watchActivePlans().listen((plans) {
      activePlans.assignAll(plans);
      isLoading.value = false;
    });
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  Future<void> enroll(InvestmentPlan plan) async {
    final uid = _auth.appUser.value?.uid;
    if (uid == null) return;
    isEnrolling.value = true;
    try {
      await _enrollmentRepo.enroll(userId: uid, plan: plan);
    } finally {
      isEnrolling.value = false;
    }
  }
}
