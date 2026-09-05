/// Computes how many billing periods a recurring service (weekly/monthly)
/// still owes for one customer, from the date and quantity of their last
/// invoice line for that service — see InvoiceDao.getLastServiceBilling.
///
/// This is a pure read-side calculation over already-synced invoice
/// history rather than a separately tracked counter, so it self-corrects if
/// an invoice is later edited or deleted and needs no sync/conflict logic
/// of its own.
abstract final class RecurringBillingCalculator {
  /// Upper bound on the pre-filled quantity, so a service left dormant for
  /// years doesn't pre-fill something absurd — the cashier can still enter a
  /// larger number by hand.
  static const maxPeriods = 24;

  /// Whole cycles owed right now — always at least 1 (the current period).
  ///
  /// [lastBilledQty] is how many periods the last invoice line covered
  /// (usually 1); its coverage is assumed to start on [lastBilledDate] and
  /// run for that many cycles. Periods due = 1 (this period) + however many
  /// whole cycles have elapsed since that coverage ended.
  static int periodsDue({
    required String cycle, // 'weekly' | 'monthly'
    DateTime? lastBilledDate,
    double lastBilledQty = 1,
    DateTime? now,
  }) {
    if (lastBilledDate == null) return 1;
    now ??= DateTime.now();
    final coveredCycles = lastBilledQty.round().clamp(1, 999);
    final coverageEnd = addCycles(lastBilledDate, cycle, coveredCycles);
    final elapsed = cycle == 'weekly'
        ? (now.difference(coverageEnd).inDays / 7).floor()
        : _monthsBetween(coverageEnd, now);
    return 1 + elapsed.clamp(0, maxPeriods - 1);
  }

  /// [date] plus [count] billing cycles (weeks or calendar months).
  static DateTime addCycles(DateTime date, String cycle, int count) {
    if (cycle == 'weekly') return date.add(Duration(days: 7 * count));
    final total = date.month - 1 + count;
    return DateTime(date.year + total ~/ 12, total % 12 + 1, date.day);
  }

  static int _monthsBetween(DateTime from, DateTime to) {
    var months = (to.year - from.year) * 12 + (to.month - from.month);
    if (to.day < from.day) months -= 1;
    return months < 0 ? 0 : months;
  }
}
