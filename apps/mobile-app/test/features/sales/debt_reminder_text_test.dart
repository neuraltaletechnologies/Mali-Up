import 'package:flutter_test/flutter_test.dart';
import 'package:mali_up/features/debt/domain/models/debt.dart';
import 'package:mali_up/features/sales/domain/debt_reminder_text.dart';

void main() {
  group('DebtReminderText.build', () {
    Debt makeDebt({
      double originalAmount = 50000,
      double paidAmount = 0,
      String dueDate = '2026-01-01',
      String invoiceRef = 'INV-202601-AAA',
      String createdAt = '2025-12-01',
    }) => Debt(
      id: 'debt-1',
      partyName: 'Juma Mwangi',
      partyPhone: '255712345678',
      type: 'receivable',
      originalAmount: originalAmount,
      paidAmount: paidAmount,
      dueDate: dueDate,
      invoiceRef: invoiceRef,
      createdAt: createdAt,
    );

    test('lists every item with quantity, unit price and line total', () {
      final text = DebtReminderText.build(
        debt: makeDebt(),
        invoice: {
          'invoiceNumber': 'INV-202601-AAA',
          'items': [
            {'name': 'Water — March', 'qty': 2, 'unitPrice': 15000, 'total': 30000},
            {'name': 'Repair', 'qty': 1, 'unitPrice': 20000, 'total': 20000},
          ],
        },
        isSwahili: false,
      );

      expect(text, contains('Water — March × 2 @ TZS 15,000 = *TZS 30,000*'));
      expect(text, contains('Repair × 1 @ TZS 20,000 = *TZS 20,000*'));
      expect(text, contains('INV-202601-AAA'));
    });

    test('shows the amount owed and already-paid figures from the debt, '
        'not the invoice', () {
      final text = DebtReminderText.build(
        debt: makeDebt(paidAmount: 20000),
        invoice: const {},
        isSwahili: false,
      );

      expect(text, contains('*Amount Owed: TZS 30,000*'));
      expect(text, contains('Already paid: TZS 20,000'));
    });

    test('omits the already-paid line when nothing has been paid yet', () {
      final text = DebtReminderText.build(
        debt: makeDebt(),
        invoice: const {},
        isSwahili: false,
      );

      expect(text, isNot(contains('Already paid')));
    });

    test('falls back to a plain balance message with no linked invoice', () {
      final text = DebtReminderText.build(
        debt: makeDebt(invoiceRef: ''),
        invoice: const {},
        isSwahili: false,
      );

      expect(text, isNot(contains('━━')));
      expect(text, contains('Amount Owed:'));
    });

    test('shows "overdue" framing when the due date has passed', () {
      final overdueDebt = makeDebt(dueDate: '2020-01-01');
      final text = DebtReminderText.build(
        debt: overdueDebt,
        invoice: const {},
        isSwahili: false,
      );

      expect(text, contains('Overdue by'));
      expect(text, isNot(contains('Due:')));
    });

    test('shows the due date when not yet overdue', () {
      final futureDebt = makeDebt(
        dueDate: DateTime.now()
            .add(const Duration(days: 30))
            .toIso8601String()
            .split('T')
            .first,
      );
      final text = DebtReminderText.build(
        debt: futureDebt,
        invoice: const {},
        isSwahili: false,
      );

      expect(text, contains('Due:'));
      expect(text, isNot(contains('Overdue by')));
    });

    test('translates to Swahili when requested', () {
      final text = DebtReminderText.build(
        debt: makeDebt(),
        invoice: const {},
        isSwahili: true,
      );

      expect(text, contains('Kiasi Kinachodaiwa'));
      expect(text, contains('Ndugu'));
    });
  });
}
