import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants.dart';
import '../../core/utils/firestore_helpers.dart';
import 'investment_plan.dart';

/// A user's subscription to a plan. Stored at `enrollments/{id}`.
///
/// Plan fields are *snapshotted* at enrollment time so later edits to the plan
/// catalog don't retroactively change an active subscription.
///
/// `paymentsMade`, `missedMonths`, `projectedDeliveryDate` and `status` are
/// derived/business fields — only an admin or Cloud Function may write them
/// (enforced by Firestore rules).
class Enrollment {
  const Enrollment({
    required this.id,
    required this.userId,
    required this.planId,
    required this.planName,
    required this.grams,
    required this.durationMonths,
    required this.monthlyAmount,
    required this.startDate,
    required this.status,
    required this.paymentsMade,
    required this.missedMonths,
    this.projectedDeliveryDate,
    this.actualDeliveryDate,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String planId;
  final String planName;
  final double grams;
  final int durationMonths;
  final double monthlyAmount;
  final DateTime startDate;
  final EnrollmentStatus status;
  final int paymentsMade;
  final int missedMonths;
  final DateTime? projectedDeliveryDate;
  final DateTime? actualDeliveryDate;
  final DateTime? createdAt;

  int get monthsRemaining {
    final r = durationMonths - paymentsMade;
    return r < 0 ? 0 : r;
  }

  bool get isCompleted =>
      status == EnrollmentStatus.completed || paymentsMade >= durationMonths;

  bool get isActive => status == EnrollmentStatus.active;

  double get progressFraction =>
      durationMonths == 0 ? 0 : (paymentsMade / durationMonths).clamp(0, 1);

  factory Enrollment.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return Enrollment(
      id: doc.id,
      userId: (d['userId'] ?? '') as String,
      planId: (d['planId'] ?? '') as String,
      planName: (d['planName'] ?? '') as String,
      grams: doubleFromFirestore(d['grams']) ?? 0,
      durationMonths: intFromFirestore(
        d['durationMonths'],
        fallback: BusinessRules.defaultDurationMonths,
      ),
      monthlyAmount: doubleFromFirestore(d['monthlyAmount']) ?? 0,
      startDate: dateFromFirestore(d['startDate']) ?? DateTime.now(),
      status: enumFromString(
        EnrollmentStatus.values,
        d['status'] as String?,
        EnrollmentStatus.active,
      ),
      paymentsMade: intFromFirestore(d['paymentsMade']),
      missedMonths: intFromFirestore(d['missedMonths']),
      projectedDeliveryDate: dateFromFirestore(d['projectedDeliveryDate']),
      actualDeliveryDate: dateFromFirestore(d['actualDeliveryDate']),
      createdAt: dateFromFirestore(d['createdAt']),
    );
  }

  /// Initial document written when a user enrolls. Business counters start at
  /// zero; the projected delivery date is `start + duration` months.
  static Map<String, dynamic> createMap({
    required String userId,
    required InvestmentPlan plan,
    required DateTime startDate,
    required DateTime projectedDeliveryDate,
  }) =>
      {
        'userId': userId,
        'planId': plan.id,
        'planName': plan.name,
        'grams': plan.grams,
        'durationMonths': plan.durationMonths,
        'monthlyAmount': plan.monthlyAmount,
        'startDate': Timestamp.fromDate(startDate),
        'status': enumToString(EnrollmentStatus.active),
        'paymentsMade': 0,
        'missedMonths': 0,
        'projectedDeliveryDate': Timestamp.fromDate(projectedDeliveryDate),
        'createdAt': FieldValue.serverTimestamp(),
      };
}
