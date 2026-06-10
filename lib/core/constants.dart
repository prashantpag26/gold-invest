/// App-wide constants: Firestore collection names, enums, and business defaults.
///
/// Keeping these in one place avoids "magic strings" scattered across the
/// codebase and keeps the Dart client in sync with the Cloud Functions / rules.
library;

class FirestorePaths {
  FirestorePaths._();

  static const String users = 'users';
  static const String plans = 'plans';
  static const String enrollments = 'enrollments';
  static const String payments = 'payments'; // subcollection of an enrollment
  static const String deliveries = 'deliveries';
  static const String goldRate = 'goldRate';
  static const String goldRateCurrentDoc = 'current';
  static const String goldRateHistory = 'history'; // subcollection of `current`
  static const String config = 'config';
  static const String configAppDoc = 'app';
}

/// Role-based access control.
enum UserRole { user, admin }

/// Registration lifecycle — only [approved] users can use the app.
enum UserStatus { pending, approved, rejected }

/// Lifecycle of a single plan enrollment.
enum EnrollmentStatus { active, completed, cancelled }

/// Where the current gold rate came from.
enum GoldRateSource { api, manual }

/// Lifecycle of a physical coin delivery.
enum DeliveryStatus { pending, delivered }

class BusinessRules {
  BusinessRules._();

  /// Number of monthly payments required before a coin can be redeemed.
  static const int defaultDurationMonths = 12;

  /// Currency used for all monetary values and gold rates.
  static const String currencyCode = 'INR';
  static const String currencySymbol = '₹';

  /// Grams in one troy ounce — used to convert API spot prices (priced per
  /// troy ounce) into a per-gram rate.
  static const double gramsPerTroyOunce = 31.1034768;
}

/// Small helpers to parse/serialize enums stored as strings in Firestore.
T enumFromString<T>(List<T> values, String? raw, T fallback) {
  if (raw == null) return fallback;
  for (final v in values) {
    if (v.toString().split('.').last == raw) return v;
  }
  return fallback;
}

String enumToString(Object enumValue) => enumValue.toString().split('.').last;
