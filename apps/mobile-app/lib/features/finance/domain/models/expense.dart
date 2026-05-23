class Expense {
  final String id;
  final String category;
  final String amount;
  final String date;
  final String note;
  final String recipient;
  final bool isRecurring;
  final String recurrenceType; // 'monthly' | 'weekly' | ''
  final String nextDueDate;    // ISO date for the next auto-create
  final String templateId;     // non-empty when generated from a template

  Expense({
    required this.id,
    required this.category,
    required this.amount,
    required this.date,
    required this.note,
    required this.recipient,
    this.isRecurring = false,
    this.recurrenceType = '',
    this.nextDueDate = '',
    this.templateId = '',
  });

  factory Expense.fromFirestore(Map<String, dynamic> data, String id) {
    return Expense(
      id: id,
      category: data['category']?.toString() ?? 'General',
      amount: data['amount']?.toString() ?? '0',
      date: data['date']?.toString() ?? '',
      note: data['note']?.toString() ?? '',
      recipient: data['recipient']?.toString() ?? '',
      isRecurring: data['isRecurring'] as bool? ?? false,
      recurrenceType: data['recurrenceType']?.toString() ?? '',
      nextDueDate: data['nextDueDate']?.toString() ?? '',
      templateId: data['templateId']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'category': category,
      'amount': amount,
      'date': date,
      'note': note,
      'recipient': recipient,
      'isRecurring': isRecurring,
      if (isRecurring) 'recurrenceType': recurrenceType,
      if (isRecurring && nextDueDate.isNotEmpty) 'nextDueDate': nextDueDate,
      if (templateId.isNotEmpty) 'templateId': templateId,
    };
  }
}
