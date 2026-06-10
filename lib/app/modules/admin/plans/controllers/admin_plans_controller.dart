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
    _sub = _repo.watchAllPlans().listen(
      (p) => allPlans.assignAll(p),
      onError: (_) {},
    );
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

  /// Creates the four standard plan denominations using fixed document IDs
  /// so the operation is idempotent — safe to run multiple times.
  static const _samplePlans = [
    ('plan_1g',  '1g Monthly Saver',  1.0,  12, 600.0),
    ('plan_2g',  '2g Monthly Saver',  2.0,  12, 1200.0),
    ('plan_5g',  '5g Gold Plan',      5.0,  12, 3000.0),
    ('plan_10g', '10g Gold Builder',  10.0, 12, 6000.0),
  ];

  Future<void> seedSamplePlans() async {
    isBusy.value = true;
    try {
      for (final (id, name, grams, months, amount) in _samplePlans) {
        await _repo.upsertPlan(
          id,
          InvestmentPlan(
            id: id,
            name: name,
            grams: grams,
            durationMonths: months,
            monthlyAmount: amount,
            active: true,
          ),
        );
      }
    } finally {
      isBusy.value = false;
    }
  }
}
