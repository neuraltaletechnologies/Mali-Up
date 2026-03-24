class Debt {
  final String id;
  final String partyName;
  final String type; // 'Receivable' or 'Payable'
  final String amount;
  final String dueDate;
  final String status; // 'Pending', 'Overdue', 'Paid'

  Debt({
    required this.id,
    required this.partyName,
    required this.type,
    required this.amount,
    required this.dueDate,
    required this.status,
  });
}
