import 'dart:async';

import 'package:get/get.dart';

import '../../../../data/models/investment_plan.dart';
import '../../../../data/repositories/plan_repository.dart';

class AdminPlansController extends GetxController {
  AdminPlansController({required PlanRepository planRepo})
      : _repo = planRepo;

  final PlanRepository _repo;

  final RxList<InvestmentPlan> allPlans = <InvestmentPlan>[].obs;
  final RxBool isBusy = false.obs;
  StreamSubscription<List<InvestmentPlan>>? _sub;

  @override
  void onInit() {
    super.onInit();
    _sub = _repo.watchAllPlans().listen((p) => allPlans.assignAll(p));
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  Future<void> createPlan(InvestmentPlan plan) async {
    isBusy.value = true;
    try {
      await _repo.createPlan(plan);
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> updatePlan(InvestmentPlan plan) async {
    isBusy.value = true;
    try {
      await _repo.updatePlan(plan);
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> deletePlan(String id) => _repo.deletePlan(id);
  Future<void> setActive(String id, bool active) =>
      _repo.setActive(id, active);
}
