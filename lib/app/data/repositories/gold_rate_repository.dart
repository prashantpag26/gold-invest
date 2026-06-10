import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants.dart';
import '../models/gold_rate.dart';

/// Reads the current gold rate (any approved user) and writes manual overrides
/// (admin only). The scheduled Cloud Function also writes here with source=api.
class GoldRateRepository {
  GoldRateRepository([FirebaseFirestore? firestore])
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> get _currentRef => _db
      .collection(FirestorePaths.goldRate)
      .doc(FirestorePaths.goldRateCurrentDoc);

  CollectionReference<Map<String, dynamic>> get _historyCol =>
      _currentRef.collection(FirestorePaths.goldRateHistory);

  Stream<GoldRate?> watchCurrent() => _currentRef.snapshots().map(
        (doc) => doc.exists ? GoldRate.fromFirestore(doc) : null,
      );

  Future<GoldRate?> getCurrent() async {
    final doc = await _currentRef.get();
    return doc.exists ? GoldRate.fromFirestore(doc) : null;
  }

  /// Admin manual override. Also appends a history snapshot for the chart/log.
  Future<void> setManualRate({
    required double pricePerGram,
    required bool lockManual,
    required String adminUid,
  }) async {
    final rate = GoldRate(
      pricePerGram: pricePerGram,
      currency: BusinessRules.currencyCode,
      source: GoldRateSource.manual,
      lockManual: lockManual,
    );
    await _currentRef.set(rate.toManualMap(adminUid), SetOptions(merge: true));
    await _historyCol.add({
      'pricePerGram': pricePerGram,
      'currency': BusinessRules.currencyCode,
      'source': enumToString(GoldRateSource.manual),
      'updatedBy': adminUid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setLockManual(bool lock) =>
      _currentRef.set({'lockManual': lock}, SetOptions(merge: true));

  /// Recent history snapshots, newest first.
  Stream<List<GoldRate>> watchHistory({int limit = 30}) => _historyCol
      .orderBy('updatedAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map(GoldRate.fromFirestore).toList());
}
