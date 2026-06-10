import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants.dart';
import '../../core/utils/firestore_helpers.dart';

/// A registered user. Stored at `users/{uid}`.
///
/// `role` and `status` are security-critical and may only be changed by an
/// admin / Cloud Function (enforced by Firestore rules) — never by the user.
class AppUser {
  const AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    this.referredBy,
    this.createdAt,
    this.approvedBy,
    this.fcmToken,
  });

  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final UserRole role;
  final UserStatus status;
  final String? referredBy;
  final DateTime? createdAt;
  final String? approvedBy;
  final String? fcmToken;

  bool get isAdmin => role == UserRole.admin;
  bool get isApproved => status == UserStatus.approved;
  bool get isPending => status == UserStatus.pending;
  bool get isRejected => status == UserStatus.rejected;

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return AppUser(
      uid: doc.id,
      fullName: (d['fullName'] ?? '') as String,
      email: (d['email'] ?? '') as String,
      phone: (d['phone'] ?? '') as String,
      role: enumFromString(UserRole.values, d['role'] as String?, UserRole.user),
      status: enumFromString(
        UserStatus.values,
        d['status'] as String?,
        UserStatus.pending,
      ),
      referredBy: d['referredBy'] as String?,
      createdAt: dateFromFirestore(d['createdAt']),
      approvedBy: d['approvedBy'] as String?,
      fcmToken: d['fcmToken'] as String?,
    );
  }

  /// Fields a *user* is allowed to write on registration. Role/status are set
  /// to safe defaults here and locked down by security rules thereafter.
  Map<String, dynamic> toCreateMap() => {
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'role': enumToString(UserRole.user),
        'status': enumToString(UserStatus.pending),
        if (referredBy != null) 'referredBy': referredBy,
        'createdAt': FieldValue.serverTimestamp(),
      };

  AppUser copyWith({UserRole? role, UserStatus? status, String? fcmToken}) =>
      AppUser(
        uid: uid,
        fullName: fullName,
        email: email,
        phone: phone,
        role: role ?? this.role,
        status: status ?? this.status,
        referredBy: referredBy,
        createdAt: createdAt,
        approvedBy: approvedBy,
        fcmToken: fcmToken ?? this.fcmToken,
      );
}
