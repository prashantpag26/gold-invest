/// Calendar-month arithmetic shared by the delivery calculator and the UI.
///
/// These are pure functions (no I/O, no `DateTime.now()`), which makes the
/// business rules unit-testable with fixed clocks.
///
/// All inputs are normalised to **UTC** before their date components are read,
/// so results are independent of the device timezone and match the server-side
/// `functions/src/delivery.ts` (which also reads UTC components). Returned dates
/// are UTC `DateTime`s — display them with `.toLocal()` (the formatters do this).
class MonthMath {
  MonthMath._();

  static int daysInMonth(int year, int month) {
    // Day 0 of the next month == last day of this month.
    return DateTime.utc(year, month + 1, 0).day;
  }

  /// Add [months] calendar months to [date], clamping the day to the target
  /// month's length (e.g. Jan 31 + 1 month => Feb 28/29).
  static DateTime addMonths(DateTime date, int months) {
    final d = date.toUtc();
    final total = d.month - 1 + months;
    final year = d.year + (total >= 0 ? total ~/ 12 : (total - 11) ~/ 12);
    final month = (total % 12 + 12) % 12 + 1;
    final day = d.day < daysInMonth(year, month)
        ? d.day
        : daysInMonth(year, month);
    return DateTime.utc(
      year,
      month,
      day,
      d.hour,
      d.minute,
      d.second,
      d.millisecond,
    );
  }

  /// Number of *fully completed* calendar months between [start] and [now],
  /// computed in UTC. Returns 0 at [start] and on any date before it.
  static int completeMonthsBetween(DateTime start, DateTime now) {
    final s = start.toUtc();
    final n = now.toUtc();
    if (!n.isAfter(s)) return 0;
    var months = (n.year - s.year) * 12 + (n.month - s.month);
    if (n.day < s.day) months -= 1;
    return months < 0 ? 0 : months;
  }
}
