import 'dart:async';

import 'package:get/get.dart';

import '../../../../data/models/enrollment.dart';
import '../../../../data/repositories/enrollment_repository.dart';
import 'package:gold_invest/app/modules/auth/controllers/auth_controller.dart';

class DashboardController extends GetxController {
  DashboardController({
    required EnrollmentRepository enrollmentRepo,
    required AuthController authController,
  })  : _enrollmentRepo = enrollmentRepo,
        _auth = authController;

  final EnrollmentRepository _enrollmentRepo;
  final AuthController _auth;

  final RxList<Enrollment> myEnrollments = <Enrollment>[].obs;
  final RxBool isLoading = true.obs;
  StreamSubscription<List<Enrollment>>? _sub;

  @override
  void onInit() {
    super.onInit();
    _subscribe();
    ever(_auth.appUser, (_) => _subscribe());
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  void refresh() => _subscribe();

  void _subscribe() {
    _sub?.cancel();
    final uid = _auth.appUser.value?.uid;
    if (uid == null) {
      myEnrollments.clear();
      isLoading.value = false;
      return;
    }
    isLoading.value = true;
    _sub = _enrollmentRepo.watchUserEnrollments(uid).listen((list) {
      myEnrollments.assignAll(list);
      isLoading.value = false;
    });
  }
}
