class Expense {
  final String id;
  final String category;
  final String amount;
  final String date;
  final String note;
  final String recipient;

  Expense({
    required this.id,
    required this.category,
    required this.amount,
    required this.date,
    required this.note,
    required this.recipient,
  });

  factory Expense.fromFirestore(Map<String, dynamic> data, String id) {
    return Expense(
      id: id,
      category: data['category']?.toString() ?? 'General',
      amount: data['amount']?.toString() ?? '0',
      date: data['date']?.toString() ?? '',
      note: data['note']?.toString() ?? '',
      recipient: data['recipient']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'category': category,
      'amount': amount,
      'date': date,
      'note': note,
      'recipient': recipient,
    };
  }
}
