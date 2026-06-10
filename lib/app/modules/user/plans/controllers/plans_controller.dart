import 'dart:async';

import 'package:flutter/foundation.dart';
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
  final RxString errorMessage = ''.obs;
  StreamSubscription<List<InvestmentPlan>>? _sub;

  @override
  void onInit() {
    super.onInit();
    _subscribe();
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  void _subscribe() {
    _sub?.cancel();
    isLoading.value = true;
    errorMessage.value = '';
    _sub = _planRepo.watchActivePlans().listen(
      (plans) {
        activePlans.assignAll(plans);
        isLoading.value = false;
      },
      onError: (e) {
        debugPrint('[PlansController] stream error: $e');
        isLoading.value = false;
        errorMessage.value = e.toString().contains('permission')
            ? 'Permission denied. Ask your admin to verify your account.'
            : 'Could not load plans. Please check your connection.';
      },
    );
  }

  void retry() => _subscribe();

  Future<void> enroll(InvestmentPlan plan) async {
    final uid = _auth.appUser.value?.uid ?? _auth.firebaseUser.value?.uid;
    if (uid == null) return;
    isEnrolling.value = true;
    try {
      await _enrollmentRepo.enroll(userId: uid, plan: plan);
    } finally {
      isEnrolling.value = false;
    }
  }
}
