import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/utils/firestore_helpers.dart';

/// A single recorded monthly installment.
/// Stored at `enrollments/{enrollmentId}/payments/{paymentId}`.
///
/// Only admins create these (after the user pays in cash).
class Payment {
  const Payment({
    required this.id,
    required this.enrollmentId,
    required this.amount,
    required this.cycle,
    required this.paidDate,
    required this.recordedBy,
    this.method = 'cash',
    this.note,
    this.goldRateAtPayment,
  });

  final String id;
  final String enrollmentId;
  final double amount;

  /// 1-based installment number this payment satisfies (1..durationMonths).
  final int cycle;
  final DateTime paidDate;

  /// Admin uid who recorded the payment.
  final String recordedBy;
  final String method;
  final String? note;

  /// Per-gram gold rate captured at the time of payment (for the record).
  final double? goldRateAtPayment;

  factory Payment.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return Payment(
      id: doc.id,
      enrollmentId: (d['enrollmentId'] ?? '') as String,
      amount: doubleFromFirestore(d['amount']) ?? 0,
      cycle: intFromFirestore(d['cycle']),
      paidDate: dateFromFirestore(d['paidDate']) ?? DateTime.now(),
      recordedBy: (d['recordedBy'] ?? '') as String,
      method: (d['method'] ?? 'cash') as String,
      note: d['note'] as String?,
      goldRateAtPayment: doubleFromFirestore(d['goldRateAtPayment']),
    );
  }

  Map<String, dynamic> toMap() => {
        'enrollmentId': enrollmentId,
        'amount': amount,
        'cycle': cycle,
        'paidDate': Timestamp.fromDate(paidDate),
        'recordedBy': recordedBy,
        'method': method,
        if (note != null && note!.isNotEmpty) 'note': note,
        if (goldRateAtPayment != null) 'goldRateAtPayment': goldRateAtPayment,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
