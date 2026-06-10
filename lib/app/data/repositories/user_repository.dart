import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants.dart';
import '../models/app_user.dart';

/// Reads/writes for `users/{uid}`. Status/role writes here are used by the
/// admin (and the optional client-side fallback); on the Functions path they
/// go through callable functions instead.
class UserRepository {
  UserRepository([FirebaseFirestore? firestore])
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestorePaths.users);

  /// Exposed for paginated queries in [AdminUsersController].
  CollectionReference<Map<String, dynamic>> get usersColRef =>
      _db.collection(FirestorePaths.users);

  Stream<AppUser?> watchUser(String uid) => _col.doc(uid).snapshots().map(
        (doc) => doc.exists ? AppUser.fromFirestore(doc) : null,
      );

  Future<AppUser?> getUser(String uid) async {
    final doc = await _col.doc(uid).get();
    return doc.exists ? AppUser.fromFirestore(doc) : null;
  }

  /// Create the user profile document on registration (status = pending).
  Future<void> createUser(AppUser user) =>
      _col.doc(user.uid).set(user.toCreateMap());

  Stream<List<AppUser>> watchByStatus(UserStatus status) => _col
      .where('status', isEqualTo: enumToString(status))
      .snapshots()
      .map((s) => s.docs.map(AppUser.fromFirestore).toList());

  Stream<List<AppUser>> watchAll() => _col
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(AppUser.fromFirestore).toList());

  Future<void> setStatus(String uid, UserStatus status, String adminUid) =>
      _col.doc(uid).update({
        'status': enumToString(status),
        'approvedBy': adminUid,
        'approvedAt': FieldValue.serverTimestamp(),
      });

  Future<void> setRole(String uid, UserRole role) =>
      _col.doc(uid).update({'role': enumToString(role)});

  /// Update only the FCM token. Uses `update` (not a merge-set) so it never
  /// creates a partial profile doc — it should only ever touch an existing one.
  Future<void> updateFcmToken(String uid, String token) =>
      _col.doc(uid).update({'fcmToken': token});
}
