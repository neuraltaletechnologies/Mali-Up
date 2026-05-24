class Budget {
  final String id;
  final String category;
  final double amount;
  final int month; // 1–12
  final int year;

  const Budget({
    required this.id,
    required this.category,
    required this.amount,
    required this.month,
    required this.year,
  });

  factory Budget.fromFirestore(Map<String, dynamic> data, String id) {
    return Budget(
      id: id,
      category: data['category']?.toString() ?? 'other',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      month: (data['month'] as num?)?.toInt() ?? DateTime.now().month,
      year: (data['year'] as num?)?.toInt() ?? DateTime.now().year,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'category': category,
        'amount': amount,
        'month': month,
        'year': year,
      };
}
