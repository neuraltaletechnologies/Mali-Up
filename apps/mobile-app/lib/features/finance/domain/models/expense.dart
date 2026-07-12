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
  final String receiptUrl;     // Firebase Storage download URL
  final String paymentMethod;  // cash | mpesa | bank | card | custom account name
  final String paymentAccountId; // the CashAccount money left, when known
  final String status;         // approved | pending | rejected
  final String approvedBy;
  final String createdBy;

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
    this.receiptUrl = '',
    this.paymentMethod = 'cash',
    this.paymentAccountId = '',
    this.status = 'approved',
    this.approvedBy = '',
    this.createdBy = '',
  });

  factory Expense.fromFirestore(Map<String, dynamic> data, String id) {
    return Expense(
      id: id,
      category: data['category']?.toString() ?? 'other',
      amount: data['amount']?.toString() ?? '0',
      date: data['date']?.toString() ?? '',
      note: data['note']?.toString() ?? '',
      recipient: data['recipient']?.toString() ?? '',
      isRecurring: data['isRecurring'] as bool? ?? false,
      recurrenceType: data['recurrenceType']?.toString() ?? '',
      nextDueDate: data['nextDueDate']?.toString() ?? '',
      templateId: data['templateId']?.toString() ?? '',
      receiptUrl: data['receiptUrl']?.toString() ?? '',
      paymentMethod: data['paymentMethod']?.toString() ?? 'cash',
      paymentAccountId: data['paymentAccountId']?.toString() ?? '',
      status: data['status']?.toString() ?? 'approved',
      approvedBy: data['approvedBy']?.toString() ?? '',
      createdBy: data['createdBy']?.toString() ?? '',
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
      'paymentMethod': paymentMethod,
      if (paymentAccountId.isNotEmpty) 'paymentAccountId': paymentAccountId,
      'status': status,
      'createdBy': createdBy,
      if (isRecurring) 'recurrenceType': recurrenceType,
      if (isRecurring && nextDueDate.isNotEmpty) 'nextDueDate': nextDueDate,
      if (templateId.isNotEmpty) 'templateId': templateId,
      if (receiptUrl.isNotEmpty) 'receiptUrl': receiptUrl,
      if (approvedBy.isNotEmpty) 'approvedBy': approvedBy,
    };
  }

  Expense copyWith({
    String? category,
    String? amount,
    String? date,
    String? note,
    String? recipient,
    bool? isRecurring,
    String? recurrenceType,
    String? nextDueDate,
    String? templateId,
    String? receiptUrl,
    String? paymentMethod,
    String? paymentAccountId,
    String? status,
    String? approvedBy,
    String? createdBy,
  }) {
    return Expense(
      id: id,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
      recipient: recipient ?? this.recipient,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      templateId: templateId ?? this.templateId,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentAccountId: paymentAccountId ?? this.paymentAccountId,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
