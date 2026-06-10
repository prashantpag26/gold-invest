import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants.dart';
import '../models/investment_plan.dart';

/// Reads/writes for the `plans/{planId}` catalog. Writes are admin-only
/// (enforced by Firestore rules).
class PlanRepository {
  PlanRepository([FirebaseFirestore? firestore])
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestorePaths.plans);

  /// Active plans visible to users, cheapest grams first.
  Stream<List<InvestmentPlan>> watchActivePlans() => _col
      .where('active', isEqualTo: true)
      .orderBy('grams')
      .snapshots()
      .map((s) => s.docs.map(InvestmentPlan.fromFirestore).toList());

  /// All plans (admin view).
  Stream<List<InvestmentPlan>> watchAllPlans() => _col
      .orderBy('grams')
      .snapshots()
      .map((s) => s.docs.map(InvestmentPlan.fromFirestore).toList());

  Future<InvestmentPlan?> getPlan(String id) async {
    final doc = await _col.doc(id).get();
    return doc.exists ? InvestmentPlan.fromFirestore(doc) : null;
  }

  Future<String> createPlan(InvestmentPlan plan) async {
    final ref = await _col.add(plan.toMap());
    return ref.id;
  }

  /// Idempotent upsert using a fixed [docId]. Used by the in-app seed so
  /// running it multiple times doesn't create duplicates.
  Future<void> upsertPlan(String docId, InvestmentPlan plan) =>
      _col.doc(docId).set(plan.toMap(), SetOptions(merge: true));

  Future<void> updatePlan(InvestmentPlan plan) =>
      _col.doc(plan.id).update(plan.toMap());

  Future<void> setActive(String id, bool active) =>
      _col.doc(id).update({'active': active});

  Future<void> deletePlan(String id) => _col.doc(id).delete();
}
