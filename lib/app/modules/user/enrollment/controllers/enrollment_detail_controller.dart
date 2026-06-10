import 'dart:async';

import 'package:get/get.dart';

import '../../../../data/models/enrollment.dart';
import '../../../../data/models/payment.dart';
import '../../../../data/repositories/enrollment_repository.dart';
import '../../../../data/repositories/payment_repository.dart';
import 'package:gold_invest/app/modules/auth/controllers/auth_controller.dart';

class EnrollmentDetailController extends GetxController {
  EnrollmentDetailController({
    required String enrollmentId,
    required EnrollmentRepository enrollmentRepo,
    required PaymentRepository paymentRepo,
    required AuthController authController,
  })  : _enrollmentId = enrollmentId,
        _enrollmentRepo = enrollmentRepo,
        _paymentRepo = paymentRepo,
        _auth = authController;

  final String _enrollmentId;
  final EnrollmentRepository _enrollmentRepo;
  final PaymentRepository _paymentRepo;
  final AuthController _auth;

  final Rx<Enrollment?> enrollment = Rx<Enrollment?>(null);
  final RxList<Payment> payments = <Payment>[].obs;
  final RxBool isLoading = true.obs;
  StreamSubscription<Enrollment?>? _enrollmentSub;
  StreamSubscription<List<Payment>>? _paymentsSub;

  String get enrollmentId => _enrollmentId;

  @override
  void onInit() {
    super.onInit();
    _enrollmentSub = _enrollmentRepo
        .watchEnrollment(_enrollmentId)
        .listen((e) {
      enrollment.value = e;
      isLoading.value = false;
    });
    _paymentsSub = _paymentRepo
        .watchPayments(_enrollmentId)
        .listen((p) => payments.assignAll(p));
  }

  @override
  void onClose() {
    _enrollmentSub?.cancel();
    _paymentsSub?.cancel();
    super.onClose();
  }

  Future<void> deleteLastPayment() async {
    if (payments.isEmpty) return;
    final last = payments.reduce((a, b) => a.cycle > b.cycle ? a : b);
    await _paymentRepo.deletePayment(
      enrollmentId: _enrollmentId,
      paymentId: last.id,
    );
  }

  bool get isAdmin => _auth.isAdmin;
  String get currentAdminUid => _auth.firebaseUser.value?.uid ?? '';
}
