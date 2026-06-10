import 'dart:async';

import 'package:get/get.dart';

import '../../../../data/models/gold_rate.dart';
import '../../../../data/repositories/gold_rate_repository.dart';
import '../../../../../services/functions_service.dart';

/// Permanent controller — registered in InitialBinding because GoldRateCard
/// is shared across the user and admin dashboards.
class GoldRateController extends GetxController {
  GoldRateController({
    required GoldRateRepository goldRateRepo,
    required FunctionsService functionsService,
  })  : _repo = goldRateRepo,
        _functions = functionsService;

  final GoldRateRepository _repo;
  final FunctionsService _functions;

  final Rx<GoldRate?> currentRate = Rx<GoldRate?>(null);
  final RxList<GoldRate> history = <GoldRate>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;

  StreamSubscription<GoldRate?>? _rateSub;
  StreamSubscription<List<GoldRate>>? _historySub;

  @override
  void onInit() {
    super.onInit();
    _rateSub = _repo.watchCurrent().listen((r) {
      currentRate.value = r;
      isLoading.value = false;
    });
    _historySub =
        _repo.watchHistory().listen((h) => history.assignAll(h));
  }

  @override
  void onClose() {
    _rateSub?.cancel();
    _historySub?.cancel();
    super.onClose();
  }

  Future<void> setManualRate({
    required double pricePerGram,
    required bool lockManual,
    required String adminUid,
  }) async {
    isSaving.value = true;
    try {
      await _repo.setManualRate(
        pricePerGram: pricePerGram,
        lockManual: lockManual,
        adminUid: adminUid,
      );
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> fetchLiveRate() async {
    isSaving.value = true;
    try {
      await _functions.refreshGoldRateNow();
    } finally {
      isSaving.value = false;
    }
  }
}
