import 'package:flutter_test/flutter_test.dart';
import 'package:mali_up/features/sales/domain/recurring_billing_calculator.dart';

void main() {
  group('RecurringBillingCalculator.periodsDue', () {
    test('never billed before defaults to 1 (just the current period)', () {
      expect(
        RecurringBillingCalculator.periodsDue(cycle: 'monthly'),
        1,
      );
    });

    test('re-picked within the just-billed period stays at 1', () {
      final now = DateTime(2026, 6, 15);
      expect(
        RecurringBillingCalculator.periodsDue(
          cycle: 'monthly',
          lastBilledDate: DateTime(2026, 6),
          now: now,
        ),
        1,
      );
    });

    test('monthly: N whole months missed adds N to the current period', () {
      // Billed for June only (qty 1) — coverage ends 1 Jul. By 1 Oct, Jul,
      // Aug, Sep are unbilled (3 elapsed months) plus the current period.
      final now = DateTime(2026, 10);
      expect(
        RecurringBillingCalculator.periodsDue(
          cycle: 'monthly',
          lastBilledDate: DateTime(2026, 6),
          now: now,
        ),
        4,
      );
    });

    test('monthly: a multi-period invoice extends the covered window', () {
      // Billed 1 Jun for 3 months (Jun-Aug) — coverage ends 1 Sep. By 1 Sep,
      // nothing has elapsed since coverage end yet.
      expect(
        RecurringBillingCalculator.periodsDue(
          cycle: 'monthly',
          lastBilledDate: DateTime(2026, 6),
          lastBilledQty: 3,
          now: DateTime(2026, 9),
        ),
        1,
      );
    });

    test('weekly: N whole weeks missed adds N to the current period', () {
      // Billed 1 Jun (qty 1) — coverage ends 8 Jun. 21 days later is exactly
      // 3 whole weeks past coverage end.
      final now = DateTime(2026, 6, 8).add(const Duration(days: 21));
      expect(
        RecurringBillingCalculator.periodsDue(
          cycle: 'weekly',
          lastBilledDate: DateTime(2026, 6),
          now: now,
        ),
        4,
      );
    });

    test('caps at maxPeriods for a very long-dormant service', () {
      final now = DateTime(2030);
      final periods = RecurringBillingCalculator.periodsDue(
        cycle: 'monthly',
        lastBilledDate: DateTime(2020),
        now: now,
      );
      expect(periods, RecurringBillingCalculator.maxPeriods);
    });
  });

  group('RecurringBillingCalculator.addCycles', () {
    test('weekly adds 7-day blocks', () {
      expect(
        RecurringBillingCalculator.addCycles(
          DateTime(2026, 6),
          'weekly',
          2,
        ),
        DateTime(2026, 6, 15),
      );
    });

    test('monthly rolls over into the next year', () {
      expect(
        RecurringBillingCalculator.addCycles(
          DateTime(2026, 11, 15),
          'monthly',
          3,
        ),
        DateTime(2027, 2, 15),
      );
    });
  });
}
