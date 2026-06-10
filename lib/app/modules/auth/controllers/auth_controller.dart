import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:gold_invest/app/data/models/app_user.dart';
import 'package:gold_invest/app/data/repositories/user_repository.dart';
import 'package:gold_invest/app/services/logger_service.dart';
import 'package:gold_invest/app/utils/app_config.dart';
import 'package:gold_invest/core/constants.dart';
import 'package:gold_invest/services/auth_service.dart';

/// Central auth + profile state.  Mirrors the two Riverpod StreamProviders
/// (`authStateProvider` and `currentAppUserProvider`) that were removed.
///
/// Both loading flags start as `true` — the middleware reads these synchronous
/// flags, so they must remain `true` until Firebase first responds.  A
/// premature `false` would redirect to /login before auth resolves.
///
/// The `ever()` reactions on [firebaseUser] and [appUser] trigger
/// `_reevaluateRoute()`, which replaces the go_router `refreshListenable`
/// ValueNotifier that caused the guard to re-run on every auth/profile change.
class AuthController extends GetxController {
  AuthController({
    required AuthService authService,
    required UserRepository userRepo,
    required LoggerService logger,
  })  : _authService = authService,
        _userRepo = userRepo,
        _logger = logger;

  final AuthService _authService;
  final UserRepository _userRepo;
  final LoggerService _logger;

  // ── Reactive state ──────────────────────────────────────────────────────────
  final Rx<User?> firebaseUser = Rx<User?>(null);
  final Rx<AppUser?> appUser = Rx<AppUser?>(null);

  /// True while the Firebase Auth stream has not yet emitted its first event.
  final RxBool isLoadingAuth = true.obs;

  /// True while the Firestore profile stream has not yet emitted its first event
  /// after a sign-in.
  final RxBool isLoadingProfile = true.obs;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<AppUser?>? _profileSub;

  // ── Lifecycle ───────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();

    _authSub = _authService.authStateChanges.listen(_onAuthStateChanged);

    ever(firebaseUser, (_) => _reevaluateRoute());
    ever(appUser, (_) => _reevaluateRoute());
    ever(isLoadingProfile, (_) => _reevaluateRoute());
  }

  @override
  void onClose() {
    _authSub?.cancel();
    _profileSub?.cancel();
    super.onClose();
  }

  // ── Auth state stream handler ───────────────────────────────────────────────
  void _onAuthStateChanged(User? user) {
    firebaseUser.value = user;
    isLoadingAuth.value = false;

    if (user == null) {
      appUser.value = null;
      isLoadingProfile.value = false;
      _profileSub?.cancel();
      _profileSub = null;
      _logger.setUserId(null);
    } else {
      isLoadingProfile.value = true;
      _profileSub?.cancel();
      _profileSub = _userRepo.watchUser(user.uid).listen((profile) {
        appUser.value = profile;
        isLoadingProfile.value = false;
        if (profile != null) _logger.setUserId(profile.uid);
      });
      // Safety timeout: if Firestore doesn't respond within 8 seconds
      // (e.g. no internet, bad credentials), unblock the loading state so the
      // app can navigate rather than staying frozen on the splash screen.
      Future.delayed(const Duration(seconds: 8), () {
        if (isLoadingProfile.value) {
          isLoadingProfile.value = false;
        }
      });
    }
  }

  // ── Route re-evaluation ─────────────────────────────────────────────────────
  /// Re-computes the canonical route and navigates when the target differs.
  ///
  /// Guard: skip if the navigator hasn't mounted yet (ever() can fire before
  /// GetMaterialApp finishes building, making Get.offAllNamed a no-op that
  /// leaves the app frozen on the splash screen).
  void _reevaluateRoute() {
    // Navigator not ready yet — wait for the next event.
    if (Get.key.currentState == null) return;

    final current = Get.currentRoute;
    final target = _targetRoute(current);
    if (target != null && target != current) {
      Get.offAllNamed(target);
    }
  }

  /// Called from GoldInvestApp.onReady() once the navigator is mounted.
  /// Runs the first evaluation that may have been skipped above.
  void onRouterReady() => _reevaluateRoute();

  String? _targetRoute(String current) {
    // 1. Auth stream not yet resolved.
    if (isLoadingAuth.value) {
      return current == '/splash' ? null : '/splash';
    }
    // 2. Signed out.
    if (firebaseUser.value == null) {
      final atAuth = current == '/login' || current == '/register';
      return atAuth ? null : '/login';
    }
    // 3. Profile not yet loaded.
    if (isLoadingProfile.value) {
      return current == '/splash' ? null : '/splash';
    }
    // 4. Not approved — skip in dev when bypassApproval is enabled.
    final user = appUser.value;
    final bypass = Get.find<AppConfig>().bypassApproval;
    if (!bypass && (user == null || !user.isApproved)) {
      return current == '/pending' ? null : '/pending';
    }
    // 5. Approved (or approval bypassed).
    final atPreAuth = current == '/login' ||
        current == '/register' ||
        current == '/pending' ||
        current == '/splash';
    if (user?.isAdmin ?? false) {
      return atPreAuth ? '/admin' : null;
    } else {
      if (atPreAuth || current.startsWith('/admin')) return '/';
      return null;
    }
  }

  // ── Auth actions ────────────────────────────────────────────────────────────
  Future<void> signIn({
    required String email,
    required String password,
  }) =>
      _authService.signIn(email: email, password: password);

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    String? referredBy,
  }) =>
      _authService.register(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        referredBy: referredBy,
      );

  Future<void> signOut() => _authService.signOut();

  Future<void> sendPasswordReset(String email) =>
      _authService.sendPasswordReset(email);

  Future<void> refreshToken() => _authService.refreshToken();

  /// Google Sign-In. Creates a `users/{uid}` profile with status=pending if
  /// this is the user's first login.
  Future<void> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return; // cancelled
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final result =
        await FirebaseAuth.instance.signInWithCredential(credential);
    await _ensureProfileExists(result.user!);
  }

  /// Apple Sign-In — iOS only.  The caller should guard with
  /// `if (defaultTargetPlatform == TargetPlatform.iOS)`.
  Future<void> signInWithApple() async {
    final provider = AppleAuthProvider();
    final result =
        await FirebaseAuth.instance.signInWithProvider(provider);
    await _ensureProfileExists(result.user!);
  }

  Future<void> _ensureProfileExists(User fireUser) async {
    final existing = await _userRepo.getUser(fireUser.uid);
    if (existing != null) return;
    await _userRepo.createUser(AppUser(
      uid: fireUser.uid,
      fullName: fireUser.displayName ?? '',
      email: fireUser.email ?? '',
      phone: '',
      role: UserRole.user,
      status: UserStatus.pending,
    ));
    if (kDebugMode) debugPrint('[AuthController] new profile created for ${fireUser.uid}');
  }

  // ── Convenience getters used by middleware ──────────────────────────────────
  bool get isSignedIn => firebaseUser.value != null;
  bool get isApproved => appUser.value?.isApproved ?? false;
  bool get isAdmin => appUser.value?.isAdmin ?? false;
}
