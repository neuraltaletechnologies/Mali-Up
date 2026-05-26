class CashTransaction {
  final String id;
  final String type; // 'deposit' | 'withdrawal' | 'transfer'
  final double amount;
  final String fromAccountId;
  final String toAccountId;
  final String description;
  final String date; // ISO date string
  final String reference;
  final String activityCategory; // 'operating' | 'investing' | 'financing'
  final String createdBy;

  const CashTransaction({
    required this.id,
    required this.type,
    required this.amount,
    this.fromAccountId = '',
    this.toAccountId = '',
    this.description = '',
    required this.date,
    this.reference = '',
    this.activityCategory = 'operating',
    this.createdBy = '',
  });

  factory CashTransaction.fromFirestore(Map<String, dynamic> data, String id) {
    return CashTransaction(
      id: id,
      type: data['type']?.toString() ?? 'deposit',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      fromAccountId: data['fromAccountId']?.toString() ?? '',
      toAccountId: data['toAccountId']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      date: data['date']?.toString() ?? '',
      reference: data['reference']?.toString() ?? '',
      activityCategory: data['activityCategory']?.toString() ?? 'operating',
      createdBy: data['createdBy']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      'amount': amount,
      'fromAccountId': fromAccountId,
      'toAccountId': toAccountId,
      'description': description,
      'date': date,
      'reference': reference,
      'activityCategory': activityCategory,
      'createdBy': createdBy,
    };
  }

  CashTransaction copyWith({
    String? type,
    double? amount,
    String? fromAccountId,
    String? toAccountId,
    String? description,
    String? date,
    String? reference,
    String? activityCategory,
    String? createdBy,
  }) {
    return CashTransaction(
      id: id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      fromAccountId: fromAccountId ?? this.fromAccountId,
      toAccountId: toAccountId ?? this.toAccountId,
      description: description ?? this.description,
      date: date ?? this.date,
      reference: reference ?? this.reference,
      activityCategory: activityCategory ?? this.activityCategory,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  bool get isDeposit => type == 'deposit';
  bool get isWithdrawal => type == 'withdrawal';
  bool get isTransfer => type == 'transfer';
}
