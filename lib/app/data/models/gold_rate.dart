import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants.dart';
import '../../core/utils/firestore_helpers.dart';

/// The current gold rate. Stored at `goldRate/current`.
///
/// `source` records whether it came from the scheduled API fetch or an admin's
/// manual override. When `lockManual` is true, the scheduled function leaves the
/// value alone so an admin override isn't overwritten.
class GoldRate {
  const GoldRate({
    required this.pricePerGram,
    required this.currency,
    required this.source,
    required this.lockManual,
    this.updatedAt,
    this.updatedBy,
  });

  final double pricePerGram;
  final String currency;
  final GoldRateSource source;
  final bool lockManual;
  final DateTime? updatedAt;
  final String? updatedBy;

  factory GoldRate.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return GoldRate(
      pricePerGram: doubleFromFirestore(d['pricePerGram']) ?? 0,
      currency: (d['currency'] ?? BusinessRules.currencyCode) as String,
      source: enumFromString(
        GoldRateSource.values,
        d['source'] as String?,
        GoldRateSource.manual,
      ),
      lockManual: (d['lockManual'] ?? false) as bool,
      updatedAt: dateFromFirestore(d['updatedAt']),
      updatedBy: d['updatedBy'] as String?,
    );
  }

  /// Map for an admin manual override.
  Map<String, dynamic> toManualMap(String adminUid) => {
        'pricePerGram': pricePerGram,
        'currency': currency,
        'source': enumToString(GoldRateSource.manual),
        'lockManual': lockManual,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': adminUid,
      };

  /// Value of [grams] worth of gold at this rate.
  double valueFor(double grams) => pricePerGram * grams;
}
