import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants.dart';
import '../models/app_user.dart';
import '../repositories/user_repository.dart';

/// Thin wrapper over [FirebaseAuth] that also creates the Firestore profile on
/// registration. UI talks to this via Riverpod providers, never to FirebaseAuth
/// directly.
class AuthService {
  AuthService({FirebaseAuth? auth, UserRepository? users})
      : _auth = auth ?? FirebaseAuth.instance,
        _users = users ?? UserRepository();

  final FirebaseAuth _auth;
  final UserRepository _users;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) =>
      _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

  /// Register a new user: create the auth account, then the `users/{uid}`
  /// profile with status=pending. The user can't access the app until an admin
  /// approves them.
  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    String? referredBy,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = cred.user!.uid;
    await cred.user!.updateDisplayName(fullName.trim());
    await _users.createUser(AppUser(
      uid: uid,
      fullName: fullName.trim(),
      email: email.trim(),
      phone: phone.trim(),
      role: UserRole.user,
      status: UserStatus.pending,
      referredBy: (referredBy?.trim().isEmpty ?? true) ? null : referredBy!.trim(),
    ));
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> signOut() => _auth.signOut();

  /// Force-refresh the ID token so newly-granted custom claims (e.g. admin)
  /// take effect without a full re-login.
  Future<void> refreshToken() async =>
      _auth.currentUser?.getIdToken(true);
}
