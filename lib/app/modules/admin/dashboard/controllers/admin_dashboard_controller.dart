import 'dart:async';

import 'package:get/get.dart';
import 'package:gold_invest/core/constants.dart';

import '../../../../data/models/app_user.dart';
import '../../../../data/models/enrollment.dart';
import '../../../../data/repositories/enrollment_repository.dart';
import '../../../../data/repositories/user_repository.dart';

class AdminDashboardController extends GetxController {
  AdminDashboardController({
    required UserRepository userRepo,
    required EnrollmentRepository enrollmentRepo,
  })  : _userRepo = userRepo,
        _enrollmentRepo = enrollmentRepo;

  final UserRepository _userRepo;
  final EnrollmentRepository _enrollmentRepo;

  final RxList<AppUser> pendingUsers = <AppUser>[].obs;
  final RxList<Enrollment> allEnrollments = <Enrollment>[].obs;
  final RxBool isLoading = true.obs;

  StreamSubscription<List<AppUser>>? _pendingSub;
  StreamSubscription<List<Enrollment>>? _enrollmentSub;

  @override
  void onInit() {
    super.onInit();
    _pendingSub = _userRepo
        .watchByStatus(UserStatus.pending)
        .listen((u) => pendingUsers.assignAll(u));
    _enrollmentSub = _enrollmentRepo.watchAll().listen((e) {
      allEnrollments.assignAll(e);
      isLoading.value = false;
    });
  }

  @override
  void onClose() {
    _pendingSub?.cancel();
    _enrollmentSub?.cancel();
    super.onClose();
  }
}
