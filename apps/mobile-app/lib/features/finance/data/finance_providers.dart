import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/expense.dart';
import '../domain/models/cash_account.dart';

final expenseListProvider = StateProvider<List<Expense>>((ref) {
  return [
    Expense(id: '1', category: 'Rent', amount: 'TSh 850,000', date: 'Oct 01, 2026', note: 'October shop rent', recipient: 'Landlord Inc.'),
    Expense(id: '2', category: 'Utilities', amount: 'TSh 45,000', date: 'Yesterday', note: 'Luku recharge', recipient: 'TANESCO'),
    Expense(id: '3', category: 'Marketing', amount: 'TSh 120,000', date: 'Today', note: 'Instagram ads fuel', recipient: 'Meta'),
  ];
});

final cashAccountListProvider = StateProvider<List<CashAccount>>((ref) {
  return [
    CashAccount(id: '1', name: 'Main Cash Drawer', type: 'Cash', balance: 'TSh 142,500', lastReconciled: 'Today, 8:00 AM'),
    CashAccount(id: '2', name: 'Business M-Pesa', type: 'Mobile Money', balance: 'TSh 4,850,000', lastReconciled: '1 hour ago'),
    CashAccount(id: '3', name: 'CRDB Bank', type: 'Bank', balance: 'TSh 12,400,000', lastReconciled: 'Yesterday'),
  ];
});
