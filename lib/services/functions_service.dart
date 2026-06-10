import 'package:cloud_functions/cloud_functions.dart';

/// Wrapper over the callable Cloud Functions.
///
/// These are the *server-enforced* equivalents of the admin actions. The app
/// can run entirely without them (using the client-side repository paths) on
/// the free Spark plan, but deploying the functions gives stronger integrity
/// and is required for the scheduled gold-rate fetch. Toggle with
/// [usesCloudFunctions] in app config.
class FunctionsService {
  FunctionsService([FirebaseFunctions? functions])
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<void> approveUser(String uid) =>
      _functions.httpsCallable('approveUser').call({'uid': uid});

  Future<void> rejectUser(String uid) =>
      _functions.httpsCallable('rejectUser').call({'uid': uid});

  Future<int> recordPayment({
    required String enrollmentId,
    required double amount,
    String? note,
    double? goldRateAtPayment,
    DateTime? paidDate,
  }) async {
    final res = await _functions.httpsCallable('recordPayment').call({
      'enrollmentId': enrollmentId,
      'amount': amount,
      if (note != null) 'note': note,
      if (goldRateAtPayment != null) 'goldRateAtPayment': goldRateAtPayment,
      if (paidDate != null) 'paidDate': paidDate.toUtc().toIso8601String(),
    });
    return (res.data?['cycle'] as num?)?.toInt() ?? 0;
  }

  /// Grant/revoke admin claim (admin-only on the server). The very first admin
  /// is bootstrapped with `tools/set_admin.js` instead.
  Future<void> setAdminClaim(String uid, bool isAdmin) =>
      _functions.httpsCallable('setAdminClaim').call({
        'uid': uid,
        'admin': isAdmin,
      });

  /// Manually trigger the gold-rate API fetch (admin-only).
  Future<void> refreshGoldRateNow() =>
      _functions.httpsCallable('refreshGoldRateNow').call();
}
