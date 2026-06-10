import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../../data/models/app_user.dart';
import '../../../../data/models/delivery.dart';
import '../../../../data/repositories/delivery_repository.dart';
import '../../../../data/repositories/user_repository.dart';

class AdminDeliveriesController extends GetxController {
  AdminDeliveriesController({
    required DeliveryRepository deliveryRepo,
    required UserRepository userRepo,
  })  : _deliveryRepo = deliveryRepo,
        _userRepo = userRepo;

  final DeliveryRepository _deliveryRepo;
  final UserRepository _userRepo;

  final RxList<Delivery> allDeliveries = <Delivery>[].obs;
  final RxList<AppUser> allUsers = <AppUser>[].obs;
  final RxBool isLoading = true.obs;

  StreamSubscription<List<Delivery>>? _deliverySub;
  StreamSubscription<List<AppUser>>? _userSub;

  @override
  void onInit() {
    super.onInit();
    _deliverySub = _deliveryRepo.watchAll().listen(
      (d) {
        allDeliveries.assignAll(d);
        isLoading.value = false;
      },
      onError: (e) {
        debugPrint('[AdminDeliveries] stream error: $e');
        isLoading.value = false;
      },
    );
    _userSub = _userRepo.watchAll().listen(
      (u) => allUsers.assignAll(u),
      onError: (e) => debugPrint('[AdminDeliveries] users error: $e'),
    );
  }

  @override
  void onClose() {
    _deliverySub?.cancel();
    _userSub?.cancel();
    super.onClose();
  }

  AppUser? userFor(String userId) {
    try {
      return allUsers.firstWhere((u) => u.uid == userId);
    } catch (_) {
      return null;
    }
  }
}
