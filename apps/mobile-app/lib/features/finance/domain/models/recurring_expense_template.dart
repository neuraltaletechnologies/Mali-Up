class RecurringExpenseTemplate {
  final String id;
  final String category;
  final String amount;
  final String note;
  final String recipient;
  final String recurrenceType; // 'monthly' | 'weekly'
  final String nextDueDate;    // ISO date YYYY-MM-DD
  final bool isActive;

  RecurringExpenseTemplate({
    required this.id,
    required this.category,
    required this.amount,
    required this.note,
    required this.recipient,
    required this.recurrenceType,
    required this.nextDueDate,
    this.isActive = true,
  });

  factory RecurringExpenseTemplate.fromMap(Map<String, dynamic> data, String id) {
    return RecurringExpenseTemplate(
      id: id,
      category: data['category']?.toString() ?? 'Other',
      amount: data['amount']?.toString() ?? '0',
      note: data['note']?.toString() ?? '',
      recipient: data['recipient']?.toString() ?? '',
      recurrenceType: data['recurrenceType']?.toString() ?? 'monthly',
      nextDueDate: data['nextDueDate']?.toString() ?? '',
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'amount': amount,
      'note': note,
      'recipient': recipient,
      'recurrenceType': recurrenceType,
      'nextDueDate': nextDueDate,
      'isActive': isActive,
    };
  }

  String get nextDueDateLabel {
    try {
      final d = DateTime.parse(nextDueDate);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return nextDueDate;
    }
  }

  String get recurrenceLabel {
    switch (recurrenceType) {
      case 'weekly':  return 'Every week';
      case 'monthly': return 'Every month';
      default:        return recurrenceType;
    }
  }

  /// Calculates the next due date after the given reference date.
  static String computeNextDue(String recurrenceType, DateTime from) {
    final DateTime next;
    if (recurrenceType == 'weekly') {
      next = from.add(const Duration(days: 7));
    } else {
      // monthly
      next = DateTime(from.year, from.month + 1, from.day);
    }
    return '${next.year}-${next.month.toString().padLeft(2, '0')}-${next.day.toString().padLeft(2, '0')}';
  }
}
