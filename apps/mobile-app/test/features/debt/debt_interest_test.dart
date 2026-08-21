import 'package:flutter_test/flutter_test.dart';
import 'package:mali_up/features/debt/domain/models/debt.dart';

String _isoDaysAgo(int days) =>
    DateTime.now().subtract(Duration(days: days)).toIso8601String().split('T').first;

/// A date exactly [months] calendar months before today, same day-of-month
/// (clamped into the target month). Using real month arithmetic — instead of
/// a day-count approximation like `30 * months` — keeps these tests exact
/// regardless of which months they straddle.
String _isoMonthsAgo(int months) {
  final now = DateTime.now();
  var year = now.year;
  var month = now.month - months;
  while (month < 1) {
    month += 12;
    year -= 1;
  }
  final lastDayOfTargetMonth = DateTime(year, month + 1, 0).day;
  final day = now.day.clamp(1, lastDayOfTargetMonth);
  final d = DateTime(year, month, day);
  return d.toIso8601String().split('T').first;
}

void main() {
  group('Debt interest accrual', () {
    test('zero rate has no interest and behaves exactly as before', () {
      final debt = Debt(
        id: '1',
        partyName: 'Asha',
        type: 'receivable',
        originalAmount: 100000,
        paidAmount: 20000,
        dueDate: _isoDaysAgo(-30),
        createdAt: _isoDaysAgo(60),
      );

      expect(debt.hasInterest, isFalse);
      expect(debt.accruedInterest, 0);
      expect(debt.totalOwedWithInterest, 100000);
      expect(debt.remainingAmount, 80000);
    });

    test('simple interest accrues rate x principal x periods elapsed', () {
      final debt = Debt(
        id: '2',
        partyName: 'Baraka',
        type: 'receivable',
        originalAmount: 100000,
        dueDate: _isoDaysAgo(-30),
        createdAt: _isoMonthsAgo(3),
        loanDate: _isoMonthsAgo(3),
        interestRatePercent: 10,
      );

      expect(debt.hasInterest, isTrue);
      expect(debt.interestPeriodsElapsed, 3);
      // 100,000 * 0.10 * 3 = 30,000
      expect(debt.accruedInterest, closeTo(30000, 0.01));
      expect(debt.totalOwedWithInterest, closeTo(130000, 0.01));
    });

    test('compound interest grows on the accumulating balance each period', () {
      final debt = Debt(
        id: '3',
        partyName: 'Chiku',
        type: 'receivable',
        originalAmount: 100000,
        dueDate: _isoDaysAgo(-30),
        createdAt: _isoMonthsAgo(3),
        loanDate: _isoMonthsAgo(3),
        interestRatePercent: 10,
        interestType: 'compound',
      );

      // 100,000 * (1.10^3 - 1) = 33,100
      expect(debt.accruedInterest, closeTo(33100, 0.01));
      expect(debt.totalOwedWithInterest, closeTo(133100, 0.01));
    });

    test('compound interest accrues more than simple over the same term', () {
      Debt withType(String type) => Debt(
            id: '4',
            partyName: 'Dogo',
            type: 'receivable',
            originalAmount: 50000,
            dueDate: _isoDaysAgo(-30),
            createdAt: _isoMonthsAgo(4),
            loanDate: _isoMonthsAgo(4),
            interestRatePercent: 5,
            interestType: type,
          );

      final simple = withType('simple').accruedInterest;
      final compound = withType('compound').accruedInterest;
      expect(compound, greaterThan(simple));
    });

    test('daily and weekly periods use whole elapsed units', () {
      final daily = Debt(
        id: '5',
        partyName: 'Eva',
        type: 'receivable',
        originalAmount: 10000,
        dueDate: _isoDaysAgo(-10),
        createdAt: _isoDaysAgo(10),
        loanDate: _isoDaysAgo(10),
        interestRatePercent: 1,
        interestPeriod: 'daily',
      );
      expect(daily.interestPeriodsElapsed, 10);

      final weekly = Debt(
        id: '6',
        partyName: 'Farid',
        type: 'receivable',
        originalAmount: 10000,
        dueDate: _isoDaysAgo(-15),
        createdAt: _isoDaysAgo(15),
        loanDate: _isoDaysAgo(15),
        interestRatePercent: 1,
        interestPeriod: 'weekly',
      );
      expect(weekly.interestPeriodsElapsed, 2);
    });

    test('accrual freezes once the debt is marked paid', () {
      final debt = Debt(
        id: '7',
        partyName: 'Grace',
        type: 'receivable',
        originalAmount: 100000,
        paidAmount: 130000,
        status: 'paid',
        dueDate: _isoDaysAgo(-30),
        createdAt: _isoMonthsAgo(3),
        loanDate: _isoMonthsAgo(3),
        interestRatePercent: 10,
      );

      expect(debt.accruedInterest, 0);
      expect(debt.isFullyPaid, isTrue);
      expect(debt.remainingAmount, 0);
    });

    test('accrual freezes once the debt is written off', () {
      final debt = Debt(
        id: '8',
        partyName: 'Haji',
        type: 'receivable',
        originalAmount: 100000,
        isWrittenOff: true,
        dueDate: _isoDaysAgo(-30),
        createdAt: _isoMonthsAgo(3),
        loanDate: _isoMonthsAgo(3),
        interestRatePercent: 10,
      );

      expect(debt.accruedInterest, 0);
    });

    test('loanDate falls back to createdAt when unset', () {
      final debt = Debt(
        id: '9',
        partyName: 'Imani',
        type: 'receivable',
        originalAmount: 100000,
        dueDate: _isoDaysAgo(-30),
        createdAt: _isoMonthsAgo(2),
        interestRatePercent: 10,
      );

      expect(debt.interestPeriodsElapsed, 2);
    });

    test('isFullyPaid and paidPercent account for accrued interest', () {
      final debt = Debt(
        id: '10',
        partyName: 'Juma',
        type: 'receivable',
        originalAmount: 100000,
        paidAmount: 100000,
        dueDate: _isoDaysAgo(-30),
        createdAt: _isoMonthsAgo(2),
        loanDate: _isoMonthsAgo(2),
        interestRatePercent: 10,
      );

      // Principal fully paid, but 20,000 interest has accrued on top —
      // the debt is not actually settled yet.
      expect(debt.isFullyPaid, isFalse);
      expect(debt.remainingAmount, closeTo(20000, 0.01));
      expect(debt.paidPercent, closeTo(100000 / 120000, 0.001));
    });
  });
}
