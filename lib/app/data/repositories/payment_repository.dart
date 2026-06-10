import 'package:cloud_firestore/cloud_firestore.dart';

import '../../business/delivery_calculator.dart';
import '../../core/constants.dart';
import '../models/enrollment.dart';
import '../models/payment.dart';

/// Reads payment history and records new installments.
///
/// [recordPayment] is the client-side (Spark-plan friendly) path: a Firestore
/// transaction that atomically writes the payment AND recomputes the
/// enrollment's counters/delivery date. The same logic exists server-side in
/// the `recordPayment` Cloud Function for installations that prefer to enforce
/// it with the Admin SDK. Both are guarded by admin-only security rules.
class PaymentRepository {
  PaymentRepository([FirebaseFirestore? firestore])
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _paymentsCol(String enrollmentId) =>
      _db
          .collection(FirestorePaths.enrollments)
          .doc(enrollmentId)
          .collection(FirestorePaths.payments);

  Stream<List<Payment>> watchPayments(String enrollmentId) =>
      _paymentsCol(enrollmentId)
          .orderBy('cycle')
          .snapshots()
          .map((s) => s.docs.map(Payment.fromFirestore).toList());

  /// Record one monthly installment for [enrollmentId].
  ///
  /// Throws [StateError] if the enrollment is missing or already complete.
  /// Returns the cycle number that was just paid.
  Future<int> recordPayment({
    required String enrollmentId,
    required double amount,
    required String adminUid,
    DateTime? paidDate,
    String? note,
    double? goldRateAtPayment,
    DateTime? now,
  }) async {
    final enrollmentRef =
        _db.collection(FirestorePaths.enrollments).doc(enrollmentId);
    final paymentRef = _paymentsCol(enrollmentId).doc();
    final paid = paidDate ?? DateTime.now();
    final clock = now ?? DateTime.now();

    return _db.runTransaction<int>((tx) async {
      final snap = await tx.get(enrollmentRef);
      if (!snap.exists) {
        throw StateError('Enrollment not found');
      }
      final enrollment = Enrollment.fromFirestore(snap);
      if (enrollment.paymentsMade >= enrollment.durationMonths) {
        throw StateError('All installments are already paid for this plan');
      }

      final newPaymentsMade = enrollment.paymentsMade + 1;
      final progress = DeliveryCalculator.progress(
        startDate: enrollment.startDate,
        paymentsMade: newPaymentsMade,
        now: clock,
        durationMonths: enrollment.durationMonths,
      );

      final payment = Payment(
        id: paymentRef.id,
        enrollmentId: enrollmentId,
        amount: amount,
        cycle: newPaymentsMade,
        paidDate: paid,
        recordedBy: adminUid,
        note: note,
        goldRateAtPayment: goldRateAtPayment,
      );

      tx.set(paymentRef, payment.toMap());
      tx.update(enrollmentRef, {
        'paymentsMade': newPaymentsMade,
        'missedMonths': progress.missedMonths,
        'projectedDeliveryDate':
            Timestamp.fromDate(progress.projectedDeliveryDate),
        'status': enumToString(progress.isComplete
            ? EnrollmentStatus.completed
            : EnrollmentStatus.active),
        'lastPaymentAt': FieldValue.serverTimestamp(),
      });

      return newPaymentsMade;
    });
  }

  /// Remove the most recent payment (admin correction). Decrements counters.
  Future<void> deletePayment({
    required String enrollmentId,
    required String paymentId,
  }) async {
    final enrollmentRef =
        _db.collection(FirestorePaths.enrollments).doc(enrollmentId);
    final paymentRef = _paymentsCol(enrollmentId).doc(paymentId);
    await _db.runTransaction((tx) async {
      final eSnap = await tx.get(enrollmentRef);
      if (!eSnap.exists) throw StateError('Enrollment not found');
      final enrollment = Enrollment.fromFirestore(eSnap);
      final newPaymentsMade =
          (enrollment.paymentsMade - 1).clamp(0, enrollment.durationMonths);
      final progress = DeliveryCalculator.progress(
        startDate: enrollment.startDate,
        paymentsMade: newPaymentsMade,
        now: DateTime.now(),
        durationMonths: enrollment.durationMonths,
      );
      tx.delete(paymentRef);
      tx.update(enrollmentRef, {
        'paymentsMade': newPaymentsMade,
        'missedMonths': progress.missedMonths,
        'projectedDeliveryDate':
            Timestamp.fromDate(progress.projectedDeliveryDate),
        'status': enumToString(EnrollmentStatus.active),
      });
    });
  }
}
