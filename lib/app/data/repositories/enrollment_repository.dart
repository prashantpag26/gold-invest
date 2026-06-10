import 'package:cloud_firestore/cloud_firestore.dart';

import '../../business/delivery_calculator.dart';
import '../../core/constants.dart';
import '../models/enrollment.dart';
import '../models/investment_plan.dart';

/// Reads/writes for `enrollments/{id}`.
///
/// A user may create their own enrollment (status=active, counters at 0). The
/// business counters (`paymentsMade`, `missedMonths`, `status`,
/// `projectedDeliveryDate`) are only mutated by admin flows / Cloud Functions —
/// see [PaymentRepository.recordPayment] and the `recordPayment` callable.
class EnrollmentRepository {
  EnrollmentRepository([FirebaseFirestore? firestore])
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get col =>
      _db.collection(FirestorePaths.enrollments);

  Stream<List<Enrollment>> watchUserEnrollments(String userId) => col
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((s) => s.docs.map(Enrollment.fromFirestore).toList()
        ..sort((a, b) =>
            (b.createdAt ?? b.startDate).compareTo(a.createdAt ?? a.startDate)));

  Stream<Enrollment?> watchEnrollment(String id) =>
      col.doc(id).snapshots().map(
            (doc) => doc.exists ? Enrollment.fromFirestore(doc) : null,
          );

  Stream<List<Enrollment>> watchAll() => col
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Enrollment.fromFirestore).toList());

  Stream<List<Enrollment>> watchByStatus(EnrollmentStatus status) => col
      .where('status', isEqualTo: enumToString(status))
      .snapshots()
      .map((s) => s.docs.map(Enrollment.fromFirestore).toList());

  Future<Enrollment?> getEnrollment(String id) async {
    final doc = await col.doc(id).get();
    return doc.exists ? Enrollment.fromFirestore(doc) : null;
  }

  /// User enrolls in a plan. Projected delivery starts at `start + duration`.
  Future<String> enroll({
    required String userId,
    required InvestmentPlan plan,
    DateTime? startDate,
  }) async {
    final start = startDate ?? DateTime.now();
    final projected = DeliveryCalculator.projectedDeliveryDate(
      startDate: start,
      durationMonths: plan.durationMonths,
      missedMonths: 0,
    );
    final ref = await col.add(Enrollment.createMap(
      userId: userId,
      plan: plan,
      startDate: start,
      projectedDeliveryDate: projected,
    ));
    return ref.id;
  }

  Future<void> cancel(String id) =>
      col.doc(id).update({'status': enumToString(EnrollmentStatus.cancelled)});
}
