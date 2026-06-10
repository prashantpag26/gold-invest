import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants.dart';
import '../models/delivery.dart';
import '../models/enrollment.dart';

/// Reads/writes for `deliveries/{id}` plus the linked enrollment update.
/// Recording a delivery is admin-only.
class DeliveryRepository {
  DeliveryRepository([FirebaseFirestore? firestore])
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestorePaths.deliveries);

  Stream<List<Delivery>> watchAll() => _col
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Delivery.fromFirestore).toList());

  Stream<List<Delivery>> watchUserDeliveries(String userId) => _col
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((s) => s.docs.map(Delivery.fromFirestore).toList());

  Stream<Delivery?> watchForEnrollment(String enrollmentId) => _col
      .where('enrollmentId', isEqualTo: enrollmentId)
      .limit(1)
      .snapshots()
      .map((s) => s.docs.isEmpty ? null : Delivery.fromFirestore(s.docs.first));

  /// Record that a completed enrollment's coin was handed over. Writes the
  /// delivery record and stamps the enrollment's actualDeliveryDate.
  Future<void> recordDelivery({
    required Enrollment enrollment,
    required String adminUid,
    DateTime? deliveredDate,
    String? note,
  }) async {
    final delivered = deliveredDate ?? DateTime.now();
    final deliveryRef = _col.doc();
    final enrollmentRef =
        _db.collection(FirestorePaths.enrollments).doc(enrollment.id);

    final batch = _db.batch();
    batch.set(deliveryRef, {
      'enrollmentId': enrollment.id,
      'userId': enrollment.userId,
      'grams': enrollment.grams,
      'status': enumToString(DeliveryStatus.delivered),
      'deliveredDate': Timestamp.fromDate(delivered),
      'recordedBy': adminUid,
      if (note != null && note.isNotEmpty) 'note': note,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(enrollmentRef, {
      'actualDeliveryDate': Timestamp.fromDate(delivered),
      'status': enumToString(EnrollmentStatus.completed),
    });
    await batch.commit();
  }
}
