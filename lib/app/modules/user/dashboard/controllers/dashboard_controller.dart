import 'dart:async';

import 'package:flutter/foundation.dart';
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
    // Also react to firebaseUser so we can load by UID even when
    // the Firestore profile hasn't arrived yet.
    ever(_auth.firebaseUser, (_) => _subscribe());
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  void refresh() => _subscribe();

  void _subscribe() {
    _sub?.cancel();
    // Prefer appUser.uid; fall back to firebaseUser.uid so the dashboard
    // can load enrollments even when the Firestore profile is still syncing.
    final uid = _auth.appUser.value?.uid ?? _auth.firebaseUser.value?.uid;
    if (uid == null) {
      myEnrollments.clear();
      isLoading.value = false;
      return;
    }
    isLoading.value = true;
    _sub = _enrollmentRepo.watchUserEnrollments(uid).listen(
      (list) {
        myEnrollments.assignAll(list);
        isLoading.value = false;
      },
      onError: (e) {
        debugPrint('[DashboardController] stream error: $e');
        isLoading.value = false;
      },
    );
  }
}
