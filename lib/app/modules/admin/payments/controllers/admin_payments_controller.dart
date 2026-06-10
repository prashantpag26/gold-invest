import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../../../data/models/app_user.dart';
import '../../../../data/models/enrollment.dart';
import '../../../../data/repositories/enrollment_repository.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../../../core/constants.dart';

enum PaymentFilter { all, active, overdue, ready, delivered }

class AdminPaymentsController extends GetxController {
  AdminPaymentsController({
    required EnrollmentRepository enrollmentRepo,
    required UserRepository userRepo,
  })  : _enrollmentRepo = enrollmentRepo,
        _userRepo = userRepo;

  final EnrollmentRepository _enrollmentRepo;
  final UserRepository _userRepo;

  // ── All enrollments — paginated cursor fetch ──────────────────────────────
  final RxList<Enrollment> allEnrollments = <Enrollment>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = true.obs;
  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;
  static const _pageSize = 20;

  // ── All users — real-time stream (needed for name lookups) ────────────────
  final RxList<AppUser> allUsers = <AppUser>[].obs;
  StreamSubscription<List<AppUser>>? _userSub;

  final Rx<PaymentFilter> filter = PaymentFilter.all.obs;

  @override
  void onInit() {
    super.onInit();
    _userSub = _userRepo.watchAll().listen((u) => allUsers.assignAll(u));
    loadMore();
  }

  @override
  void onClose() {
    _userSub?.cancel();
    super.onClose();
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value) return;
    isLoadingMore.value = true;
    try {
      final query = _lastDoc == null
          ? _enrollmentRepo.col
              .orderBy('createdAt', descending: true)
              .limit(_pageSize)
          : _enrollmentRepo.col
              .orderBy('createdAt', descending: true)
              .startAfterDocument(_lastDoc!)
              .limit(_pageSize);
      final snap = await query.get();
      if (snap.docs.length < _pageSize) hasMore.value = false;
      if (snap.docs.isNotEmpty) {
        _lastDoc = snap.docs.last
            as DocumentSnapshot<Map<String, dynamic>>;
      }
      allEnrollments
          .addAll(snap.docs.map(Enrollment.fromFirestore));
      isLoading.value = false;
    } finally {
      isLoadingMore.value = false;
    }
  }

  void resetAndReload() {
    allEnrollments.clear();
    _lastDoc = null;
    hasMore.value = true;
    isLoading.value = true;
    loadMore();
  }

  List<Enrollment> get filtered {
    final now = DateTime.now();
    return allEnrollments.where((e) {
      switch (filter.value) {
        case PaymentFilter.all:
          return true;
        case PaymentFilter.active:
          return e.status == EnrollmentStatus.active &&
              !_isOverdue(e, now) &&
              !e.isCompleted;
        case PaymentFilter.overdue:
          return _isOverdue(e, now);
        case PaymentFilter.ready:
          return e.isCompleted &&
              e.status != EnrollmentStatus.cancelled;
        case PaymentFilter.delivered:
          return e.actualDeliveryDate != null;
      }
    }).toList();
  }

  bool _isOverdue(Enrollment e, DateTime now) {
    if (e.status != EnrollmentStatus.active) return false;
    if (e.projectedDeliveryDate == null) return false;
    return now.isAfter(e.projectedDeliveryDate!) && !e.isCompleted;
  }

  AppUser? userFor(String userId) {
    try {
      return allUsers.firstWhere((u) => u.uid == userId);
    } catch (_) {
      return null;
    }
  }
}
