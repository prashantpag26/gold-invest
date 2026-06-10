import 'package:flutter_test/flutter_test.dart';
import 'package:gold_invest/business/delivery_calculator.dart';
import 'package:gold_invest/core/utils/month_math.dart';

/// Unit tests for the core business rule:
/// "Each fully-elapsed month without a payment extends the delivery date by
///  one month; 12 payments unlock redemption."
///
/// Dates are constructed in UTC so the assertions are deterministic on any CI
/// timezone and exercise the same UTC path the production code normalises to.
void main() {
  final start = DateTime.utc(2025, 1, 15);

  group('MonthMath.addMonths', () {
    test('adds whole months', () {
      expect(MonthMath.addMonths(start, 12), DateTime.utc(2026, 1, 15));
      expect(MonthMath.addMonths(start, 1), DateTime.utc(2025, 2, 15));
    });

    test('clamps day to shorter target month (Jan 31 + 1 = Feb 28)', () {
      expect(MonthMath.addMonths(DateTime.utc(2025, 1, 31), 1),
          DateTime.utc(2025, 2, 28));
    });

    test('handles leap February', () {
      expect(MonthMath.addMonths(DateTime.utc(2024, 1, 31), 1),
          DateTime.utc(2024, 2, 29));
    });

    test('rolls across year boundary', () {
      expect(MonthMath.addMonths(DateTime.utc(2025, 11, 10), 3),
          DateTime.utc(2026, 2, 10));
    });
  });

  group('MonthMath.completeMonthsBetween', () {
    test('is zero at start and before', () {
      expect(MonthMath.completeMonthsBetween(start, start), 0);
      expect(
          MonthMath.completeMonthsBetween(start, DateTime.utc(2024, 12, 1)), 0);
    });

    test('counts only fully-completed months', () {
      expect(
          MonthMath.completeMonthsBetween(start, DateTime.utc(2025, 2, 14)), 0);
      expect(
          MonthMath.completeMonthsBetween(start, DateTime.utc(2025, 2, 15)), 1);
      expect(
          MonthMath.completeMonthsBetween(start, DateTime.utc(2025, 4, 20)), 3);
    });
  });

  group('DeliveryCalculator.progress — on track', () {
    test('fresh enrollment: 0 paid, 0 missed, delivery = start + 12mo', () {
      final p = DeliveryCalculator.progress(
        startDate: start,
        paymentsMade: 0,
        now: start,
      );
      expect(p.paymentsMade, 0);
      expect(p.missedMonths, 0);
      expect(p.monthsRemaining, 12);
      expect(p.isComplete, false);
      expect(p.projectedDeliveryDate, DateTime.utc(2026, 1, 15));
    });

    test('paying every month keeps delivery at month 12', () {
      final p = DeliveryCalculator.progress(
        startDate: start,
        paymentsMade: 3,
        now: DateTime.utc(2025, 4, 15), // 3 months elapsed, 3 paid
      );
      expect(p.missedMonths, 0);
      expect(p.projectedDeliveryDate, DateTime.utc(2026, 1, 15));
    });
  });

  group('DeliveryCalculator.progress — missed payments extend delivery', () {
    test('1 missed month pushes delivery from month 12 to month 13', () {
      // 3 months elapsed but only 2 payments recorded => 1 miss.
      final p = DeliveryCalculator.progress(
        startDate: start,
        paymentsMade: 2,
        now: DateTime.utc(2025, 4, 15),
      );
      expect(p.missedMonths, 1);
      expect(p.projectedDeliveryDate, DateTime.utc(2026, 2, 15)); // +13 months
    });

    test('each additional miss extends by one more month', () {
      // 5 months elapsed, 2 payments => 3 misses => start + 15 months.
      final p = DeliveryCalculator.progress(
        startDate: start,
        paymentsMade: 2,
        now: DateTime.utc(2025, 6, 15),
      );
      expect(p.missedMonths, 3);
      expect(p.projectedDeliveryDate, DateTime.utc(2026, 4, 15));
    });
  });

  group('DeliveryCalculator.progress — completion', () {
    test('12 payments completes the plan; nothing can be missed', () {
      final p = DeliveryCalculator.progress(
        startDate: start,
        paymentsMade: 12,
        now: DateTime.utc(2030, 1, 1), // long after — still complete, 0 missed
      );
      expect(p.isComplete, true);
      expect(p.missedMonths, 0);
      expect(p.monthsRemaining, 0);
    });

    test('over-counted payments are clamped to duration', () {
      final p = DeliveryCalculator.progress(
        startDate: start,
        paymentsMade: 15,
        now: DateTime.utc(2026, 6, 1),
      );
      expect(p.paymentsMade, 12);
      expect(p.isComplete, true);
    });
  });

  group('DeliveryCalculator.cycleStates', () {
    test('on-track: paid cells, then a due cell, then upcoming', () {
      final states = DeliveryCalculator.cycleStates(
        startDate: start,
        paymentsMade: 3,
        now: DateTime.utc(2025, 4, 20), // 3 elapsed, 3 paid -> cycle 4 is due
      );
      expect(states[0], CycleState.paid);
      expect(states[2], CycleState.paid);
      expect(states[3], CycleState.due);
      expect(states[4], CycleState.upcoming);
    });

    test('behind: overdue cell shows as missed', () {
      final states = DeliveryCalculator.cycleStates(
        startDate: start,
        paymentsMade: 2,
        now: DateTime.utc(2025, 4, 20), // 3 elapsed, 2 paid -> cycle 3 missed
      );
      expect(states[0], CycleState.paid);
      expect(states[1], CycleState.paid);
      expect(states[2], CycleState.missed);
      expect(states[3], CycleState.upcoming);
    });
  });
}
