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
  factory Debt.fromFirestore(Map<String, dynamic> data, String id) {
    return Debt(
      id: id,
      partyName: data['partyName'] ?? '',
      type: data['type'] ?? 'Receivable',
      amount: data['amount']?.toString() ?? '0',
      dueDate: data['dueDate'] ?? '',
      status: data['status'] ?? 'Pending',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'partyName': partyName,
      'type': type,
      'amount': amount,
      'dueDate': dueDate,
      'status': status,
    };
  }
}
