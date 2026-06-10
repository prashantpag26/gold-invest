/**
 * Server-side mirror of lib/business/delivery_calculator.dart.
 *
 * Keep these two implementations in sync — they encode the core business rule:
 * each fully-elapsed month without a payment extends the projected delivery
 * date by one month.
 *
 * All date-component reads use the UTC getters so this matches the Dart side
 * (which normalises to UTC) regardless of the host's local timezone — client
 * previews and the nightly server recompute then always agree.
 */

function daysInMonth(year: number, month0: number): number {
  // month0 is 0-based; day 0 of next month == last day of this month.
  return new Date(Date.UTC(year, month0 + 1, 0)).getUTCDate();
}

/** Add `months` calendar months, clamping the day to the target month length. */
export function addMonths(date: Date, months: number): Date {
  const total = date.getUTCMonth() + months;
  const year = date.getUTCFullYear() + Math.floor(total / 12);
  const month0 = ((total % 12) + 12) % 12;
  const day = Math.min(date.getUTCDate(), daysInMonth(year, month0));
  return new Date(
    Date.UTC(
      year,
      month0,
      day,
      date.getUTCHours(),
      date.getUTCMinutes(),
      date.getUTCSeconds(),
      date.getUTCMilliseconds()
    )
  );
}

/** Number of fully completed calendar months between start and now (UTC). */
export function completeMonthsBetween(start: Date, now: Date): number {
  if (now <= start) return 0;
  let months =
    (now.getUTCFullYear() - start.getUTCFullYear()) * 12 +
    (now.getUTCMonth() - start.getUTCMonth());
  if (now.getUTCDate() < start.getUTCDate()) months -= 1;
  return months < 0 ? 0 : months;
}

export interface Progress {
  paymentsMade: number;
  durationMonths: number;
  missedMonths: number;
  monthsRemaining: number;
  projectedDeliveryDate: Date;
  isComplete: boolean;
}

export function computeProgress(
  startDate: Date,
  paymentsMade: number,
  now: Date,
  durationMonths: number
): Progress {
  const clamped = Math.max(0, Math.min(paymentsMade, durationMonths));
  let missed = 0;
  if (clamped < durationMonths) {
    const elapsed = completeMonthsBetween(startDate, now);
    missed = Math.max(0, elapsed - clamped);
  }
  const remaining = Math.max(0, durationMonths - clamped);
  return {
    paymentsMade: clamped,
    durationMonths,
    missedMonths: missed,
    monthsRemaining: remaining,
    projectedDeliveryDate: addMonths(startDate, durationMonths + missed),
    isComplete: clamped >= durationMonths,
  };
}
