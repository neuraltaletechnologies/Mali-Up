import 'debt.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final debtListProvider = StateProvider<List<Debt>>((ref) {
  return [
    Debt(
      id: '1',
      partyName: 'Main Street Supplier',
      type: 'Payable',
      amount: 'TSh 2,450,000',
      dueDate: 'Oct 30, 2026',
      status: 'Pending',
    ),
    Debt(
      id: '2',
      partyName: 'Global Wholesale',
      type: 'Payable',
      amount: 'TSh 890,000',
      dueDate: 'Yesterday',
      status: 'Overdue',
    ),
    Debt(
      id: '3',
      partyName: 'Alice Johnson',
      type: 'Receivable',
      amount: 'TSh 120,500',
      dueDate: 'Oct 28, 2026',
      status: 'Pending',
    ),
  ];
});
