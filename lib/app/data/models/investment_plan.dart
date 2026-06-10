import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants.dart';
import '../../core/utils/firestore_helpers.dart';

/// An investment plan denomination in the admin-managed catalog.
/// Stored at `plans/{planId}`.
///
/// e.g. "1g Monthly" — grams: 1, durationMonths: 12, monthlyAmount: 600.
class InvestmentPlan {
  const InvestmentPlan({
    required this.id,
    required this.name,
    required this.grams,
    required this.durationMonths,
    required this.monthlyAmount,
    required this.active,
    this.createdAt,
  });

  final String id;
  final String name;
  final double grams;
  final int durationMonths;
  final double monthlyAmount;
  final bool active;
  final DateTime? createdAt;

  /// Total cash the user pays over the full plan.
  double get totalPayable => monthlyAmount * durationMonths;

  factory InvestmentPlan.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return InvestmentPlan(
      id: doc.id,
      name: (d['name'] ?? '') as String,
      grams: doubleFromFirestore(d['grams']) ?? 0,
      durationMonths: intFromFirestore(
        d['durationMonths'],
        fallback: BusinessRules.defaultDurationMonths,
      ),
      monthlyAmount: doubleFromFirestore(d['monthlyAmount']) ?? 0,
      active: (d['active'] ?? true) as bool,
      createdAt: dateFromFirestore(d['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'grams': grams,
        'durationMonths': durationMonths,
        'monthlyAmount': monthlyAmount,
        'active': active,
        'createdAt':
            createdAt == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt!),
      };

  InvestmentPlan copyWith({
    String? name,
    double? grams,
    int? durationMonths,
    double? monthlyAmount,
    bool? active,
  }) =>
      InvestmentPlan(
        id: id,
        name: name ?? this.name,
        grams: grams ?? this.grams,
        durationMonths: durationMonths ?? this.durationMonths,
        monthlyAmount: monthlyAmount ?? this.monthlyAmount,
        active: active ?? this.active,
        createdAt: createdAt,
      );
}
