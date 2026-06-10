import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:gold_invest/core/constants.dart';

import '../../../../data/models/app_user.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../../../../services/functions_service.dart';

class AdminUsersController extends GetxController {
  AdminUsersController({
    required UserRepository userRepo,
    required FunctionsService functionsService,
  })  : _userRepo = userRepo,
        _functions = functionsService;

  final UserRepository _userRepo;
  final FunctionsService _functions;

  // ── Pending users — real-time stream (small, critical for notifications) ──
  final RxList<AppUser> pendingUsers = <AppUser>[].obs;
  StreamSubscription<List<AppUser>>? _pendingSub;

  // ── All users — paginated cursor fetch ─────────────────────────────────────
  final RxList<AppUser> allUsers = <AppUser>[].obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = true.obs;
  final RxBool isBusy = false.obs;
  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;
  static const _pageSize = 20;

  @override
  void onInit() {
    super.onInit();
    _pendingSub = _userRepo
        .watchByStatus(UserStatus.pending)
        .listen((u) => pendingUsers.assignAll(u));
    loadMoreUsers();
  }

  @override
  void onClose() {
    _pendingSub?.cancel();
    super.onClose();
  }

  Future<void> loadMoreUsers() async {
    if (isLoadingMore.value || !hasMore.value) return;
    isLoadingMore.value = true;
    try {
      final query = _lastDoc == null
          ? _userRepo.usersColRef
              .orderBy('createdAt', descending: true)
              .limit(_pageSize)
          : _userRepo.usersColRef
              .orderBy('createdAt', descending: true)
              .startAfterDocument(_lastDoc!)
              .limit(_pageSize);
      final snap = await query.get();
      if (snap.docs.length < _pageSize) hasMore.value = false;
      if (snap.docs.isNotEmpty) {
        _lastDoc = snap.docs.last
            as DocumentSnapshot<Map<String, dynamic>>;
      }
      allUsers.addAll(snap.docs.map(AppUser.fromFirestore));
    } finally {
      isLoadingMore.value = false;
    }
  }

  void resetAndReload() {
    allUsers.clear();
    _lastDoc = null;
    hasMore.value = true;
    loadMoreUsers();
  }

  Future<void> approveUser(String uid, String adminUid,
      {bool useCloudFunctions = false}) async {
    isBusy.value = true;
    try {
      if (useCloudFunctions) {
        await _functions.approveUser(uid);
      } else {
        await _userRepo.setStatus(uid, UserStatus.approved, adminUid);
      }
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> rejectUser(String uid, String adminUid,
      {bool useCloudFunctions = false}) async {
    isBusy.value = true;
    try {
      if (useCloudFunctions) {
        await _functions.rejectUser(uid);
      } else {
        await _userRepo.setStatus(uid, UserStatus.rejected, adminUid);
      }
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> setAdminClaim(String uid, bool isAdmin) =>
      _functions.setAdminClaim(uid, isAdmin);
}
