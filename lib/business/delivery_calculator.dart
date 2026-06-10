import '../core/utils/month_math.dart';

/// A computed, point-in-time view of an enrollment's progress.
class EnrollmentProgress {
  const EnrollmentProgress({
    required this.paymentsMade,
    required this.durationMonths,
    required this.missedMonths,
    required this.monthsRemaining,
    required this.projectedDeliveryDate,
    required this.isComplete,
    required this.currentDueCycle,
  });

  /// Number of monthly installments recorded so far.
  final int paymentsMade;

  /// Total installments required (typically 12).
  final int durationMonths;

  /// Fully-elapsed months with no recorded payment. Each one pushes the
  /// projected delivery date out by one month.
  final int missedMonths;

  /// Installments still owed (`duration - paymentsMade`, never negative).
  final int monthsRemaining;

  /// Date the coin is projected to be deliverable, given misses so far.
  final DateTime projectedDeliveryDate;

  /// True once all required payments are recorded — redemption unlocks.
  final bool isComplete;

  /// The 1-based installment the user should pay next (== paymentsMade + 1),
  /// or `durationMonths` when complete.
  final int currentDueCycle;

  double get progressFraction =>
      durationMonths == 0 ? 0 : (paymentsMade / durationMonths).clamp(0, 1);
}

/// Status of a single installment cell in the 12-month checklist UI.
enum CycleState { paid, due, missed, upcoming }

/// Pure, side-effect-free implementation of the core business rules:
///
/// 1. A user must complete [durationMonths] (default 12) monthly payments.
/// 2. Payments fill cycles in order (1st payment => cycle 1, etc.).
/// 3. Each fully-elapsed month without a payment is a "miss" and extends the
///    projected delivery date by exactly one month
///    (`delivery = start + (duration + missed) months`).
/// 4. Redemption unlocks once [durationMonths] payments are recorded.
///
/// `now` is injected so the logic is deterministic and unit-testable.
class DeliveryCalculator {
  DeliveryCalculator._();

  /// Months that have fully elapsed since [startDate], capped so we never
  /// report more elapsed cycles than the (extended) schedule contains.
  static int _elapsedCycles(DateTime startDate, DateTime now) =>
      MonthMath.completeMonthsBetween(startDate, now);

  /// Missed months = elapsed-but-unpaid cycles, while the plan is still active.
  /// Once all payments are in, nothing can be "missed".
  static int missedMonths({
    required DateTime startDate,
    required int paymentsMade,
    required int durationMonths,
    required DateTime now,
  }) {
    if (paymentsMade >= durationMonths) return 0;
    final elapsed = _elapsedCycles(startDate, now);
    final missed = elapsed - paymentsMade;
    return missed < 0 ? 0 : missed;
  }

  static DateTime projectedDeliveryDate({
    required DateTime startDate,
    required int durationMonths,
    required int missedMonths,
  }) =>
      MonthMath.addMonths(startDate, durationMonths + missedMonths);

  /// Compute the full progress snapshot for an enrollment.
  static EnrollmentProgress progress({
    required DateTime startDate,
    required int paymentsMade,
    required DateTime now,
    int durationMonths = 12,
  }) {
    final clampedPaid = paymentsMade < 0
        ? 0
        : (paymentsMade > durationMonths ? durationMonths : paymentsMade);
    final missed = missedMonths(
      startDate: startDate,
      paymentsMade: clampedPaid,
      durationMonths: durationMonths,
      now: now,
    );
    final remaining = durationMonths - clampedPaid;
    final isComplete = clampedPaid >= durationMonths;
    return EnrollmentProgress(
      paymentsMade: clampedPaid,
      durationMonths: durationMonths,
      missedMonths: missed,
      monthsRemaining: remaining < 0 ? 0 : remaining,
      projectedDeliveryDate: projectedDeliveryDate(
        startDate: startDate,
        durationMonths: durationMonths,
        missedMonths: missed,
      ),
      isComplete: isComplete,
      currentDueCycle: isComplete ? durationMonths : clampedPaid + 1,
    );
  }

  /// State of each installment cell (1..durationMonths) for the checklist UI.
  static List<CycleState> cycleStates({
    required DateTime startDate,
    required int paymentsMade,
    required DateTime now,
    int durationMonths = 12,
  }) {
    final elapsed = _elapsedCycles(startDate, now);
    return List<CycleState>.generate(durationMonths, (i) {
      final cycle = i + 1; // 1-based
      if (cycle <= paymentsMade) return CycleState.paid;
      if (cycle <= elapsed) return CycleState.missed; // due window passed, unpaid
      if (cycle == paymentsMade + 1) return CycleState.due; // pay this next
      return CycleState.upcoming;
    });
  }
}
