import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants.dart';
import '../../core/utils/firestore_helpers.dart';

/// A physical gold coin delivery record. Stored at `deliveries/{id}`.
/// Created by an admin once a completed enrollment's coin is handed over.
class Delivery {
  const Delivery({
    required this.id,
    required this.enrollmentId,
    required this.userId,
    required this.grams,
    required this.status,
    this.deliveredDate,
    this.recordedBy,
    this.note,
  });

  final String id;
  final String enrollmentId;
  final String userId;
  final double grams;
  final DeliveryStatus status;
  final DateTime? deliveredDate;
  final String? recordedBy;
  final String? note;

  factory Delivery.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return Delivery(
      id: doc.id,
      enrollmentId: (d['enrollmentId'] ?? '') as String,
      userId: (d['userId'] ?? '') as String,
      grams: doubleFromFirestore(d['grams']) ?? 0,
      status: enumFromString(
        DeliveryStatus.values,
        d['status'] as String?,
        DeliveryStatus.pending,
      ),
      deliveredDate: dateFromFirestore(d['deliveredDate']),
      recordedBy: d['recordedBy'] as String?,
      note: d['note'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'enrollmentId': enrollmentId,
        'userId': userId,
        'grams': grams,
        'status': enumToString(status),
        if (deliveredDate != null)
          'deliveredDate': Timestamp.fromDate(deliveredDate!),
        if (recordedBy != null) 'recordedBy': recordedBy,
        if (note != null && note!.isNotEmpty) 'note': note,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
